const SimpleStorage = artifacts.require("SimpleStorage");
//const TutorialToken = artifacts.require("TutorialToken");
const PhillipsToken = artifacts.require("PhillipsToken");
const ComplexStorage = artifacts.require("ComplexStorage");

var SupplyChainStorage = artifacts.require("SupplyChainStorage");
var SalesContract = artifacts.require("SalesContract");
var Verify = artifacts.require("Verify");


require('@openzeppelin/test-helpers/configure')({ provider: web3.currentProvider,
      environment: 'truffle'});


const { singletons } = require('@openzeppelin/test-helpers');
/*
module.exports = function(deployer) {
  deployer.deploy(SimpleStorage);
  deployer.deploy(TutorialToken);
  deployer.deploy(ComplexStorage);
};
*/

module.exports = async function (deployer, network, accounts) {

  if(network == 'development') {
    //in a test environment an ERC777 token requires deploying an ERC1820 registry
    await singletons.ERC1820Registry(accounts[0]);
  }

  await deployer.deploy(PhillipsToken);

  await deployer.deploy(SimpleStorage);
  await deployer.deploy(ComplexStorage);

  deployer.deploy(Verify)
      .then(() => Verify.deployed())
      .then(() => deployer.link(Verify, SupplyChainStorage))
      // Wait until the storage contract is deployed
      .then(() => deployer.deploy(SupplyChainStorage))
      .then(() => SupplyChainStorage.deployed())
      .then(() => deployer.deploy(SalesContract, SupplyChainStorage.address))

}
