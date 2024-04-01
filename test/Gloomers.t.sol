// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Gloomers} from "../src/Gloomers.sol";

contract CounterTest is Test {
    Gloomers public gloomers;

    function setUp() public {
        gloomers = new Gloomers();
    }
}
