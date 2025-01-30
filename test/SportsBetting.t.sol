// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {SportsBetting} from "../contracts/SportsBetting.sol";

contract SportsBettingTest is Test {
    SportsBetting public betting;

    function setUp() public {
        betting = new SportsBetting();
    }

    function testCreateBracket() public {
        string[] memory predictions = new string[](13);
        // Fill predictions array with test data
        for(uint i = 0; i < 13; i++) {
            predictions[i] = string(abi.encodePacked("team", vm.toString(i)));
        }
        
        betting.createBracket(predictions);
        assertTrue(betting.hasSubmittedBracket(address(this)));
    }
} 