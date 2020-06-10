pragma solidity >= 0.6.0 < 0.7.0;

import "./SupplyChainStorage.sol";


contract SalesContract {

    //Events
    event SaleContractRegistered(address batchNo, string productName,
               uint quantity, uint price, uint deliveryCost, uint256 deliveryDate);
    event AcknowledgeContract(address batchNo);

    /* Storage Variables */
    SupplyChainStorage supplyChainStorage;

    //constructor
    constructor(address _supplyChainAddress) public {
        supplyChainStorage = SupplyChainStorage(_supplyChainAddress);
    }


    //seller call this function to register new sales contract
    function registerSalesContract(string memory productName,
                                  uint quantity,
                                  uint price,
                                  uint deliveryCost,
                                  uint256 deliveryDate,
                                  address buyer
                                  ) public returns (address) {

       address seller = msg.sender;
       //call storage contract
       address batchNo = supplyChainStorage.setSalesContract(productName,
                                                             quantity,
                                                             price,
                                                             deliveryCost,
                                                             deliveryDate,
                                                             seller,
                                                             buyer);

      emit SaleContractRegistered(batchNo, productName, quantity, price,
                               deliveryCost, deliveryDate);

      return (batchNo);

    }

    function getContractDetails(address batchNo) public view returns
                                                     (string memory productName,
                                                      uint quantity,
                                                      uint pricePerItem,
                                                      uint shippingCostPerItem,
                                                      uint256 deliveryDate,
                                                      address seller,
                                                      address buyer,
                                                      bool acknowledgeByBuyer)
    {
      (productName, quantity, pricePerItem, shippingCostPerItem, deliveryDate,
      seller, buyer, acknowledgeByBuyer) = supplyChainStorage.getSalesContract(batchNo);

      return (productName, quantity, pricePerItem, shippingCostPerItem,
              deliveryDate, seller, buyer, acknowledgeByBuyer);

    }

    //seller calls to amend on SalesContract, only allowed to amend if buyer has yet to acknowledge
    function amendSalesContract(address batchNo, string memory productName,
                                  uint quantity, uint price,
                                  uint deliveryCost, uint256 deliveryDate,
                                  address buyer) public returns (bool amended)
    {
        amended = supplyChainStorage.amendSalesContract(batchNo, productName,
                                    quantity, price, deliveryCost, deliveryDate,
                                    buyer, msg.sender);

        return amended;
    }

    //seller calls to delete SalesContract, only allowed to delete if buyer has yet to acknowledge
    function deleteSalesContract(address batchNo) public returns (bool deleted){

      deleted = supplyChainStorage.deleteSalesContract(batchNo, msg.sender);

      return deleted;

    }

    //Buyer calls this to acknowledge the Sales Contract RegisteredStorage
    function acknowledgeSalesContract(address batchNo) public {
      supplyChainStorage.acknowledgeSalesContract(batchNo);
      emit AcknowledgeContract(batchNo);
    }


    //Buyer calls this to set the tax rate
    function setTaxRate(address batchNo, uint taxRate) public {
      supplyChainStorage.setTaxRate(batchNo, taxRate);
    }


    function getTaxRate(address batchNo) public view returns (uint taxRate){
      taxRate = supplyChainStorage.getTaxRate(batchNo);
      return taxRate;

    }

    function getSalesContractCount() public view returns (uint256 count){
      count = supplyChainStorage.getSalesContractCount();

      return count;
    }

    function getBatchNo(uint256 index) public view returns (address batchNo){
      batchNo = supplyChainStorage.getBatchNo(index);

      return batchNo;
    }

}
