// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/WhitelistVerifier.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "forge-std/console.sol";

contract WhitelistVerifierTest is Test {
    using ECDSA for bytes32;

    WhitelistVerifier verifier;

    address owner;
    uint256 privateKey = 0x1010101010101010101010101010101010101010101010101010101010101010;

    function setUp() public {
        owner = vm.addr(privateKey);
        verifier = new WhitelistVerifier(owner);
    }

    function testRecover() public {
        string memory message = "attack at dawn";

        bytes32 msgHash =
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", uint256(bytes(message).length), message));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);

        address signer = ECDSA.recover(msgHash, v, r, s);
        assertTrue(signer == owner, "Signer should be owner");

        //assertTrue(verifier.isValidWhitelistRequest(msgHash, abi.encodePacked(v, r, s)), "Signature should be valid");
    }
}
