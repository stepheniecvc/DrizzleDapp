import Web3 from "web3";
//import ComplexStorage from "./contracts/ComplexStorage.json";
//import SimpleStorage from "./contracts/SimpleStorage.json";
//import TutorialToken from "./contracts/TutorialToken.json";
import PhillipsToken from "./contracts/PhillipsToken.json";
import SalesContract from "./contracts/SalesContract.json";

const options = {
  web3: {
    block: false,
    customProvider: new Web3("ws://localhost:8545"),
  },
  //contracts: [SimpleStorage, ComplexStorage, PhillipsToken],
  contracts: [PhillipsToken, SalesContract],
  events: {
    SalesContract: ["SaleContractRegistered", "AcknowledgeContract"],
  },
};

export default options;
