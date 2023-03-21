// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Charity.sol";

contract ProjectMarketStorage {
    struct project {
        uint256 projectId;
        uint256 charityId;
        string title;
        string description;
        uint256 targetAmount;
        donation[] donations;
        bool isActive;
    }

    struct donation {
        uint256 projectId;
        address donor;
        uint256 amt;
    }

    uint256 projectIdCtr = 0;
    Charity charityContract;

    address public owner = msg.sender; // set deployer as owner of the storage contract
    mapping(uint256 => project) allProjects; // mapping of projectMarket ID to projectMarket
    mapping(uint256 => project[]) projectsByCharity; // mapping of charity ID to list of projectMarkets

    constructor(Charity charityAddress) {
        charityContract = charityAddress;
    }

    modifier ownerOnly() {
        require(
            msg.sender == owner,
            "Only the owner of this contract is allowed to perform this operation"
        );
        _;
    }

    function addProjectToMarket(
        uint256 charityId,
        string memory title,
        string memory description,
        uint256 targetAmount
    ) public returns (uint256) {
        donation[] memory donations;
        project memory newProject = project(
            projectIdCtr,
            charityId,
            title,
            description,
            targetAmount,
            donations,
            true
        );

        allProjects[projectIdCtr] = newProject;
        projectsByCharity[charityId].push(newProject);

        return projectIdCtr++;
    }

    function closeProject(uint256 charityId, uint256 projectId) public {
        allProjects[projectId].isActive = false;
        projectsByCharity[charityId][projectId].isActive = false;
    }

    function getProjectActive(uint256 projectId) public view returns (bool) {
        return allProjects[projectId].isActive;
    }

    function getProjectOwner(uint256 projectId) public view returns (address) {
        return
            charityContract.getCharityOwner(allProjects[projectId].charityId);
    }

    function addDonationToProject(
        uint256 projectId,
        uint256 amt,
        address donor
    ) public ownerOnly {
        donation memory newDonation = donation(projectId, donor, amt);
        allProjects[projectId].donations.push(newDonation);
    }
}
