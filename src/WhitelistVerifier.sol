// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract WhitelistVerifier {
    address public whitelistSigner;

    constructor(address _whitelistSigner) {
        whitelistSigner = _whitelistSigner;
    }

    // Validate signer appproved the hash (address + quantity) for whitelist minting
    function isValidWhitelistRequest(bytes32 hash, bytes memory signature) public view returns (bool) {
        address signer = ECDSA.recover(hash, signature);
        return signer == whitelistSigner;
    }
}
