pragma solidity >= 0.6.0 < 0.7.0;

import "./BasicQualityAndGrade.sol";

contract CoffeeQualityAndGrade is BasicQualityAndGrade{

    //event
    event CoffeeCertified(address batchNo, string originCountry, uint date,
                                string coffeeType, string grade);

    struct CoffeeInfo{
      string coffeeType;
      string grade;
      string moisture;
      string taste;
      uint   beanSize;
      uint   caffeine;
      uint   caffeineInDryMatter;
    }


    mapping(address => CoffeeInfo) CoffeeInfoMap;

    function certifyCoffee(address batchNo,
                                          string memory originCountry,
                                          string memory description,
                                          uint256 date,
                                          string memory coffeeType,
                                          string memory grade, string memory moisture,
                                          string memory taste, uint size,
                                          uint caffeine, uint caffeineInDryMatter)
                                          public{

      super.certifyBasicInfo(batchNo, originCountry, description, date);

      CoffeeInfoMap[batchNo].coffeeType = coffeeType;
      CoffeeInfoMap[batchNo].grade = grade;
      CoffeeInfoMap[batchNo].moisture = moisture;
      CoffeeInfoMap[batchNo].taste = taste;
      CoffeeInfoMap[batchNo].beanSize = size;
      CoffeeInfoMap[batchNo].caffeine = caffeine;
      CoffeeInfoMap[batchNo].caffeineInDryMatter = caffeineInDryMatter;

      certifyFlag[batchNo] = true;   //certified successfully

      emit CoffeeCertified(batchNo, originCountry, date, coffeeType, grade);
    }

    function getCoffeeCertDetails(address batchNo) public view returns (
                                               string memory originCountry,
                                               string memory description,
                                               uint256 date ) {//,
                                              // string memory coffeeType,
                                            //   string memory grade,
                                            //   string memory moisture,
                                            //   string memory taste,
                                          //     uint size, uint caffeine,
                                            //   uint caffeineInDryMatter){

       (originCountry, description, date) = super.getBasicDetails(batchNo);
  //     CoffeeInfo memory tmpData = CoffeeInfoMap[batchNo];
  //     return (originCountry, description, date, tmpData.coffeeType,
//            tmpData.grade, tmpData.moisture, tmpData.taste,
//            tmpData.beanSize, tmpData.caffeine, tmpData.caffeineInDryMatter);
        return  (originCountry, description, date);
    }

    function isCoffeeCertified(address batchNo) public view returns (bool result){
        if(certifyFlag[batchNo] == true)
          return (true);
        else
          return (false);

    }

}
