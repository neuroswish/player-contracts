// SPDX-License-Identifier: MIT
// ============ External Imports ============
const { ethers, waffle } = require('hardhat');
const { provider } = waffle;
const { expect }  = require('chai');
const { deployTestContractSetup } = require("./helpers/deploy");
const { NAME } = require('./helpers/constants');


describe("Deploy new cryptomedia via clone proxy from Cryptomedia Factory", async () => {
  let cryptomedia, signer, creator, deploymentGas;

  // runs before all tests in this file, regardless of line placement
  before(async() => {
    // get random signer
    [signer, creator] = await ethers.getSigners();

    // deploy cryptomedia contract
    const contract = await(deployTestContractSetup(NAME, provider, creator));
    cryptomedia = contract.cryptomedia
    deploymentGas = contract.gasUsed;
    console.log(deploymentGas);
  });

  it('Cryptomedia has been initialized', async() => {
    const name = await cryptomedia.name();
    expect(name).to.equal(NAME);
  });

  it('Uses 184019 gas', async() => {
    expect(deploymentGas.toString()).to.eq("184019");
  });

  it('Pool balance is 0', async() => {
    const poolBalance = await cryptomedia.poolBalance();
    expect(poolBalance).to.equal(0);
  });

  it('Total supply is 0', async() => {
    const totalSupply = await cryptomedia.totalSupply();
    expect(totalSupply).to.equal(0);
  });

  it('Random account token balance is 0', async() => {
    const randomBalance = await cryptomedia.balanceOf(signer.address);
    expect(randomBalance).to.equal(0);
  });

  it('Reserve ratio has been initialized', async() => {
    const reserveRatio = await cryptomedia.reserveRatio();
    expect(reserveRatio).to.equal(333333);
  });

  it('ppm has been initialized', async() => {
    const ppm = await cryptomedia.ppm();
    expect(ppm).to.equal(1000000);
  });

  // it('Fee percentage has been initialized', async() => {
  //   const initializedFeePct = await market.feePct();
  //   const expectedFeePct = ethers.BigNumber.from(FEE_PCT);
  //   expect(initializedFeePct.toString()).to.equal(expectedFeePct);
  // });

  // it('Percentage base has been initialized', async() => {
  //   const initializedPctBase = await market.pctBase();
  //   const expectedPctBase = ethers.BigNumber.from(PCT_BASE);
  //   expect(initializedPctBase.toString()).to.equal(expectedPctBase.toString());
  // });

   it('Cryptomedia has been initialized with bonding curve contract address', async() => {
    const bondingCurveAddress = await cryptomedia.bondingCurve();
  });
})