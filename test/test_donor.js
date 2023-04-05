const _deploy_contracts = require('../migrations/2_deploy_contracts')
const truffleAssert = require('truffle-assertions')
var assert = require('assert')

var DonorStorage = artifacts.require('../contracts/DonorStorage.sol')
var Donor = artifacts.require('../contracts/Donor.sol')

const BigNumber = require('bignumber.js') // npm install bignumber.js

const oneEth = new BigNumber(1000000000000000000) // 1 eth

contract('Donor', function (accounts) {
  before(async () => {
    donorStorageInstance = await DonorStorage.deployed()
    donorInstance = await Donor.deployed()
  })
  console.log('Testing Donor Contract')

  // initialise testing constants
  const donor = {
    donorAddr: accounts[1]
  }

  it('Verify Donor', async () => {
    // create and verify donor
    let verifiedDonor = await donorInstance.verifyDonor(donor.donorAddr, {
      from: accounts[0]
    })

    // donor that is created has an ID of 0
    assert.ok(await donorInstance.isValidDonor(donor.donorAddr))

    truffleAssert.eventEmitted(
      verifiedDonor,
      'donorVerified',
      (ev) => ev.donor == accounts[1]
    )
  })

  it('Get tokens', async () => {
    // add tokens to donor's wallet - for testing purposes
    let getTokens = await donorInstance.getTokens({
      from: accounts[1],
      value: oneEth
    })

    // only valid donors can get tokens
    await truffleAssert.reverts(
      donorInstance.getTokens({
        from: accounts[2],
        value: oneEth
      }),
      'Donor address is not valid'
    )

    // require at least 0.01ETH to obtain a CharityToken
    await truffleAssert.reverts(
      donorInstance.getTokens({
        from: accounts[1],
        value: oneEth / 1000
      }),
      'At least 0.01ETH is required to get CharityToken'
    )

    truffleAssert.eventEmitted(
      getTokens,
      'buyCredits',
      (ev) => ev.donor == accounts[1]
    )
  })

  it('Check Balance', async () => {
    let balance = await donorInstance.checkTokenBalance({
      from: accounts[1]
    })

    // only valid donors can check token balance
    await truffleAssert.reverts(
      donorInstance.checkTokenBalance({
        from: accounts[2]
      }),
      'Donor address is not valid'
    )

    assert.strictEqual(balance.toNumber(), 100, 'Check Balance not working')
  })

  it('Withdraw Tokens', async () => {
    const oldBalance = new BigNumber(
      await donorInstance.checkTokenBalance({
        from: accounts[1]
      })
    )

    // withdraw 50 tokens from donor wallet
    const amtToWithdraw = 50
    let withdraw = await donorInstance.withdrawTokens(amtToWithdraw, {
      from: accounts[1]
    })

    const newBalance = new BigNumber(
      await donorInstance.checkTokenBalance({
        from: accounts[1]
      })
    )

    // non-valid donors cannot withdraw
    await truffleAssert.reverts(
      donorInstance.withdrawTokens(amtToWithdraw, {
        from: accounts[2]
      }),
      'Donor address is not valid'
    )

    truffleAssert.eventEmitted(
      withdraw,
      'withdrawCredits',
      (ev) => ev.donor == accounts[1]
    )

    assert.ok(
      oldBalance.minus(amtToWithdraw).isEqualTo(newBalance),
      'Withdraw Tokens not working'
    )
  })
})
