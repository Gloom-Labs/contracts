// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.2 <0.9.0;

import {Test, console} from "forge-std/Test.sol";
import {GloomToken} from "../src/GloomToken.sol";
import {GloomGovernor} from "../src/GloomGovernor.sol";
import {GloomMigrator} from "../src/GloomMigrator.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
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
        0x00F7Ff777B7a2633edd8D50Bc831Fbd09Fe9d67F
    ];

    address public gloomTokenDeployer =
        0x42e9c498135431a48796B5fFe2CBC3d7A1811927;

    address public gloomMigratorDeployer =
        0x000c987F621B3788F84112fa7a1E8B42AB8CC212;

    IERC20Reflection public oldGloom;
    GloomToken public newGloom;
    GloomMigrator public gloomMigrator;
    GloomGovernor public gloomGovernor;

    function setUp() public {
        oldGloom = IERC20Reflection(0x4Ff77748E723f0d7B161f90B4bc505187226ED0D);

        // console.log(
        //     "balance of old gloom:",
        //     oldGloom.balanceOf(gloomMigratorDeployer)
        // );

        uint256 nonce = vm.getNonce(gloomMigratorDeployer);
        // compute the address of the gloom migrator contract

        address computedNewGloomAddress = vm.computeCreateAddress(
            gloomMigratorDeployer,
            nonce
        );
        // console.log("Computed address:", computedNewGloomAddress);

        // deploy the new Gloom token and mint the total supply to the migrator
        vm.prank(gloomTokenDeployer);
        newGloom = new GloomToken(computedNewGloomAddress);

        // deploy the gloom governor
        vm.prank(gloomTokenDeployer);
        gloomGovernor = new GloomGovernor(newGloom);

        // deploy the gloom migrator
        vm.prank(gloomMigratorDeployer);
        gloomMigrator = new GloomMigrator(newGloom, gloomGovernor);
    }

    // test balances after deployment
    function testDeployment() public view {
        assertEq(
            address(oldGloom),
            address(gloomMigrator.OLD_GLOOM_TOKEN()),
            "Old Gloom token address mismatch"
        );
        uint256 newTokenSupply = newGloom.totalSupply();
        uint256 migratorBalance = newGloom.balanceOf(address(gloomMigrator));
        assertEq(newTokenSupply, migratorBalance, "Migrator balance mismatch");
    }

    function testBulkMigrations() public {
        assertEq(
            address(oldGloom),
            address(gloomMigrator.OLD_GLOOM_TOKEN()),
            "Old Gloom token address mismatch"
        );
        uint256 newTokenSupply = newGloom.totalSupply();
        uint256 migratorBalance = newGloom.balanceOf(address(gloomMigrator));
        assertEq(newTokenSupply, migratorBalance, "Migrator balance mismatch");
        uint256 initalBurnAddressBalance = oldGloom.balanceOf(
            gloomMigrator.BURN_ADDRESS()
        );
        uint256 holderBalanceAccumulator = 0;
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
            holderBalanceAccumulator += initialBalance;
            uint256 newTokenBalanceAfterMigration = newGloom.balanceOf(account);
            assertEq(newTokenBalanceAfterMigration, initialBalance); // check that the balance is the same
            uint256 oldTokenBalanceAfterMigration = oldGloom.balanceOf(account);
            assertEq(oldTokenBalanceAfterMigration, 0);
        }

        uint256 burnBalanceAfterMigrations = oldGloom.balanceOf(
            gloomMigrator.BURN_ADDRESS()
        );

        uint256 burnAddressTokenDelta = burnBalanceAfterMigrations -
            initalBurnAddressBalance;

        uint256 difference = holderBalanceAccumulator - burnAddressTokenDelta;

        console.log("Total tokens migrated:", holderBalanceAccumulator);
        console.log("Burn address balance delta:", burnAddressTokenDelta);
        console.log("Difference:", difference / 10 ** 18);
    }

    function testMaliciousMigrations() public {
        vm.startPrank(holders[0]);
        // try to migrate without approval
        vm.expectRevert();
        gloomMigrator.migrateTokens(1);

        // try to migrate more tokens than the account has
        uint256 initialBalance = oldGloom.balanceOf(holders[0]);
        oldGloom.approve(address(gloomMigrator), initialBalance);
        vm.expectRevert();
        gloomMigrator.migrateTokens(initialBalance + 1);
        vm.stopPrank();
    }

    function testMigrationPeriod() public {
        uint256 initialBalance = oldGloom.balanceOf(holders[0]);
        oldGloom.approve(address(gloomMigrator), initialBalance);
        vm.startPrank(holders[0]);
        vm.expectRevert();
        // try to migrate before the migration period ends
        gloomMigrator.migrateTokens(initialBalance);
        vm.stopPrank();
    }
}
