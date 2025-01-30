// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {SportsBetting} from "../contracts/SportsBetting.sol";

contract SportsBettingTest is Test {
    SportsBetting public betting;
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    uint256 public constant ENTRY_FEE = 0.000001 ether;

    function setUp() public {
        betting = new SportsBetting();
        // Fund test accounts
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
    }

    function testCreateBracket() public {
        string[] memory predictions = new string[](13);
        predictions[0] = "Bills";   // Round 1
        predictions[1] = "Ravens";
        predictions[2] = "Chargers";
        predictions[3] = "Eagles";
        predictions[4] = "Bucs";
        predictions[5] = "Vikings";
        predictions[6] = "Chiefs";  // Round 2
        predictions[7] = "Ravens";
        predictions[8] = "Lions";
        predictions[9] = "Eagles";
        predictions[10] = "Ravens"; // Round 3
        predictions[11] = "Lions";
        predictions[12] = "Ravens"; // Round 4

        vm.prank(alice);
        betting.createBracket{value: ENTRY_FEE}(predictions);
        
        assertTrue(betting.hasSubmittedBracket(alice));
        assertEq(betting.getPlayerCount(), 1);
        assertEq(betting.getPrizePool(), (ENTRY_FEE * 90) / 100);

        // Verify bracket predictions
        string[][] memory bracket = betting.getBracketPredictions(alice);
        assertEq(bracket[0][0], "Bills");
        assertEq(bracket[0][1], "Ravens");
        assertEq(bracket[1][0], "Chiefs");
        assertEq(bracket[1][1], "Ravens");
        assertEq(bracket[2][0], "Ravens");
        assertEq(bracket[2][1], "Lions");
        assertEq(bracket[3][0], "Ravens");
    }

    function testSetAllWinnersAndCalculateWinner() public {
        // Create brackets for both players
        string[] memory alicePredictions = new string[](13);
        alicePredictions[0] = "Bills";   // Round 1 - 6 teams
        alicePredictions[1] = "Ravens";
        alicePredictions[2] = "Chargers";
        alicePredictions[3] = "Eagles";
        alicePredictions[4] = "Bucs";
        alicePredictions[5] = "Vikings";
        alicePredictions[6] = "Bills";   // Round 2 - 4 teams
        alicePredictions[7] = "Eagles";
        alicePredictions[8] = "Ravens";
        alicePredictions[9] = "Vikings";
        alicePredictions[10] = "Bills";  // Round 3 - 2 teams
        alicePredictions[11] = "Ravens";
        alicePredictions[12] = "Bills";  // Round 4 - 1 team

        string[] memory bobPredictions = new string[](13);
        bobPredictions[0] = "Bills";    // Different predictions for Bob
        bobPredictions[1] = "Ravens";
        bobPredictions[2] = "Chiefs";
        bobPredictions[3] = "Eagles";
        bobPredictions[4] = "Bucs";
        bobPredictions[5] = "Vikings";
        bobPredictions[6] = "Ravens";
        bobPredictions[7] = "Eagles";
        bobPredictions[8] = "Chiefs";
        bobPredictions[9] = "Vikings";
        bobPredictions[10] = "Ravens";
        bobPredictions[11] = "Chiefs";
        bobPredictions[12] = "Ravens";

        // Submit brackets
        vm.prank(alice);
        betting.createBracket{value: ENTRY_FEE}(alicePredictions);
        
        vm.prank(bob);
        betting.createBracket{value: ENTRY_FEE}(bobPredictions);

        // Set actual winners (matching more with Bob's predictions)
        string[] memory actualWinners = new string[](13);
        actualWinners[0] = "Bills";
        actualWinners[1] = "Ravens";
        actualWinners[2] = "Chiefs";
        actualWinners[3] = "Eagles";
        actualWinners[4] = "Bucs";
        actualWinners[5] = "Vikings";
        actualWinners[6] = "Ravens";
        actualWinners[7] = "Eagles";
        actualWinners[8] = "Chiefs";
        actualWinners[9] = "Vikings";
        actualWinners[10] = "Ravens";
        actualWinners[11] = "Chiefs";
        actualWinners[12] = "Ravens";

        // Record Bob's balance before winning
        uint256 bobBalanceBefore = bob.balance;

        // Set winners and trigger payout
        betting.setAllWinners(actualWinners);

        // Verify Bob won and received payment
        assertGt(bob.balance, bobBalanceBefore);
        assertEq(betting.getPrizePool(), 0);
    }

    function testCannotSubmitTwice() public {
        string[] memory predictions = new string[](13);
        for(uint i = 0; i < 13; i++) {
            predictions[i] = string(abi.encodePacked("team", vm.toString(i)));
        }

        vm.prank(alice);
        betting.createBracket{value: ENTRY_FEE}(predictions);

        vm.expectRevert(SportsBetting.BracketAlreadySubmitted.selector);
        vm.prank(alice);
        betting.createBracket{value: ENTRY_FEE}(predictions);
    }

    function testIncorrectEntryFee() public {
        string[] memory predictions = new string[](13);
        for(uint i = 0; i < 13; i++) {
            predictions[i] = string(abi.encodePacked("team", vm.toString(i)));
        }

        vm.prank(alice);
        vm.expectRevert("Must send exactly 0.000001 ETH to submit bracket");
        betting.createBracket{value: 0.000002 ether}(predictions);
    }
} 