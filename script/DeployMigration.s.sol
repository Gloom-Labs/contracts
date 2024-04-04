// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.12 <0.9.0;

import {Script, console} from "forge-std/Script.sol";
import {GloomToken} from "../src/GloomToken.sol";
import {GloomMigrator} from "../src/GloomMigrator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Reflection} from "../src/interfaces/IERC20Reflection.sol";

contract DeployMigrationScript is Script {
    function run() public {
        vm.startBroadcast();

        IERC20Reflection oldGloom = IERC20Reflection(
            0x4Ff77748E723f0d7B161f90B4bc505187226ED0D
        );
        GloomMigrator gloomMigrator = new GloomMigrator(oldGloom);
        GloomToken gloom = new GloomToken(address(gloomMigrator)); // deploy the new token, send supply to migrator
        gloomMigrator.initialize(IERC20(gloom)); // initialize the migrator

        console.log("deployed gloom: ", address(gloom));
        console.log("deployed gloomMigrator: ", address(gloomMigrator));
        
        vm.stopBroadcast();
    }
}
