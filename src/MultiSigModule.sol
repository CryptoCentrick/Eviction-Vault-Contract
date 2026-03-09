// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControl} from "./AccessControl.sol";

abstract contract MultiSigModule is AccessControl {

    event Submission(uint256 indexed txId);
    event Confirmation(uint256 indexed txId, address indexed owner);
    event Revocation(uint256 indexed txId, address indexed owner);
    event Execution(uint256 indexed txId);

    function submitTransaction(
        address to,
        uint256 value,
        bytes calldata data
    ) external onlyOwner whenNotPaused returns (uint256 txId) {
        txId = txCount++;
        transactions[txId] = Transaction({
            to: to,
            value: value,
            data: data,
            executed: false,
            confirmations: 1,
            submissionTime: block.timestamp,
            executionTime: 0
        });

        confirmed[txId][msg.sender] = true;

        emit Submission(txId);
    }

    function confirmTransaction(uint256 txId) external onlyOwner whenNotPaused {
        Transaction storage txn = transactions[txId];

        require(!txn.executed, "MS: already executed");
        require(!confirmed[txId][msg.sender], "MS: already confirmed");

        confirmed[txId][msg.sender] = true;
        txn.confirmations++;

        if (txn.confirmations == threshold && txn.executionTime == 0) {
            txn.executionTime = block.timestamp + TIMELOCK_DURATION;
        }

        emit Confirmation(txId, msg.sender);
    }

    function executeTransaction(uint256 txId) external {
        Transaction storage txn = transactions[txId];

        require(txn.confirmations >= threshold, "MS: not enough confirmations");
        require(!txn.executed, "MS: already executed");
        require(txn.executionTime != 0, "MS: timelock not started");
        require(block.timestamp >= txn.executionTime, "MS: timelock not expired");

        txn.executed = true;

        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        require(success, "MS: execution failed");

        emit Execution(txId);
    }

    function revokeConfirmation(uint256 txId) external onlyOwner {
        Transaction storage txn = transactions[txId];

        require(!txn.executed, "MS: already executed");
        require(confirmed[txId][msg.sender], "MS: not confirmed");

        confirmed[txId][msg.sender] = false;
        txn.confirmations--;

        if (txn.confirmations < threshold) {
            txn.executionTime = 0;
        }

        emit Revocation(txId, msg.sender);
    }

    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function getTransaction(uint256 txId)
        external
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 confirmations,
            uint256 executionTime
        )
    {
        Transaction storage txn = transactions[txId];

        return (
            txn.to,
            txn.value,
            txn.data,
            txn.executed,
            txn.confirmations,
            txn.executionTime
        );
    }
}