// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/governance/Governor.sol";

/**
 * @title This is the migration contract for the Gloom token to remove the reflection mechanism
 * @notice The migration period is 30 days. Migrating tokens is a one-way process and cannot be reversed
 * After the migration period ends, any remaining tokens will be either burned or transferred pending a proposal
 * The GloomGovernor is an OpenZeppelin governor contract controlled by new Gloom token holders
 * @custom:security-contact support@gloomtoken.com
 */
contract GloomMigrator {
    /// Old Gloom token contract
    ERC20 public constant OLD_GLOOM_TOKEN = ERC20(0x4Ff77748E723f0d7B161f90B4bc505187226ED0D);

    /// New Gloom token contract
    ERC20 public newGloomToken;

    /// OpenZeppelin governor contract that will have authority over unmigrated tokens
    Governor public gloomGovernor;

    /// Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    /// Unix timestamp when the migration period ends and GloomGovernor can transfer remaining tokens
    uint256 public immutable migrationPeriodEndTimestamp;

    /// Event emitted for each token migration
    event TokensMigrated(address indexed caller, uint256 tokenAmount);

    /**
     * @notice Contract must be deployed with the entire supply of the new Gloom token
     * @param newGloomToken_ The new Gloom token contract
     * @param gloomGovernor_ The new Gloom OpenZeppelin governor contract
     */
    constructor(ERC20 newGloomToken_, Governor gloomGovernor_) {
        require(newGloomToken_.decimals() == OLD_GLOOM_TOKEN.decimals(), "Decimals do not match");
        require(newGloomToken_.balanceOf(address(this)) == OLD_GLOOM_TOKEN.totalSupply(), "Token supply does not match");

        newGloomToken = newGloomToken_;
        gloomGovernor = gloomGovernor_;

        // Migration period is 30 days
        migrationPeriodEndTimestamp = block.timestamp + 30 days;
    }

    /**
     * @notice Burn old Gloom tokens to receive new Gloom tokens, requires approval
     * @param tokenAmount The amount of old tokens to migrate
     */
    function migrateTokens(uint256 tokenAmount) external {
        require(block.timestamp < migrationPeriodEndTimestamp, "Migration period has ended");
        bool success = OLD_GLOOM_TOKEN.transferFrom(msg.sender, BURN_ADDRESS, tokenAmount);
        require(success, "Transfer failed");

        newGloomToken.transfer(msg.sender, tokenAmount);

        emit TokensMigrated(msg.sender, tokenAmount);
    }

    /**
     * @notice After the migration period ends, the GloomGovernor has access to the transfer function
     * GloomGovernor is operated by new Gloom token holders using ERC20 voting
     * @param recipient The address to transfer remaining tokens to MUST be either GloomGovernor or BURN_ADDRESS
     */
    function transferUnmigratedTokens(address recipient) external {
        require(block.timestamp >= migrationPeriodEndTimestamp, "Migration period is still active");
        require(msg.sender == address(gloomGovernor), "Only GloomGovernor contract can call this function");
        require(
            recipient == address(gloomGovernor) || recipient == BURN_ADDRESS,
            "Recipient must be GloomGovernor or burn address"
        );

        uint256 unmigratedTokenAmount = newGloomToken.balanceOf(address(this));

        newGloomToken.transfer(recipient, unmigratedTokenAmount);
    }
}
