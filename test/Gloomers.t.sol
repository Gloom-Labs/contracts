// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import "../src/Gloomers.sol";

import "../src/WhitelistVerifier.sol";

contract GloomersTest is Test {
    using ECDSA for bytes32;

    Gloomers public gloomers;
    WhitelistVerifier public whitelistVerifier;
    address public owner;
    address public user1;

    function setUp() public {
        owner = address(this);
        user1 = address(0x9dF0C6b0066D5317aA5b38B36850548DaCCa6B4e);

        gloomers = new Gloomers();
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function testInitialState() public {
        vm.startPrank(user1);
        assertEq(gloomers.START_TOKEN_ID(), 1);
        assertEq(gloomers.PRICE_PER_TOKEN(), 0.03 ether);
        assertEq(gloomers.getMintLimitPerWallet(), 3);
        assertEq(
            gloomers.PROVENANCE_HASH(),
            0x5158cf3ac201d8d9dfe63ac7c7d1e7aa58b7c33426665c9bf643e0003e095e2f
        );
        assertEq(gloomers.WHITELIST_START_TIMESTAMP(), 1714838400);
        assertEq(gloomers.PUBLIC_MINT_TIMESTAMP(), 1714838400 + 3 hours);
        assertEq(gloomers.mintingEnabled(), false);

        vm.warp(gloomers.WHITELIST_START_TIMESTAMP() + 1);
        assertEq(gloomers.getMintLimitPerWallet(), 3);

        vm.warp(gloomers.PUBLIC_MINT_TIMESTAMP() + 1);
        assertEq(gloomers.getMintLimitPerWallet(), 420);

        vm.stopPrank();
    }

    function testSetTokenUri() public {
        // set drop status to PRESALE
        gloomers.setMintingEnabled(true);
        vm.warp(gloomers.PUBLIC_MINT_TIMESTAMP() + 1);
        gloomers.mint{value: 0.03 ether}(1);
        string memory originalURI = gloomers.tokenURI(1);
        console.log("prereveal tokenURI(1)", originalURI);
        string memory newBaseURI = "ipfs://newbaseuri/";
        gloomers.setTokenUri(newBaseURI);
        vm.startPrank(user1);
        vm.expectRevert();
        gloomers.setTokenUri("randomURIFromUnauthorizedCaller");
        vm.stopPrank();

        string memory newURI = gloomers.tokenURI(1);
        console.log("postreveal tokenURI(1)", newURI);
        assertEq(
            gloomers.tokenURI(1),
            string(abi.encodePacked(newBaseURI, "1"))
        );
    }

    function testSetDefaultRoyalty() public {
        address receiver = address(0x2);
        uint96 feeNumerator = 1000;
        gloomers.setDefaultRoyalty(receiver, feeNumerator);
        (address royaltyReceiver, uint256 royaltyAmount) = gloomers.royaltyInfo(
            1,
            1 ether
        );
        assertEq(royaltyReceiver, receiver);
        assertEq(royaltyAmount, (1 ether * feeNumerator) / 10000);
    }

    function testWithdraw() public {
        uint256 balance = address(this).balance;
        payable(address(gloomers)).transfer(address(this).balance);
        console.log("balance", balance);
        uint256 contractBalance = address(gloomers).balance;
        console.log("contractBalance", contractBalance);
        address gloomersDeployer = gloomers.owner();
        console.log("gloomersDeployer", gloomersDeployer);
        gloomers.withdraw();
    }

    // test mint
    function testMint() public {
        //vm.createSelectFork("https://mainnet.base.org");

        gloomers.setMintingEnabled(true);
        vm.warp(gloomers.PUBLIC_MINT_TIMESTAMP() + 1);

        gloomers.setTokenUri("ipfs://newbaseuri/");

        for (uint256 i = 1; i <= 3333; i++) {
            vm.deal(vm.addr(i), 1 ether);
            vm.prank(vm.addr(i));
            gloomers.mint{value: 0.03 ether}(1);
            console.log("TOKEN URI", gloomers.tokenURI(i));
            uint256[] memory tokenId = gloomers.tokensOfOwner(vm.addr(i));
            console.log("tokenId", tokenId[0]);
        }
    }

    function testPresale() public {
        gloomers.setMintingEnabled(true);

        vm.startBroadcast();
        vm.deal(user1, 1 ether);
        gloomers.registerPresale{value: 0.03 ether}(1);

        uint256 allocation = gloomers.getPresaleAllocation(user1);
        console.log("user1 allocation", allocation);

        vm.warp(gloomers.WHITELIST_START_TIMESTAMP() + 1);

        gloomers.claimPresale();

        uint256[] memory tokenId = gloomers.tokensOfOwner(user1);
        console.log("tokenId", tokenId[0]);

        console.log("TOKEN URI", gloomers.tokenURI(tokenId[0]));

        vm.stopBroadcast();
    }
}
