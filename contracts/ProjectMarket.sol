// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ProjectMarketStorage.sol";
import "./Charity.sol";
import "./Donor.sol";

contract ProjectMarket {
    address public owner;
    bool public contractStopped;
    ProjectMarketStorage projectMarketStorage;
    CharityToken tokenContract;
    Charity charityContract;
    Donor donorContract;

    event projectListed(uint256 charityId);
    event projectClosed(uint256 charityId, uint256 projectId);
    event donationMade(uint256 projectId, address donor);
    event proofVerified(uint256 projectId, uint256 amount);

    constructor(
        ProjectMarketStorage projectMarketAddress,
        CharityToken tokenAddress,
        Charity charityAddress,
        Donor donorAddress
    ) {
        owner = msg.sender;
        projectMarketStorage = projectMarketAddress;
        tokenContract = tokenAddress;
        charityContract = charityAddress;
        donorContract = donorAddress;
    }

    modifier contractOwnerOnly() {
        require(
            msg.sender == owner,
            "Only contract owner can perform this action!"
        );
        _;
    }

    modifier owningCharityOnly(uint256 charityId) {
        require(
            charityContract.isOwnerOfCharity(charityId, msg.sender) == true,
            "Only owning charity can perform this action!"
        );
        _;
    }

    modifier activeCharityId(uint256 charityId) {
        require(
            charityContract.isCharityActive(charityId) == true,
            "Charity ID given is not valid or active"
        );
        _;
    }

    modifier activeProjectId(uint256 projectMarketId) {
        require(
            projectMarketStorage.getProjectActive(projectMarketId) == true,
            "ProjectMarket ID given is not valid or active"
        );
        _;
    }

    modifier isValidDonor() {
        require(
            donorContract.isValidDonor(msg.sender),
            "You are not a valid donor!"
        );
        _;
    }


    modifier haltInEmergency() {
        require(!contractStopped, "Contract stopped!");
        _;
    }

    function toggleContractStopped() public ownerOnly {
        contractStopped != contractStopped;
    }

    function listProject(
        uint256 charityId,
        string memory title,
        string memory description,
        uint256 targetAmount
    ) public owningCharityOnly(charityId) activeCharityId(charityId) {
        projectMarketStorage.addProjectToMarket(
            charityId,
            title,
            description,
            targetAmount
        );
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
    {
        projectMarketStorage.closeProject(charityId, projectId);
        emit projectClosed(charityId, projectId);
    }

    function relistProject(uint256 charityId, uint256 projectId) public owningCharityOnly(charityId) activeCharityId(charityId) {
        projectMarketStorage.setProjectActive(projectId, true);
        emit projectListed(charityId);
    }

    // in order to donate, donor must first APPROVE the ProjectMarket contract's address to spend the specified ether
    function donateToProject(
        uint256 projectId,
        uint256 amt
    ) public isValidDonor haltInEmergency {
        uint256 balance = tokenContract.checkBalance(msg.sender);
        require(amt <= balance, "You don't have sufficient funds to donate!");
        require(
            projectMarketStorage.getProjectActive(projectId),
            "Project ID provided is not valid or currently not active"
        );
        // require(
        //     tokenContract.checkApproval(msg.sender, owner) >= amt,
        //     "You did not authorise ProjectMarket to spend the specified amount to donate!"
        // );

        address projectOwner = projectMarketStorage.getProjectOwner(projectId);
        //tokenContract.transferTokensFrom(msg.sender, projectOwner, amt);
        tokenContract.transferTokens(projectOwner, amt);
        emit donationMade(projectId, msg.sender);
    }

    function verifyProofOfUsage(uint256 projectId, uint256 amount) public {
        projectMarketStorage.addProofOfUsageToProject(projectId, amount);
        emit proofVerified(projectId, amount);
    }
}

    function getAllProjectListings() public view returns (ProjectMarketStorage.project[] memory) {
        return projectMarketStorage.getAllProjects();
    }

    function getProjectListingDetails(uint256 projectId) public view returns (ProjectMarketStorage.project memory) {
        return projectMarketStorage.getProjectById(projectId);
    }

    function isProjectActive(uint256 projectId) public view returns (bool) {
        return projectMarketStorage.getProjectActive(projectId);
    }
}
