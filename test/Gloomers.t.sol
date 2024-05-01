// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import "../src/Gloomers.sol";

contract GloomersTest is Test {
    Gloomers public gloomers;
    address public owner;
    address public user1;
    address public whitelistSigner;

    function setUp() public {
        owner = address(this);
        user1 = address(0x9dF0C6b0066D5317aA5b38B36850548DaCCa6B4e);
        whitelistSigner = address(0x1);
        gloomers = new Gloomers(whitelistSigner);
    }

    function testInitialState() public view {
        assertEq(gloomers.START_TOKEN_ID(), 3334);
        assertEq(gloomers.PRICE_PER_TOKEN(), 0.03 ether);
        assertEq(gloomers.MAX_MINT_PER_WALLET(), 3);
        assertEq(
            gloomers.PROVENANCE_HASH(),
            0x5158cf3ac201d8d9dfe63ac7c7d1e7aa58b7c33426665c9bf643e0003e095e2f
        );
        assertEq(gloomers.WHITELIST_START_TIMESTAMP(), 1714838400);
        assertEq(gloomers.PUBLIC_MINT_TIMESTAMP(), 1714838400 + 3 hours);
        assertEq(uint256(gloomers.dropStatus()), 0);
    }

    function testSetTokenUri() public {
        // set drop status to PRESALE
        Gloomers.DropStatus newDropStatus = Gloomers.DropStatus.PRESALE;
        string memory originalURI = gloomers.tokenURI(3339);
        string memory newBaseURI = "https://new.baseuri.com/";
        gloomers.setTokenUri(newBaseURI);
        vm.expectRevert();
        string memory newURI = gloomers.tokenURI(3339);
        assertEq(
            gloomers.tokenURI(3334),
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

    function testSetWhitelistSigner() public {
        address newWhitelistSigner = address(0x3);
        gloomers.setWhitelistSigner(newWhitelistSigner);
        assertEq(gloomers.whitelistSigner(), newWhitelistSigner);
    }

    function testSetDropStatus() public {
        Gloomers.DropStatus newDropStatus = Gloomers.DropStatus.PUBLIC;
        gloomers.setDropStatus(newDropStatus);
        assertEq(uint256(gloomers.dropStatus()), uint256(newDropStatus));
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
        gloomers.setDropStatus(Gloomers.DropStatus.PUBLIC);
        vm.warp(gloomers.PUBLIC_MINT_TIMESTAMP() + 1);

        gloomers.setTokenUri(
            "ipfs://bafaf/"
        );

        for (uint256 i = 3334; i <= 6666; i++) {
            vm.deal(vm.addr(i), 1 ether);
            vm.prank(vm.addr(i));
            gloomers.mint{value: 0.03 ether}(1);
            console.log("TOKEN URI", gloomers.tokenURI(i));
            uint256[] memory tokenId = gloomers.tokensOfOwner(vm.addr(i));
        }
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
