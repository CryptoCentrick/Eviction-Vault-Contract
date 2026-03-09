// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {AccessControl} from "./AccessControl.sol";

abstract contract MerkleClaimModule is AccessControl {

    event MerkleRootSet(bytes32 indexed newRoot);
    event Claim(address indexed claimant, uint256 amount);

    function setMerkleRoot(bytes32 root) external onlyVaultItself {
        merkleRoot = root;
        emit MerkleRootSet(root);
    }

    function claim(
        bytes32[] calldata proof,
        uint256 amount
    ) external whenNotPaused nonReentrant {

        require(merkleRoot != bytes32(0), "MC: no merkle root set");
        require(!claimed[msg.sender], "MC: already claimed");
        require(totalVaultValue >= amount, "MC: insufficient vault balance");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        bytes32 computed = MerkleProof.processProof(proof, leaf);

        require(computed == merkleRoot, "MC: invalid proof");

        claimed[msg.sender] = true;
        totalVaultValue -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "MC: ETH transfer failed");

        emit Claim(msg.sender, amount);
    }
}