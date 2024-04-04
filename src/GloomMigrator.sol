// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Gloom token migration contract
 * @dev This contract facilitates the migration of tokens from the old Gloom token contract to the new one
 * After initialization, this contract will hold the full token supply of the new Gloom token contract
 * In the migration process, old tokens are sent to the burn address and new Gloom tokens are transfered to the user
 * There is no owner, admin, upgrade, or pause functionality in this contract for maximum simplicity and transparency
 * @notice Migrating tokens is a one-way process and cannot be reversed
 */
contract GloomMigrator {
    /// Old Gloom token contract, tokens to be sent to the burn address during migration
    IERC20 public oldGloomToken;

    /// New Gloom token contract, tokens to be transferred to the user during migration
    IERC20 public newGloomToken;

    /// Low-entropy burn address where old Gloom tokens are sent during migration
    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    /// Event emitted when the contract is initialized with the new Gloom token contract
    event Initialized(address newGloomToken);

    /// Event emitted when a user migrates their tokens
    event TokensMigrated(address user, uint256 amount);

    /**
     * @dev Constructor function that sets the old Gloom token contract
     * @param oldGloomToken_ IERC20 interface of the old Gloom token contract
     */
    constructor(IERC20 oldGloomToken_) {
        oldGloomToken = oldGloomToken_;
    }

    /**
     * @dev Initializes the contract with the new Gloom token contract
     * GloomMigrator must hold the full token supply of the new Gloom token contract
     * This function can only be called once and will revert on subsequent calls
     * @param newGloomToken_ IERC20 interface of the new Gloom token contract
     */
    function initialize(IERC20 newGloomToken_) external {
        require(address(newGloomToken) == address(0), "Already initialized");
        newGloomToken = newGloomToken_;
        require(
            newGloomToken.balanceOf(address(this)) ==
                newGloomToken.totalSupply(),
            "Full token supply must be sent to GloomMigrator"
        );
        emit Initialized(address(newGloomToken));
    }

    /**
     * @dev Migrate tokens from the old Gloom token contract to the new one
     * Requires token approval before calling this function
     * @param tokenAmount The amount of old tokens to migrate
     * @notice Migrating tokens is a one-way process and cannot be reversed
     */
    function migrateTokens(uint256 tokenAmount) external {
        oldGloomToken.transferFrom(msg.sender, BURN_ADDRESS, tokenAmount);
        newGloomToken.transfer(msg.sender, tokenAmount);
        emit TokensMigrated(msg.sender, tokenAmount);
    }
}
