
# Compound Pool

Solidity smart contract that allows people to pool a "deposit token" into compound tokens, and the interest is given to a beneficiary.


## Deposit

Deposit your deposit tokens (i.e. DAI) to the pool. You can always withdraw exactly your total deposit, not more, not less.

**CompoundPool.sol.sol**
```
function deposit(uint256 amount) public view returns (bool)
```

The caller of this function must have already set an allowance for the CompoundPool contract to transfer at least `amount` deposit tokens.


## Withdraw

Withdraw your deposit tokens (i.e. DAI) from the pool.

**CompoundPool.sol**
```
function withdraw(uint256 amount) public view returns (bool)
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