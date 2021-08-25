// DEPLOY LOGIC CONTRACT
async function deploy(name, args = []) {
  const Implementation = await ethers.getContractFactory(name);
  const contract = await Implementation.deploy(...args);
  return contract.deployed();
}

// GET CRYPTOMEDIA CONTRACT FROM CRYPTOMEDIA FACTORY EVENT LOGS
async function getCryptomediaContractFromEventLogs(
  provider,
  factory,
  signer,
) {
  // get logs emitted from Cryptomedia Factory
  const logs = await provider.getLogs({ address: factory.address });

  // parse events from logs
  const CryptomediaFactory = await ethers.getContractFactory('CryptomediaFactory');
  const events = logs.map((log) => CryptomediaFactory.interface.parseLog(log));

  // extract cryptomedia clone address from CryptomediaDeployed log
  const cryptomediaCloneAddress = events[0]['args'][0];

  // create new instance of contract with Cryptomedia Logic interface + cryptomedia proxy address
  const Cryptomedia = await ethers.getContractFactory('Cryptomedia');
  const cryptomedia = new ethers.Contract(
    cryptomediaCloneAddress,
    Cryptomedia.interface,
    signer,
  );
  return cryptomedia;
}

async function deployTestContractSetup(
  name,
  provider,
  signer,
) {
  
  // DEPLOY CRYPTOMEDIA FACTORY
  const bondingCurve = await deploy('BondingCurve');
  const CryptomediaFactory = await deploy('CryptomediaFactory', [bondingCurve.address]);

  //create new factory instance
  const factory = new ethers.Contract(CryptomediaFactory.address, CryptomediaFactory.interface, signer);
  await factory.createCryptomedia(name);
  const cryptomedia = await getCryptomediaContractFromEventLogs(provider, factory, signer);

  const deployment = await factory.createCryptomedia(name);
  const receipt = await deployment.wait();
  const gasUsed = receipt.gasUsed;
  return {
    cryptomedia, gasUsed
  };
}


module.exports = {
deployTestContractSetup,
getCryptomediaContractFromEventLogs,
};

