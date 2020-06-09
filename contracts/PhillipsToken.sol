pragma solidity >=0.6.0 <0.7.0;
/*
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PhiullipsToken is ERC20 {
    string public name = "PhillipsToken";
    string public symbol = "PT";
    uint256 public decimals = 2;
    uint256 public INITIAL_SUPPLY = 12000;

    constructor() public {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}
*/

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";

contract PhillipsToken is ERC777 {
  uint256 public constant INITIAL_SUPPLY = 12000000;

  constructor () public ERC777("PhillipsToken", "PT", new address[](0)) {
    //_mint(msg.sender,12000 * 10 **2, "", "")_mint(msg.sender,12000 * 10 **2, "", "");;
    _mint(msg.sender,INITIAL_SUPPLY, "", "");


  }

}
