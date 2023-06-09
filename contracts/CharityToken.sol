// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract CharityToken {
    address owner;
    ERC20 erc20Contract;

    constructor() {
        owner = msg.sender;
        ERC20 e = new ERC20(); // create a new instance of ERC20
        erc20Contract = e; // assign it to the variable erc20Contract
    }

    function getTokens(address recipient, uint256 weiAmt) public {
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

    function transferTokensFrom(address from, address to, uint256 amt) public {
        erc20Contract.transferFrom(from, to, amt);
    }

    function approveTokenSpending(address spender, uint256 amt) public {
        erc20Contract.approve(spender, amt);
    }

    function checkApproval(
        address approver,
        address spender
    ) public view returns (uint256) {
        return erc20Contract.allowance(approver, spender);
    }
}
