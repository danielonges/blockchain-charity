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
        bool isActive;
    }

    struct donation {
        uint256 donationId;
        uint256 projectId;
        address donor;
        uint256 amt;
        uint256 amtVerified;
        uint256 transactionDate;
        uint256 timeTakenToVerify;
        DonationType donationType;
    }

    struct proof {
        uint256 proofId;
        uint256 projectId;
        uint256 amtVerified;
        uint256 timeOfUpload;
        string utility;
    }

    uint256 projectIdCtr = 0;
    uint256 donationIdCtr = 0;
    uint256 proofIdCtr = 0;
    uint256 numActiveListings = 0;
    Charity charityContract;

    address public owner = msg.sender; // set deployer as owner of the storage contract
    mapping(uint256 => project) public allProjects; // mapping of projectMarket ID to projectMarket
    mapping(uint256 => donation) public allDonations; // mapping of donation ID to donation
    mapping(uint256 => project[]) public projectsByCharity; // mapping of charity ID to list of projectMarkets
    mapping(uint256 => donation[]) public donationsByProject; // mapping of project ID to list of donations
    mapping(address => donation[]) public donationsByDonor; // don't use this to access donations, purely for counting number of donations per donor
    mapping(address => donation[]) transactions; // mapping of donor address to their past transactions
    mapping(uint256 => proof[]) proofsByProject; // mapping of project ID to list of proofs

    project[] projects;
    uint256 numDonations;

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
        projects.push(newProject);
        numActiveListings++;
        return projectIdCtr++;
    }

    function closeProject(uint256 projectId) public {
        allProjects[projectId].isActive = false;
        projectsByCharity[getProjectById(projectId).charityId][projectId].isActive = false;
        numActiveListings--;
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
    ) public returns (uint256) {
        DonationType d = DonationType.ONETIME;
        if (isRecurring) {
            d = DonationType.RECURRING;
        }
        uint256 cId = allProjects[projectId].charityId;
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
        allDonations[donationIdCtr] = newDonation;
        donationsByProject[projectId].push(newDonation);
        donationsByDonor[donor].push(newDonation);
        numDonations++;
        incrementOrDecrementNumUnverifiedTransaction(cId, true);
        return donationIdCtr++;
    }

    function addProofOfUsageToProject(
        uint256 projectId,
        uint256 amount,
        string memory utility
    ) public returns (uint256) {
        uint256 cId = allProjects[projectId].charityId;
        proof memory newProof = proof(
            proofIdCtr,
            projectId,
            amount,
            block.timestamp,
            utility
        );
        proofsByProject[projectId].push(newProof);
        for (uint i = 0; i < donationsByProject[projectId].length; i++) {
            uint256 donationId = donationsByProject[projectId][i].donationId;
            if (donationsByProject[projectId][i].timeTakenToVerify == 0) { // not yet verified
                uint256 amtNeededToFullyVerifyCurrDonation = donationsByProject[projectId][i].amt - donationsByProject[projectId][i].amtVerified;
                if (amount >= amtNeededToFullyVerifyCurrDonation) { // can just verify full amount
                    amount -= amtNeededToFullyVerifyCurrDonation;                    
                    donationsByProject[projectId][i].amtVerified = donationsByProject[projectId][i].amt;
                    donationsByProject[projectId][i].timeTakenToVerify = block.timestamp - donationsByProject[projectId][i].transactionDate;
                    allDonations[donationId].amtVerified = donationsByProject[projectId][i].amt;
                    allDonations[donationId].timeTakenToVerify = block.timestamp - donationsByProject[projectId][i].transactionDate;
                    uint256 averageTimeTakenToVerify = getAverageTimeTakenToVerifyByCharity(cId);
                    setCharityAverageTimeTakenToVerify(cId, averageTimeTakenToVerify);
                    incrementOrDecrementNumVerifiedTransaction(cId, true);
                    incrementOrDecrementNumUnverifiedTransaction(cId, false);
                } else {
                    donationsByProject[projectId][i].amtVerified += amount; // add remaining amount to amount verified
                    allDonations[donationId].amtVerified += amount;
                    break;
                }
            }
        }
        return proofIdCtr++;
    }

    function getAllProjects() public view returns (project[] memory) {
        return projects;
    }

    function getAllActiveProjects() public view returns (project[] memory) {
        project[] memory active = new project[](numActiveListings);
        uint256 idx = 0;
        for (uint256 i = 0; i < projects.length; i++) {
            if (isProjectActive(i) && idx < numActiveListings) {
                active[idx] = allProjects[i];
                idx++;
            }
        }
        return active;
    }

    function getAllProofsByProject(uint256 projectId) public view returns (proof[] memory) {
        return proofsByProject[projectId];
    }

    function getProjectById(uint256 id) public view returns (project memory) {
        return allProjects[id];
    }

    function isProjectActive(uint256 id) public view returns (bool) {
        return allProjects[id].isActive;
    }

    function setProjectActive(uint256 id) public {
        allProjects[id].isActive = true;
        numActiveListings++;
    }

    function getDonationsByProject(uint256 projectId) public view returns (donation[] memory) {
        return donationsByProject[projectId];
    }

    function getDonationsByDonor(address donor) public view returns (donation[] memory) {
        donation[] memory filtered = new donation[](donationsByDonor[donor].length);
        uint256 idx = 0;
        for (uint256 i = 0; i < numDonations; i++) {
            if (allDonations[i].donor == donor) {
                filtered[idx] = allDonations[i];
                idx++;
            }
        }
        return filtered;
    }

    function setCharityAverageTimeTakenToVerify(uint256 charityId, uint256 timeTakenToVerify) public {
        charityContract.setCharityAverageTimeTakenToVerify(charityId, timeTakenToVerify);
    }

    function incrementOrDecrementNumVerifiedTransaction(uint256 charityId, bool isIncrement) public {
        charityContract.incrementOrDecrementNumVerifiedTransaction(charityId, isIncrement);
    }

    function incrementOrDecrementNumUnverifiedTransaction(uint256 charityId, bool isIncrement) public {
        charityContract.incrementOrDecrementNumUnverifiedTransaction(charityId, isIncrement);
    }

    function getAverageTimeTakenToVerifyByCharity(uint256 charityId) public view returns (uint256) {
        uint256 totalTime = 0;
        uint256 numDonationsVerifiable = 0;
        project[] memory allProjectsByCharity = projectsByCharity[charityId];
        for (uint256 i = 0; i < allProjectsByCharity.length; i++) {
            donation[] memory allDonationsByProject = getDonationsByProject(allProjectsByCharity[i].projectId);
            for (uint256 j = 0; j < allDonationsByProject.length; j++) {
                if (allDonationsByProject[j].timeTakenToVerify > 0) {
                    totalTime += allDonationsByProject[j].timeTakenToVerify;
                    numDonationsVerifiable++;
                }
            }
        }
        return totalTime / numDonationsVerifiable;
    }
}
