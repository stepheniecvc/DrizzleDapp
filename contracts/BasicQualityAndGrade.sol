pragma solidity >= 0.6.0 < 0.7.0;

contract BasicQualityAndGrade{


  struct BasicInfo{
    string originCountry;
    string description;
    uint256 date;
  }


  mapping(address => bool) certifyFlag;  //false by default
  mapping(address => BasicInfo) BasicInformation;

  function certifyBasicInfo(address blockNo, string memory originCountry,
                                  string memory description, uint256 date)
                                  public {
      BasicInformation[blockNo].originCountry = originCountry;
      BasicInformation[blockNo].description = description;
      BasicInformation[blockNo].date = date;


  }



  function getBasicDetails(address blockNo) public view returns
                                  (string memory originCountry,
                                  string memory description, uint256 date){

    BasicInfo memory tmpData = BasicInformation[blockNo];
    return (tmpData.originCountry, tmpData.description, tmpData.date);

  }
}
