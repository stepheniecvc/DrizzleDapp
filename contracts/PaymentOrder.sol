pragma solidity >= 0.6.0 < 0.7.0;

//import "./SupplyChainStorage.sol";
import "./SalesInvoice.sol";

contract PaymentOrder {

  //event
  event PaymentOrderApprove(address batchNo, string invoiceNo, uint amount, uint256 date);
  event PaymentMade(address batchNo, string invoiceNo, uint256 date, uint amount);
  event TradeIsCompleted(address batchNo);

  /* Storage Variables */
  //SupplyChainStorage supplyChainStorage;
  SalesInvoice salesInvoice;

  //constructor
  //constructor(address _supplyChainAddress) public {
  //    supplyChainStorage = SupplyChainStorage(_supplyChainAddress);
  //}

  constructor (address _salesInvoice) public {
        salesInvoice = SalesInvoice(_salesInvoice);
  }


  //buyer calls this to approve on payment orderNo, emit an event to alert Financier
  function approvePaymentOrder(address batchNo, string memory invoiceNo, uint amount,
                                    uint256 date) public returns (bool result){

      address payee;
      bool isApproved;

      (isApproved, payee) = salesInvoice.approvePaymentOrder(batchNo,
                                           invoiceNo, amount);
      if(isApproved == true)
      {
         emit PaymentOrderApprove(batchNo, invoiceNo, amount, date);

         return (true);
      }
      else
         return (false);
  }


  //Financier calls this to initiate payment order - to record that payment already made
  //Assumption: financier knows the newOwner name
  function makePayment(address batchNo, string memory invoiceNo, uint amountPaid,
                              uint256 date) public
                              payable returns (bool result){

     bool unpaid;


     unpaid = salesInvoice.makePayment(batchNo, invoiceNo);

     //to record transfer money to seller/payee
     if(unpaid)
     {
       emit PaymentMade(batchNo, invoiceNo, amountPaid, date);
     }

     return unpaid;
  }


  //check if payment already been made
  function checkPaymentDone(address batchNo, string memory invoiceNo) public view
                                                        returns (bool result){
     if(salesInvoice.checkPaymentDone(batchNo, invoiceNo)== true)
        return (true);
     else
        return (false);
  }

  //check if all the invoices are fully paid - must call this before title released
  function checkFullPayment(address batchNo) public returns (bool result){
    result = salesInvoice.updatePaymentStatus(batchNo);

    if(result == true)
      emit TradeIsCompleted(batchNo);  //emit even if all the invoices issued are fully paid

    return result;

  }






}
