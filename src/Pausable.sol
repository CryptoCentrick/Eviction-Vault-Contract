// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IEvictionVault.sol";

contract Pausable is IPausable {
    bool public paused;
    mapping(address => bool) public isOwner;

    function pause() external override {
        require(isOwner[msg.sender], "not owner");
        paused = true;
    }

    function unpause() external override {
        require(isOwner[msg.sender], "not owner");
        paused = false;
    }
}