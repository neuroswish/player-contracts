// SPDX-License-Identifier: MIT
// ============ External Imports ============
const { waffle } = require('hardhat');
const { provider } = waffle;
const { expect } = require('chai');

describe("Deploy", async () => {
  let market, creator;
  before(async() => {
    // GET RANDOM CREATOR
    creator = await ethers.getSigners();
    

    // DEPLOY MARKET CONTRACT

  })
})