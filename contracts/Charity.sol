// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;
import "./CharityStorage.sol";

contract Charity {
    address public owner;
    CharityStorage charityStorage;

    event charityVerified(address charity);
    event charityDeactivated(address charity);
    event charityActivated(address charity);

    constructor(CharityStorage charityAddress) public {
        owner = msg.sender;
        charityStorage = charityAddress;
    }

    function verifyCharity(
        address charityOwner,
        string memory name,
        CharityStorage.charityCategory category
    ) public {
        charityStorage.addCharity(charityOwner, name, category);
        emit charityVerified(charityOwner);
    }

    function deactivateCharity(uint256 charityId) public {
        charityStorage.setCharityActive(charityId, false);
    }

    function activateCharity(uint256 charityId) public {
        charityStorage.setCharityActive(charityId, true);
    }
}
