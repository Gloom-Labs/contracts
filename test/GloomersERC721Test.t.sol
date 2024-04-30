// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {GloomersERC721} from "../src/GloomersERC721.sol";

contract GloomersERC721Test is Test {
    GloomersERC721 gloomersErc721;

    function setUp() public {
        vm.createSelectFork("https://mainnet.base.org");

        gloomersErc721 = new GloomersERC721();
    }

    // function testMint() public {
    //     gloomers.mint(1);
    //     assertEq(gloomers.balanceOf(address(this)), 1);
    // }

    // function testTokenURI() public {
    //     gloomers.mint(1);
    //     string memory uri = gloomers.tokenURI(1);
    //     console.log("URI: ", uri);
    // }

    // function testReveal() public {
    //     gloomers.reveal("ipfs://bafybeicgkb56vydl3kkcrgox7dpyatrgafxogurp42opjmiocfnwmbftlm/");
    //     gloomers.mint(1);
    //     string memory uri = gloomers.tokenURI(1);
    //     console.log("URI: ", uri);
    // }

    // get next token id

    // function testFewMints() public {
    //     uint256 nextTokenId = gloomers.nextTokenId();
    //     console.log("Next Token ID: ", nextTokenId);

    //     vm.prank(vm.addr(1));
    //     gloomers.mint(1);
    // }

    // test full suite
    function testFullSuiteERC721() public {
        //mint 3333 gloomers 3 to each address
        for (uint256 i = 1; i <= 1111; i++) {
            vm.roll(i);
            uint256 mintAmount = (uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao))) % 3) + 1;
            for (uint256 j = 0; j < mintAmount; j++) {
                vm.prank(vm.addr(i));
                gloomersErc721.mint(vm.addr(i), "20");
            }
        }

        string memory uri1 = gloomersErc721.tokenURI(1);
        string memory uri1500 = gloomersErc721.tokenURI(15);
        string memory uri3333 = gloomersErc721.tokenURI(20);
        console.log("URI 1: ", uri1);
        console.log("URI 1500: ", uri1500);
        console.log("URI 3333: ", uri3333);

        // //get the tokenURI for 1 and 3333
        // string memory uri1 = gloomers.tokenURI(1);
        // string memory uri1500 = gloomers.tokenURI(1500);
        // string memory uri3333 = gloomers.tokenURI(3333);
        // console.log("URI 1: ", uri1);
        // console.log("URI 1500: ", uri1500);
        // console.log("URI 3333: ", uri3333);

        // // set the baseURI
        // gloomers.reveal("ipfs://bafybeicgkb56vydl3kkcrgox7dpyatrgafxogurp42opjmiocfnwmbftlm/");
        // string memory uri1Updated = gloomers.tokenURI(1);
        // string memory uri1500Updated = gloomers.tokenURI(1500);
        // string memory uri3333Updated = gloomers.tokenURI(3333);
        // console.log("URI 1 Updated: ", uri1Updated);
        // console.log("URI 1500 Updated: ", uri1500Updated);
        // console.log("URI 3333 Updated: ", uri3333Updated);
    }
}
