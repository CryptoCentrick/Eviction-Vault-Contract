// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {EvictionVault} from "../src/EvictionVault.sol";
import {MerkleClaimModule} from "../src/MerkleClaimModule.sol";

contract EvictionVaultTest is Test {

    EvictionVault public vault;

    address public owner1 = makeAddr("owner1");
    address public owner2 = makeAddr("owner2");
    address public owner3 = makeAddr("owner3");
    address public samuel  = makeAddr("Samuel");

    uint256 constant INITIAL_BALANCE = 10 ether;

    function _buildOwners() internal view returns (address[] memory) {
        address[] memory o = new address[](3);
        o[0] = owner1; o[1] = owner2; o[2] = owner3;
        return o;
    }

    function _multisigExecute(
        address to,
        uint256 value,
        bytes memory data
    ) internal returns (uint256 txId) {
        vm.prank(owner1);
        txId = vault.submitTransaction(to, value, data);

        vm.prank(owner2);
        vault.confirmTransaction(txId);

        vm.warp(block.timestamp + 1 hours + 1);

        vm.prank(owner3);
        vault.executeTransaction(txId);
    }

    function setUp() public {
        address[] memory o = _buildOwners();
        vault = new EvictionVault{value: INITIAL_BALANCE}(o, 2);
        vm.deal(samuel, 5 ether);
    }

    function test_DepositUpdatesBalance() public {
        uint256 depositAmount = 1 ether;
        vm.prank(samuel);
        vault.deposit{value: depositAmount}();
        assertEq(vault.balances(samuel), depositAmount);
        assertEq(vault.totalVaultValue(), INITIAL_BALANCE + depositAmount);
    }

    function test_WithdrawReturnsEth() public {
        uint256 depositAmount = 2 ether;
        vm.prank(samuel);
        vault.deposit{value: depositAmount}();
        uint256 balBefore = samuel.balance;
        vm.prank(samuel);
        vault.withdraw(depositAmount);
        assertEq(vault.balances(samuel), 0);
        assertEq(samuel.balance, balBefore + depositAmount);
    }

    function test_ReceiveCreditsMsgSender() public {
        uint256 sendAmount = 0.5 ether;
        vm.prank(samuel);
        (bool ok, ) = address(vault).call{value: sendAmount}("");
        assertTrue(ok);
        assertEq(vault.balances(samuel), sendAmount);
    }

    function test_SetMerkleRootRequiresMultisig() public {
        bytes32 root = keccak256("test-root");
        vm.prank(owner1);
        vm.expectRevert("AC: must go through multisig");
        vault.setMerkleRoot(root);

        bytes memory data = abi.encodeWithSelector(MerkleClaimModule.setMerkleRoot.selector, root);
        _multisigExecute(address(vault), 0, data);

        assertEq(vault.merkleRoot(), root);
    }

    function test_EmergencyWithdrawRequiresMultisig() public {
        address payable recipient = payable(makeAddr("recipient"));
        vm.expectRevert("AC: must go through multisig");
        vault.emergencyWithdrawAll(recipient);

        uint256 vaultBal = address(vault).balance;

        bytes memory data = abi.encodeWithSelector(
            EvictionVault.emergencyWithdrawAll.selector,
            recipient
        );
        _multisigExecute(address(vault), 0, data);

        assertEq(address(vault).balance, 0);
        assertEq(recipient.balance, vaultBal);
    }

    function test_PauseRequiresMultisigAndBlocksWithdraw() public {
        vm.prank(owner1);
        vm.expectRevert("AC: must go through multisig");
        vault.pause();

        vm.prank(samuel);
        vault.deposit{value: 1 ether}();

        bytes memory pauseData = abi.encodeWithSelector(EvictionVault.pause.selector);
        _multisigExecute(address(vault), 0, pauseData);

        assertTrue(vault.paused());

        vm.prank(samuel);
        vm.expectRevert("AC: paused");
        vault.withdraw(1 ether);
    }
}