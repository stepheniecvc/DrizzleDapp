pragma solidity >= 0.6.0 < 0.7.0;

import "./SupplyChainStorage.sol";


contract Acknowledgement{

  //event
  event SellerFinalAcknowledgement(address batchNo, uint256 date);
  event BuyerFinalAcknowledgement(address batchNo, uint256 date);

  /* Storage Variables */
  SupplyChainStorage supplyChainStorage;

  //constructor
  constructor(address _supplyChainAddress) public {
      supplyChainStorage = SupplyChainStorage(_supplyChainAddress);
  }

  //seller call this function to acknowledge on the final quality and quantity
  function finalAcknowledgeBySeller(address batchNo, uint256 date) public returns (bool result){
    result = supplyChainStorage.finalAcknowledgeBySeller(batchNo);

    emit SellerFinalAcknowledgement(batchNo, date);

    return (result);

  }

  //buyer call this function to acknowledge on the final quality and quantity
  function finalAcknowledgeByBuyer(address batchNo, uint256 date) public returns (bool result){
    result = supplyChainStorage.finalAcknowledgeByBuyer(batchNo);

    emit BuyerFinalAcknowledgement(batchNo, date);

    return (result);

  }

}
