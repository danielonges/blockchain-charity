// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./CharityToken.sol";
import "./Charity.sol";
import "./Project.sol";

contract ProjectMarket {
    address public owner;

    CharityToken tokenContract;
    Charity charityContract;
    Project projectContract;

    constructor(CharityToken token, Charity charity, Project project) public {
        tokenContract = token;
        charityContract = charity;
        projectContract = project;
        owner = msg.sender;
    }
}
