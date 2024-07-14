// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library Utils {
    function generateUniqueID() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(block.timestamp, msg.sender, block.prevrandao));
    }
}