// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.12 <0.9.0;

import {Script, console} from "forge-std/Script.sol";
import {GloomToken} from "../src/GloomToken.sol";
import {GloomMigrator} from "../src/GloomMigrator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Reflection} from "../src/interfaces/IERC20Reflection.sol";

// GLOOM address: 0x4Ff77748E723f0d7B161f90B4bc505187226ED0D

contract DeployMigrationScript is Script {
    function run() public {
        vm.startBroadcast();

        uint256 nonce = vm.getNonce(address(this));

        address computedGloomMigratorAddress = computeCreateAddress(
            address(this),
            nonce + 1
        );
        GloomToken gloomToken = new GloomToken(computedGloomMigratorAddress); // deploy the new token, send supply to migrator
        console.log("deployed Gloom: ", address(gloomToken));
        GloomMigrator gloomMigrator = new GloomMigrator(gloomToken); // deploy the migrator
        console.log("deployed GloomMigrator: ", address(gloomMigrator));

        uint256 migratorBalance = gloomToken.balanceOf(address(gloomMigrator));
        console.log(
            "initialized GloomMigrator with balance: ",
            migratorBalance / 10 ** 18
        );

        vm.stopBroadcast();
    }
}
