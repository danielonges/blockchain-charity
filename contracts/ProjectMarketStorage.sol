// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProjectMarketStorage {
    struct projectMarket {
        uint256 projectMarketId;
        uint256 charityId;
        string title;
        string description;
        uint256 targetAmount;
        bool isActive;
    }

    uint256 projectMarketIdCtr = 0;

    address public owner = msg.sender; // set deployer as owner of the storage contract
    mapping(uint256 => projectMarket) allProjectMarkets; // mapping of projectMarket ID to projectMarket
    mapping(uint256 => projectMarket[]) projectMarketsByCharity; // mapping of charity ID to list of projectMarkets

    function addProjectMarket(
        uint256 charityId,
        string memory title,
        string memory description,
        uint256 targetAmount
    ) public returns (uint256) {
        projectMarket memory newProjectMarket = projectMarket(
            projectMarketIdCtr,
            charityId,
            title,
            description,
            targetAmount,
            true
        );

        allProjectMarkets[projectMarketIdCtr] = newProjectMarket;
        projectMarketsByCharity[charityId].push(newProjectMarket);

        return projectMarketIdCtr++;
    }

    function closeProjectMarket(
        uint256 charityId,
        uint256 projectMarketId
    ) public {
        allProjectMarkets[projectMarketId].isActive = false;
        projectMarketsByCharity[charityId][projectMarketId].isActive = false;
    }

    function getProjectMarketActive(
        uint256 projectMarketId
    ) public view returns (bool) {
        return allProjectMarkets[projectMarketId].isActive;
    }
}
