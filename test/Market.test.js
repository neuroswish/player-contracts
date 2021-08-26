// SPDX-License-Identifier: MIT
// ============ External Imports ============
const { ethers, waffle } = require('hardhat');
const { provider } = waffle;
const { expect }  = require('chai');
const { scenarios } = require('./scenarios.json');
const { deployTestContractSetup } = require("./helpers/deploy");
const { NAME } = require('./helpers/constants');


describe("New Market contract is deployed through Cryptomedia Factory", async () => {
  let cryptomedia, signer1, signer2, signer3, signer4, signer5, deploymentGas;

  // deploy market contract (runs before all tests in this file, regardless of line placement)
  before(async() => {
    // get random signers
    [signer1, signer2, signer3, signer4, signer5] = await ethers.getSigners();

    // deploy market contract
    const contract = await(deployTestContractSetup(NAME, provider, signer1));
    cryptomedia = contract.cryptomedia
    deploymentGas = contract.gasUsed;
  });

  describe("Interacting with cryptomedia", async() => {
    // scenarios tested using wolfram
    describe("scenarios", () => {
      let slippageTokens = 1;
      let slippageEth = 1;
      for(let i=0; i<scenarios.length; i++) {
        const {
          initialEthContributed,
          initializedPoolBalance,
          initializedTotalSupply,
          ethContributed,
          resultingPoolBalance,
          resultingTotalSupply
        } = scenarios[i];

        // test changes to pool balance and total supply when supply is initialized
        describe(`signer 1 initialized the market supply with ${initialEthContributed} ETH`, async () => {
          // this is gonna run before each of the the test blocks below
          before(async() => {
            await cryptomedia.connect(signer1).buy(ethers.utils.parseEther(initialEthContributed), slippageTokens, {
              value: ethers.utils.parseEther(initialEthContributed)
            });
          });
          it("it increased the market's pool balance", async() => {
            const initialPoolBalance = await cryptomedia.poolBalance();
            expect(initialPoolBalance.toString()).eq(ethers.utils.parseEther(initializedPoolBalance).toString());
          });

          it("and increased the market's total token supply in circulation", async() => {
            const initialTokenSupply = await cryptomedia.totalSupply();
            expect(initialTokenSupply.toString()).eq(initializedTotalSupply);
          });

          // test layer actions
          describe(`signer2 then contributed ${ethContributed} ETH`, () => {
            before(async() => {
              await cryptomedia.connect(signer2).buy(ethers.utils.parseEther(ethContributed), slippageTokens, {
                value: ethers.utils.parseEther(ethContributed)
              });
            });
            it("it increased the market's pool balance", async() => {
              const resultPoolBalance = await cryptomedia.poolBalance();
              expect(resultPoolBalance.toString()).eq(ethers.utils.parseEther(resultingPoolBalance).toString());
            });

            it("and increased the market's total token supply in circulation", async() => {
              const resultTotalSupply = await cryptomedia.totalSupply();
              expect(resultTotalSupply.toString()).eq(resultingTotalSupply);
            });

            it("signer1 can add a layer to the collection", async() => {
              await cryptomedia.connect(signer1).addLayer("www.verse.xyz");
              const created = await cryptomedia.created(signer1.address);
              expect(created).eq(true);
            });

            it("non-token-holding address cannot add a layer to the collection", async() => {
              await expect(cryptomedia.connect(signer3).addLayer("www.verse.xyz")).to.be.revertedWith("MUST HOLD TOKENS");
            });
          });
        });
      }
    })
  })
})