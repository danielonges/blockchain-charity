// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

contract ProjectStorage {
    struct project {
        uint256 projectId;
        uint256 charityId;
        string title;
        string description;
        uint256 targetAmount;
        bool isActive;
    }

    uint256 projectIdCtr = 0;

    address public owner = msg.sender; // set deployer as owner of the storage contract
    mapping(uint256 => project) allProjects; // mapping of project ID to project
    mapping(uint256 => project[]) projectsByCharity; // mapping of charity ID to list of projects

    function addProject(
        uint256 charityId,
        string memory title,
        string memory description,
        uint256 targetAmount
    ) public returns (uint256) {
        project memory newProject = project(
            projectIdCtr,
            charityId,
            title,
            description,
            targetAmount,
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
}
