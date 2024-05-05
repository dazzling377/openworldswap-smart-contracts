// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OWS is ERC20 {
    constructor() ERC20("OepnWorldSwap Token", "OWS") {
        _mint(msg.sender, 16000000 ether);
    }
}
