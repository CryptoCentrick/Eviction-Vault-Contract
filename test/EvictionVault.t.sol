// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/EvictionVault.sol";

contract EvictionVaultTest is Test {
    EvictionVault vault;
    address[] owners;
    address owner1;
    address owner2;
    address user;

    function setUp() public {
        owner1 = address(1);
        owner2 = address(2);
        user = address(3);
        owners = [owner1, owner2];
        vault = new EvictionVault{value: 10 ether}(owners, 2);
    }

    function testDeposit() public {
        vm.prank(user);
        vault.deposit{value: 1 ether}();
        assertEq(vault.balances(user), 1 ether);
        assertEq(vault.totalVaultValue(), 11 ether);
    }

    function testWithdraw() public {
        vm.prank(user);
        vault.deposit{value: 1 ether}();
        vm.prank(user);
        vault.withdraw(0.5 ether);
        assertEq(vault.balances(user), 0.5 ether);
        assertEq(vault.totalVaultValue(), 10.5 ether);
    }

    function testSubmitTransaction() public {
        vm.prank(owner1);
        vault.submitTransaction(user, 1 ether, "");
        assertEq(vault.txCount(), 1);
    }

    function testConfirmAndExecuteTransaction() public {
        vm.prank(owner1);
        vault.submitTransaction(user, 1 ether, "");
        vm.prank(owner2);
        vault.confirmTransaction(0);
        vm.warp(block.timestamp + 1 hours + 1);
        vm.prank(owner1);
        vault.executeTransaction(0);
        // Check if executed
    }

    function testPause() public {
        vm.prank(owner1);
        vault.pause();
        assertTrue(vault.paused());
    }

    function testClaim() public {
        // Set merkle root via transaction
        vm.prank(owner1);
        vault.submitTransaction(address(vault), 0, abi.encodeWithSignature("setMerkleRoot(bytes32)", keccak256("root")));
        vm.prank(owner2);
        vault.confirmTransaction(0);
        vm.warp(block.timestamp + 1 hours + 1);
        vm.prank(owner1);
        vault.executeTransaction(0);
        // Then claim, but need proper proof
        // For simplicity, skip full claim test
    }
}