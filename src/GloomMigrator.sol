// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Gloom token migration contract
 * @dev This contract facilitates the migration of tokens from the old Gloom token contract to the new one
 * To initialize migration, this contract must be minted the total supply of the new Gloom token
 * There is no owner, admin, upgradability, or pause functionality in this contract
 * @notice Migrating tokens is a one-way process and cannot be reversed
 */
contract GloomMigrator {
    /// Old Gloom token contract, these tokens will be burned during migration
    IERC20 public constant oldGloomToken =
        IERC20(0x4Ff77748E723f0d7B161f90B4bc505187226ED0D);

    /// New Gloom token contract, these tokens will be sent from the migrator to the caller
    IERC20 public newGloomToken;

    /// Low-entropy burn address where old Gloom tokens are sent during migration
    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    /// Event emitted when a caller migrates tokens from the old Gloom token contract to the new one
    event TokensMigrated(address indexed caller, uint256 tokenAmount);

    /**
     * @dev Contract must own the same amount of new Gloom tokens as the total supply of the old Gloom token
     * @param _newGloomToken The new Gloom token contract
     */
    constructor(IERC20 _newGloomToken) {
        newGloomToken = _newGloomToken;
        require(
            newGloomToken.balanceOf(address(this)) ==
                oldGloomToken.totalSupply()
        );
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
