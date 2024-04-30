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

        assertTrue(verifier.verifySignature(msgHash, abi.encodePacked(v, r, s)), "Signature should be valid");
    }

    function testAddToAllowlist() public {
        address addr = vm.addr(0x2020202020202020202020202020202020202020202020202020202020202020);
        verifier.addToAllowlist(addr);
        assertTrue(verifier.isAllowlisted(addr), "Address should be allowlisted");
    }

    function testRemoveFromAllowlist() public {
        address addr = vm.addr(0x2020202020202020202020202020202020202020202020202020202020202020);
        verifier.addToAllowlist(addr);
        verifier.removeFromAllowlist(addr);
        assertTrue(!verifier.isAllowlisted(addr), "Address should not be allowlisted");
    }

    function testUpdateSigner() public {
        address newSigner = vm.addr(0x3030303030303030303030303030303030303030303030303030303030303030);
        verifier.updateSigner(newSigner);
        assertTrue(verifier.signer() == newSigner, "Signer should be updated");
    }

    function testOnlySigner() public {
        address addr = vm.addr(0x2020202020202020202020202020202020202020202020202020202020202020);
        verifier.addToAllowlist(addr);
        verifier.updateSigner(addr);
        verifier.removeFromAllowlist(addr);
    }

    function testFailOnlySigner() public {
        address addr = vm.addr(0x2020202020202020202020202020202020202020202020202020202020202020);
        verifier.addToAllowlist(addr);
        verifier.updateSigner(addr);
        verifier.removeFromAllowlist(addr);
    }

    function testFailRecover() public {
        string memory message = "attack at dawn";

        bytes32 msgHash =
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", uint256(bytes(message).length), message));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);

        address signer = ECDSA.recover(msgHash, v, r, s);
        assertTrue(signer == owner, "Signer should be owner");

        assertTrue(verifier.verifySignature(msgHash, abi.encodePacked(v, r, s)), "Signature should be valid");
    }

    function testFailAddToAllowlist() public {
        address addr = vm.addr(0x2020202020202020202020202020202020202020202020202020202020202020);
        verifier.addToAllowlist(addr);
        assertTrue(verifier.isAllowlisted(addr), "Address should be allowlisted");
    }
}
