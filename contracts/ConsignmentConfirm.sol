pragma solidity >= 0.6.0 < 0.7.0;

import "./SupplyChainStorage.sol";

contract ConsignmentConfirm{

  //event
  event ConsignmentConfirmed(address batchNo, string DONumber);

  /* Storage Variables */
  SupplyChainStorage supplyChainStorage;


  //constructor
  constructor(address _supplyChainAddress) public {
      supplyChainStorage = SupplyChainStorage(_supplyChainAddress);
  }

/*
  //seller calls this to confirm on consignment
  function confirmConsignment(address batchNo, string memory DONumber) public
                                                        returns (bool result){
      //if confirm successfully
      if(supplyChainStorage.confirmConsignment(batchNo, DONumber) == true)
      {
        //emit event
        emit ConsignmentConfirmed(batchNo, DONumber);
        return (true);
      }
      else
        return (false);
  }
*/
}
