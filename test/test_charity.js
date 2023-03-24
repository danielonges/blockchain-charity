const _deploy_contracts = require("../migrations/2_deploy_contracts");
const truffleAssert = require("truffle-assertions");
var assert = require("assert");

var Charity = artifacts.require("../contracts/Charity.sol");
var CharityStorage = artifacts.require("../contracts/CharityStorage.sol");
var CharityToken = artifacts.require("../contracts/CharityToken.sol");

contract("Charity", function (accounts) {
  before(async () => {
    charityInstance = await Charity.deployed();
    charityStorageInstance = await CharityStorage.deployed();
    charityTokenInstance = await CharityToken.deployed();
  });
  console.log("Testing Charity Contract");

  it("Verify Charity", async () => {
    var charityVerified = await charityInstance.verifyCharity(
      accounts[1],
      "Leonard Foundation",
      CharityStorage.charityCategory.CHILDREN,
      { from: accounts[0] }
    );

    assert.ok(await charityInstance.isOwnerOfCharity(0, accounts[1]));

    truffleAssert.eventEmitted(
      charityVerified,
      "charityVerified",
      (ev) => ev.charity == accounts[1]
    );
  });
});
