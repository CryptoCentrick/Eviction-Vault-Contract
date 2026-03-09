// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract VaultStorage {
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public threshold;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
        uint256 submissionTime;
        uint256 executionTime;
    }

    uint256 public txCount;
    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmed;

    mapping(address => uint256) public balances;
    uint256 public totalVaultValue;

    bytes32 public merkleRoot;
    mapping(address => bool) public claimed;

    bool public paused;
    uint256 public constant TIMELOCK_DURATION = 1 hours;

    uint256 internal _guardStatus;
    uint256 internal constant _NOT_ENTERED = 1;
    uint256 internal constant _ENTERED = 2;
}