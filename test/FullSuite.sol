// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.2 <0.9.0;

import {Test, console} from "forge-std/Test.sol";
import {GloomToken} from "../src/GloomToken.sol";
import {GloomGovernor} from "../src/GloomGovernor.sol";
import {GloomMigrator} from "../src/GloomMigrator.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/Governor.sol";
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
        0xf7Cd85F9A38D4928262d6254292cF186D453335E,
        0x4CB87bB9189EB10Ca24DEA257c2DCF6Fdef3E4eC,
        0x4023b23F3219BD24197f465d9F2b842bb892Dd9f,
        0xC2e6B265cb965DED721566f0f9Eb5ab1A6162A21,
        0x6c39acC16dEb25b496c24c21E1e5f5E192eD01C8,
        0xf492ae73D3bfD2956Bff0B07082331b94D7eFad1
    ];

    address public GLOOM_TOKEN_DEPLOYER =
        0x7941142c79b18b988B7FD22C09e17DBf85F1B0A1;

    address public GLOOM_MIGRATOR_DEPLOYER =
        0x63e2a7Ac6970dc11562A98732f93fbB28404d43d;

    IERC20Reflection public oldGloom;
    GloomToken public newGloom;
    GloomMigrator public gloomMigrator;
    GloomGovernor public gloomGovernor;

    function setUp() public {
        oldGloom = IERC20Reflection(0x4Ff77748E723f0d7B161f90B4bc505187226ED0D);

        // 1. COMPUTE GLOOMMIGRATOR ADDRESS
        uint256 nonce = vm.getNonce(GLOOM_MIGRATOR_DEPLOYER);
        address computedNewGloomAddress = vm.computeCreateAddress(
            GLOOM_MIGRATOR_DEPLOYER,
            nonce
        );
        console.log("COMPUTED GLOOMMIGRATOR ADDRESS:", computedNewGloomAddress);

        // 2. DEPLOY GLOOM_TOKEN MINT TO GLOOM_MIGRATOR
        vm.startPrank(GLOOM_TOKEN_DEPLOYER);
        newGloom = new GloomToken(computedNewGloomAddress);
        console.log("NEW GLOOM TOKEN ADDRESS:", address(newGloom));

        // 3. DEPLOY GLOOM GOVERNOR
        gloomGovernor = new GloomGovernor(newGloom);
        console.log("NEW GLOOM GOVERNOR ADDRESS:", address(gloomGovernor));
        vm.stopPrank();

        // 4. DEPLOY GLOOM MIGRATOR
        vm.prank(GLOOM_MIGRATOR_DEPLOYER);
        gloomMigrator = new GloomMigrator(newGloom, gloomGovernor);
        console.log("NEW GLOOM MIGRATOR ADDRESS:", address(gloomMigrator));
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

        // make sure governor is correctly set
        assertEq(
            address(gloomGovernor),
            address(gloomMigrator.gloomGovernor()),
            "Governor address mismatch"
        );

        // check that the migration period is 30 days from the deployment time
        uint256 migrationPeriod = gloomMigrator.migrationPeriodEndTimestamp() -
            block.timestamp;

        assertEq(migrationPeriod, 30 days, "Migration period mismatch");
    }

    function testBulkMigrations() public {
        uint256 newTokenSupply = newGloom.totalSupply();
        uint256 migratorBalance = newGloom.balanceOf(address(gloomMigrator));
        assertEq(
            newTokenSupply,
            migratorBalance,
            "Migrator does not have the total supply of the new token"
        );

        uint256 initalBurnAddressBalance = oldGloom.balanceOf(
            gloomMigrator.BURN_ADDRESS()
        );
        console.log("Initial burn address balance:", initalBurnAddressBalance); // 43044857184230988902008

        uint256 totalMigratedTokens = 0;

        for (uint256 i = 0; i < holders.length; i++) {
            address account = holders[i];
            uint256 initialBalance = oldGloom.balanceOf(account);
            if (initialBalance == 0) {
                continue;
            }
            vm.startPrank(account);
            // approve the migrator to transfer the tokens
            oldGloom.approve(address(gloomMigrator), initialBalance);
            // migrate the tokens
            gloomMigrator.migrateTokens(initialBalance);
            vm.stopPrank();
            // accumulate the transferred tokens
            totalMigratedTokens += initialBalance;
            // check that the new token balance is the same as the old token balance
            uint256 newGloomBalanceAfterMigration = newGloom.balanceOf(account);
            assertEq(newGloomBalanceAfterMigration, initialBalance);
            // check that the old token balance is 0
            uint256 oldGloomBalanceAfterMigration = oldGloom.balanceOf(account);
            assertEq(oldGloomBalanceAfterMigration, 0);
        }
    }

    // test migration without approval
    function testMigrationWithoutApproval() public {
        uint256 initialBalance = oldGloom.balanceOf(holders[0]);
        vm.startPrank(holders[0]);
        vm.expectRevert();
        // try to migrate without approval
        gloomMigrator.migrateTokens(initialBalance);
        vm.stopPrank();
    }

    //test migration without any tokens & without enough tokens
    function testMigrationWithoutTokens() public {
        uint256 initialBalance = oldGloom.balanceOf(holders[0]);
        oldGloom.approve(address(gloomMigrator), initialBalance);
        vm.startPrank(holders[0]);
        vm.expectRevert();
        // try to migrate without any tokens
        gloomMigrator.migrateTokens(0);
        vm.stopPrank();

        vm.startPrank(holders[0]);
        vm.expectRevert();
        // try to migrate more tokens than the account has
        gloomMigrator.migrateTokens(initialBalance + 1);
        vm.stopPrank();
    }

    // test migration period, try to call transferUnmigratedTokens before the migration period ends as a non-governor
    function testTransferUnmigratedTokensBeforeMigrationPeriod() public {
        vm.startPrank(GLOOM_MIGRATOR_DEPLOYER);
        vm.expectRevert();
        // try to transfer unmigrated tokens before the migration period ends
        gloomMigrator.transferUnmigratedTokens(GLOOM_MIGRATOR_DEPLOYER);
        vm.stopPrank();
    }

    // test transfer unmigrated tokens before the migration period ends as the governor
    function testTransferUnmigratedTokensAsGovernor() public {
        uint256 initialBalance = oldGloom.balanceOf(holders[0]);
        oldGloom.approve(address(gloomMigrator), initialBalance);
        vm.startPrank(holders[0]);
        vm.expectRevert();
        // try to migrate before the migration period ends
        gloomMigrator.migrateTokens(initialBalance);
        vm.stopPrank();
        // try to transfer unmigrated tokens before the migration period ends as the governor
        vm.startPrank(GLOOM_MIGRATOR_DEPLOYER);
        vm.expectRevert();
        gloomMigrator.transferUnmigratedTokens(GLOOM_MIGRATOR_DEPLOYER);
        vm.stopPrank();
    }

    // test transfer unmigrated tokens after the migration period ends as the governor to a non-governor / non-burn address
    function testTransferUnmigratedTokensAfterMigrationPeriod() public {
        uint256 initialBalance = oldGloom.balanceOf(holders[0]);
        oldGloom.approve(address(gloomMigrator), initialBalance);
        vm.startPrank(holders[0]);
        vm.expectRevert();
        // try to migrate before the migration period ends
        gloomMigrator.migrateTokens(initialBalance);
        vm.stopPrank();
        // advance the block time to the end of the migration period
        vm.warp(block.timestamp + 30 days);
        // try to transfer unmigrated tokens after the migration period ends as the governor to a non-governor / non-burn address
        vm.startPrank(GLOOM_MIGRATOR_DEPLOYER);
        vm.expectRevert();
        gloomMigrator.transferUnmigratedTokens(holders[0]);
        vm.stopPrank();
    }

    // test transfer unmigrated tokens after the migration period ends as the governor to the burn address
    function testTransferUnmigratedTokensAfterMigrationPeriodToBurnAddress()
        public
    {
        uint256 initialBalance = oldGloom.balanceOf(holders[0]);
        oldGloom.approve(address(gloomMigrator), initialBalance);
        vm.startPrank(holders[0]);
        vm.expectRevert();
        // try to migrate before the migration period ends
        gloomMigrator.migrateTokens(initialBalance);
        vm.stopPrank();
    }

    // test transfer unmigrated tokens after the migration period ends as as the governor to the governor address
    function testTransferUnmigratedTokensAfterMigrationPeriodToGovernorAddress()
        public
    {
        uint256 initialBalance = oldGloom.balanceOf(holders[0]);
        oldGloom.approve(address(gloomMigrator), initialBalance);
        vm.startPrank(holders[0]);
        vm.expectRevert();
        // try to migrate before the migration period ends
        gloomMigrator.migrateTokens(initialBalance);

        // delegate voting power
        newGloom.delegate(holders[0]);
        vm.stopPrank();
    }

    // test transfer unmigrated tokens after the migration period ends as a non-governor
    function testTransferUnmigratedTokensAfterMigrationPeriodAsNonGovernor()
        public
    {
        uint256 initialBalance = oldGloom.balanceOf(holders[0]);
        oldGloom.approve(address(gloomMigrator), initialBalance);
        vm.startPrank(holders[0]);
        vm.expectRevert();
        // try to migrate before the migration period ends
        gloomMigrator.migrateTokens(initialBalance);
        vm.stopPrank();
        // advance the block time to the end of the migration period
        vm.warp(block.timestamp + 30 days);
        // try to transfer unmigrated tokens after the migration period ends as a non-governor
        vm.startPrank(holders[0]);
        vm.expectRevert();
        gloomMigrator.transferUnmigratedTokens(holders[0]);
        vm.stopPrank();
    }

    // withdraw the remaining tokens by creating and executing a governor proposal
    function testGovernorWithdrawal() public {
        // migrate and delegate voting power
        for (uint256 i = 0; i < holders.length; i++) {
            vm.startPrank(holders[i]);
            uint256 initialBalance = oldGloom.balanceOf(holders[i]);
            if (initialBalance == 0) {
                vm.stopPrank();
                continue;
            }
            oldGloom.approve(address(gloomMigrator), initialBalance);
            gloomMigrator.migrateTokens(initialBalance);

            newGloom.delegate(holders[0]);
            vm.stopPrank();
        }
        vm.startPrank(holders[0]);
        newGloom.delegate(holders[0]);
        vm.roll(vm.getBlockNumber() + 1);

        // propose a new proposal to call transferUnmigratedTokens(address recipient) to the governor address
        address[] memory targets = new address[](1);
        targets[0] = address(gloomMigrator);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature(
            "transferUnmigratedTokens(address)",
            address(gloomGovernor)
        );

        string
            memory description = "Transfer unmigrated tokens to the governor address";

        uint256 proposalId = gloomGovernor.propose(
            targets,
            values,
            calldatas,
            description
        );

        GloomGovernor.ProposalState proposalState = gloomGovernor.state(
            proposalId
        );
        console.log("Proposal state:", uint256(proposalState));
        vm.roll(gloomGovernor.proposalDeadline(proposalId) - 1);
        gloomGovernor.castVote(proposalId, 1);
        vm.roll(gloomGovernor.proposalDeadline(proposalId) + 1);

        uint256 unmigratedTokens = newGloom.balanceOf(address(gloomMigrator));

        uint256 governorBalanceBefore = newGloom.balanceOf(
            address(gloomGovernor)
        );
        vm.warp(gloomMigrator.migrationPeriodEndTimestamp() - 1);
        vm.expectRevert();
        gloomGovernor.execute(proposalId);
        vm.warp(gloomMigrator.migrationPeriodEndTimestamp() + 1);
        gloomGovernor.execute(proposalId);

        uint256 governorBalanceAfter = newGloom.balanceOf(
            address(gloomGovernor)
        );

        assertEq(
            governorBalanceAfter - governorBalanceBefore,
            unmigratedTokens,
            "Governor balance mismatch"
        );

        assertEq(
            newGloom.balanceOf(address(gloomMigrator)),
            0,
            "Migrator balance mismatch"
        );

        assertEq(
            newGloom.balanceOf(address(gloomGovernor)),
            unmigratedTokens,
            "Governor balance mismatch"
        );

        vm.stopPrank();
    }
}
