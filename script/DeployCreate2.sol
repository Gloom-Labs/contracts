// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.9.0;

import {Script, console} from "forge-std/Script.sol";
import {GloomToken} from "../src/GloomToken.sol";
import {GloomMigrator} from "../src/GloomMigrator.sol";
import {IERC20Reflection} from "../src/interfaces/IERC20Reflection.sol";
import {GloomGovernor} from "../src/GloomGovernor.sol";

contract DeployGloomSuite is Script {
    function run() public {
        // IERC20Reflection oldGloom = IERC20Reflection(
        //     0x34A1D3fff3958843C43aD80F30b94c510645C316
        // );
        vm.startBroadcast();
        address deployer = address(msg.sender);
        bytes32 salt = keccak256("GLOOM_DEPLOY_SALT");

        // address GLOOM_TOKEN_DEPLOYER = 0x7941142c79b18b988B7FD22C09e17DBf85F1B0A1;
        // address GLOOM_MIGRATOR_DEPLOYER = 0x63e2a7Ac6970dc11562A98732f93fbB28404d43d;

        /// 1. PRE-COMPUTE CONTRACT ADDRESSES

        bytes32 gloomMigratorBytecode = keccak256(
            type(GloomMigrator).creationCode
        );
        address gloomMigratorAddress = vm.computeCreate2Address(
            salt,
            gloomMigratorBytecode,
            deployer
        );

        // bytes32 gloomTokenBytecode = keccak256(type(GloomToken).creationCode);
        // address newGloomAddress = vm.computeCreate2Address(
        //     salt,
        //     gloomTokenBytecode,
        //     deployer
        // );

        // bytes32 gloomGovernorBytecode = keccak256(
        //     type(GloomGovernor).creationCode
        // );
        // address gloomGovernorAddress = vm.computeCreate2Address(
        //     salt,
        //     gloomGovernorBytecode,
        //     address(this)
        // );

        /// 2. DEPLOY GLOOM TOKEN - MINT TO GLOOM MIGRATOR

        GloomToken gloomToken = new GloomToken(gloomMigratorAddress);
        console.log("NEW GLOOM TOKEN ADDRESS:", address(gloomToken));

        /// 3. DEPLOY GLOOM GOVERNOR - NEW GLOOM TOKEN ARG

        GloomGovernor gloomGovernor = new GloomGovernor(gloomToken);
        console.log("NEW GLOOM GOVERNOR ADDRESS:", address(gloomGovernor));

        /// 4. DEPLOY GLOOM MIGRATOR - NEW GLOOM TOKEN ARG & GLOOM GOVERNOR ARG

        GloomMigrator gloomMigrator = new GloomMigrator(
            gloomToken,
            gloomGovernor
        );
        console.log("NEW GLOOM MIGRATOR ADDRESS:", address(gloomMigrator));

        vm.stopBroadcast();
    }
}
