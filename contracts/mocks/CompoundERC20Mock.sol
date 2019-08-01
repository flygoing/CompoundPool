pragma solidity 0.5.7;

import { ERC20 } from "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract  CompoundERC20Mock is ERC20{

  uint256 internal constant PRECISION = 10 ** 18;

  ERC20 wrappingToken;
  uint256 exchangeRate = 50 * PRECISION;
  uint256 lastUpdateBlock = 0;

  
  constructor(ERC20 _wrappingToken) public {
    lastUpdateBlock = block.number;
    wrappingToken = _wrappingToken;
  }

  function enterMarkets(address[] memory cTokens) public returns (uint[] memory){
    return new uint[](0);
  }

  function updateExchangeRate() public {
    //Naive, but just want to keep the mock simple
    for(uint256 start = lastUpdateBlock+1; start <= block.number; start++){
      exchangeRate = exchangeRate * 1001 / 1000;
    }
    lastUpdateBlock = block.number;
  }

  function exchangeRateStored() public view returns (uint256) {
    return exchangeRate;
  }
  
  function exchangeRateCurrent() public returns (uint256) {
    updateExchangeRate();
    return exchangeRateStored();
  }

  function mint(uint256 _amount) public returns (uint256) {
    wrappingToken.transferFrom(msg.sender, address(this), _amount);
    _mint(msg.sender, _amount.mul(PRECISION).div(exchangeRateCurrent()));
  }

  function redeemUnderlying(uint256 _amount) public returns (uint256) {
    wrappingToken.transfer(msg.sender, _amount);
    _burn(msg.sender, _amount.mul(PRECISION).div(exchangeRateCurrent()));
  }
}
