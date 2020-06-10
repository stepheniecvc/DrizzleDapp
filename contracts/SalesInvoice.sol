pragma solidity >= 0.6.0 < 0.7.0;

import "./SupplyChainStorage.sol";
import {Verify} from "./Verify.sol";

contract SalesInvoice{

  struct InvoiceDetails {
    string  invoiceNo;
    uint    amount;  //should multiple by 10**2 (2 for decimals)
    uint    qty;
    uint256 date;
    bool    isPrepayment; // true - if this is for prepayment
    bool    paymentApproved;  //true - if approve by buyer
    bool    paid;     // true if invoice is paid
    address creator;   //the seller
  }

  //event
  event SalesInvoiceIssued(address batchNo, string invoiceNo, uint amount,
                     uint qty, uint256 date);
  event SalesInvoiceAmended(address batchNo, string invoiceNo, uint amount,
                     uint qty, uint256 date);
  event SalesInvoiceRequested(address batchNo, bool isPrepayment);

  /* Storage Variables */
  SupplyChainStorage supplyChainStorage;
  mapping (address => InvoiceDetails[]) private SalesInvoiceMap;
  using Verify for *;

  //constructor
  constructor(address _supplyChainAddress) public {
      supplyChainStorage = SupplyChainStorage(_supplyChainAddress);
  }


  //seller calls to issue invoice to Buyer
  function issueInvoice(address batchNo, bool isPrepayment, string memory invoiceNo,
                                            uint qty, uint256 date) public returns
                                            (bool isIssued){
    uint amount = 0;
    isIssued = false;


    if(qty > checkUnbilledQty(batchNo)) //if the qty of the SI greater than the unbilled qty
        return isIssued;

    //only the seller can issue the invoice
    if(supplyChainStorage.getSellerAddress(batchNo) != msg.sender)
      return isIssued;

    InvoiceDetails memory tmpData;

    if(isPrepayment !=true)  //if this is not prepayment
    {
        if((supplyChainStorage.getTransactionStage(batchNo,
                         uint(Verify.TState.finalAgreeBySeller)) != true) ||
                  (supplyChainStorage.getTransactionStage(batchNo,
                    uint(Verify.TState.finalAgreeByBuyer)) != true))  //if not fully agreed by seller or buyer
        {
            return isIssued;  //cannot issue invoice
        }
    }
    else   //if this is prepayment -- without buyer & seller acknowledgement
    {
        supplyChainStorage.setTransactionStage(batchNo, uint(Verify.TState.isPrepayment), true); //record prepayment at Sales Contract
        tmpData.isPrepayment = true;                  //record into Sales Invoice
    }

    isIssued = true;

    uint invAmtAfterTax = calculateInvoiceAmt(batchNo, qty);

    //start recording
    tmpData.invoiceNo = invoiceNo;
    tmpData.amount = invAmtAfterTax ;
    tmpData.qty = qty;
    tmpData.date = date;
    tmpData.creator = msg.sender;

    SalesInvoiceMap[batchNo].push(tmpData);  //save into array

    emit SalesInvoiceIssued(batchNo, invoiceNo, amount, qty, date);

    return isIssued;
  }


  function amendInvoice(address batchNo, string memory origInvoiceNo,
                        string memory newInvoiceNo, uint qty, uint256 date,
                        bool isPrepayment)
                        public returns (bool isAmended){

    uint backUpQty;  //to backup the original qty, in case the totat SI'qty greater than Sales Contract's qty
    uint backUpIndex;
    uint totalQty;
    uint contractQty;
    isAmended = false;



    //cannot amend invoice if the transaction is completed
    if(supplyChainStorage.getTransactionStage(batchNo, uint(Verify.TState.completed)) == true)
      return isAmended;


    //get qty from Sales Contract
    (, contractQty, , ) = supplyChainStorage.getPriceQuantityAndTax(batchNo);

    for (uint i = 0; i< SalesInvoiceMap[batchNo].length; i++)
    {
       if(SalesInvoiceMap[batchNo][i].invoiceNo.verifyString(origInvoiceNo)) //if a SI is found
       {
        if((SalesInvoiceMap[batchNo][i].paid == false) && //can only be amended if not yet Paid
           (SalesInvoiceMap[batchNo][i].paymentApproved == false) &&
           (SalesInvoiceMap[batchNo][i].creator == msg.sender))  //can only be amended if not yet approved payment by buyer
          {
            //make amendment
             SalesInvoiceMap[batchNo][i].invoiceNo = newInvoiceNo;
             SalesInvoiceMap[batchNo][i].date = date;

             if(SalesInvoiceMap[batchNo][i].isPrepayment != isPrepayment)
             {
               //record the state
                supplyChainStorage.setTransactionStage(batchNo, uint(Verify.TState.isPrepayment), isPrepayment);
             }

             SalesInvoiceMap[batchNo][i].isPrepayment = isPrepayment;

             backUpQty = SalesInvoiceMap[batchNo][i].qty;
             //backUpAmount = SalesInvoiceMap[batchNo][i].amount;
             backUpIndex = i;
             SalesInvoiceMap[batchNo][i].qty = qty;
             SalesInvoiceMap[batchNo][i].amount = calculateInvoiceAmt(batchNo, qty);
             //newAmount = SalesInvoiceMap[batchNo][i].amount;
             isAmended = true;

          }
          else
          {
            break;
          }
       }

         //calculate totalQty of SI
         totalQty += SalesInvoiceMap[batchNo][i].qty;
    }

    if(isAmended == true)   //if there is amendment
    {
      uint newAmount;

      if((totalQty == contractQty) || (totalQty < contractQty))//check if all SI qty equal or less than to Sales Contract qty, after amentment
      {
          //newQty = qty;
          //emit event
          newAmount = calculateInvoiceAmt(batchNo, qty);
          emit SalesInvoiceAmended(batchNo, newInvoiceNo, newAmount, qty, date);
      }
      else if(totalQty > contractQty) //if the total SI's qty greater than Sales Contract's qty, revert
      {
        //revert back to the orig qty & amount
        SalesInvoiceMap[batchNo][backUpIndex].qty = backUpQty;
        newAmount = calculateInvoiceAmt(batchNo, backUpQty);

        SalesInvoiceMap[batchNo][backUpIndex].amount = newAmount;

        //emit event
        emit SalesInvoiceAmended(batchNo, newInvoiceNo, newAmount, backUpQty, date);
      }


    }

    return isAmended;



  }


  function deleteSalesInvoice(address batchNo, string memory invoiceNo) public
                                                       returns (bool isDeleted){

    isDeleted = false;
    //cannot delete invoice if the transaction is completed
    //only the seller/ creator can amend on the invoice
    if((supplyChainStorage.getTransactionStage(batchNo, uint(Verify.TState.completed)) == true) ||
                   (supplyChainStorage.getSellerAddress(batchNo) != msg.sender))
       return isDeleted;

    for (uint i = 0; i< SalesInvoiceMap[batchNo].length; i++)
    {
      if(SalesInvoiceMap[batchNo][i].invoiceNo.verifyString(invoiceNo)) //if a SI is found
      {
         if((SalesInvoiceMap[batchNo][i].paid == false) && //can only be deleted if not yet paid
          (SalesInvoiceMap[batchNo][i].paymentApproved == false))  //can only be deleted if not yet approved payment by buyer
         {
            //copy the last array element
            SalesInvoiceMap[batchNo][i] = SalesInvoiceMap[batchNo][SalesInvoiceMap[batchNo].length -1];

            //remove the last element
            SalesInvoiceMap[batchNo].pop();

            isDeleted = true;

            break;
         }
      }
    }

    return isDeleted;
  }


  function checkUnbilledQty(address batchNo) public view returns (uint unbilledQty){

    uint SIQty = 0;
    uint contractQty;

    //get qty from Sales Contract
    (, contractQty, , ) = supplyChainStorage.getPriceQuantityAndTax(batchNo);

    for(uint i = 0; i< SalesInvoiceMap[batchNo].length; i++)
    {
      SIQty += SalesInvoiceMap[batchNo][i].qty;
    }

    unbilledQty = contractQty - SIQty;

    return unbilledQty;
  }

  function calculateInvoiceAmt(address batchNo, uint qty) public view returns
                                                                (uint amount){
    uint price;  //per item
    uint shippingCost; //per item
    uint taxRate;

    (price, , shippingCost, taxRate) = supplyChainStorage.getPriceQuantityAndTax(batchNo);


    uint invAmt = qty * (price + shippingCost); //amount before tax

    amount = (invAmt * (taxRate +100))/100; //amount after tax

    return amount;
  }

  //call this to get the Sales Invoice count per Sales contract
  function getInvoiceCount(address batchNo) public view returns
                                              (uint count){
      count = SalesInvoiceMap[batchNo].length;

      return count;
  }

  //call to check on invoice Detail
  function getInvoiceDetails(address batchNo, uint index) public view returns (
                                        string memory invoiceNo,
                                        uint invoiceAmount,
                                        uint date, uint qty, bool
                                        paid){
      InvoiceDetails memory tmpData;

      tmpData = SalesInvoiceMap[batchNo][index];

      return (tmpData.invoiceNo, tmpData.amount, tmpData.date, tmpData.qty, tmpData.paid);

  }



  //buyer call this to request for Sales Invoice
  function requestForInvoice(address batchNo, bool isPrepayment) public{
    emit SalesInvoiceRequested(batchNo, isPrepayment);

  }

  function approvePaymentOrder(address batchNo, string memory invoiceNo,
                                                uint amount) public returns
                                                (bool result, address payee){
      //check if invoice is issued
      bool isInvoiceIssued = false;
      uint i;

      for(i = 0; i < SalesInvoiceMap[batchNo].length; i++)
      {
        if(invoiceNo.verifyString(SalesInvoiceMap[batchNo][i].invoiceNo) &&
             (amount == SalesInvoiceMap[batchNo][i].amount))//if this invoice is issued and amount tally
        {
          isInvoiceIssued = true;
          SalesInvoiceMap[batchNo][i].paymentApproved = true;

          break;
        }
      }

      if(isInvoiceIssued == true)
          payee = SalesInvoiceMap[batchNo][i].creator;
      else
          payee = address(0);

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
          supplyChainStorage.setTransactionStage(batchNo, uint(Verify.TState.completed), true);
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



}
