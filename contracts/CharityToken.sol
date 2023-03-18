pragma solidity ^0.5.0;

import "./ERC20.sol";

contract CharityToken {
    address owner;
    ERC20 erc20Contract;

    constructor() public {
        owner = msg.sender;
        ERC20 e = new ERC20(); // create a new instance of ERC20
        erc20Contract = e; // assign it to the variable erc20Contract
    }

    function getTokens(address recipient, uint256 weiAmt) public payable {
        uint256 amt = weiAmt / (1000000000000000000 / 100); // Convert weiAmt to Charity Token
        erc20Contract.mint(recipient, amt);
    }

    function checkBalance(address ad) public view returns (uint256) {
        return erc20Contract.balanceOf(ad);
    }

    function transferTokens(address recipient, uint256 amt) public {
        // Transfers from tx.origin to receipient
        erc20Contract.transfer(recipient, amt);
    }
}
