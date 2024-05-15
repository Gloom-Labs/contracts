// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.12 <0.9.0;

import {Script, console} from "forge-std/Script.sol";
import {GloomToken} from "../src/GloomToken.sol";
import {GloomMigrator} from "../src/GloomMigrator.sol";
import {GloomGovernor} from "../src/GloomGovernor.sol";

contract DeployMigrationScript is Script {
    function run() public {
        // address GLOOM_TOKEN_DEPLOYER = 0x7941142c79b18b988B7FD22C09e17DBf85F1B0A1;
        // address GLOOM_MIGRATOR_DEPLOYER = 0x63e2a7Ac6970dc11562A98732f93fbB28404d43d;
        GloomToken gloomToken;
        GloomMigrator gloomMigrator;
        GloomGovernor gloomGovernor;

        vm.startBroadcast();
        // address deployer = address(msg.sender);
        // address deployer = address(msg.sender);

        // 4. DEPLOY GLOOM MIGRATOR
        gloomMigrator = new GloomMigrator(gloomToken, gloomGovernor);
        console.log("NEW GLOOM MIGRATOR ADDRESS:", address(gloomMigrator));
        vm.stopBroadcast();
    }
}
