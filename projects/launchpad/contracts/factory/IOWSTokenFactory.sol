pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface IOWSTokenFactory {
    /**
     * @notice When token ownership is transferred, it updates structure as well in the factory
     */
    function transferTokenOwnership(address from, address to) external;
}
