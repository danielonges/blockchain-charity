// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ProjectMarketStorage.sol";
import "./Charity.sol";

contract ProjectMarket {
    address public owner;
    ProjectMarketStorage projectMarketStorage;
    Charity charity;

    event projectMarketListed(uint256 charityId);
    event projectMarketClosed(uint256 charityId, uint256 projectMarketId);

    constructor(
        ProjectMarketStorage projectMarketAddress,
        Charity charityAddress
    ) {
        owner = msg.sender;
        projectMarketStorage = projectMarketAddress;
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

    modifier activeProjectMarketId(uint256 projectMarketId) {
        require(
            projectMarketStorage.getProjectMarketActive(projectMarketId) ==
                true,
            "ProjectMarket ID given is not valid or active"
        );
        _;
    }

    function listProjectMarket(
        uint256 charityId,
        string memory title,
        string memory description,
        uint256 targetAmount
    ) public owningCharityOnly(charityId) activeCharityId(charityId) {
        projectMarketStorage.addProjectMarket(
            charityId,
            title,
            description,
            targetAmount
        );
        emit projectMarketListed(charityId);
    }

    function unlistProjectMarket(
        uint256 charityId,
        uint256 projectMarketId
    )
        public
        owningCharityOnly(charityId)
        activeCharityId(charityId)
        activeProjectMarketId(projectMarketId)
    {
        projectMarketStorage.closeProjectMarket(charityId, projectMarketId);
        emit projectMarketClosed(charityId, projectMarketId);
    }
}
