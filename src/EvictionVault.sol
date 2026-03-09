// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MultiSigModule} from "./MultiSigModule.sol";
import {MerkleClaimModule} from "./MerkleClaimModule.sol";

contract EvictionVault is MultiSigModule, MerkleClaimModule {

    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed withdrawer, uint256 amount);
    event EmergencyWithdrawal(address indexed recipient, uint256 amount);
    event Paused(address indexed triggeredBy);
    event Unpaused(address indexed triggeredBy);

    bool public vaultClosed;

    constructor(
        address[] memory _owners,
        uint256 _threshold
    ) payable {
        _initAccessControl(_owners, _threshold);

        if (msg.value > 0) {
            balances[msg.sender] += msg.value;
            totalVaultValue += msg.value;
            emit Deposit(msg.sender, msg.value);
        }
    }

    receive() external payable whenNotPaused {
        require(!vaultClosed, "EV: vault closed");

        balances[msg.sender] += msg.value;
        totalVaultValue += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    fallback() external payable whenNotPaused {
        require(!vaultClosed, "EV: vault closed");

        balances[msg.sender] += msg.value;
        totalVaultValue += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    function deposit() external payable whenNotPaused {
        require(!vaultClosed, "EV: vault closed");
        require(msg.value > 0, "EV: zero deposit");

        balances[msg.sender] += msg.value;
        totalVaultValue += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external whenNotPaused nonReentrant {
        require(!vaultClosed, "EV: vault closed");
        require(amount > 0, "EV: zero withdrawal");
        require(balances[msg.sender] >= amount, "EV: insufficient balance");
        require(address(this).balance >= amount, "EV: insufficient vault liquidity");

        balances[msg.sender] -= amount;
        totalVaultValue -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "EV: ETH transfer failed");

        emit Withdrawal(msg.sender, amount);
    }

    function emergencyWithdrawAll(address payable recipient)
        external
        onlyVaultItself
    {
        require(recipient != address(0), "EV: zero recipient");

        uint256 balance = address(this).balance;

        vaultClosed = true;
        paused = true;
        totalVaultValue = 0;

        emit EmergencyWithdrawal(recipient, balance);

        (bool success, ) = recipient.call{value: balance}("");
        require(success, "EV: emergency transfer failed");
    }

    function pause() external onlyVaultItself {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyVaultItself {
        require(!vaultClosed, "EV: vault closed");
        paused = false;
        emit Unpaused(msg.sender);
    }

    function vaultBalance() external view returns (uint256) {
        return address(this).balance;
    }
}