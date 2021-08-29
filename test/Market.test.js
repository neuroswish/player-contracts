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

      // test token exchange actions
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
          await cryptomedia.connect(signer1).createLayer("www.verse.xyz");
          const created = await cryptomedia.created(signer1.address);
          expect(created).eq(true);
        });

        it("Second token-holding address can add a layer to the collection", async() => {
          await cryptomedia.connect(signer2).createLayer("www.verse.co");
          const created = await cryptomedia.created(signer2.address);
          expect(created).eq(true);
        });

        it("Non-token-holding address cannot add a layer to the collection", async() => {
          await expect(cryptomedia.connect(signer4).createLayer("www.verse.xyz")).to.be.revertedWith("MUST HOLD TOKENS");
        });

        it("Creator cannot add a second layer to the collection", async() => {
          await expect(cryptomedia.connect(signer1).createLayer("www.verse.xyz")).to.be.revertedWith("ALREADY CONTRIBUTED");
        });

        it("Creator can create another layer after removing the first", async() => {
          await cryptomedia.connect(signer1).removeCreatedLayer();
          const createdShouldBeFalse = await cryptomedia.created(signer1.address)
          expect(createdShouldBeFalse).eq(false);
          await cryptomedia.connect(signer1).createLayer("www.verse.com");
          const createdShouldBeTrue = await cryptomedia.created(signer1.address);
          expect(createdShouldBeTrue).eq(true);
        });

        it("Creator cannot create another layer in the collection", async() => {
          await expect(cryptomedia.connect(signer1).createLayer("www.verse.io")).to.be.revertedWith("ALREADY CONTRIBUTED");
        });

        it("Creator can remove a created layer", async() => {
          await cryptomedia.connect(signer1).removeCreatedLayer();
          const created = await cryptomedia.created(signer1.address);
          expect(created).eq(false);
        });

        it("Token-holding non-creator cannot remove a layer that has not been created yet", async() => {
          await expect(cryptomedia.connect(signer3).removeCreatedLayer()).to.be.revertedWith("NOTHING TO REMOVE");
        });
      });

      describe("Layer-curating actions work properly", () => {
       
        it("Token-holding address can curate a layer in the collection", async() => {
          await cryptomedia.connect(signer3).curateLayer(signer1.address);
          const curated = await cryptomedia.curated(signer3.address);
          expect(curated).eq(true);
          const result = await cryptomedia.getLayer(signer3.address)
          expect(result[0]).eq(signer1.address);
        });

        it("Token-holders cannot repeatedly curate a layer that they have already curated", async() => {
          await expect(cryptomedia.connect(signer3).curateLayer(signer1.address)).to.be.revertedWith("ALREADY CONTRIBUTED");
        });

        it("Curators cannot curate another layer before removing the first curation", async() => {
          await expect(cryptomedia.connect(signer3).curateLayer(signer1.address)).to.be.revertedWith("ALREADY CONTRIBUTED");
        });

        it("Non-token-holding address cannot curate a layer in the collection", async() => {
          await expect(cryptomedia.connect(signer4).curateLayer(signer1.address)).to.be.revertedWith("MUST HOLD TOKENS");
        });

        it("Curator can remove curation for a layer in the collection", async() => {
          await cryptomedia.connect(signer3).removeCuratedLayer();
          const curated = await cryptomedia.curated(signer3.address);
          expect(curated).eq(false);
        });

        it("Curator can curate another layer after removing the first", async() => {
          await cryptomedia.connect(signer3).curateLayer(signer2.address);
          const curatedShouldBeTrue = await cryptomedia.curated(signer3.address);
          expect(curatedShouldBeTrue).eq(true);
        });

        it("Token-holder cannot remove curation for a layer that he has not curated", async() => {
          await expect(cryptomedia.connect(signer2).removeCuratedLayer()).to.be.revertedWith("NOTHING TO REMOVE");
        });
      });
    }
  });
})