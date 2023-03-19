// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./DonorStorage.sol";
import "./CharityToken.sol";

contract Donor {
    address public owner;
    DonorStorage donorStorage;
    CharityToken tokenContract;

    event DonorVerified(address donor);
    event DonorDeactivated(address donor);
    event DonorActivated(address donor);

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
        emit DonorVerified(donorAddr);
    }

    function deactivateDonor(uint256 charityId) public ownerOnly {
        donorStorage.setDonorActive(charityId, false);
    }

    function activateCharity(uint256 charityId) public ownerOnly {
        donorStorage.setDonorActive(charityId, true);
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
}
