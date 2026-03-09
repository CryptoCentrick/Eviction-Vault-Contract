// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../interfaces/IEvictionVault.sol";

contract Claim is IClaim {
    bytes32 public merkleRoot;
    mapping(address => bool) public claimed;
    bool public paused;

    event MerkleRootSet(bytes32 indexed newRoot);
    event Claim(address indexed claimant, uint256 amount);

    function setMerkleRoot(bytes32 root) external override {
        // This will be called via multi-sig transaction, so no direct restriction here
        merkleRoot = root;
        emit MerkleRootSet(root);
    }

    function claim(bytes32[] calldata proof, uint256 amount) external override {
        require(!paused, "paused");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "invalid proof");
        require(!claimed[msg.sender], "already claimed");
        claimed[msg.sender] = true;
        (bool success,) = payable(msg.sender).call{value: amount}(""); // Fixed: use call instead of transfer
        require(success, "transfer failed");
        emit Claim(msg.sender, amount);
    }
}