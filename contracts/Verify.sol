pragma solidity >= 0.6.0 < 0.7.0;

library Verify{

  //transaction state
  enum TState {
     acknowledgeByBuyer,   //0
     registeredAllDO,      //1
     registeredAllStorage, //2
     finalAgreeBySeller,   //3
     finalAgreeByBuyer,    //4
     isPrepayment,         //5
     completed             //6
  }

  function verifyString(string memory s1, string memory s2) public pure returns (bool result){
    if(keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2)))
      return true;
    else
      return false;
  }

  function verifyAndReturnIndex(uint index, uint arrayLength) public pure returns (uint){
    if((index < 0) || (index >= arrayLength))
    {
      index = arrayLength - 1;   //set it to the last index if index is -ve or over the Array size
    }

    return index;
  }
}
