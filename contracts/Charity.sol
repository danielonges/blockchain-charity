// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./CharityStorage.sol";
import "./CharityToken.sol";

contract Charity {
    address public owner;
    CharityStorage charityStorage;
    CharityToken charityTokenContract;

    event charityVerified(address charity);
    event charitytDeactivated(address charity);
    event charityActivated(address charity);
    event withdrawCredits(address charity);

    constructor(
        CharityStorage charityAddress,
        CharityToken charityTokenAddress
    ) {
        owner = msg.sender;
        charityStorage = charityAddress;
        charityTokenContract = charityTokenAddress;
    }

    modifier ownerOnly() {
        require(
            msg.sender == owner,
            "Only the owner of this contract is allowed to perform this operation"
        );
        _;
    }

    modifier isValidCharity(uint256 charityId) {
        require(
            charityStorage.getCharityActive(charityId),
            "Charity ID given is not valid"
        );
        _;
    }

    modifier owningCharityOnly(uint256 charityId) {
        require(
            isOwnerOfCharity(charityId, msg.sender),
            "Only owning charity can perform this action!"
        );
        _;
    }

    modifier walletNotLocked(uint256 charityId) {
        require(
            !charityStorage.getCharityWalletLocked(charityId),
            "Wallet is locked and tokens cannot be withdrawn"
        );
        _;
    }

    function verifyCharity(
        address charityOwner,
        string memory name,
        CharityStorage.charityCategory category
    ) public ownerOnly {
        charityStorage.addCharity(charityOwner, name, category);
        emit charityVerified(charityOwner);
    }

    function deactivateCharity(uint256 charityId) public ownerOnly {
        charityStorage.setCharityActive(charityId, false);
        emit charitytDeactivated(charityStorage.getCharityOwner(charityId));
    }

    function activateCharity(uint256 charityId) public ownerOnly {
        charityStorage.setCharityActive(charityId, true);
        emit charityActivated(charityStorage.getCharityOwner(charityId));
    }

    function checkTokenBalance(
        uint256 charityId
    ) public view owningCharityOnly(charityId) returns (uint256) {
        return charityTokenContract.checkBalance(msg.sender);
    }

    function withdrawTokens(
        uint256 charityId,
        uint256 numTokens
    )
        public
        isValidCharity(charityId)
        owningCharityOnly(charityId)
        walletNotLocked(charityId)
    {
        uint256 charityTokensBalance = checkTokenBalance(charityId);
        require(
            numTokens <= charityTokensBalance,
            "You don't have enough tokens"
        );

        uint256 etherAmt = numTokens / 100;
        uint256 weiAmt = 1000000000000000000 * etherAmt;

        payable(msg.sender).transfer(weiAmt);
        charityTokenContract.transferTokens(address(this), numTokens); // transfer CT back to this contract address
        emit withdrawCredits(msg.sender);
    }

    function lockWallet(
        uint256 charityId
    ) public ownerOnly isValidCharity(charityId) {
        charityStorage.setCharityWalletLocked(charityId, true);
    }

    function isOwnerOfCharity(
        uint256 charityId,
        address charityOwner
    ) public view returns (bool) {
        return charityStorage.getCharityOwner(charityId) == charityOwner;
    }

    function isCharityActive(uint256 charityId) public view returns (bool) {
        return charityStorage.getCharityActive(charityId);
    }
}
