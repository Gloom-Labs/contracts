// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract WhitelistVerifier {
    address public whitelistSigner;

    error InvalidWhitelistRequest();

    constructor(address _whitelistSigner) {
        whitelistSigner = _whitelistSigner;
    }

    modifier validatedWhitelistRequest(bytes32 hash, bytes memory signature) {
        if (!isValidWhitelistRequest(hash, signature)) {
            revert InvalidWhitelistRequest();
        }
        _;
    }

    // Validate signer appproved the hash (address + quantity) for whitelist minting
    function isValidWhitelistRequest(bytes32 hash, bytes memory signature) private view returns (bool) {
        address signer = ECDSA.recover(hash, signature);
        return signer == whitelistSigner;
    }

    function updateWhitelistSigner(address _whitelistSigner) internal {
        whitelistSigner = _whitelistSigner;
    }
}
