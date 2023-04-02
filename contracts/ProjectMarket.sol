// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ProjectMarketStorage.sol";
import "./Charity.sol";
import "./Donor.sol";

contract ProjectMarket {
    address public owner;
    bool public contractStopped;
    bool internal locked;
    ProjectMarketStorage projectMarketStorage;
    CharityToken tokenContract;
    Charity charityContract;
    Donor donorContract;

    uint256 internal unverifiedCtLimit = 100;
    uint256 internal unverifiedTimeLimit = 20 days;

    event projectListed(uint256 charityId);
    event projectClosed(uint256 projectId);
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
            projectMarketStorage.isProjectActive(projectMarketId) == true,
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

    modifier noReentrant() {
        require(!locked, "No re-entrancy!");
        locked = true;
        _;
        locked = false;
    }

    function toggleContractStopped() public view contractOwnerOnly {
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
        uint256 projectId
    )
        public
        owningCharityOnly(projectMarketStorage.getProjectById(projectId).charityId)
        activeCharityId(projectMarketStorage.getProjectById(projectId).charityId)
        activeProjectId(projectId)
    {
        projectMarketStorage.closeProject(projectId);
        emit projectClosed(projectId);
    }

    function relistProject(uint256 charityId, uint256 projectId) public owningCharityOnly(charityId) activeCharityId(charityId) {
        projectMarketStorage.setProjectActive(projectId);
        emit projectListed(charityId);
    }

    // in order to donate, donor must first APPROVE the ProjectMarket contract's address to spend the specified ether
    function donateToProject(
        uint256 projectId,
        uint256 amt
    ) public isValidDonor haltInEmergency noReentrant {
        uint256 balance = tokenContract.checkBalance(msg.sender);
        require(amt <= balance, "You don't have sufficient funds to donate!");
        require(
            projectMarketStorage.isProjectActive(projectId),
            "Project ID provided is not valid or currently not active"
        );
        // require(
        //     tokenContract.checkApproval(msg.sender, owner) >= amt,
        //     "You did not authorise ProjectMarket to spend the specified amount to donate!"
        // );

        // perform check for automatic locking of charity wallet
        if (isExceedUnverifiedLimit(projectId)) {
            charityContract.lockWallet(
                projectMarketStorage.getProjectOwnerId(projectId)
            );
        }

        address projectOwner = projectMarketStorage.getProjectOwner(projectId);
        //tokenContract.transferTokensFrom(msg.sender, projectOwner, amt);
        tokenContract.transferTokens(projectOwner, amt);
        projectMarketStorage.addDonationToProject(projectId, amt, msg.sender, false);
        emit donationMade(projectId, msg.sender);
    }

    // perform check for automatic locking of charity wallet
    function isExceedUnverifiedLimit(
        uint256 projectId
    ) internal view returns (bool) {
        ProjectMarketStorage.donation[] memory donations = projectMarketStorage
            .getDonationsByProject(projectId);

        uint256 totalUnverifiedAmt = 0;

        for (uint256 i = 0; i < donations.length; i++) {
            uint256 unverifiedAmt = donations[i].amt - donations[i].amtVerified;
            if (
                block.timestamp - donations[i].transactionDate >=
                unverifiedTimeLimit
            ) {
                totalUnverifiedAmt += unverifiedAmt;
            }
            if (totalUnverifiedAmt >= unverifiedCtLimit) {
                return true;
            }
        }
        return false;
    }

    function verifyProofOfUsage(uint256 projectId, uint256 amount) public {
        projectMarketStorage.addProofOfUsageToProject(projectId, amount);
        emit proofVerified(projectId, amount);
    }

    function getAllProjectListings()
        public
        view
        returns (ProjectMarketStorage.project[] memory)
    {
        return projectMarketStorage.getAllProjects();
    }

    function getAllActiveProjectListings() public view returns (ProjectMarketStorage.project[] memory) {
        return projectMarketStorage.getAllActiveProjects();
    }
    
    function getProofsByProject(uint256 projectId) public view returns (ProjectMarketStorage.proof[] memory) {
        return projectMarketStorage.getAllProofsByProject(projectId);
    }

    function getProjectListingDetails(uint256 projectId) public view returns (ProjectMarketStorage.project memory) {
        return projectMarketStorage.getProjectById(projectId);
    }

    function isProjectActive(uint256 projectId) public view returns (bool) {
        return projectMarketStorage.isProjectActive(projectId);
    }

    function getDonationsByProject(uint256 projectId) public view returns (ProjectMarketStorage.donation[] memory) {
        return projectMarketStorage.getDonationsByProject(projectId);
    }

    function viewPastDonationsByDonor() public view returns (ProjectMarketStorage.donation[] memory) {
        return projectMarketStorage.getDonationsByDonor(msg.sender);
    }
}
