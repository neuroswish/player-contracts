// DEPLOY LOGIC CONTRACT
async function deploy(name, args = []) {
  const Implementation = await ethers.getContractFactory(name);
  const contract = await Implementation.deploy(...args);
  return contract.deployed();
}

// DEPLOY MARKET LOGIC
async function deployMarket(
  reserveRatio,
  slopeN,
  slopeD,
  feePct
) {
  return deploy('Market', [
    reserveRatio,
    slopeN,
    slopeD,
    feePct
  ]);
}

// GET MARKET CONTRACT FROM MARKET FACTORY EVENT LOGS
async function getMarketContractFromEventLogs(
  provider,
  factory,
  signer,
) {
  // get logs emitted from Market Factory
  const logs = await provider.getLogs({ address: factory.address });

  // parse events from logs
  const MarketFactory = await ethers.getContractFactory('MarketFactory');
  const events = logs.map((log) => MarketFactory.interface.parseLog(log));

  // extract market clone address from marketDeployed log
  const marketCloneAddress = events[0]['args'][0];

  // instantiate ethers contract with Market Logic interface + market proxy address
  const Market = await ethers.getContractFactory('Market');
  const market = new ethers.Contract(
    marketCloneAddress,
    Market.interface,
    signer,
  );
  return market;
}

async function deployTestContractSetup(
  foundationalMediaURI,
  provider,
  signer,
) {
  
  // DEPLOY MARKET FACTORY
  const MarketFactory = await deploy('MarketFactory');

  // DEPLOY MARKET CLONE
  await MarketFactory.createMarket(foundationalMediaURI);

  // Get market ethers contract
  const market = await getMarketContractFromEventLogs(
    provider,
    MarketFactory,
    signer,
  );

  return {
    market
  };
}


module.exports = {
deployMarket,
deployTestContractSetup,
getMarketContractFromEventLogs,
deploy
};

