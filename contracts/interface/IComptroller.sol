pragma solidity >=0.4.21 <0.6.0;

// Compound finance comptroller
interface IComptroller {
  function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
}
