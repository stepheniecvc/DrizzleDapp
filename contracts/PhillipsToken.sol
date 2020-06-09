pragma solidity >=0.4.21 <0.7.0;
/*
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TutorialToken is ERC20 {
    string public name = "TutorialToken";
    string public symbol = "TT";
    uint256 public decimals = 2;
    uint256 public INITIAL_SUPPLY = 12000;

    constructor() public {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}
*/

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";

contract PhillipsToken is ERC777 {

  constructor () public ERC777("PhillipsToken", "PT", new address[](0)) {
    _mint(msg.sender, msg.sender, 12000 * 10 **2, "", "");
  }
  
}
