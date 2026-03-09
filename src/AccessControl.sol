// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VaultStorage} from "./VaultStorage.sol";

abstract contract AccessControl is VaultStorage {

    function _initAccessControl(address[] memory _owners, uint256 _threshold) internal {
        require(_owners.length > 0, "AC: no owners");
        require(_threshold > 0, "AC: bad threshold");
        require(_threshold <= _owners.length, "AC: threshold > owners");

        threshold = _threshold;

        for (uint256 i = 0; i < _owners.length; i++) {
            address o = _owners[i];
            require(o != address(0), "AC: zero address");
            require(!isOwner[o], "AC: duplicate owner");
            isOwner[o] = true;
            owners.push(o);
        }

        _guardStatus = _NOT_ENTERED;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "AC: not owner");
        _;
    }

    modifier onlyVaultItself() {
        require(msg.sender == address(this), "AC: must go through multisig");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "AC: paused");
        _;
    }

    modifier nonReentrant() {
        require(_guardStatus != _ENTERED, "AC: reentrant call");
        _guardStatus = _ENTERED;
        _;
        _guardStatus = _NOT_ENTERED;
    }
}