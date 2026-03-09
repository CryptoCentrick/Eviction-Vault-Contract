// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IEvictionVault.sol";

contract MultiSig is IMultiSig {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
        uint256 submissionTime;
        uint256 executionTime;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;

    uint256 public threshold;

    mapping(uint256 => mapping(address => bool)) public confirmed;
    mapping(uint256 => Transaction) public transactions;

    uint256 public txCount;

    uint256 public constant TIMELOCK_DURATION = 1 hours;

    event Submission(uint256 indexed txId);
    event Confirmation(uint256 indexed txId, address indexed owner);
    event Execution(uint256 indexed txId);

    constructor(address[] memory _owners, uint256 _threshold) {
        require(_owners.length > 0, "no owners");
        threshold = _threshold;

        for (uint i = 0; i < _owners.length; i++) {
            address o = _owners[i];
            require(o != address(0));
            isOwner[o] = true;
            owners.push(o);
        }
    }

    function submitTransaction(address to, uint256 value, bytes calldata data) external override {
        require(isOwner[msg.sender], "not owner");
        uint256 id = txCount++;
        transactions[id] = Transaction({
            to: to,
            value: value,
            data: data,
            executed: false,
            confirmations: 1,
            submissionTime: block.timestamp,
            executionTime: 0
        });
        confirmed[id][msg.sender] = true;
        emit Submission(id);
    }

    function confirmTransaction(uint256 txId) external override {
        require(isOwner[msg.sender], "not owner");
        Transaction storage txn = transactions[txId];
        require(!txn.executed, "already executed");
        require(!confirmed[txId][msg.sender], "already confirmed");
        confirmed[txId][msg.sender] = true;
        txn.confirmations++;
        if (txn.confirmations >= threshold) {
            txn.executionTime = block.timestamp + TIMELOCK_DURATION;
        }
        emit Confirmation(txId, msg.sender);
    }

    function executeTransaction(uint256 txId) external override {
        Transaction storage txn = transactions[txId];
        require(txn.confirmations >= threshold, "not enough confirmations");
        require(!txn.executed, "already executed");
        require(block.timestamp >= txn.executionTime, "timelock not passed");
        txn.executed = true;
        (bool s,) = txn.to.call{value: txn.value}(txn.data);
        require(s, "execution failed");
        emit Execution(txId);
    }
}