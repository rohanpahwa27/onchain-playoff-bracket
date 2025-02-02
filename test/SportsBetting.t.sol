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

        // Calculate expected scores
        // Bob: Round 1 (6 matches = 6 points) + Round 2 (4 matches = 8 points) + Round 3 (2 matches = 8 points) + Round 4 (1 match = 6 points) = 28 points
        // Alice: Round 1 (6 matches = 6 points) + Round 2 (2 matches = 4 points) + Round 3 (0 matches = 0 points) + Round 4 (0 matches = 0 points) = 10 points
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

    function testPauseAndResumeBracketCreation() public {
        // Test pausing
        betting.pauseBracketCreation();
        assertTrue(betting.isBracketCreationPaused());

        // Try to create bracket while paused
        string[] memory predictions = new string[](13);
        for(uint i = 0; i < 13; i++) {
            predictions[i] = string(abi.encodePacked("team", vm.toString(i)));
        }

        vm.prank(alice);
        vm.expectRevert("Bracket creation is currently paused");
        betting.createBracket{value: ENTRY_FEE}(predictions);

        // Test resuming
        betting.resumeBracketCreation();
        assertFalse(betting.isBracketCreationPaused());

        // Should be able to create bracket now
        vm.prank(alice);
        betting.createBracket{value: ENTRY_FEE}(predictions);
        assertTrue(betting.hasSubmittedBracket(alice));
    }

    function testRemoveWinner() public {
        // First add a winner
        betting.updateWinner(1, "Bills");
        
        // Verify winner was added
        string[] memory winners = betting.getRoundWinners(1);
        assertEq(winners.length, 1);
        assertEq(winners[0], "Bills");

        // Remove the winner
        betting.removeWinner(1, "Bills");

        // Verify winner was removed
        winners = betting.getRoundWinners(1);
        assertEq(winners.length, 0);
    }

    function testGetUserScoreAndAllScores() public {
        // Create brackets for both players
        string[] memory alicePredictions = new string[](13);
        string[] memory bobPredictions = new string[](13);
        
        // Set predictions for Alice - all TeamA
        for(uint i = 0; i < 6; i++) alicePredictions[i] = "TeamA"; // Round 1
        for(uint i = 6; i < 10; i++) alicePredictions[i] = "TeamA"; // Round 2
        for(uint i = 10; i < 12; i++) alicePredictions[i] = "TeamA"; // Round 3
        alicePredictions[12] = "TeamA"; // Round 4

        // Set predictions for Bob - all TeamB
        for(uint i = 0; i < 6; i++) bobPredictions[i] = "TeamB"; // Round 1
        for(uint i = 6; i < 10; i++) bobPredictions[i] = "TeamB"; // Round 2
        for(uint i = 10; i < 12; i++) bobPredictions[i] = "TeamB"; // Round 3
        bobPredictions[12] = "TeamB"; // Round 4

        vm.prank(alice);
        betting.createBracket{value: ENTRY_FEE}(alicePredictions);
        
        vm.prank(bob);
        betting.createBracket{value: ENTRY_FEE}(bobPredictions);

        // Set some winners matching Alice's predictions
        betting.updateWinner(1, "TeamA"); // Round 1 = 1 point
        assertEq(betting.getUserScore(alice), 1); // 1 correct winner in Round 1 = 1 point
        assertEq(betting.getUserScore(bob), 0);

        betting.updateWinner(2, "TeamA"); // Round 2 = 2 points
        assertEq(betting.getUserScore(alice), 3); // 1 point from Round 1 + 2 points from Round 2 = 3
        assertEq(betting.getUserScore(bob), 0);
        
        // Check all scores
        (address[] memory users, uint256[] memory scores) = betting.getAllScores();
        assertEq(users.length, 2);
        assertEq(scores.length, 2);
        
        // Find Alice's score in the array
        bool foundAlice = false;
        for(uint i = 0; i < users.length; i++) {
            if(users[i] == alice) {
                assertEq(scores[i], 3);
                foundAlice = true;
                break;
            }
        }
        assertTrue(foundAlice);
    }

    function testDeleteBracket() public {
        // Create a bracket first
        string[] memory predictions = new string[](13);
        for(uint i = 0; i < 13; i++) {
            predictions[i] = string(abi.encodePacked("team", vm.toString(i)));
        }

        vm.prank(alice);
        betting.createBracket{value: ENTRY_FEE}(predictions);
        
        // Verify bracket exists
        assertTrue(betting.hasSubmittedBracket(alice));
        assertEq(betting.getPlayerCount(), 1);

        // Delete the bracket
        betting.deleteBracket(alice);

        // Verify bracket was deleted
        assertFalse(betting.hasSubmittedBracket(alice));
        assertEq(betting.getPlayerCount(), 0);

        // Try to get predictions for deleted bracket
        vm.expectRevert("Player has not submitted a bracket");
        betting.getBracketPredictions(alice);
    }

    function testUpdateWinnerAndGetRoundWinners() public {
        // Update winners for different rounds
        betting.updateWinner(1, "TeamA");
        betting.updateWinner(1, "TeamB");
        betting.updateWinner(2, "TeamC");
        
        // Check round 1 winners
        string[] memory round1Winners = betting.getRoundWinners(1);
        assertEq(round1Winners.length, 2);
        assertEq(round1Winners[0], "TeamA");
        assertEq(round1Winners[1], "TeamB");

        // Check round 2 winners
        string[] memory round2Winners = betting.getRoundWinners(2);
        assertEq(round2Winners.length, 1);
        assertEq(round2Winners[0], "TeamC");
    }

    function testErrorCases() public {
        // Test invalid round number for getRoundWinners
        vm.expectRevert("Invalid round");
        betting.getRoundWinners(0);
        
        vm.expectRevert("Invalid round");
        betting.getRoundWinners(5);

        // Test removing winner from invalid round
        vm.expectRevert(SportsBetting.InvalidRound.selector);
        betting.removeWinner(0, "TeamA");

        // Test removing non-existent winner
        vm.expectRevert("Winner not found in this round");
        betting.removeWinner(1, "NonExistentTeam");

        // Test getting score for non-existent bracket
        vm.expectRevert("No bracket found for this address");
        betting.getUserScore(alice);

        // Test deleting non-existent bracket
        vm.expectRevert("No bracket found for this address");
        betting.deleteBracket(alice);

        // Test pausing when already paused
        betting.pauseBracketCreation();
        vm.expectRevert("Bracket creation is already paused");
        betting.pauseBracketCreation();

        // Test resuming when not paused
        betting.resumeBracketCreation();
        vm.expectRevert("Bracket creation is not paused");
        betting.resumeBracketCreation();
    }

    function testMaximumWinnersPerRound() public {
        // Test maximum winners for each round
        // Round 1 should allow 6 winners
        for(uint i = 1; i <= 6; i++) {
            betting.updateWinner(1, string(abi.encodePacked("Team", vm.toString(i))));
        }
        vm.expectRevert("Maximum winners for this round already set");
        betting.updateWinner(1, "ExtraTeam");

        // Round 2 should allow 4 winners
        for(uint i = 1; i <= 4; i++) {
            betting.updateWinner(2, string(abi.encodePacked("Team", vm.toString(i))));
        }
        vm.expectRevert("Maximum winners for this round already set");
        betting.updateWinner(2, "ExtraTeam");

        // Round 3 should allow 2 winners
        for(uint i = 1; i <= 2; i++) {
            betting.updateWinner(3, string(abi.encodePacked("Team", vm.toString(i))));
        }
        vm.expectRevert("Maximum winners for this round already set");
        betting.updateWinner(3, "ExtraTeam");

        // Round 4 should allow 1 winner
        betting.updateWinner(4, "Team1");
        vm.expectRevert("Maximum winners for this round already set");
        betting.updateWinner(4, "ExtraTeam");
    }

    function testDuplicateWinnerInRound() public {
        betting.updateWinner(1, "TeamA");
        vm.expectRevert("Winner already exists in this round");
        betting.updateWinner(1, "TeamA");
    }

    function testSetAllWinnersInvalidLength() public {
        string[] memory invalidWinners = new string[](12); // Should be 13
        vm.expectRevert(SportsBetting.InvalidPredictionsLength.selector);
        betting.setAllWinners(invalidWinners);
    }

    function testRoundSpecificPoints() public {
        string[] memory predictions = new string[](13);
        
        // Set predictions - all TeamA
        for(uint i = 0; i < 6; i++) predictions[i] = "TeamA"; // Round 1
        for(uint i = 6; i < 10; i++) predictions[i] = "TeamA"; // Round 2
        for(uint i = 10; i < 12; i++) predictions[i] = "TeamA"; // Round 3
        predictions[12] = "TeamA"; // Round 4

        vm.prank(alice);
        betting.createBracket{value: ENTRY_FEE}(predictions);

        // Test points for each round
        betting.updateWinner(1, "TeamA"); // Round 1 = 1 point per winner
        assertEq(betting.getUserScore(alice), 1); // 1 correct winner = 1 point

        betting.updateWinner(2, "TeamA"); // Round 2 = 2 points per winner
        assertEq(betting.getUserScore(alice), 3); // 1 + 2 = 3 points

        betting.updateWinner(3, "TeamA"); // Round 3 = 4 points per winner
        assertEq(betting.getUserScore(alice), 7); // 1 + 2 + 4 = 7 points

        betting.updateWinner(4, "TeamA"); // Round 4 = 6 points per winner
        assertEq(betting.getUserScore(alice), 13); // 1 + 2 + 4 + 6 = 13 points

        // Test multiple winners in a round
        betting.updateWinner(1, "TeamB"); // Second winner in round 1
        assertEq(betting.getUserScore(alice), 13); // Score should stay the same since Alice didn't predict TeamB
    }

    function testOwnerOnlyFunctions() public {
        address nonOwner = makeAddr("nonOwner");
        vm.deal(nonOwner, 1 ether);

        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        betting.updateWinner(1, "TeamA");

        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        betting.setAllWinners(new string[](13));

        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        betting.removeWinner(1, "TeamA");

        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        betting.deleteBracket(alice);

        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        betting.pauseBracketCreation();

        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        betting.resumeBracketCreation();
    }
} 