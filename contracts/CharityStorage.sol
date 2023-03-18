// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CharityStorage {
    enum charityCategory {
        CHILDREN,
        HUMAN_RIGHTS,
        DISASTER_RELIEF,
        RELIGIOUS,
        CULTURAL
    }

    struct charity {
        uint256 id;
        address owner;
        string name;
        charityCategory category;
        bool isActive;
    }

    uint256 charityIdCtr = 0;

    address public owner = msg.sender; // set deployer as owner of the storage contract
    mapping(uint256 => charity) charities;
    // charity[] verifiedCharities;

    modifier ownerOnly() {
        require(
            msg.sender == owner,
            "Only the owner of this contract is allowed to perform this operation"
        );
        _;
    }

    modifier activeCharityId(uint256 id) {
        require(
            charities[id].isActive,
            "Charity ID given is not valid or active"
        );
        _;
    }

    function addCharity(
        address charityOwner,
        string memory name,
        charityCategory category
    ) public ownerOnly returns (uint256) {
        charity memory newCharity = charity(
            charityIdCtr,
            charityOwner,
            name,
            category,
            true
        );

        charities[charityIdCtr] = newCharity;
        // verifiedCharities.push(newCharity);

        return charityIdCtr++;
    }

    function getCharityActive(uint256 id) public view returns (bool) {
        return charities[id].isActive;
    }

    function setCharityActive(uint256 id, bool active) public ownerOnly {
        charities[id].isActive = active;
    }

    function getCharityOwner(uint256 id) public view returns (address) {
        return charities[id].owner;
    }

    function getCharityName(uint256 id) public view returns (string memory) {
        return charities[id].name;
    }
}
