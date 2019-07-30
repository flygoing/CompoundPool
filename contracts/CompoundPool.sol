pragma solidity 0.5.7;
pragma experimental ABIEncoderV2;

import { IERC20 } from "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import { SafeMath } from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import { Ownable } from "openzeppelin-solidity/contracts/ownership/Ownable.sol";

import { ICompoundERC20 } from "./interface/ICompoundERC20.sol";
import { IComptroller } from "./interface/IComptroller.sol";

/**
 * @title CompoundPool
 * @dev A bank that will pool compound tokens and allows the beneficiary to withdraw
 */
contract CompoundPool is ERC20, Ownable {
    using SafeMath for uint;
    uint256 internal constant PRECISION = 10 ** 18;

    ICompoundERC20 public compoundToken;
    IERC20 public depositToken;
    address public governance;

    address public beneficiary;


    constructor(
        IComptroller _comptroller,
        ICompoundERC20 _compoundToken,
        IERC20 _depositToken,
        address _beneficiary
    )
        public
    {
        compoundToken = _compoundToken;
        depositToken = _depositToken;
    	beneficiary = _beneficiary;
        _approve();

        // Enter compound token market
        address[] memory markets = new address[](1);
        markets[0] = address(compoundToken);
        uint[] memory errors = _comptroller.enterMarkets(markets);
        require(errors[0] == 0, "Failed to enter compound token market");
    }

    modifier onlyBeneficiary() {
        require(msg.sender == address(beneficiary), "Bank::onlyBeneficiary: Only callable by owner");
        _;
    }

    function updateBeneficiary(address _newBeneficiary) public onlyOwner {
        beneficiary = _newBeneficiary;
    }

    function withdrawInterest(address _to, uint256 _amount) public onlyBeneficiary returns (uint256) {
        uint availableDepositTokens = excessDepositTokens();
        require(_amount <= availableDepositTokens, "Bank::sendInterest: Not enough excess deposit token");

        // redeem `_amount` of `depositToken`s from compound
        require(compoundToken.redeemUnderlying(_amount) == 0, "Bank::withdrawInterest: Compound redeem failed");

        depositToken.transfer(_to, _amount);
    }

    function deposit(uint256 _amount) public {
        // transfer `_amount` of deposit tokens from `msg.sender`
        require(depositToken.transferFrom(msg.sender, address(this), _amount), "Bank::deposit: Transfer failed");

        // use `_amount` of deposit tokens to mint compound tokens for the bank
        require(compoundToken.mint(_amount) == 0, "Bank::deposit: Compound mint failed");
    
        // mint `amount` bank funds for `msg.sender`
        _mint(msg.sender, _amount);
    }

    function donate(uint256 _amount) public {
        // transfer `_amount` of deposit tokens from `msg.sender`
        require(depositToken.transferFrom(msg.sender, address(this), _amount), "Bank::donate: Transfer failed");

        // use `_amount` of deposit tokens to mint compound tokens for the bank
        require(compoundToken.mint(_amount) == 0, "Bank::deposit: Compound mint failed");
    }

    function withdraw(uint256 _amount) public {
        // burn `amount` bank tokens from msg.sender
        _burn(msg.sender, _amount);

        // redeem `_amount` of depositTokens from compound
        require(compoundToken.redeemUnderlying(_amount) == 0, "Bank::withdraw: Compound redeem failed");

        // transfer deposit token to msg.sender
        require(depositToken.transfer(msg.sender, _amount), "Bank::withdraw: Transfer failed");
    }

    function excessDepositTokens() public returns (uint256) {
        return compoundToken.exchangeRateCurrent().mul(compoundToken.balanceOf(address(this))).div(PRECISION).sub(totalSupply());
    }

    function wrapStandingDonations() public {
        require(compoundToken.mint(depositToken.balanceOf(address(this))) == 0, "Failed to mint compound token");
    }

    function _approve() public {
        depositToken.approve(address(compoundToken),uint256(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff));
    }
}