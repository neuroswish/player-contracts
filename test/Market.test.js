// SPDX-License-Identifier: MIT
// ============ External Imports ============
const { ethers, waffle } = require('hardhat');
const { provider } = waffle;
const { expect }  = require('chai');
const { scenarios } = require('./scenarios.json');
const { deployTestContractSetup } = require("./helpers/deploy");
const { NAME } = require('./helpers/constants');


describe("New Cryptomedia is deployed through Cryptomedia Factory", async () => {
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

  // scenarios tested using wolfram + python
  describe("For the following scenarios", () => {
    for(let i=0; i<scenarios.length; i++) {
      const {
        firstEthContributed,
        firstSlippageShouldNotRevert,
        firstPoolBalance,
        firstTotalSupply,
        signer1Balance,
        secondEthContributed,
        signer2SlippageShouldRevert,
        signer2SlippageShouldNotRevert,
        secondPoolBalance,
        secondTotalSupply,
        signer2Balance,
        thirdEthContributed,
        signer3SlippageShouldNotRevert,
        thirdPoolBalance,
        thirdTotalSupply,
        signer3Balance,
        sellAmount,
        sellSlippage,
        poolBalancePostSell,
        totalSupplyPostSell,
        signerBalancePostSell,
      } = scenarios[i];

      // this is gonna run before each of the the test blocks below
      before(async() => {
        await cryptomedia.connect(signer1).buy(ethers.utils.parseEther(firstEthContributed), firstSlippageShouldNotRevert, {
          value: ethers.utils.parseEther(firstEthContributed)
        });
      });
      
      // test changes to pool balance and total supply when supply is initialized
      describe("The market has been initialized", async () => {
        it("The pool balance has been increased by the correct amount", async() => {
          const returnedFirstPoolBalance = await cryptomedia.poolBalance();
          expect(returnedFirstPoolBalance.toString()).eq(ethers.utils.parseEther(firstPoolBalance).toString());
        });

        it("The total supply has been increased by the correct amount", async() => {
          const returnedFirstTokenSupply = await cryptomedia.totalSupply();
          expect(returnedFirstTokenSupply.toString()).eq(firstTotalSupply);
        });

        it("And signer 1's balance is correct", async() => {
          const returnedSigner1Balance = await cryptomedia.balanceOf(signer1.address);
          expect(returnedSigner1Balance.toString()).eq(signer1Balance);
        });

        it("Signer2 buying tokens outside the specified slippage reverts", async() => {
          await expect(cryptomedia.connect(signer2).buy(ethers.utils.parseEther(secondEthContributed), signer2SlippageShouldRevert, {
            value: ethers.utils.parseEther(secondEthContributed)
          })).to.be.revertedWith("SLIPPAGE");
        });
        
      });

      // test layer actions
      describe("Token-exchange actions work properly", async () => {
        before(async() => {
          await cryptomedia.connect(signer2).buy(ethers.utils.parseEther(secondEthContributed), signer2SlippageShouldNotRevert, {
            value: ethers.utils.parseEther(secondEthContributed)
          });
        });
        it("New signer buying tokens increases market's pool balance by the correct amount", async() => {
          const returnedSecondPoolBalance = await cryptomedia.poolBalance();
          expect(returnedSecondPoolBalance.toString()).eq(ethers.utils.parseEther(secondPoolBalance).toString());
        });

        it("And increases the market's total supply by the correct amount", async() => {
          const returnedSecondTotalSupply = await cryptomedia.totalSupply();
          expect(returnedSecondTotalSupply.toString()).eq(secondTotalSupply);
        });

        it("And signer 2's balance is correct", async() => {
          const returnedSigner2Balance = await cryptomedia.balanceOf(signer2.address);
          expect(returnedSigner2Balance.toString()).eq(signer2Balance);
        });
        

        it("Third signer buying tokens increases the market's pool balance by the correct amount", async() => {
          await cryptomedia.connect(signer3).buy(ethers.utils.parseEther(thirdEthContributed), signer3SlippageShouldNotRevert, {
            value: ethers.utils.parseEther(thirdEthContributed)
          });
          const returnedThirdPoolBalance = await cryptomedia.poolBalance();
          expect(returnedThirdPoolBalance.toString()).eq(ethers.utils.parseEther(thirdPoolBalance).toString());
        });

        it("And increases the market's total supply by the correct amount", async() => {
          const returnedThirdTotalSupply = await cryptomedia.totalSupply();
          expect(returnedThirdTotalSupply.toString()).eq(thirdTotalSupply);
        });

        it("And signer 3's balance is correct", async() => {
          const returnedSigner3Balance = await cryptomedia.balanceOf(signer3.address);
          expect(returnedSigner3Balance.toString()).eq(signer3Balance);
        });

        it("Signer selling tokens decreases the market's pool balance by the correct amount", async() => {
          await cryptomedia.connect(signer2).sell(sellAmount, sellSlippage);
          const returnedPoolBalancePostSell = await cryptomedia.poolBalance();
          expect(returnedPoolBalancePostSell.toString()).eq(poolBalancePostSell);
        });

        it("Signer selling tokens decreases the market's total supply by the correct amount", async() => {
          const returnedTotalSupplyPostSell = await cryptomedia.totalSupply();
          expect(returnedTotalSupplyPostSell.toString()).eq(totalSupplyPostSell);
        });

        it("Signer selling tokens decreases the signer's balance by the correct amount", async() => {
          const returnedSignerBalancePostSell = await cryptomedia.balanceOf(signer2.address);
          expect(returnedSignerBalancePostSell.toString()).eq(signerBalancePostSell);
        });
      });

      describe("Layer-creating actions work properly", () => {

        it("Token-holding address can add a layer to the collection", async() => {
          await cryptomedia.connect(signer1).addLayer("www.verse.xyz");
          const created = await cryptomedia.created(signer1.address);
          expect(created).eq(true);
        });

        it("Non-token-holding address cannot add a layer to the collection", async() => {
          await expect(cryptomedia.connect(signer4).addLayer("www.verse.xyz")).to.be.revertedWith("MUST HOLD TOKENS");
        });

        it("Creator cannot add a second layer to the collection", async() => {
          await expect(cryptomedia.connect(signer1).addLayer("www.verse.xyz")).to.be.revertedWith("ALREADY CREATED");
        });

        it("Creator can remove a created layer", async() => {
          await cryptomedia.connect(signer1).removeLayer();
          const created = await cryptomedia.created(signer1.address);
          expect(created).eq(false);
        });

        it("Token-holding non-creator cannot remove a layer that has not been created yet", async() => {
          await expect(cryptomedia.connect(signer2).removeLayer()).to.be.revertedWith("HAVE NOT CREATED");
        });
      });

      describe("Curating actions work properly", () => {
       
        it("Token-holding address can curate a layer in the collection", async() => {
          await cryptomedia.connect(signer3).curate(signer1.address);
          const isCurating = await cryptomedia.isCuratingLayer(signer3.address, signer1.address);
          expect(isCurating).eq(true);
        });

        it("Token-holders cannot repeatedly curate a layer that they have already curated", async() => {
          await expect(cryptomedia.connect(signer3).curate(signer1.address)).to.be.revertedWith("ALREADY CURATED");
        });

        it("Non-token-holding address cannot curate a layer in the collection", async() => {
          await expect(cryptomedia.connect(signer4).curate(signer1.address)).to.be.revertedWith("MUST HOLD TOKENS");
        });

        it("Curator can remove curation for a layer in the collection", async() => {
          await cryptomedia.connect(signer3).removeCuration(signer1.address);
          const isCurating = await cryptomedia.isCuratingLayer(signer3.address, signer1.address);
          expect(isCurating).eq(false);
        });

        it("Token-holder cannot remove curation for a layer that he has not curated", async() => {
          await expect(cryptomedia.connect(signer2).removeCuration(signer1.address)).to.be.revertedWith("HAVE NOT CURATED");
        });
      });
    }
  });
})