
# Compound Pool

Solidity smart contract that allows people to pool a "deposit token" into compound tokens, and the interest is given to a beneficiary.


## Deposit

Deposit your deposit tokens (e.g. DAI) to the pool. You can always withdraw exactly your total deposit, not more, not less. Must have allowances set before.

**CompoundPool.sol**
```
function deposit(uint256 amount) public view returns (bool)
```

The caller of this function must have already set an allowance for the CompoundPool contract to transfer at least `amount` deposit tokens.


## Withdraw

Withdraw your deposit tokens (e.g. DAI) from the pool.

**CompoundPool.sol**
```
function withdraw(uint256 amount) public view returns (bool)
```

## Donate

Donate an amount of deposit tokens (e.g. DAI) from the pool. All this does is transfer in the deposit token and wrap it on Compound. You can achieve the same affect for less gas by just sending the Compound token to the CompoundPool contract if you already have the wrapped token.

**CompoundPool.sol**
```
function donate(uint256 amount) public view returns (bool)
```

## Withdraw Interest

Only the beneficiary has access to this. The beneficiary can't withdraw more than the total `deposit`ed amount. Sends `_amount` of deposit tokens to `_to`. 

**CompoundPool.sol**
```
    function withdrawInterest(address _to, uint256 _amount) public onlyBeneficiary returns (uint256) {
```

## Change the beneficiary

Only the owner has access to this.

**CompoundPool.sol**
```
function updateBeneficiary(address _newBeneficiary) public onlyOwner
```

This function call will fail if not called by the owner.

## Change the owner

The owner can use this to give control over the pool's beneficiary to another address.

**CompoundPool.sol**
```
    function transferOwnership(address newOwner) public onlyOwner
```
