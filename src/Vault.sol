// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IEvictionVault.sol";

contract Vault is IVault {
    mapping(address => uint256) public balances;
    uint256 public totalVaultValue;
    bool public paused;

    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed withdrawer, uint256 amount);

    receive() external payable {
        balances[msg.sender] += msg.value; // Fixed: use msg.sender instead of tx.origin
        totalVaultValue += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function deposit() external payable override {
        balances[msg.sender] += msg.value;
        totalVaultValue += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external override {
        require(!paused, "paused");
        require(balances[msg.sender] >= amount, "insufficient balance");
        balances[msg.sender] -= amount;
        totalVaultValue -= amount;
        (bool success,) = payable(msg.sender).call{value: amount}(""); // Fixed: use call instead of transfer
        require(success, "transfer failed");
        emit Withdrawal(msg.sender, amount);
    }
}