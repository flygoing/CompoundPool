var CompoundPool = artifacts.require("CompoundPool")
var CompoundERC20Mock = artifacts.require("CompoundERC20Mock")
var ComptrollerMock = artifacts.require("ComptrollerMock")
var DepositTokenMock = artifacts.require("DepositTokenMock")

contract('CompoundPool', (accounts) => {
    var comptrollerMock,
        depositTokenMock,
        compoundERC20Mock,
        compoundPool


    beforeEach(async () => {
        comptrollerMock = await ComptrollerMock.new()
        depositTokenMock = await DepositTokenMock.new()
        compoundERC20Mock = await CompoundERC20Mock.new(depositTokenMock.address)
        compoundPool = await CompoundPool.new(comptrollerMock.address, compoundERC20Mock.address, depositTokenMock.address, accounts[0])
        await depositTokenMock.approve(compoundPool.address, "1000000000000000000000000000000")
        await depositTokenMock.transfer(compoundERC20Mock.address, "10000000000000000000")
    })

    it("test deposit, withdraw, donate, and sendInterest", async () => {
        //Depositing should set the balances up correctly, and interest should start to accrue
        await compoundPool.deposit("1000000000000000000")
        assert.equal(await compoundPool.balanceOf(accounts[0]), "1000000000000000000")
        assert.equal(await depositTokenMock.balanceOf(compoundERC20Mock.address),"11000000000000000000")
        assert.equal((await compoundPool.excessDepositTokens.call()).toString(),"999999999999965")

        //Donate should affect the excessDepositTokens correctly
        await compoundPool.donate("100000000000000000")
        assert.equal((await compoundPool.excessDepositTokens.call()).toString(),"102100999999999944")

        
        //Should fail to withdraw more than excess deposit amount, but still less than total holdings
        await compoundPool.withdrawInterest(accounts[0],"900000000000000000").then(function(){
            assert.fail("Should have failed withdrawing more than excess interest")
        }).catch(function(){})
        //Withdrawing <= the user's balance should work        
        await compoundPool.withdraw("1000000000000000000")

        //Withdrawing more than the user's balance should fail
        await compoundPool.withdraw("100000").then(function(){
            assert.fail("Should have failed withdrawing more than user deposited")
        }).catch(function(){})

        //Non-beneficiary shouldn't be able to withdraw interest
        await compoundPool.withdrawInterest(accounts[0],"103409610405100967", {from:accounts[1]}).then(function(){
            assert.fail("Should have failed when non-beneficiary tried to withdraw interest")
        }).catch(function(){})

        //Beneficiary should be able to withdraw all interest
        await compoundPool.withdrawInterest(accounts[0],"103513020015506068")
        
        assert.equal((await compoundERC20Mock.balanceOf(compoundPool.address)).toString(),"1")

    })


})