// SPDX-License-Identifier: MIT
// ============ External Imports ============
const { ethers, waffle } = require('hardhat');
const { provider } = waffle;
const { expect }  = require('chai');
const { scenarios } = require('./scenarios.json');
const { deployTestContractSetup } = require("./helpers/deploy");
const { NAME, SYMBOL, FEE_PCT, PCT_BASE } = require('./helpers/constants');


describe("New Market contract is deployed through Market Factory", async () => {
  let market, signer1, signer2, signer3, signer4, signer5, deploymentGas;

  // deploy market contract (runs before all tests in this file, regardless of line placement)
  before(async() => {
    // get random signers
    [signer1, signer2, signer3, signer4, signer5] = await ethers.getSigners();

    // deploy market contract
    const contract = await(deployTestContractSetup(NAME, SYMBOL, provider, signer1));
    market = contract.market
    deploymentGas = contract.gasUsed;
  });

  describe("Interacting with market", async() => {
    describe("scenarios", () => {
      let slippageTokens = 1;
      let slippageEth = 1;
      for(let i=0; i<scenarios.length; i++) {
        const {
          ethContributed,
          tokensReturned,
          initialSupply,
          finalSupply,
          initialPoolBalance,
          finalPoolBalance,
          rewards
        } = scenarios[i];

        // test changes to pool balance and total supply when supply is initialized
        describe(`signer 1 initialized the market supply with ${ethContributed} ETH`, async () => {
          // this is gonna run before each of the the test blocks below
          beforeEach(async() => {
            await market.connect(signer1).buy(ethers.utils.parseEther(ethContributed), slippageTokens, {
              value: ethers.utils.parseEther(ethContributed)
            });
          });
          it("It increased the market's pool balance", async() => {
            const newPoolBalance = await market.poolBalance();
            expect(newPoolBalance.toString()).eq(ethers.utils.parseEther(ethContributed).toString());
          });

          it("And increased the market's total token supply in circulation", async() => {
            const tokenSupply = await market.totalSupply();
            expect(tokenSupply.toString()).eq(finalSupply);
          });

          // test layer actions
          describe(`signer2 then contributed ${ethContributed} ETH`, () => {
            beforeEach(async() => {
              await market.connect(signer2).buy(ethers.utils.parseEther(ethContributed), slippageTokens, {
                value: ethers.utils.parseEther(ethContributed)
              });
            });
            it("it increased the market's pool balance", async() => {
              const newPoolBalance = await market.poolBalance();
              expect(newPoolBalance.toString()).eq(ethers.utils.parseEther(ethContributed).toString());
            });

            it("and increased the market's total token supply in circulation", async() => {
              const tokenSupply = await market.totalSupply();
              expect(tokenSupply.toString()).eq(finalSupply);
            });

            it("signer1 can add a layer to the market", async() => {
              const layerAdded = await market.connect(signer1).addLayer("www.verse.xyz");
              expect(layerAdded).eq(true);
            });

            it("non-token-holding address cannot add a layer to the market", async() => {
              await expect(market.connect(signer3).addLayer("www.verse.xyz")).to.be.reverted;
            });
          });
        });
      }
    })
  })
})