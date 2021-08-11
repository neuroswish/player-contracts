// SPDX-License-Identifier: MIT
// ============ External Imports ============
const { ethers, waffle } = require('hardhat');
const { provider } = waffle;
const { expect }  = require('chai');
const { deployTestContractSetup } = require("./helpers/deploy");
const { FOUNDATIONAL_MEDIA_URI } = require('./helpers/constants');


describe("Deploy new market via clone proxy from Market Factory", async () => {
  let market, signer, creator;

  // runs before all tests in this file, regardless of line placement
  before(async() => {
    // get random signer
    [signer, creator] = await ethers.getSigners();

    // deploy market contract
    const contract = await(deployTestContractSetup(FOUNDATIONAL_MEDIA_URI, provider, creator));
    market = contract.market
  });

  it('Market has been initialized with foundational layer', async() => {
    const foundationURI = await market.foundationURI();
    expect(foundationURI).to.equal(FOUNDATIONAL_MEDIA_URI);
  });


  it('Market has been initialized by the foundational layer creator', async() => {
    const foundationalLayerCreator = await market.getLayerCreator(0);
    const marketCreator = await market.creator()
    expect(foundationalLayerCreator).to.equal(marketCreator);
  });

  it('Pool balance is 0', async() => {
    const poolBalance = await market.poolBalance();
    expect(poolBalance).to.equal(0);
  });

  it('Total supply is 0', async() => {
    const totalSupply = await market.totalSupply();
    expect(totalSupply).to.equal(0);
  });

  it('Creator token balance is 0', async() => {
    const marketCreator = await market.creator()
    const creatorBalance = await market.totalBalance(marketCreator);
    expect(creatorBalance).to.equal(0);
  });

  it('Random account token balance is 0', async() => {
    const randomBalance = await market.totalBalance(signer.address);
    expect(randomBalance).to.equal(0);
  });
})