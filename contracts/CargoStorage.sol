pragma solidity >= 0.6.0 < 0.7.0;

import "./SupplyChainStorage.sol";
import {Verify} from "./Verify.sol";

contract CargoStorage {

  //Storage Confimation
  struct StorageConfirmation {
    string  owner;
    string  storageNo;
    string  DONumber;
    uint    actualQty;
    bool    cargoRelease;    //false by default, true when payment is made, and new owner will be updated- Assumption:
    bool    paid;           //false by default -- info from SI
    string  invoiceNo;      // to be used when SI is issued
    address operator;
  }

  //event
  event StorageRegistered(address batchNo, string storageNo, string DONumber, uint actualQty);   //to alert buyer of actualQty
  event AllStorageRegistered(address batchNo, string storageNo, string DONumber);

  /* Storage Variables */
  SupplyChainStorage supplyChainStorage;
  mapping (address => StorageConfirmation[]) private StorageConfirmationMap;
  using Verify for *;



  //constructor
  constructor(address _supplyChainAddress) public {
      supplyChainStorage = SupplyChainStorage(_supplyChainAddress);
  }

  //warehouse operator calls to register storage
  function registerStorage(address batchNo, string memory storageNo,
                                 string memory owner, string memory DONumber,
                                 uint actualQty) public returns (bool result){

   bool allReg = false;

   //(result, allReg) = supplyChainStorage.registerStorage(batchNo, owner,
    //                     storageNo, DONumber, actualQty);

   // if acknowledged by buyer, then only proceed to register storage
   if(supplyChainStorage.getTransactionStage(batchNo, uint(Verify.TState.acknowledgeByBuyer)) == true)
   {
       StorageConfirmation memory tmpData;
       tmpData.storageNo = storageNo;
       tmpData.owner = owner;
       tmpData.DONumber = DONumber;
       tmpData.actualQty = actualQty;
       tmpData.cargoRelease = false;  //false by default
       tmpData.operator = msg.sender;

       StorageConfirmationMap[batchNo].push(tmpData);  //add to storage array under 1 batchNo/ sales contract

       //set the state once storage of all qty is registered
       uint totalQty = 0;
       uint qty;

       //get qty from Sales Contract
       (, qty, , ) = supplyChainStorage.getPriceQuantityAndTax(batchNo);

       for (uint i = 0; i< StorageConfirmationMap[batchNo].length; i++)
       {
          totalQty += StorageConfirmationMap[batchNo][i].actualQty;
       }

       result = true;
       //if all the qty at Sales Contract already confirm on storage
       if(totalQty == qty)
       {
         supplyChainStorage.setTransactionStage(batchNo,
                uint(Verify.TState.registeredAllStorage), true); //set registeredAllStorage to true at sales contract
         allReg = true;
       }
       else if(totalQty > qty) //the total registered Storage qty greater than Sales Contract's qty, remove
       {
         //revert
         StorageConfirmationMap[batchNo].pop();
         result = false;
       }

   }



   if(result == true)
   {
      emit StorageRegistered(batchNo, storageNo, DONumber, actualQty);

      if(allReg == true)
        emit AllStorageRegistered(batchNo, storageNo, DONumber); //emit event when all goods arrive and storage registered - so that surveyor can start action

    }

    return result;
  }

  //call this to get the Storage Confirmation count per Sales contract
  function getStorageCount(address batchNo) public view returns (uint count){

    //count = supplyChainStorage.getStorageCount(batchNo);
    count = StorageConfirmationMap[batchNo].length;

    return count;
  }


  //to check for actual consignmentQuantity
  /*
  function getStorageActualQty(address batchNo, uint index) public view returns
                                                             (uint actualQty){

    //actualQty = supplyChainStorage.getStorageActualQty(batchNo, index);
    StorageConfirmation memory tmpData;
    uint arrayLength = StorageConfirmationMap[batchNo].length;

    if(arrayLength > 0)
    {
      index = index.verifyAndReturnIndex(arrayLength);

      tmpData =  StorageConfirmationMap[batchNo][index];
    }

    return (tmpData.actualQty);

  }
 */
  //operator calls to make changes on registered storage
  function amendStorage(address batchNo, string memory origStorageNo,
                                 string memory newStorageNo, string memory owner,
                                 string memory DONumber,
                                 uint actualQty) public returns (bool amended){

      //can be amended if both seller and buyer have not confirmed
      if((supplyChainStorage.getTransactionStage(batchNo,
            uint(Verify.TState.finalAgreeBySeller)) == false) &&
            (supplyChainStorage.getTransactionStage(batchNo,
                 uint(Verify.TState.finalAgreeByBuyer)) == false))
      {
        amended = false;
        uint qty;
        uint totalQty;
        uint backUpQty;  //in case the qty newly assigned, the total will be ended up greater than Sales contract's qty
        uint backUpIndex;

        //get qty from Sales Contract
        (, qty, , ) = supplyChainStorage.getPriceQuantityAndTax(batchNo);

        for (uint i = 0; i< StorageConfirmationMap[batchNo].length; i++)
        {
           if(StorageConfirmationMap[batchNo][i].storageNo.verifyString(origStorageNo)) //if a Storage No is found
           {
              if(StorageConfirmationMap[batchNo][i].operator == msg.sender) //can only be amended by creator
              {
                 StorageConfirmationMap[batchNo][i].storageNo = newStorageNo;
                 StorageConfirmationMap[batchNo][i].owner = owner;
                 StorageConfirmationMap[batchNo][i].DONumber = DONumber;

                 backUpQty = StorageConfirmationMap[batchNo][i].actualQty;
                 backUpIndex = i;
                 StorageConfirmationMap[batchNo][i].actualQty = actualQty;

                 amended = true;

              }
           }

           //calculate totalQty
           totalQty += StorageConfirmationMap[batchNo][i].actualQty;
        }



        if(amended == true)   //if there is amendment
        {
          bool isRegisteredAllStorage;

          isRegisteredAllStorage = supplyChainStorage.getTransactionStage(batchNo,
                                                 uint(Verify.TState.registeredAllStorage));

          if((totalQty == qty) && (isRegisteredAllStorage == false)) //check if all Storage qty equal to Sales Contract qty, after amentment
          {
              supplyChainStorage.setTransactionStage(batchNo,
                                      uint(Verify.TState.registeredAllStorage), true); //set registeredAllStorage =true at Sales Contract

              emit AllStorageRegistered(batchNo, newStorageNo, DONumber);
          }
          else if((isRegisteredAllStorage == true) && (totalQty < qty))
          {
              supplyChainStorage.setTransactionStage(batchNo,
                                    uint(Verify.TState.registeredAllStorage), false); //set registeredAllDO =false at Sales Contract

          }
          else if(totalQty > qty) //if the total Storage's qty greater than Sales Contract's qty, revert
          {
            //revert back to the orig qty
            StorageConfirmationMap[batchNo][backUpIndex].actualQty = backUpQty;
          }


        }
        return amended;


      }


  }

  //operator called delete Storage, allowed to delete only if it is not confirmed by buyer or seller yet
  function deleteStorage(address batchNo, string memory storageNo) public
                                      returns (bool deleted){

      deleted = false;

      //can be deleted if both seller and buyer have not confirmed
      if((supplyChainStorage.getTransactionStage(batchNo,
            uint(Verify.TState.finalAgreeBySeller)) == false) &&
            (supplyChainStorage.getTransactionStage(batchNo,
                 uint(Verify.TState.finalAgreeByBuyer)) == false))
      {
        for (uint i = 0; i< StorageConfirmationMap[batchNo].length; i++)
        {
           if(StorageConfirmationMap[batchNo][i].storageNo.verifyString(storageNo)) //if a DO is found
           {
              if(StorageConfirmationMap[batchNo][i].operator == msg.sender)  //can only be amended by creator
              {
                 //copy the last array element
                 StorageConfirmationMap[batchNo][i] = StorageConfirmationMap[batchNo][StorageConfirmationMap[batchNo].length -1];

                 //remove the last element
                 StorageConfirmationMap[batchNo].pop();

                 deleted = true;

                 break;
              }
           }
        }
      }

      if(deleted)  //set the registeredAllStorage to false whenever there is a delete
      {
        supplyChainStorage.setTransactionStage(batchNo,
                              uint(Verify.TState.registeredAllStorage), false);
      }

      return deleted;

  }

  function getStorageDetails(address batchNo, uint index) public view returns
                                (string memory storageNo, string memory owner,
                                 string memory DONumber, uint actualQty){

      StorageConfirmation memory tmpData;

      if(StorageConfirmationMap[batchNo].length > 0)  //if there is any DO
      {
           index = index.verifyAndReturnIndex(StorageConfirmationMap[batchNo].length);
           tmpData =  StorageConfirmationMap[batchNo][index];
      }

     return (tmpData.storageNo, tmpData.owner, tmpData.DONumber,
            tmpData.actualQty);


  }

  function getOwner(address batchNo, uint index) public view returns (string memory owner){
    StorageConfirmation memory tmpData;
    uint arrayLength = StorageConfirmationMap[batchNo].length;

    if(arrayLength > 0)
    {
      index = index.verifyAndReturnIndex(arrayLength);

      tmpData =  StorageConfirmationMap[batchNo][index];
    }

    return (tmpData.owner);

  }

  function releaseCargoTitle(address batchNo, string memory newOwner) public returns
                                                (bool result){
    //if(TradeDetailsMap[batchNo].completed == true) //true when all the invoice issued are fully paid
    if(supplyChainStorage.getTransactionStage(batchNo, uint(Verify.TState.completed)) == true)
    {
        for (uint i = 0; i< StorageConfirmationMap[batchNo].length; i++)
        {
          StorageConfirmationMap[batchNo][i].owner = newOwner;
          StorageConfirmationMap[batchNo][i].cargoRelease = true;
        }

        return (true);
    }
    else
        return (false);
  }

  function checkCargoReleaseState(address batchNo) public view returns
                                        (bool cargoRelease, string memory newOwner){
    StorageConfirmation memory tmpData;

    tmpData = StorageConfirmationMap[batchNo][0]; //check the first record will do

    return (tmpData.cargoRelease, tmpData.owner);

  }





}
