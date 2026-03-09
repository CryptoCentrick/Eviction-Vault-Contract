// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {EvictionVault} from "../src/EvictionVault.sol";

contract EvictionVaultScript is Script {
    function run() external {
        address owner1 = vm.envAddress("OWNER_1");
        address owner2 = vm.envAddress("OWNER_2");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 initialVaultEth = vm.envOr("INITIAL_VAULT_ETH", uint256(0));

        address[] memory owners = new address[](2);
        owners[0] = owner1;
        owners[1] = owner2;

        vm.startBroadcast(deployerPrivateKey);
        new EvictionVault{value: initialVaultEth}(owners, 2);
        vm.stopBroadcast();
    }
}
