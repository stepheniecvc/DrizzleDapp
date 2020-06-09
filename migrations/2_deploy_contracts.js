const SimpleStorage = artifacts.require("SimpleStorage");
//const TutorialToken = artifacts.require("TutorialToken");
const PhillipsToken = artifacts.require("PhillipsToken");
const ComplexStorage = artifacts.require("ComplexStorage");


require('@openzeppelin/test-helpers/configure')({ provider: web3.currentProvider,
      environment: 'truffle'});


const { singletons } = require('@openzeppelin/test-helpers');
/*
try {
    require('openzeppelin-test-helpers/configure')({ web3 });
} catch (e) {
    console.error("ERROR: Failed openzeppelin-test-helpers configuration.")
}
*/
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


}
