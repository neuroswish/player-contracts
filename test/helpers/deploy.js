const {
  eth,
  approve,
} = require('./utils');

// DEPLOY LOGIC CONTRACT
async function deploy(name, args = []) {
  const Implementation = await ethers.getContractFactory(name);
  const contract = await Implementation.deploy(...args);
  return contract.deployed();
}

// DEPLOY MARKET LOGIC
async function deployMarket(
  reserveRatio,
  slopeN = 1,
  slopeD,
  feePct
) {
  return deploy('Market', [
    reserveRatio,
    slopeN,
    slopeD
  ]);
}

