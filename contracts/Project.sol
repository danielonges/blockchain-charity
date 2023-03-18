// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;
import "./ProjectStorage.sol";
import "./Charity.sol";

contract Project {
    address public owner;
    ProjectStorage projectStorage;
    Charity charity;

    event projectListed(uint256 charityId);
    event projectClosed(uint256 charityId, uint256 projectId);

    constructor(ProjectStorage projectAddress, Charity charityAddress) public {
        owner = msg.sender;
        projectStorage = projectAddress;
        charity = charityAddress;
    }

    modifier owningCharityOnly(uint256 charityId) {
        require(
            charity.isOwnerOfCharity(charityId, msg.sender) == true,
            "Only owning charity can perform this action!"
        );
        _;
    }

    modifier activeCharityId(uint256 charityId) {
        require(
            charity.isCharityActive(charityId) == true,
            "Charity ID given is not valid or active"
        );
        _;
    }

    modifier activeProjectId(uint256 projectId) {
        require(
            projectStorage.getProjectActive(projectId) == true,
            "Project ID given is not valid or active"
        );
        _;
    }

    function listProject(
        uint256 charityId,
        string memory title,
        string memory description,
        uint256 targetAmount
    )
        public
        owningCharityOnly(charityId)
        activeCharityId(charityId)
        returns (uint256)
    {
        projectStorage.addProject(charityId, title, description, targetAmount);
        emit projectListed(charityId);
    }

    function unlistProject(
        uint256 charityId,
        uint256 projectId
    )
        public
        owningCharityOnly(charityId)
        activeCharityId(charityId)
        activeProjectId(projectId)
        returns (uint256)
    {
        projectStorage.closeProject(charityId, projectId);
        emit projectClosed(charityId, projectId);
    }
}
