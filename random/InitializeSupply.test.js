// SPDX-License-Identifier: MIT
// ============ External Imports ============
const { ethers, waffle } = require('hardhat');
const { provider } = waffle;
const { expect }  = require('chai');
const { deployTestContractSetup } = require("../test/helpers/deploy");
const { NAME, SYMBOL } = require('../test/helpers/constants');

describe("Initialize supply", async () => {
  let market, signer, creator;
  let amount = 1**18;

  // runs before all tests in this file, regardless of line placement
  before(async() => {
    // get random signer
    [signer, creator] = await ethers.getSigners();

    // deploy market contract
    const contract = await(deployTestContractSetup(NAME, SYMBOL, provider, creator));
    market = contract.market
  });

  it('Total supply is 0 before initialization', async() => {
    const totalSupply = await market.totalSupply();
    expect(totalSupply).to.equal(0);
  });

  // it('Creator is able to initialize supply', async() => {
  //   await market.connect(creator).initializeSupply(ethers.utils.parseEther(amount.toString()), {
  //     value: ethers.utils.parseEther(amount.toString()),
  //   });
  //   const supplyInitialized = await market.supplyInitialized();
  //   const supply = await market.totalSupply();
  //   console.log(supply);
  //   expect(supplyInitialized).to.equal(true);
  // });

  // it('Non-creator is not able to initialize supply', async() => {
  //   await expect(market.connect(signer).initializeSupply(ethers.utils.parseEther(amount.toString()), {
  //     value: ethers.utils.parseEther(amount.toString()),
  //   })).to.be.revertedWith("only creator can initialize supply");
  // });

})