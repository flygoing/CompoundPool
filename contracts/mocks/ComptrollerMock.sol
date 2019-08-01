pragma solidity >=0.4.21 <0.6.0;

contract  ComptrollerMock {
  function enterMarkets(address[] memory cTokens) public returns (uint[] memory){
    uint[] memory errors = new uint[](1);
    errors[0] = 0;
    return errors;
  }
}
