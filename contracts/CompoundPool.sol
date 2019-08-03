pragma solidity 0.5.7;
pragma experimental ABIEncoderV2;

import { IERC20 } from "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import { ERC20Detailed } from "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import { ERC20 } from "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import { SafeMath } from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import { Ownable } from "openzeppelin-solidity/contracts/ownership/Ownable.sol";

import { ICompoundERC20 } from "./interface/ICompoundERC20.sol";
import { IComptroller } from "./interface/IComptroller.sol";

/**
 * @title CompoundPool
 * @author Nate Welch <github.com/flyging>
 * @notice Based on Zefram Lou's implementation https://github.com/ZeframLou/pooled-cdai
 * @dev A bank that will pool compound tokens and allows the beneficiary to withdraw
 */
contract CompoundPool is ERC20, ERC20Detailed, Ownable {
    using SafeMath for uint;

    uint256 internal constant PRECISION = 10 ** 18;

    ICompoundERC20 public compoundToken;
    IERC20 public depositToken;
    address public governance;
    address public beneficiary;

    /**
     * @notice Constructor
     * @param _name name of the pool share token
     * @param _symbol symbol of the pool share token
     * @param _comptroller the Compound Comptroller contract used to enter the compoundToken's market
     * @param _compoundToken the Compound Token contract (e.g. cDAI)
     * @param _depositToken the Deposit Token contract (e.g. DAI)
     * @param _beneficiary the address that can withdraw excess deposit tokens (interest/donations)
     */
    constructor(
        string memory _name,
        string memory _symbol,
        IComptroller _comptroller,
        ICompoundERC20 _compoundToken,
        IERC20 _depositToken,
        address _beneficiary
    )
        ERC20Detailed(_name, _symbol, 18)
        public
    {
        compoundToken = _compoundToken;
        depositToken = _depositToken;
        beneficiary = _beneficiary;

        _approveDepositToken(1);

        // Enter compound token market
        address[] memory markets = new address[](1);
        markets[0] = address(compoundToken);
        uint[] memory errors = _comptroller.enterMarkets(markets);
        require(errors[0] == 0, "Failed to enter compound token market");
    }

    /**
     * @dev used to restrict access of functions to the current beneficiary
     */
    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "CompoundPool::onlyBeneficiary: Only callable by beneficiary");
        _;
    }

    /**
     * @notice Called by the `owner` to set a new beneficiary
     * @dev This function will fail if called by a non-owner address
     * @param _newBeneficiary The address that will become the new beneficiary
     */
    function updateBeneficiary(address _newBeneficiary) public onlyOwner {
        beneficiary = _newBeneficiary;
    }

    /**
     * @notice The beneficiary calls this function to withdraw excess deposit tokens
     * @dev This function will fail if called by a non-beneficiary or if _amount is higher than the excess deposit tokens
     * @param _to The address that the deposit tokens will be sent to
     * @param _amount The amount of deposit tokens to send to the `_to` address
     */
    function withdrawInterest(address _to, uint256 _amount) public onlyBeneficiary returns (uint256) {
        require(compoundToken.redeemUnderlying(_amount) == 0, "CompoundPool::withdrawInterest: Compound redeem failed");

        //Doing this *after* `redeemUnderlying` so I don't have compoundToken do `exchangeRateCurrent` twice, it's not cheap
        require(depositTokenStoredBalance() >= totalSupply(), "CompoundPool::withdrawInterest: Not enough excess deposit token");

        depositToken.transfer(_to, _amount);
    }

    /**
     * @notice Called by someone wishing to deposit to the bank. This amount, plus previous user's balance, will always be withdrawable
     * @dev Allowance for CompoundPool to transferFrom the msg.sender's balance must be set on the deposit token
     * @param _amount The amount of deposit tokens to deposit
     */
    function deposit(uint256 _amount) public {
        require(depositToken.transferFrom(msg.sender, address(this), _amount), "CompoundPool::deposit: Transfer failed");

        _approveDepositToken(_amount);

        require(compoundToken.mint(_amount) == 0, "CompoundPool::deposit: Compound mint failed");
    
        _mint(msg.sender, _amount);
    }

    /**
     * @notice Called by someone wishing to withdraw from the bank
     * @dev This will fail if msg.sender doesn't have at least _amount pool share tokens
     * @param _amount The amount of deposit tokens to withdraw
     */
    function withdraw(uint256 _amount) public {
        _burn(msg.sender, _amount);

        require(compoundToken.redeemUnderlying(_amount) == 0, "CompoundPool::withdraw: Compound redeem failed");

        require(depositToken.transfer(msg.sender, _amount), "CompoundPool::withdraw: Transfer failed");
    }

    /**
     * @notice Called by someone wishing to donate to the bank. This amount will *not* be added to users balance, and will be usable by the beneficiary.
     * @dev Allowance for CompoundPool to transferFrom the msg.sender's balance must be set on the deposit token
     * @param _amount The amount of deposit tokens to donate
     */
    function donate(uint256 _amount) public {
        require(depositToken.transferFrom(msg.sender, address(this), _amount), "CompoundPool::donate: Transfer failed");

        _approveDepositToken(_amount);

        require(compoundToken.mint(_amount) == 0, "CompoundPool::donate: Compound mint failed");
    }

    /**
     * @notice Returns the amount of deposit tokens that are usable by the beneficiary. Basically, interestEarned+donations
     * @dev Allowance for CompoundPool to transferFrom the msg.sender's balance must be set on the deposit token
     */
    function excessDepositTokens() public returns (uint256) {
        return compoundToken.exchangeRateCurrent().mul(compoundToken.balanceOf(address(this))).div(PRECISION).sub(totalSupply());
    }

    function depositTokenStoredBalance() internal returns (uint256) {
        return compoundToken.exchangeRateStored().mul(compoundToken.balanceOf(address(this))).div(PRECISION);
    }

    function _approveDepositToken(uint256 _minimum) internal {
        if(depositToken.allowance(address(this), address(compoundToken)) < _minimum){
            depositToken.approve(address(compoundToken),uint256(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff));
        }
    }
}
