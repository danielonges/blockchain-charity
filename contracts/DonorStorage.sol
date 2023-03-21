// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DonorStorage {
    struct donor {
        uint256 id;
        address donorAddr;
        bool isActive;
    }

    uint256 donorIdCtr = 0;
    address public owner = msg.sender;
    mapping(uint256 => donor) donorsById; // map donorId to donor
    mapping(address => donor) donorsByAddr; // map donor's address to donor
    donor[] allDonors;

    modifier ownerOnly() {
        require(
            msg.sender == owner,
            "Only the owner of this contract is allowed to perform this operation"
        );
        _;
    }

    function addDonor(address donorAddr) public ownerOnly returns (uint256) {
        donor memory newDonor = donor(donorIdCtr, donorAddr, true);

        donorsById[donorIdCtr] = newDonor;
        allDonors.push(newDonor);

        return donorIdCtr++;
    }

    function getDonorActive(uint256 id) public view returns (bool) {
        return donorsById[id].isActive;
    }

    function setDonorActive(uint256 id, bool active) public ownerOnly {
        donorsById[id].isActive = active;
    }

    function getNumDonors() public view returns (uint256) {
        return allDonors.length;
    }

    function getAllDonors() public view returns (donor[] memory) {
        return allDonors;
    }

    function getDonorAddr(uint256 id) public view returns (address) {
        return donorsById[id].donorAddr;
    }

    function isValidDonor(address addr) public view returns (bool) {
        return donorsByAddr[addr].isActive;
    }
}
