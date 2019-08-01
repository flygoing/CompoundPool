pragma solidity 0.5.7;

import { ERC20 } from "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract DepositTokenMock is ERC20{

 
  constructor() public {
      _mint(msg.sender,100000000000000000000);
  }

}
