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
    IERC20 public constant oldGloomToken =
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
     * @dev Initializes the Gloom token migration contract
     * Verifies the total supply of the new Gloom token is correct and owned by this contract
     * @param newGloomToken_ The new Gloom token contract
     */
    constructor(IERC20 newGloomToken_) {
        require(newGloomToken_.totalSupply() == TOTAL_SUPPLY);
        require(newGloomToken_.balanceOf(address(this)) == TOTAL_SUPPLY);
        newGloomToken = newGloomToken_;
    }

    /**
     * @dev Migrate tokens from the old Gloom token contract to the new one
     * Requires token approval from the caller before calling this function
     * @param tokenAmount The amount of old tokens to migrate
     * @notice Migrating tokens is a one-way process and cannot be reversed
     */
    function migrateTokens(uint256 tokenAmount) external {
        oldGloomToken.transferFrom(msg.sender, BURN_ADDRESS, tokenAmount);
        newGloomToken.transfer(msg.sender, tokenAmount);
        emit TokensMigrated(msg.sender, tokenAmount);
    }
}
