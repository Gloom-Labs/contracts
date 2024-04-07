// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Gloom token migration contract created for the purpose of removing reflections from the Gloom token
 * @notice Migrating tokens is a one-way process which burns old tokens and cannot be reversed
 */
contract GloomMigrator {
    /// Old Gloom token contract
    IERC20 public constant OLD_GLOOM_TOKEN =
        IERC20(0x4Ff77748E723f0d7B161f90B4bc505187226ED0D);

    /// New Gloom token contract
    IERC20 public newGloomToken;

    /// Burn address
    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    /// Event emitted for each token migration
    event TokensMigrated(address indexed caller, uint256 tokenAmount);

    /**
     * @notice Contract must own an equal amount of new Gloom tokens as the total supply of the old Gloom contract
     * @param newGloomToken_ The new Gloom token contract
     */
    constructor(IERC20 newGloomToken_) {
        require(
            newGloomToken_.balanceOf(address(this)) ==
                OLD_GLOOM_TOKEN.totalSupply()
        );
        newGloomToken = newGloomToken_;
    }

    /**
     * @notice Burn old Gloom tokens to receive new Gloom tokens, requires approval
     * @param tokenAmount The amount of old tokens to migrate
     */
    function migrateTokens(uint256 tokenAmount) external {
        OLD_GLOOM_TOKEN.transferFrom(msg.sender, BURN_ADDRESS, tokenAmount);
        newGloomToken.transfer(msg.sender, tokenAmount);
        emit TokensMigrated(msg.sender, tokenAmount);
    }
}
