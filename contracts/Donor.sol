// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./DonorStorage.sol";
import "./CharityToken.sol";

contract Donor {
    address public owner;
    DonorStorage donorStorage;
    CharityToken tokenContract;

    event donorVerified(address donor);
    event donorDeactivated(address donor);
    event donorActivated(address donor);
    event buyCredits(address donor);

    constructor(DonorStorage donorAddress, CharityToken token) {
        owner = msg.sender;
        donorStorage = donorAddress;
        tokenContract = token;
    }

    modifier ownerOnly() {
        require(
            msg.sender == owner,
            "Only the owner of this contract is allowed to perform this operation"
        );
        _;
    }

    modifier donorOnly(uint256 donorId) {
        require(
            donorStorage.getDonorAddr(donorId) == msg.sender,
            "Only the donor is allowed to perform this operation"
        );
        _;
    }

    modifier isValidDonor(uint256 donorId) {
        require(
            donorStorage.getDonorActive(donorId),
            "Donor ID given is not valid"
        );
        _;
    }

    function verifyDonor(address donorAddr) public ownerOnly {
        donorStorage.addDonor(donorAddr);
        emit donorVerified(donorAddr);
    }

    function deactivateDonor(uint256 donorId) public ownerOnly {
        donorStorage.setDonorActive(donorId, false);
        emit donorDeactivated(donorStorage.getDonorAddr(donorId));
    }

    function activateCharity(uint256 donorId) public ownerOnly {
        donorStorage.setDonorActive(donorId, true);
        emit donorActivated(donorStorage.getDonorAddr(donorId));
    }

    function checkTokenBalance(
        uint256 donorId
    ) public view donorOnly(donorId) returns (uint256) {
        return tokenContract.checkBalance(msg.sender);
    }

    function withdrawTokens(
        uint256 donorId,
        uint256 numTokens
    ) public isValidDonor(donorId) donorOnly(donorId) {
        uint256 tokenBalance = checkTokenBalance(donorId);
        require(numTokens <= tokenBalance, "You don't have enough tokens");

        uint256 etherAmt = numTokens / 100;
        uint256 weiAmt = 1000000000000000000 * etherAmt;

        payable(msg.sender).transfer(weiAmt);
        tokenContract.transferTokens(address(this), numTokens);
    }

    function getTokens(
        uint256 donorId
    ) public payable isValidDonor(donorId) donorOnly(donorId) {
        require(
            msg.value >= 1E16,
            "At least 0.01ETH is required to get CharityToken"
        );
        tokenContract.getTokens(msg.sender, msg.value / 1E16);
        emit buyCredits(msg.sender);
    }
}
