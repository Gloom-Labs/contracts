// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.2 <0.9.0;

import {Test, console} from "forge-std/Test.sol";
import {GloomToken} from "../src/GloomToken.sol";
import {GloomMigrator} from "../src/GloomMigrator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Reflection} from "../src/interfaces/IERC20Reflection.sol";

contract MigrationTest is Test {
    address[] public holders = [
        0x073f0DC58e9989C827bA5b7b35570B7315652e63,
        0x41C6B00A19D167C84660A1268052Aa21c3f291bE,
        0x978Ee81C305D5a1Fc028c8593F3409a8474821BC,
        0x00000000000Ba9Cd9F5175108141A82B6c24d727,
        0x0000000088Bf97Fff3e7f6d915a38cc9dDB80B79,
        0x00024eACb7936b04ba5E07eDDFd7Fe701E7c66e0,
        0x000488429Af0fe9B62F61e3F33638d3970a3CeC9,
        0x0006A126d498aeA76f845bC81fE1aBE80c2697bA,
        0x00088aC614621a0c0CfFFE12Ee6217c3320dDbf1,
        0x000BEaBbf0a8035C23bFfb94B0b4fb4a3861f7F4,
        0x000c987F621B3788F84112fa7a1E8B42AB8CC212,
        0x000Cbf0BEC88214AAB15bC1Fa40d3c30b3CA97a9,
        0x000cf673cA65Db55054a681E220F85FBDf058220,
        0x0010b70d4987D0D2a410c7Df7df8460b3136219E,
        0x007678a2Fb7EE0E04a6B1ae37ff7fd6CFb22046A,
        0x0076F74CC966fdD705deD40df8aB86604e4b5759,
        0x00de67Aa2735Ff2D2672a79B2aAbD53FcA63e541,
        0x00f23269D914cfC8cF277991C3Bef6e95A7724B4,
        0x00F7Ff777B7a2633edd8D50Bc831Fbd09Fe9d67F,
        0x00fB7ccb1f054792252d31b2F6a5D3E923765d02,
        0x0101a64A09290EC5075e1887EB7B6686e9050DAC
    ];

    IERC20Reflection public oldGloom;
    GloomToken public newGloom;
    GloomMigrator public gloomMigrator;

    function setUp() public {
        oldGloom = IERC20Reflection(0x4Ff77748E723f0d7B161f90B4bc505187226ED0D);
        gloomMigrator = new GloomMigrator(oldGloom);
        newGloom = new GloomToken(address(gloomMigrator)); // deploy the new token, send supply to migrator
        gloomMigrator.initialize(IERC20(newGloom));
    }

    function testMigration() public {
        for (uint256 i = 0; i < holders.length; i++) {
            address account = holders[i];
            uint256 initialBalance = oldGloom.balanceOf(account);
            if (initialBalance == 0) {
                continue;
            }
            vm.startPrank(account);
            oldGloom.approve(address(gloomMigrator), initialBalance);
            gloomMigrator.migrateTokens(initialBalance);
            vm.stopPrank();

            uint256 newBalance = newGloom.balanceOf(account);
            console.log("Migrated", initialBalance, "tokens to", account);
            console.log("New token balance:", newBalance);
            assertEq(newBalance, initialBalance);

            uint256 oldBalance = oldGloom.balanceOf(account);
            console.log("Old token balance:", oldBalance);
            assertEq(oldBalance, 0);
        }
    }
}
