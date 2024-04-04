// SPDX-License-Identifier: MIT
/// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/// @title The Gloom token
contract GloomToken is ERC20, ERC20Burnable, ERC20Permit, ERC20Votes {
    /**
     * Initial supply of 1,000,000,000 tokens.
     * @param mintAddress Address to mint initial supply to.
     */
    constructor(
        address mintAddress
    ) ERC20("Gloom", "GLOOM") ERC20Permit("Gloom") {
        _mint(mintAddress, 1_000_000_000 * 10 ** decimals());
    }

    /// The following functions are overrides required by Solidity.

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    function nonces(
        address owner
    ) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
