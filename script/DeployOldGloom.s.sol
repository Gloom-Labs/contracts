// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.12 <0.9.0;

import {Script, console} from "forge-std/Script.sol";
import {OldGloom} from "../src/OldGloom.sol";

contract DeployOldGloomScript is Script {
    function run() public {
        vm.startBroadcast();
        address deployer = address(msg.sender);

        OldGloom oldGloom = new OldGloom(
            "GLOOM",
            "GLOOM",
            18,
            1_000_000_000 * 10 ** 18,
            1,
            deployer,
            0x000000000000000000000000000000000000dEaD
        );
        console.log("deployed oldGloom: ", address(oldGloom));

        vm.stopBroadcast();
    }
}