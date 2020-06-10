pragma solidity >= 0.6.0 < 0.7.0;

import {Verify} from "./Verify.sol";


contract SupplyChainStorage {

    //Sales Contract
    struct TradeDetails{
      string  productName;
      uint    quantity;
      uint    pricePerItem;   //should multiple by 10**2 (2 for decimals)
      uint    shippingCostPerItem; //should multiple by 10**2 (2 for decimals)
      uint    taxRate;
      uint256 deliveryDate;
      address seller;    // need to record seller address? - Assumption:
      address buyer;     // need to record buyer address?  - Assumption:
      bool    acknowledgeByBuyer;
      bool    registeredAllDO;
      bool    registeredAllStorage;
      bool    finalAgreeBySeller;
      bool    finalAgreeByBuyer;
      bool    isPrepayment;  //false by default, no prepayment
      bool    completed;   //false by default, true - fully paid
    }
/*
    struct SalesInvoice {
      string  invoiceNo;
      uint    amount;  //should multiple by 10**2 (2 for decimals)
      uint    qty;
      uint256 date;
//      address payable payee;   //need to record payee here? or get payee from Sales Contract? Assumption:
      bool    isPrepayment; // true - if this is for prepayment
      bool    paymentApproved;  //true - if approve by buyer
      bool    paid;     // true if invoice is paid
    }
*/

    using Verify for *;
    TradeDetails tradeDetailsData;
    uint256 private timeStampCount;


    //mapping
    mapping (address => TradeDetails) private TradeDetailsMap;  //key: batchId, value: TradeDetails
    //mapping (address => SalesInvoice[]) private SalesInvoiceMap;

    address[] public batchNoAddresses;

    //to record the new sales contract
    function setSalesContract(string memory productName,
                                  uint quantity,
                                  uint price,
                                  uint deliveryCost,
                                  uint256 deliveryDate,
                                  address seller,
                                  address buyer
                                  ) public returns (address) {

        //ncrement 1 when a contract is registered
        timeStampCount++;

        uint tmpData = uint(keccak256(abi.encodePacked(msg.sender, now + timeStampCount)));
        address batchNo = address(tmpData);

        tradeDetailsData.productName = productName;
        tradeDetailsData.quantity = quantity;
        tradeDetailsData.pricePerItem = price;
        tradeDetailsData.shippingCostPerItem = deliveryCost;
        tradeDetailsData.deliveryDate = deliveryDate;
        tradeDetailsData.seller = seller;
        tradeDetailsData.buyer = buyer;
        tradeDetailsData.completed = false;

        //store the sales contract details
        TradeDetailsMap[batchNo] = tradeDetailsData;

        //to record no of BatchNo
        batchNoAddresses.push(batchNo);

        return batchNo;
    }

    //retrieve info of Sales Contract
    function getSalesContract(address batchNo) public view returns
                                                  (string memory productName,
                                                   uint quantity, uint price,
                                                   uint deliveryCost, uint256 deliveryDate,
                                                   address seller, address buyer,
                                                   bool acknowledgeByBuyer){

        TradeDetails memory tmpData = TradeDetailsMap[batchNo];

        return (tmpData.productName, tmpData.quantity, tmpData.pricePerItem,
                tmpData.shippingCostPerItem, tmpData.deliveryDate, tmpData.seller,
                tmpData.buyer, tmpData.acknowledgeByBuyer);
    }

    //seller calls to amend on SalesContract, only allowed to amend if buyer has yet to acknowledge
    function amendSalesContract(address batchNo, string memory productName,
                                  uint quantity, uint price,
                                  uint deliveryCost, uint256 deliveryDate,
                                  address buyer, address sender
                                  ) public returns (bool amended)
    {
        if((sender == TradeDetailsMap[batchNo].seller) &&   //if the msg sender is the creator
            (TradeDetailsMap[batchNo].acknowledgeByBuyer == false)) //if not yet acknowledged by Buyer
        {
          TradeDetailsMap[batchNo].productName = productName;
          TradeDetailsMap[batchNo].quantity = quantity;
          TradeDetailsMap[batchNo].pricePerItem = price;
          TradeDetailsMap[batchNo].shippingCostPerItem = deliveryCost;
          TradeDetailsMap[batchNo].deliveryDate = deliveryDate;
          TradeDetailsMap[batchNo].buyer = buyer;

          return true;
        }

        return false;
    }

    function deleteSalesContract(address batchNo, address sender) public returns (bool deleted)
    {
      if((sender == TradeDetailsMap[batchNo].seller) &&   //if the msg sender is the creator
          (TradeDetailsMap[batchNo].acknowledgeByBuyer == false)) //if not yet acknowledged by Buyer
      {
          //delete 1 mapping
          delete TradeDetailsMap[batchNo];

          uint i;
          uint arrayLength = batchNoAddresses.length;
          //find the index of the batchNoAddresses
          for(i = 0; i< arrayLength; i++)
          {
             if(batchNoAddresses[i] == batchNo)
               break;
          }
          //copy the last array element and remove the last
          batchNoAddresses[i] = batchNoAddresses[arrayLength - 1];
          batchNoAddresses.pop();

          return true;
      }

      return false;
    }


    function acknowledgeSalesContract(address batchNo) public {
      //TradeDetailsMap[batchNo].acknowledgeByBuyer = true;
      setTransactionStage(batchNo, uint(Verify.TState.acknowledgeByBuyer), true);
    }


    //for testing
    function getSalesContractState(address batchNo) public view returns
                                                                (bool result){
      return TradeDetailsMap[batchNo].acknowledgeByBuyer;
    }

    function setTaxRate(address batchNo, uint taxRate) public {
      TradeDetailsMap[batchNo].taxRate = taxRate;
    }


    function getTaxRate(address batchNo) public view returns (uint taxRate){
      taxRate = TradeDetailsMap[batchNo].taxRate;

      return taxRate;
    }

    function getSalesContractCount() public view returns (uint256 count){
      return batchNoAddresses.length;
    }

    function getBatchNo(uint256 index) public view returns (address batchNo){
      return batchNoAddresses[index];
    }


    function getPriceQuantityAndTax(address batchNo) public view returns
                                           (uint price, uint quantity,
                                             uint shippingCost,
                                             uint tax){
        return (TradeDetailsMap[batchNo].pricePerItem, TradeDetailsMap[batchNo].quantity,
             TradeDetailsMap[batchNo].shippingCostPerItem, TradeDetailsMap[batchNo].taxRate);
    }

    function setTransactionStage(address batchNo, uint stage, bool state) public {

      if(stage == uint(Verify.TState.acknowledgeByBuyer))
      {
          TradeDetailsMap[batchNo].acknowledgeByBuyer = state;
      }
      else if (stage == uint(Verify.TState.registeredAllDO))
      {
        TradeDetailsMap[batchNo].registeredAllDO = state;
      }
      else if(stage ==uint(Verify.TState.registeredAllStorage))
      {
        TradeDetailsMap[batchNo].registeredAllStorage = state;
      }
      else if(stage ==uint(Verify.TState.finalAgreeBySeller))
      {
        TradeDetailsMap[batchNo].finalAgreeBySeller = state;
      }
      else if(stage ==uint(Verify.TState.finalAgreeByBuyer))
      {
        TradeDetailsMap[batchNo].finalAgreeByBuyer = state;
      }
      else if(stage ==uint(Verify.TState.isPrepayment))
      {
        TradeDetailsMap[batchNo].isPrepayment = state;
      }
      else if(stage ==uint(Verify.TState.completed))
      {
        TradeDetailsMap[batchNo].completed = state;
      }

    }

    function getTransactionStage(address batchNo, uint stage) public view
                                              returns (bool){
      bool result;

      if(stage == uint(Verify.TState.acknowledgeByBuyer))
      {
          result = TradeDetailsMap[batchNo].acknowledgeByBuyer;
      }
      if(stage == uint(Verify.TState.registeredAllDO))
      {
          result =  TradeDetailsMap[batchNo].registeredAllDO;
      }
      else if(stage == uint(Verify.TState.registeredAllStorage))
      {
          result = TradeDetailsMap[batchNo].registeredAllStorage;
      }
      else if(stage == uint(Verify.TState.finalAgreeBySeller))
      {
          result = TradeDetailsMap[batchNo].finalAgreeBySeller;
      }
      else if(stage == uint(Verify.TState.finalAgreeByBuyer))
      {
          result = TradeDetailsMap[batchNo].finalAgreeByBuyer;
      }
      else if(stage == uint(Verify.TState.isPrepayment))
      {
          result = TradeDetailsMap[batchNo].isPrepayment;
      }
      else if(stage == uint(Verify.TState.completed))
      {
          result = TradeDetailsMap[batchNo].completed;
      }



      return result;
    }


    function finalAcknowledgeBySeller(address batchNo) public returns (bool result){
      //if(TradeDetailsMap[batchNo].registeredAllStorage)   //when all storage is registered
      if(getTransactionStage(batchNo, uint(Verify.TState.registeredAllStorage)))
      {
         //TradeDetailsMap[batchNo].finalAgreeBySeller = true;
         setTransactionStage(batchNo, uint(Verify.TState.finalAgreeBySeller), true);
         return (true);
      }
      else
        return (false);

    }

    function finalAcknowledgeByBuyer(address batchNo) public returns (bool result){
      //if(TradeDetailsMap[batchNo].registeredAllStorage) //when all storage is registered
      if(getTransactionStage(batchNo, uint(Verify.TState.registeredAllStorage)))
      {
         //TradeDetailsMap[batchNo].finalAgreeByBuyer = true;
         setTransactionStage(batchNo, uint(Verify.TState.finalAgreeByBuyer), true);
         return (true);
      }
      else
        return (false);

    }

    function getSellerAddress(address batchNo) public  view returns (address payee){
        payee = TradeDetailsMap[batchNo].seller;

        return payee;

    }

/*
    function issueInvoice(address batchNo, bool isPrepayment,
                                    string memory invoiceNo, uint qty,
                                    uint256 date) public returns (uint amount,
                                    bool result){

      SalesInvoice memory tmpData;

      if(qty > checkUnbilledQty(batchNo)) //if the qty of the SI greater than the unbilled qty
      {
          return (0, false);
      }


      if(isPrepayment !=true)  //if this is not prepayment
      {
          if((TradeDetailsMap[batchNo].finalAgreeBySeller != true) ||
                    (TradeDetailsMap[batchNo].finalAgreeByBuyer != true))  //if not fully agreed by seller or buyer
          {
              return (0, false);  //cannot issue invoice
          }
      }
      else   //if this is prepayment
      {
          TradeDetailsMap[batchNo].isPrepayment = true; //record prepayment at Sales Contract
          tmpData.isPrepayment = true;                  //record into Sales Invoice
      }


      //start recording
      //uint invAmt = qty * (TradeDetailsMap[batchNo].pricePerItem +
      //                      TradeDetailsMap[batchNo].shippingCostPerItem);
      //uint invAmtAfterTax = (invAmt * (TradeDetailsMap[batchNo].taxRate+100))/100;

      uint invAmtAfterTax = calculateInvoiceAmt(batchNo, qty);

      tmpData.invoiceNo = invoiceNo;
      tmpData.amount = invAmtAfterTax ;
      tmpData.qty = qty;
      tmpData.date = date;
  //    tmpData.payee = msg.seller;     //record the seller address as payee

      SalesInvoiceMap[batchNo].push(tmpData);  //save into array

      return (invAmtAfterTax, true);

    }


    function getInvoiceCount(address batchNo) public view returns
                                                (uint count){
        count = SalesInvoiceMap[batchNo].length;

        return count;
    }

    function getInvoiceDetails(address batchNo, uint index) public view returns
                                          (string memory invoiceNo, uint invoiceAmount,
                                           uint256 date, uint qty, bool paid){
      SalesInvoice memory tmpData;
      tmpData = SalesInvoiceMap[batchNo][index];

      return (tmpData.invoiceNo, tmpData.amount, tmpData.date, tmpData.qty, tmpData.paid);

    }


    function checkUnbilledQty(address batchNo) public view returns (uint unbilledQty){

      uint SIQty = 0;

      for(uint i = 0; i< SalesInvoiceMap[batchNo].length; i++)
      {
        SIQty += SalesInvoiceMap[batchNo][i].qty;
      }

      unbilledQty = TradeDetailsMap[batchNo].quantity - SIQty;

      return unbilledQty;
    }


    function calculateInvoiceAmt(address batchNo, uint qty) public view returns
                                                                  (uint amount){
      uint invAmt = qty * (TradeDetailsMap[batchNo].pricePerItem
                      + TradeDetailsMap[batchNo].shippingCostPerItem); //amount before tax

      amount = (invAmt * (TradeDetailsMap[batchNo].taxRate +100))/100; //amount after tax

      return amount;
    }


    function approvePaymentOrder(address batchNo, string memory invoiceNo,
                                                  uint amount) public returns
                                                  (bool result, address payee){
        //check if invoice is issued
        bool isInvoiceIssued = false;

        for(uint i = 0; i < SalesInvoiceMap[batchNo].length; i++)
        {
          if(invoiceNo.verifyString(SalesInvoiceMap[batchNo][i].invoiceNo) &&
               (amount == SalesInvoiceMap[batchNo][i].amount))//if this invoice is issued and amount tally
          {
            isInvoiceIssued = true;
            SalesInvoiceMap[batchNo][i].paymentApproved = true;

            break;
          }
        }

        payee = TradeDetailsMap[batchNo].seller;

        return (isInvoiceIssued, payee);

    }

    function makePayment(address batchNo, string memory invoiceNo)public
                              returns (bool unPaid){
        //check if invoice paid already or not
        unPaid = false;

        for(uint i = 0; i < SalesInvoiceMap[batchNo].length; i++)
        {
          if(invoiceNo.verifyString(SalesInvoiceMap[batchNo][i].invoiceNo) &&
               (SalesInvoiceMap[batchNo][i].paid == false))
          {
            unPaid = true;
            SalesInvoiceMap[batchNo][i].paid = true;  //set to paid already
            break;
          }
        }

        return (unPaid);

    }


    function updatePaymentStatus(address batchNo) public returns
                                                  (bool tradeCompleted)
    {
        tradeCompleted = false;

        if(checkUnbilledQty(batchNo) == 0)  //if all the qty already billed
        {
          uint invPaidCount = 0;
          //loop thrg to check if all the invoice issued already paid
          for(uint i = 0; i< SalesInvoiceMap[batchNo].length; i++)
          {
            if(SalesInvoiceMap[batchNo][i].paid == true)
            {
              invPaidCount++;
            }
          }

          if(invPaidCount == SalesInvoiceMap[batchNo].length) //if all the invoice issued are fully paid
          {
            tradeCompleted = true;
            TradeDetailsMap[batchNo].completed = true;
          }
        }

        return (tradeCompleted);
    }


    function checkPaymentDone(address batchNo, string memory invoiceNo) public
                                                   view returns (bool isPaid){
        isPaid = false;

        for(uint i = 0; i < SalesInvoiceMap[batchNo].length; i++)
        {
          if(invoiceNo.verifyString(SalesInvoiceMap[batchNo][i].invoiceNo) &&
               (SalesInvoiceMap[batchNo][i].paid == true))
          {
            isPaid = true;

            break;

          }
        }

        return isPaid;

    }


    function releaseCargoTitle(address batchNo, string memory newOwner) public returns
                                                  (bool result){
      if(TradeDetailsMap[batchNo].completed == true) //true when all the invoice issued are fully paid
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
*/

}
