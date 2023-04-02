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
    event withdrawCredits(address donor);

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

    // modifier donorOnly(uint256 donorId) {
    //     require(
    //         donorStorage.getDonorAddr(donorId) == msg.sender,
    //         "Only the donor is allowed to perform this operation"
    //     );
    //     _;
    // }

    modifier validDonor() {
        require(
            donorStorage.isValidDonor(msg.sender),
            "Donor address is not valid"
        );
        _;
    }

    function isValidDonor(address addr) public view returns (bool) {
        return donorStorage.isValidDonor(addr);
    }

    function verifyDonor(address donorAddr) public ownerOnly {
        donorStorage.addDonor(donorAddr);
        emit donorVerified(donorAddr);
    }

    function deactivateDonor(uint256 donorId) public ownerOnly {
        donorStorage.setDonorActive(donorId, false);
        emit donorDeactivated(donorStorage.getDonorAddr(donorId));
    }

    function activateDonor(uint256 donorId) public ownerOnly {
        donorStorage.setDonorActive(donorId, true);
        emit donorActivated(donorStorage.getDonorAddr(donorId));
    }

    function checkTokenBalance() public view validDonor returns (uint256) {
        return tokenContract.checkBalance(msg.sender);
    }

    function withdrawTokens(uint256 numTokens) public validDonor {
        uint256 tokenBalance = checkTokenBalance();
        require(numTokens <= tokenBalance, "You don't have enough tokens");

        uint256 etherAmt = numTokens / 100;
        uint256 weiAmt = 1000000000000000000 * etherAmt;

        payable(msg.sender).transfer(weiAmt);
        tokenContract.transferTokens(address(this), numTokens);
        emit withdrawCredits(msg.sender);
    }

    function getTokens() public payable validDonor {
        require(
            msg.value >= 1E16,
            "At least 0.01ETH is required to get CharityToken"
        );
        tokenContract.getTokens(msg.sender, msg.value);
        emit buyCredits(msg.sender);
    }
}
