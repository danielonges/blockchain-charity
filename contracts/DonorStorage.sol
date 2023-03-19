// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DonorStorage {
    struct donor {
        uint256 id;
        address donorAddr;
        uint256 tokenBalance;
        bool isActive;
    }

    uint256 donorIdCtr = 0;
    address public owner = msg.sender;
    mapping(uint256 => donor) donors;
    donor[] allDonors;

    modifier ownerOnly() {
        require(
            msg.sender == owner,
            "Only the owner of this contract is allowed to perform this operation"
        );
        _;
    }

    modifier ownerOrDonorOnly(uint256 donorId) {
        require(
            msg.sender == owner || donors[donorId].donorAddr == msg.sender,
            "Only the owner of the contract or the donor associated with the donor ID is allowed to perform this operation"
        );
        _;
    }

    modifier activeDonorId(uint256 id) {
        require(donors[id].isActive, "Donor ID given is not valid or active");
        _;
    }

    function addDonor(address donorAddr) public ownerOnly returns (uint256) {
        donor memory newDonor = donor(donorIdCtr, donorAddr, 0, true);

        donors[donorIdCtr] = newDonor;
        allDonors.push(newDonor);

        return donorIdCtr++;
    }

    function getDonorActive(uint256 id) public view returns (bool) {
        return donors[id].isActive;
    }

    function setDonorActive(uint256 id, bool active) public ownerOnly {
        donors[id].isActive = active;
    }

    function getDonorBalance(
        uint256 id
    ) public view ownerOrDonorOnly(id) returns (uint256) {
        return donors[id].tokenBalance;
    }

    function getNumDonors() public view returns (uint256) {
        return allDonors.length;
    }

    function getAllDonors() public view returns (donor[] memory) {
        return allDonors;
    }

    function getDonorAddr(uint256 id) public view returns (address) {
        return donors[id].donorAddr;
    }
}
