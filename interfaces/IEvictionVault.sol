// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMultiSig {
    function submitTransaction(address to, uint256 value, bytes calldata data) external;
    function confirmTransaction(uint256 txId) external;
    function executeTransaction(uint256 txId) external;
    function isOwner(address) external view returns (bool);
    function threshold() external view returns (uint256);
}

interface IVault {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function balances(address) external view returns (uint256);
    function totalVaultValue() external view returns (uint256);
}

interface IClaim {
    function setMerkleRoot(bytes32 root) external;
    function claim(bytes32[] calldata proof, uint256 amount) external;
    function claimed(address) external view returns (bool);
    function merkleRoot() external view returns (bytes32);
}

interface IPausable {
    function pause() external;
    function unpause() external;
    function paused() external view returns (bool);
}