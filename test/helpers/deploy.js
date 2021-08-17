// DEPLOY LOGIC CONTRACT
async function deploy(name, args = []) {
  const Implementation = await ethers.getContractFactory(name);
  const contract = await Implementation.deploy(...args);
  return contract.deployed();
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

  // create new instance of contract with Market Logic interface + market proxy address
  const Market = await ethers.getContractFactory('Market');
  const market = new ethers.Contract(
    marketCloneAddress,
    Market.interface,
    signer,
  );
  return market;
}

async function deployTestContractSetup(
  name,
  symbol,
  provider,
  signer,
) {
  
  // DEPLOY MARKET FACTORY
  const bondingCurve = await deploy('BondingCurve');
  const MarketFactory = await deploy('MarketFactory', [bondingCurve.address]);

  //create new factory instance
  const factory = new ethers.Contract(MarketFactory.address, MarketFactory.interface, signer);
  await factory.createMarket(name, symbol);
  const market = await getMarketContractFromEventLogs(provider, factory, signer);

  const deployment = await factory.createMarket(name, symbol);
  const receipt = await deployment.wait();
  const gasUsed = receipt.gasUsed;
  return {
    market, gasUsed
  };
}


module.exports = {
deployTestContractSetup,
getMarketContractFromEventLogs,
};

