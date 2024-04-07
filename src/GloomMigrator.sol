// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Gloom token migration contract
 * @dev Migration contract used for migrating old Gloom tokens to the new Gloom token contract
 * @notice Migrating tokens is a one-way process and cannot be reversed
 */
contract GloomMigrator {
    /// Old Gloom token contract
    IERC20 public constant OLD_GLOOM_TOKEN =
        IERC20(0x4Ff77748E723f0d7B161f90B4bc505187226ED0D);

    /// New Gloom token contract
    IERC20 public newGloomToken;

    /// Total supply of the new Gloom token 1 billion (18 decimals)
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 10 ** 18;

    /// Burn address
    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    /// Event emitted for each token migration
    event TokensMigrated(address indexed caller, uint256 tokenAmount);

    /**
     * @dev Construct the migration contract with the new Gloom token contract
     * Requires total supply of the new Gloom token to be valid and owned by this contract
     * @param newGloomToken_ The new Gloom token contract
     */
    constructor(IERC20 newGloomToken_) {
        require(newGloomToken_.totalSupply() == TOTAL_SUPPLY);
        require(newGloomToken_.balanceOf(address(this)) == TOTAL_SUPPLY);
        newGloomToken = newGloomToken_;
    }

    /**
     * @dev Burn old Gloom tokens in return for an equal amount of new Gloom tokens
     * Requires token approval to this contract
     * @param tokenAmount The amount of old tokens to migrate
     */
    function migrateTokens(uint256 tokenAmount) external {
        OLD_GLOOM_TOKEN.transferFrom(msg.sender, BURN_ADDRESS, tokenAmount);
        newGloomToken.transfer(msg.sender, tokenAmount);
        emit TokensMigrated(msg.sender, tokenAmount);
    }
}
