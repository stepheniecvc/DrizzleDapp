pragma solidity >= 0.6.0 < 0.7.0;

import "./SupplyChainStorage.sol";
import {Verify} from "./Verify.sol";

contract DeliveryOrder{

  //Delivery Order struct
  struct OrderDetails {
    string  DONumber;
    uint    pricePerItem;
    uint256 deliveryDate;
    string  consignmentQuality;
    uint    consignmentQuantity;
    string  truckDetails;
    bool    confirmed;   //false by default --seller to confirm
    address transporter;
  }

  mapping (address => OrderDetails[]) private OrderDetailsMap;  //key: batchId, value: OrderDetails

  //event
  event DORegistered(address batchNo, string DONumber, uint consignmentQuantity);
  event AllDORegistered(address batchNo);
  event ConsignmentConfirmed(address batchNo, string DONumber);

  /* Storage Variables */
  SupplyChainStorage supplyChainStorage;
  using Verify for *;


  //constructor
  constructor(address _supplyChainAddress) public {
      supplyChainStorage = SupplyChainStorage(_supplyChainAddress);
  }

  //transporter call this to register Delivery Order Details
  function registerDeliveryOrder(address batchNo, string memory DONumber,
                                 uint256 deliveryDate,
                                 string memory consignmentQuality,
                                 uint consignmentQuantity, string memory truckDetails)
                                 public returns (bool result) {

      bool allReg = false;
      result = false;

      //can only register if acknowledged by buyer
      if((supplyChainStorage.getTransactionStage(batchNo,
                 uint(Verify.TState.acknowledgeByBuyer)) == true) &&
          (supplyChainStorage.getTransactionStage(batchNo,
                      uint(Verify.TState.registeredAllDO)) == false))  //not yet registeredAllDO
      {
        uint price;
        uint qty;

        //get price and qty from Sales Contract
        (price, qty, , ) = supplyChainStorage.getPriceQuantityAndTax(batchNo);

        OrderDetails memory tmpData;
        tmpData.DONumber = DONumber;
        tmpData.pricePerItem = price;
        tmpData.deliveryDate = deliveryDate;
        tmpData.consignmentQuality = consignmentQuality;
        tmpData.consignmentQuantity = consignmentQuantity;
        tmpData.truckDetails = truckDetails;
        tmpData.transporter = msg.sender;

        OrderDetailsMap[batchNo].push(tmpData);  //add to DO array under 1 batchNo/ sales contract

        //check if total DO quantity is equal to the sales contract's quantity
        uint totalQty = 0;

        for (uint i = 0; i< OrderDetailsMap[batchNo].length; i++)
        {
           totalQty += OrderDetailsMap[batchNo][i].consignmentQuantity;
        }

        result = true;
        //if all the qty at Sales Contract already has DO registered
        if(totalQty == qty)
        {
          supplyChainStorage.setTransactionStage(batchNo,
                                 uint(Verify.TState.registeredAllDO), true); //set registeredAllDO =true at Sales Contract
          allReg = true;
        }
        else if(totalQty > qty) //the total registered DO qty greater than Sales Contract's qty, remove
        {
          //revert
          OrderDetailsMap[batchNo].pop();
          result = false;
        }

      }

      /*
      (result, allReg) = supplyChainStorage.registerDODetails(batchNo, DONumber, deliveryDate,
                                           consignmentQuality, consignmentQuantity,
                                           truckDetails) ;
      */
      if(result == true)  //if register successfully
      {
        //emit event
        emit DORegistered(batchNo, DONumber, consignmentQuantity);

        if(allReg == true)
          emit AllDORegistered(batchNo);

      }

      return result;
  }


  //call this to get the Delivery Order count per Sales contract
  function getDeliveryOrderCount(address batchNo) public view returns
                                              (uint count){
      //count = supplyChainStorage.getDeliveryOrderCount(batchNo);
      count = OrderDetailsMap[batchNo].length;

      return count;
  }

  //once caller knows the DO count, caller can repeatedly call this function to get the DO details
  function getDeliveryOrderDetails(address batchNo, uint index) public view returns (
                                            string memory DONumber,
                                            uint256 deliveryDate,
                                            string memory consignmentQuality,
                                            uint consignmentQuantity,
                                            string memory truckDetails,
                                            bool confirmed) {
      /*
      (DONumber, deliveryDate, consignmentQuality, consignmentQuantity,
      truckDetails, confirmed) = supplyChainStorage.getDODetails(batchNo, index);

      return (DONumber, deliveryDate, consignmentQuality, consignmentQuantity,
      truckDetails, confirmed);
      */
      OrderDetails memory tmpData;

      if(OrderDetailsMap[batchNo].length > 0)  //if there is any DO
      {
        index = index.verifyAndReturnIndex(OrderDetailsMap[batchNo].length);

        tmpData =  OrderDetailsMap[batchNo][index];
      }

      return (tmpData.DONumber, tmpData.deliveryDate, tmpData.consignmentQuality,
         tmpData.consignmentQuantity, tmpData.truckDetails, tmpData.confirmed);
  }

  //transporter called to amend on DO, allowed to amend only if it is not confirmed yet
  function amendDeliveryOrder(address batchNo, string memory origDONumber,
                                 string memory newDONumber,
                                 uint256 deliveryDate,
                                 string memory consignmentQuality,
                                 uint consignmentQuantity, string memory truckDetails)
                                 public returns (bool amended) {
      amended = false;
      uint contractQty;
      uint totalQty;
      uint backUpQty;  //in case the qty newly assigned, the total will be ended up greater than Sales contract's qty
      uint backUpIndex;
      //get price and qty from Sales Contract
      (, contractQty, , ) = supplyChainStorage.getPriceQuantityAndTax(batchNo);

      for (uint i = 0; i< OrderDetailsMap[batchNo].length; i++)
      {
         if(OrderDetailsMap[batchNo][i].DONumber.verifyString(origDONumber)) //if a DO is found
         {
            if((OrderDetailsMap[batchNo][i].confirmed == false) && //can only be amended if DO not yet confirmed
             (OrderDetailsMap[batchNo][i].transporter == msg.sender))  //can only be amended by creator
            {
               OrderDetailsMap[batchNo][i].DONumber = newDONumber;
               OrderDetailsMap[batchNo][i].deliveryDate = deliveryDate;
               OrderDetailsMap[batchNo][i].consignmentQuality = consignmentQuality;

               backUpQty = OrderDetailsMap[batchNo][i].consignmentQuantity;
               backUpIndex = i;
               OrderDetailsMap[batchNo][i].consignmentQuantity = consignmentQuantity;
               OrderDetailsMap[batchNo][i].truckDetails = truckDetails;
               amended = true;

            }
         }

         //calculate totalQty
         totalQty += OrderDetailsMap[batchNo][i].consignmentQuantity;
      }



      if(amended == true)   //if there is amendment
      {
        bool isRegisteredAllDO;

        isRegisteredAllDO = supplyChainStorage.getTransactionStage(batchNo,
                                               uint(Verify.TState.registeredAllDO));

        if((totalQty == contractQty) && (isRegisteredAllDO == false)) //check if all DO qty equal to Sales Contract qty, after amentment
        {
            supplyChainStorage.setTransactionStage(batchNo,
                                    uint(Verify.TState.registeredAllDO), true); //set registeredAllDO =true at Sales Contract

            emit AllDORegistered(batchNo);
        }
        else if((isRegisteredAllDO == true) && (totalQty < contractQty))
        {
            supplyChainStorage.setTransactionStage(batchNo,
                                  uint(Verify.TState.registeredAllDO), false); //set registeredAllDO =false at Sales Contract

        }
        else if(totalQty > contractQty) //if the total DO's qty greater than Sales Contract's qty, revert
        {
          //revert back to the orig qty
          OrderDetailsMap[batchNo][backUpIndex].consignmentQuantity = backUpQty;
        }


      }
      return amended;

  }

  //transporter called delete DO, allowed to delete only if it is not confirmed yet
  function deleteDeliveryOrder(address batchNo, string memory DONumber) public
                                      returns (bool deleted){

      //deleted = supplyChainStorage.deleteDeliveryOrder(batchNo, DONumber);
      deleted = false;

      for (uint i = 0; i< OrderDetailsMap[batchNo].length; i++)
      {
         if(OrderDetailsMap[batchNo][i].DONumber.verifyString(DONumber)) //if a DO is found
         {
            if((OrderDetailsMap[batchNo][i].confirmed == false) && //can only be amended if DO not yet confirmed
             (OrderDetailsMap[batchNo][i].transporter == msg.sender))  //can only be amended by creator
            {
               //copy the last array element
               OrderDetailsMap[batchNo][i] = OrderDetailsMap[batchNo][OrderDetailsMap[batchNo].length -1];

               //remove the last element
               OrderDetailsMap[batchNo].pop();

               deleted = true;

               break;
            }
         }
      }

      if(deleted)  //set the registeredAllDO to false whenever there is a delete
      {
        supplyChainStorage.setTransactionStage(batchNo,
                              uint(Verify.TState.registeredAllDO), false); //set registeredAllDO =false at Sales Contract
      }

      return deleted;

  }

  function confirmConsignment(address batchNo, string memory DONumber) public
                                                       returns (bool result){
    bool isThereDO = false;

    for (uint i = 0; i< OrderDetailsMap[batchNo].length; i++)
    {
       if(OrderDetailsMap[batchNo][i].DONumber.verifyString(DONumber)) //if a DO is found
       {
          OrderDetailsMap[batchNo][i].confirmed = true;  //confirm it
          isThereDO = true;

          //emit event
          emit ConsignmentConfirmed(batchNo, DONumber);

          break;
       }
    }

    return isThereDO;

  }


}
