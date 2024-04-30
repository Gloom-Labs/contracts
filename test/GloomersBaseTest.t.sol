// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {GloomersBase} from "../src/GloomersBase.sol";

contract GloomersBaseTest is Test {
    GloomersBase gloomers;

    function setUp() public {
        // vm.createSelectFork("https://mainnet.base.org");

        gloomers = new GloomersBase();
    }

    // test full suite
    function testFullSuite() public {
        //mint 3333 gloomers 3 to each address
        for (uint256 i = 1; i <= 2000; i++) {
            vm.startPrank(vm.addr(i));
            uint256 totalSupply = gloomers.totalSupply();
            uint256 mintAmount = i % 3;
            if (totalSupply + mintAmount > 3333) {
                mintAmount = 3333 - totalSupply;
            }
            gloomers.mint(mintAmount);

            uint256 nextSequentialTokenId = gloomers.nextSequentialTokenId();
            uint256 nextSpotMintTokenId = gloomers.nextSpotMintTokenId();

            uint256 totalSequentialMinted = gloomers.totalMinted();
            uint256 totalSpotMinted = gloomers.totalSpotMinted();
            console.log("nextSequentialTokenId: ", nextSequentialTokenId);
            console.log("nextSpotMintTokenId: ", nextSpotMintTokenId);
            console.log("totalSequentialMinted: ", totalSequentialMinted);
            console.log("totalSpotMinted: ", totalSpotMinted);
            console.log("Total Supply: ", totalSupply);
            vm.stopPrank();
        }

        vm.expectRevert();
        string memory uri1500 = gloomers.tokenURI(1500);
        vm.expectRevert();
        string memory uri3333 = gloomers.tokenURI(3333);
        vm.expectRevert();
        string memory uri6667 = gloomers.tokenURI(6667);
        vm.expectRevert();
        string memory uri10000 = gloomers.tokenURI(10000);

        for (uint256 i = 3334; i <= 6666; i++) {
            gloomers.tokenURI(i);
        }
        gloomers.reveal("ipfs://bafybeicgkb56vydl3kkcrgox7dpyatrgafxogurp42opjmiocfnwmbftlm/");

        string memory uri3334Updated = gloomers.tokenURI(3334);
        string memory uri6666Updated = gloomers.tokenURI(6666);
        console.log("URI 3334 Updated: ", uri3334Updated);
        console.log("URI 6666 Updated: ", uri6666Updated);
    }
}
