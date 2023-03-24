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
        bool isWalletLocked;
    }

    uint256 charityIdCtr = 0;

    address public owner = msg.sender; // set deployer as owner of the storage contract
    mapping(uint256 => charity) charitiesById;
    mapping(address => charity) charitiesByAddr;
    // uint256 numCharities = 0; // total number of charities
    charity[] allCharities;

    modifier ownerOnly() {
        require(
            tx.origin == owner,
            "Only the owner of this contract is allowed to perform this operation"
        );
        _;
    }

    // modifier activeCharityId(uint256 id) {
    //     require(
    //         charitiesById[id].isActive || charitiesByAddr[msg.sender].isActive,
    //         "Charity ID given is not valid or active"
    //     );
    //     _;
    // }

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
            true,
            false
        );

        charitiesById[charityIdCtr] = newCharity;
        allCharities.push(newCharity);

        return charityIdCtr++;
    }

    function getCharityActive(uint256 id) public view returns (bool) {
        return charitiesById[id].isActive;
    }

    function setCharityActive(uint256 id, bool active) public ownerOnly {
        charitiesById[id].isActive = active;
    }

    function getCharityOwner(uint256 id) public view returns (address) {
        return charitiesById[id].owner;
    }

    function getCharityName(uint256 id) public view returns (string memory) {
        return charitiesById[id].name;
    }

    function getCharityWalletLocked(uint256 id) public view returns (bool) {
        return charitiesById[id].isWalletLocked;
    }

    function setCharityWalletLocked(uint256 id, bool locked) public ownerOnly {
        charitiesById[id].isWalletLocked = locked;
    }

    function getNumCharities() public view returns (uint256) {
        return allCharities.length;
    }

    function getAllCharities() public view returns (charity[] memory) {
        return allCharities;
    }

    function getCharityById(uint256 id) public view returns (charity memory) {
        return charitiesById[id];
    }
}
