pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface IBase {
    struct TokenCreationProps {
        string name;
        string symbol;
        address marketingWallet;
        uint8 decimals;
        uint16 buyTax;
        uint16 sellTax;
        uint16 transferTax;
        uint256 totalSupply;
        uint256 txLimit;
        uint256 holdLimit;
    }
}