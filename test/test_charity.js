const _deploy_contracts = require("../migrations/2_deploy_contracts");
const truffleAssert = require("truffle-assertions");
var assert = require("assert");

var Charity = artifacts.require("../contracts/Charity.sol");
var CharityStorage = artifacts.require("../contracts/CharityStorage.sol");
var CharityToken = artifacts.require("../contracts/CharityToken.sol");

const BigNumber = require("bignumber.js"); // npm install bignumber.js

const oneEth = new BigNumber(1000000000000000000); // 1 eth

contract("Charity", function (accounts) {
  before(async () => {
    charityInstance = await Charity.deployed();
    charityStorageInstance = await CharityStorage.deployed();
    charityTokenInstance = await CharityToken.deployed();
  });
  console.log("Testing Charity Contract");

  const charityId = 0;
  const charity = {
    name: "Leonard Foundation",
    category: CharityStorage.charityCategory.CHILDREN,
    owner: accounts[1]
  };

  it("Verify Charity", async () => {
    let verifiedCharity = await charityInstance.verifyCharity(
      charity.owner,
      charity.name,
      charity.category,
      { from: accounts[0] }
    );

    // charity that is created has an ID of 0
    assert.ok(await charityInstance.isOwnerOfCharity(charityId, accounts[1]));

    truffleAssert.eventEmitted(
      verifiedCharity,
      "charityVerified",
      (ev) => ev.charity == accounts[1]
    );
  });

  it("Check Balance", async () => {
    await charityTokenInstance.getTokens(accounts[1], oneEth, {
      from: accounts[0]
    });
    let balance = await charityInstance.checkTokenBalance(charityId, {
      from: accounts[1]
    });

    // non-owner can't check balance
    await truffleAssert.reverts(
      charityInstance.checkTokenBalance(charityId, {
        from: accounts[2]
      }),
      "Only owning charity can perform this action!"
    );

    assert.strictEqual(balance.toNumber(), 100, "Check Balance not working");
  });

  it("Withdraw Tokens", async () => {
    const oldBalance = new BigNumber(
      await charityInstance.checkTokenBalance(charityId, {
        from: accounts[1]
      })
    );
    const amtToWithdraw = 50;
    let withdraw = await charityInstance.withdrawTokens(
      charityId,
      amtToWithdraw,
      {
        from: accounts[1]
      }
    );
    const newBalance = new BigNumber(
      await charityInstance.checkTokenBalance(charityId, {
        from: accounts[1]
      })
    );

    // handle case where non-owner can't withdraw
    await truffleAssert.reverts(
      charityInstance.withdrawTokens(charityId, amtToWithdraw, {
        from: accounts[2]
      }),
      "Only owning charity can perform this action!"
    );

    truffleAssert.eventEmitted(
      withdraw,
      "withdrawCredits",
      (ev) => ev.charity == accounts[1]
    );

    assert.ok(
      oldBalance.minus(amtToWithdraw).isEqualTo(newBalance),
      "Withdraw Tokens not working"
    );
  });

  it("Lock Wallet", async () => {
    let lockWallet = await charityInstance.lockWallet(charityId, {
      from: accounts[0]
    });

    await truffleAssert.reverts(
      charityInstance.withdrawTokens(charityId, 10, {
        from: accounts[1]
      }),
      "Wallet is locked and tokens cannot be withdrawn"
    );

    truffleAssert.eventEmitted(
      lockWallet,
      "charityWalletLocked",
      (ev) => ev.charity == accounts[1]
    );
  });

  it("Unlock Wallet", async () => {
    const amtToWithdraw = 10;
    await truffleAssert.reverts(
      charityInstance.withdrawTokens(charityId, amtToWithdraw, {
        from: accounts[1]
      }),
      "Wallet is locked and tokens cannot be withdrawn"
    );

    let unlockWallet = await charityInstance.unlockWallet(charityId, {
      from: accounts[0]
    });

    const oldBalance = new BigNumber(
      await charityInstance.checkTokenBalance(charityId, {
        from: accounts[1]
      })
    );
    let withdraw = await charityInstance.withdrawTokens(
      charityId,
      amtToWithdraw,
      {
        from: accounts[1]
      }
    );
    const newBalance = new BigNumber(
      await charityInstance.checkTokenBalance(charityId, {
        from: accounts[1]
      })
    );

    truffleAssert.eventEmitted(
      unlockWallet,
      "charityWalletUnlocked",
      (ev) => ev.charity == accounts[1]
    );

    truffleAssert.eventEmitted(
      withdraw,
      "withdrawCredits",
      (ev) => ev.charity == accounts[1]
    );

    assert.ok(
      oldBalance.minus(amtToWithdraw).isEqualTo(newBalance),
      "Unlock Wallet not working"
    );
  });

  it("View All Charities", async () => {
    let allCharities = await charityInstance.getAllCharities();
    const charityToCheck = allCharities[0];
    assert.strictEqual(
      allCharities.length,
      1,
      "All charities length is not correct"
    );
    assert.ok(
      charityToCheck.owner,
      accounts[1],
      "Charity owner is not correct"
    );
    assert.strictEqual(
      parseInt(charityToCheck.id),
      charityId,
      "Charity ID is not correct"
    );
  });

  it("View Charity Details", async () => {
    let charityToCheck = await charityInstance.getCharityDetails(charityId);

    assert.strictEqual(
      charityToCheck.name,
      charity.name,
      "Charity name is not correct"
    );
    assert.strictEqual(
      charityToCheck.owner,
      charity.owner,
      "Charity owner is not correct"
    );
    assert.strictEqual(
      parseInt(charityToCheck.id),
      charityId,
      "Charity ID is not correct"
    );
    assert.strictEqual(
      parseInt(charityToCheck.category),
      charity.category,
      "Charity category is not correct"
    );
  });
});
