pragma solidity >= 0.6.0 < 0.7.0;

//import "./SupplyChainStorage.sol";
import "./CargoStorage.sol";

contract CargoTitleRelease{

    //event
    event CargoNewOwner(address bacthNo, string newOwner);

    /* Storage Variables */
    //SupplyChainStorage supplyChainStorage;
    CargoStorage cargoStorage;


    //constructor
    //constructor(address _supplyChainAddress) public {
    //    supplyChainStorage = SupplyChainStorage(_supplyChainAddress);
    //}

    constructor(address _cargoStorage) public {
        cargoStorage = CargoStorage(_cargoStorage);
    }

    //to check for ownership - of each storage
    function getOwner(address batchNo, uint index)public view returns
                                              (string memory owner){

      //owner = supplyChainStorage.getOwner(batchNo, index);
      owner = cargoStorage.getOwner(batchNo, index);

      return (owner);

    }


    //Warehouse operator calls to confirm cargo title release to new Owner
    function releaseCargoTitle(address batchNo, string memory newOwner) public returns
                                                      (bool result){

      //if(supplyChainStorage.releaseCargoTitle(batchNo, newOwner) == true)
      if(cargoStorage.releaseCargoTitle(batchNo, newOwner) == true)
      {
          emit CargoNewOwner(batchNo, newOwner);

          return (true);
      }
      else
          return (false);
    }


    function checkCargoReleaseState(address batchNo) public view returns
                                          (bool cargoRelease, string memory newOwner){

      //(cargoRelease, newOwner) = supplyChainStorage.checkCargoReleaseState(batchNo);
      (cargoRelease, newOwner) = cargoStorage.checkCargoReleaseState(batchNo);

      return (cargoRelease, newOwner);
    }

}
