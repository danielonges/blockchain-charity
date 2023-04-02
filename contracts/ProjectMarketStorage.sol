// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Charity.sol";
import "./CharityStorage.sol";

contract ProjectMarketStorage {
    enum DonationType {
        ONETIME,
        RECURRING
    }

    struct project {
        uint256 projectId;
        uint256 charityId;
        string title;
        string description;
        uint256 targetAmount;
        // donation[] donations;
        bool isActive;
    }

    struct donation {
        uint256 donationId;
        uint256 projectId;
        address donor;
        uint256 amt;
        uint256 amtVerified;
        uint256 transactionDate;
        // uint256 timeOfProofUpload;
        uint256 timeTakenToVerify;
        DonationType donationType;
    }

    struct proof {
        uint256 proofId;
        uint256 projectId;
        uint256 amtVerified;
        uint256 timeTakenToVerify;
        CharityStorage.charityCategory category;
    }

    uint256 projectIdCtr = 0;
    uint256 donationIdCtr = 0;
    Charity charityContract;

    address public owner = msg.sender; // set deployer as owner of the storage contract
    mapping(uint256 => project) public allProjects; // mapping of projectMarket ID to projectMarket
    mapping(uint256 => donation) public allDonations; // mapping of donation ID to donation
    mapping(uint256 => project[]) public projectsByCharity; // mapping of charity ID to list of projectMarkets
    mapping(uint256 => donation[]) public donationsByProject; // mapping of project ID to list of donations
    mapping(address => donation[]) transactions; // mapping of donor address to their past transactions
    project[] projects;

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

    modifier owningCharityOnly(address charityAddress) {
        require(
            charityAddress == msg.sender,
            "Only owning charity can perform this action!"
        );
        _;
    }

    function addProjectToMarket(
        uint256 charityId,
        string memory title,
        string memory description,
        uint256 targetAmount
    ) public returns (uint256) {
        // donation[] memory donations;
        project memory newProject = project(
            projectIdCtr,
            charityId,
            title,
            description,
            targetAmount,
            // donations,
            true
        );

        allProjects[projectIdCtr] = newProject;
        projectsByCharity[charityId].push(newProject);
        projects.push(newProject);
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

    function getProjectOwnerId(
        uint256 projectId
    ) public view returns (uint256) {
        return allProjects[projectId].charityId;
    }

    function addDonationToProject(
        uint256 projectId,
        uint256 amt,
        address donor,
        bool isRecurring
    ) public ownerOnly returns (uint256) {
        DonationType d = DonationType.ONETIME;
        if (isRecurring) {
            d = DonationType.RECURRING;
        }
        donation memory newDonation = donation(
            donationIdCtr,
            projectId,
            donor,
            amt,
            0,
            block.timestamp,
            0,
            d
        );
        // allProjects[projectId].donations.push(newDonation);
        allDonations[donationIdCtr] = newDonation;
        donationsByProject[projectId].push(newDonation);
        return donationIdCtr++;
    }

    function addProofOfUsageToProject(
        uint256 projectId,
        uint256 amount
    ) public owningCharityOnly(getProjectOwner(projectId)) {
        uint amt = amount;
        for (uint i = 0; i < donationsByProject[projectId].length; i++) {
            if (amt == 0) {
                break;
            }
            if (
                donationsByProject[projectId][i].amt !=
                donationsByProject[projectId][i].amtVerified
            ) {
                // not fully verified
                uint256 diff = donationsByProject[projectId][i].amt -
                    donationsByProject[projectId][i].amtVerified;
                uint256 amtToAdd = 0;
                if (amt >= diff) {
                    amtToAdd = diff;
                    amt -= diff;
                } else {
                    amtToAdd = amt;
                    amt = 0;
                }
                donationsByProject[projectId][i].amtVerified += amtToAdd;
                donationsByProject[projectId][i].timeTakenToVerify =
                    block.timestamp -
                    donationsByProject[projectId][i].transactionDate;
            }
        }
    }

    function getAllProjects() public view returns (project[] memory) {
        return projects;
    }

    function getProjectById(uint256 id) public view returns (project memory) {
        return allProjects[id];
    }

    function setProjectActive(uint256 id, bool active) public {
        allProjects[id].isActive = active;
    }

    function getDonationsByProject(
        uint256 id
    ) public view returns (donation[] memory) {
        return donationsByProject[id];
    }
}
