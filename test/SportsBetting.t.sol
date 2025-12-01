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
        predictions[0] = "Bills"; // Round 1
        predictions[1] = "Ravens";
        predictions[2] = "Chargers";
        predictions[3] = "Eagles";
        predictions[4] = "Bucs";
        predictions[5] = "Vikings";
        predictions[6] = "Chiefs"; // Round 2
        predictions[7] = "Ravens";
        predictions[8] = "Lions";
        predictions[9] = "Eagles";
        predictions[10] = "Ravens"; // Round 3
        predictions[11] = "Lions";
        predictions[12] = "Ravens"; // Round 4

        // Create group first
        vm.prank(alice);
        betting.createGroup("TestGroup", "password123", ENTRY_FEE);

        vm.prank(alice);
        betting.createBracket{value: ENTRY_FEE}(
            predictions,
            "TestGroup",
            "password123",
            "TestUser"
        );

        assertTrue(
            betting.hasSubmittedGroupBracket(alice, "TestGroup", "password123")
        );
        assertEq(betting.getGroupMemberCount("TestGroup", "password123"), 1);
        assertEq(
            betting.getGroupPrizePool("TestGroup", "password123"),
            (ENTRY_FEE * 97) / 100
        );

        // Verify bracket predictions
        // Verify bracket predictions
        // Verify bracket predictions
        // Pause brackets to allow viewing predictions
        betting.pauseBracketCreation();
        (, , , string[][][] memory allPredictions) = betting.getGroupData(
            "TestGroup",
            "password123"
        );
        string[][] memory bracket = allPredictions[0];
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
        alicePredictions[0] = "Bills"; // Round 1 - 6 teams
        alicePredictions[1] = "Ravens";
        alicePredictions[2] = "Chargers";
        alicePredictions[3] = "Eagles";
        alicePredictions[4] = "Bucs";
        alicePredictions[5] = "Vikings";
        alicePredictions[6] = "Bills"; // Round 2 - 4 teams
        alicePredictions[7] = "Eagles";
        alicePredictions[8] = "Ravens";
        alicePredictions[9] = "Vikings";
        alicePredictions[10] = "Bills"; // Round 3 - 2 teams
        alicePredictions[11] = "Ravens";
        alicePredictions[12] = "Bills"; // Round 4 - 1 team

        string[] memory bobPredictions = new string[](13);
        bobPredictions[0] = "Bills"; // Different predictions for Bob
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

        // Create group first
        vm.prank(alice);
        betting.createGroup("TestGroup", "password123", ENTRY_FEE);

        // Submit brackets
        vm.prank(alice);
        betting.createBracket{value: ENTRY_FEE}(
            alicePredictions,
            "TestGroup",
            "password123",
            "Alice"
        );

        vm.prank(bob);
        betting.createBracket{value: ENTRY_FEE}(
            bobPredictions,
            "TestGroup",
            "password123",
            "Bob"
        );

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

        // Set winners
        betting.setAllWinners(actualWinners);

        // Manually distribute group prize
        betting.distributeGroupPrize("TestGroup");

        // Calculate expected scores
        // Bob: Round 1 (6 matches = 6 points) + Round 2 (4 matches = 8 points) + Round 3 (2 matches = 8 points) + Round 4 (1 match = 6 points) = 28 points
        // Alice: Round 1 (6 matches = 6 points) + Round 2 (2 matches = 4 points) + Round 3 (0 matches = 0 points) + Round 4 (0 matches = 0 points) = 10 points
        assertGt(bob.balance, bobBalanceBefore);
        assertEq(betting.getGroupPrizePool("TestGroup", "password123"), 0);
    }

    function testCannotSubmitTwice() public {
        string[] memory predictions = new string[](13);
        for (uint256 i = 0; i < 13; i++) {
            predictions[i] = string(abi.encodePacked("team", vm.toString(i)));
        }

        vm.prank(alice);
        betting.createGroup("TestGroup", "password123", ENTRY_FEE);

        vm.prank(alice);
        betting.createBracket{value: ENTRY_FEE}(
            predictions,
            "TestGroup",
            "password123",
            "TestUser"
        );

        vm.expectRevert(SportsBetting.BracketAlreadySubmitted.selector);
        vm.prank(alice);
        betting.createBracket{value: ENTRY_FEE}(
            predictions,
            "TestGroup",
            "password123",
            "TestUser"
        );
    }

    function testIncorrectEntryFee() public {
        string[] memory predictions = new string[](13);
        for (uint256 i = 0; i < 13; i++) {
            predictions[i] = string(abi.encodePacked("team", vm.toString(i)));
        }

        vm.prank(alice);
        betting.createGroup("TestGroup", "password123", ENTRY_FEE);

        vm.prank(alice);
        vm.expectRevert(SportsBetting.IncorrectEntryFeeAmount.selector);
        betting.createBracket{value: 0.000002 ether}(
            predictions,
            "TestGroup",
            "password123",
            "TestUser"
        );
    }

    function testPauseAndResumeBracketCreation() public {
        // Test pausing
        betting.pauseBracketCreation();
        assertTrue(betting.isBracketCreationPaused());

        // Try to create bracket while paused
        string[] memory predictions = new string[](13);
        for (uint256 i = 0; i < 13; i++) {
            predictions[i] = string(abi.encodePacked("team", vm.toString(i)));
        }

        vm.prank(alice);
        betting.createGroup("TestGroup", "password123", ENTRY_FEE);

        vm.prank(alice);
        vm.expectRevert("Brackets paused");
        betting.createBracket{value: ENTRY_FEE}(
            predictions,
            "TestGroup",
            "password123",
            "TestUser"
        );

        // Test resuming
        betting.resumeBracketCreation();
        assertFalse(betting.isBracketCreationPaused());

        // Should be able to create bracket now
        vm.prank(alice);
        betting.createBracket{value: ENTRY_FEE}(
            predictions,
            "TestGroup",
            "password123",
            "TestUser"
        );
        assertTrue(
            betting.hasSubmittedGroupBracket(alice, "TestGroup", "password123")
        );
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
        for (uint256 i = 0; i < 6; i++) {
            alicePredictions[i] = "TeamA";
        } // Round 1
        for (uint256 i = 6; i < 10; i++) {
            alicePredictions[i] = "TeamA";
        } // Round 2
        for (uint256 i = 10; i < 12; i++) {
            alicePredictions[i] = "TeamA";
        } // Round 3
        alicePredictions[12] = "TeamA"; // Round 4

        // Set predictions for Bob - all TeamB
        for (uint256 i = 0; i < 6; i++) {
            bobPredictions[i] = "TeamB";
        } // Round 1
        for (uint256 i = 6; i < 10; i++) {
            bobPredictions[i] = "TeamB";
        } // Round 2
        for (uint256 i = 10; i < 12; i++) {
            bobPredictions[i] = "TeamB";
        } // Round 3
        bobPredictions[12] = "TeamB"; // Round 4

        vm.prank(alice);
        betting.createGroup("TestGroup", "password123", ENTRY_FEE);

        vm.prank(alice);
        betting.createBracket{value: ENTRY_FEE}(
            alicePredictions,
            "TestGroup",
            "password123",
            "Alice"
        );

        vm.prank(bob);
        betting.createBracket{value: ENTRY_FEE}(
            bobPredictions,
            "TestGroup",
            "password123",
            "Bob"
        );

        // Set some winners matching Alice's predictions
        betting.updateWinner(1, "TeamA"); // Round 1 = 1 point
        // Pause brackets to view scores
        betting.pauseBracketCreation();
        (address[] memory users1, uint256[] memory scores1, , ) = betting
            .getGroupData("TestGroup", "password123");
        // Find Alice's and Bob's scores
        for (uint256 i = 0; i < users1.length; i++) {
            if (users1[i] == alice) {
                assertEq(scores1[i], 1); // 1 correct winner in Round 1 = 1 point
            } else if (users1[i] == bob) {
                assertEq(scores1[i], 0);
            }
        }

        betting.updateWinner(2, "TeamA"); // Round 2 = 2 points
        (address[] memory users2, uint256[] memory scores2, , ) = betting
            .getGroupData("TestGroup", "password123");
        for (uint256 i = 0; i < users2.length; i++) {
            if (users2[i] == alice) {
                assertEq(scores2[i], 3); // 1 point from Round 1 + 2 points from Round 2 = 3
            } else if (users2[i] == bob) {
                assertEq(scores2[i], 0);
            }
        }

        // Check all scores
        (address[] memory users, uint256[] memory scores, , ) = betting
            .getGroupData("TestGroup", "password123");
        assertEq(users.length, 2);
        assertEq(scores.length, 2);

        // Find Alice's score in the array
        bool foundAlice = false;
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] == alice) {
                assertEq(scores[i], 3);
                foundAlice = true;
                break;
            }
        }
        assertTrue(foundAlice);
    }

    function testGroupFunctionality() public {
        // Test group creation and membership
        string[] memory predictions = new string[](13);
        for (uint256 i = 0; i < 13; i++) {
            predictions[i] = string(abi.encodePacked("team", vm.toString(i)));
        }

        // Test group doesn't exist initially
        assertFalse(betting.groupExists("TestGroup"));

        vm.prank(alice);
        betting.createGroup("TestGroup", "password123", ENTRY_FEE);

        vm.prank(alice);
        betting.createBracket{value: ENTRY_FEE}(
            predictions,
            "TestGroup",
            "password123",
            "Alice"
        );

        // Verify group was created and alice joined
        assertTrue(betting.groupExists("TestGroup"));
        assertTrue(
            betting.hasSubmittedGroupBracket(alice, "TestGroup", "password123")
        );
        assertEq(betting.getGroupMemberCount("TestGroup", "password123"), 1);

        // Test bob joining the same group
        vm.prank(bob);
        betting.createBracket{value: ENTRY_FEE}(
            predictions,
            "TestGroup",
            "password123",
            "Bob"
        );
        assertEq(betting.getGroupMemberCount("TestGroup", "password123"), 2);

        // Try to get predictions for alice
        // Try to get predictions for alice
        // Pause brackets to view predictions
        betting.pauseBracketCreation();
        (, , , string[][][] memory allPredictions) = betting.getGroupData(
            "TestGroup",
            "password123"
        );
        // Alice should be first since she joined first
        string[][] memory bracket = allPredictions[0];
        assertEq(bracket[0][0], "team0");
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
        vm.expectRevert("BadRound");
        betting.getRoundWinners(0);

        vm.expectRevert("BadRound");
        betting.getRoundWinners(5);

        // Test removing winner from invalid round
        vm.expectRevert(SportsBetting.InvalidRound.selector);
        betting.removeWinner(0, "TeamA");

        // Test removing non-existent winner
        vm.expectRevert("Winner not found");
        betting.removeWinner(1, "NonExistentTeam");

        // Test getting score for non-existent group
        vm.expectRevert("NoGroup");
        betting.getGroupData("NonExistentGroup", "password123");

        // Test pausing when already paused
        betting.pauseBracketCreation();
        vm.expectRevert("Paused");
        betting.pauseBracketCreation();

        // Test resuming when not paused
        betting.resumeBracketCreation();
        vm.expectRevert("Not paused");
        betting.resumeBracketCreation();
    }

    function testMaximumWinnersPerRound() public {
        // Test maximum winners for each round
        // Round 1 should allow 6 winners
        for (uint256 i = 1; i <= 6; i++) {
            betting.updateWinner(
                1,
                string(abi.encodePacked("Team", vm.toString(i)))
            );
        }
        vm.expectRevert("Max winners set");
        betting.updateWinner(1, "ExtraTeam");

        // Round 2 should allow 4 winners
        for (uint256 i = 1; i <= 4; i++) {
            betting.updateWinner(
                2,
                string(abi.encodePacked("Team", vm.toString(i)))
            );
        }
        vm.expectRevert("Max winners set");
        betting.updateWinner(2, "ExtraTeam");

        // Round 3 should allow 2 winners
        for (uint256 i = 1; i <= 2; i++) {
            betting.updateWinner(
                3,
                string(abi.encodePacked("Team", vm.toString(i)))
            );
        }
        vm.expectRevert("Max winners set");
        betting.updateWinner(3, "ExtraTeam");

        // Round 4 should allow 1 winner
        betting.updateWinner(4, "Team1");
        vm.expectRevert("Max winners set");
        betting.updateWinner(4, "ExtraTeam");
    }

    function testDuplicateWinnerInRound() public {
        betting.updateWinner(1, "TeamA");
        vm.expectRevert("Duplicate");
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
        for (uint256 i = 0; i < 6; i++) {
            predictions[i] = "TeamA";
        } // Round 1
        for (uint256 i = 6; i < 10; i++) {
            predictions[i] = "TeamA";
        } // Round 2
        for (uint256 i = 10; i < 12; i++) {
            predictions[i] = "TeamA";
        } // Round 3
        predictions[12] = "TeamA"; // Round 4

        vm.prank(alice);
        betting.createGroup("TestGroup", "password123", ENTRY_FEE);

        vm.prank(alice);
        betting.createBracket{value: ENTRY_FEE}(
            predictions,
            "TestGroup",
            "password123",
            "TestUser"
        );

        // Test points for each round
        betting.updateWinner(1, "TeamA"); // Round 1 = 1 point per winner
        // Pause brackets to view scores
        betting.pauseBracketCreation();
        (, uint256[] memory scores1, , ) = betting.getGroupData(
            "TestGroup",
            "password123"
        );
        assertEq(scores1[0], 1); // 1 correct winner = 1 point

        // Resume to update more winners
        betting.resumeBracketCreation();
        betting.updateWinner(2, "TeamA"); // Round 2 = 2 points per winner
        // Pause brackets to view scores
        betting.pauseBracketCreation();
        (, uint256[] memory scores2, , ) = betting.getGroupData(
            "TestGroup",
            "password123"
        );
        assertEq(scores2[0], 3); // 1 + 2 = 3 points

        // Resume to update more winners
        betting.resumeBracketCreation();
        betting.updateWinner(3, "TeamA"); // Round 3 = 4 points per winner
        // Pause brackets to view scores
        betting.pauseBracketCreation();
        (, uint256[] memory scores3, , ) = betting.getGroupData(
            "TestGroup",
            "password123"
        );
        assertEq(scores3[0], 7); // 1 + 2 + 4 = 7 points

        // Resume to update more winners
        betting.resumeBracketCreation();
        betting.updateWinner(4, "TeamA"); // Round 4 = 6 points per winner
        // Pause brackets to view scores
        betting.pauseBracketCreation();
        (, uint256[] memory scores4, , ) = betting.getGroupData(
            "TestGroup",
            "password123"
        );
        assertEq(scores4[0], 13); // 1 + 2 + 4 + 6 = 13 points

        // Test multiple winners in a round
        // Resume to update more winners
        betting.resumeBracketCreation();
        betting.updateWinner(1, "TeamB"); // Second winner in round 1
        betting.pauseBracketCreation();
        (, uint256[] memory scores5, , ) = betting.getGroupData(
            "TestGroup",
            "password123"
        );
        assertEq(scores5[0], 13); // Score should stay the same since Alice didn't predict TeamB
    }

    function testOwnerOnlyFunctions() public {
        address nonOwner = makeAddr("nonOwner");
        vm.deal(nonOwner, 1 ether);

        vm.prank(nonOwner);
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                nonOwner
            )
        );
        betting.updateWinner(1, "TeamA");

        vm.prank(nonOwner);
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                nonOwner
            )
        );
        betting.setAllWinners(new string[](13));

        vm.prank(nonOwner);
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                nonOwner
            )
        );
        betting.removeWinner(1, "TeamA");

        vm.prank(nonOwner);
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                nonOwner
            )
        );
        betting.distributeGroupPrize("TestGroup");

        vm.prank(nonOwner);
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                nonOwner
            )
        );
        betting.pauseBracketCreation();

        vm.prank(nonOwner);
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                nonOwner
            )
        );
        betting.resumeBracketCreation();
    }

    function testGroupPasswordValidation() public {
        string[] memory predictions = new string[](13);
        for (uint256 i = 0; i < 13; i++) {
            predictions[i] = string(abi.encodePacked("team", vm.toString(i)));
        }

        // Create group first
        vm.prank(alice);
        betting.createGroup("SecretGroup", "correctPassword", ENTRY_FEE);

        // Alice joins
        vm.prank(alice);
        betting.createBracket{value: ENTRY_FEE}(
            predictions,
            "SecretGroup",
            "correctPassword",
            "Alice"
        );

        // Bob tries to join with wrong password
        vm.prank(bob);
        vm.expectRevert(SportsBetting.InvalidPassword.selector);
        betting.createBracket{value: ENTRY_FEE}(
            predictions,
            "SecretGroup",
            "wrongPassword",
            "Bob"
        );

        // Bob joins with correct password
        vm.prank(bob);
        betting.createBracket{value: ENTRY_FEE}(
            predictions,
            "SecretGroup",
            "correctPassword",
            "Charlie"
        );

        assertEq(
            betting.getGroupMemberCount("SecretGroup", "correctPassword"),
            2
        );
    }

    function testEmptyGroupNameAndPassword() public {
        string[] memory predictions = new string[](13);
        for (uint256 i = 0; i < 13; i++) {
            predictions[i] = string(abi.encodePacked("team", vm.toString(i)));
        }

        // Test empty group name
        vm.prank(alice);
        vm.expectRevert(SportsBetting.EmptyGroupName.selector);
        betting.createGroup("", "password123", ENTRY_FEE);

        // Test empty password
        vm.prank(alice);
        vm.expectRevert(SportsBetting.EmptyPassword.selector);
        betting.createGroup("TestGroup", "", ENTRY_FEE);
    }

    function testGroupSizeLimit() public {
        string[] memory predictions = new string[](13);
        for (uint256 i = 0; i < 13; i++) {
            predictions[i] = string(abi.encodePacked("team", vm.toString(i)));
        }

        // Create group first
        vm.prank(alice);
        betting.createGroup("FullGroup", "password123", ENTRY_FEE);

        // Create 20 users and have them join the same group
        for (uint256 i = 0; i < 50; i++) {
            address user = makeAddr(
                string(abi.encodePacked("user", vm.toString(i)))
            );
            vm.deal(user, 1 ether);
            vm.prank(user);
            betting.createBracket{value: ENTRY_FEE}(
                predictions,
                "FullGroup",
                "password123",
                string(abi.encodePacked("User", vm.toString(i)))
            );
        }

        assertEq(betting.getGroupMemberCount("FullGroup", "password123"), 50);

        // 51st user should be rejected
        address user51 = makeAddr("user51");
        vm.deal(user51, 1 ether);
        vm.prank(user51);
        vm.expectRevert(SportsBetting.GroupFull.selector);
        betting.createBracket{value: ENTRY_FEE}(
            predictions,
            "FullGroup",
            "password123",
            "User51"
        );
    }

    function testMultipleGroups() public {
        string[] memory predictions = new string[](13);
        for (uint256 i = 0; i < 13; i++) {
            predictions[i] = string(abi.encodePacked("team", vm.toString(i)));
        }

        // Create groups first
        vm.prank(alice);
        betting.createGroup("Group1", "password1", ENTRY_FEE);
        vm.prank(alice);
        betting.createGroup("Group2", "password2", ENTRY_FEE);

        // Alice joins multiple groups
        vm.prank(alice);
        betting.createBracket{value: ENTRY_FEE}(
            predictions,
            "Group1",
            "password1",
            "TestUser"
        );

        vm.prank(alice);
        betting.createBracket{value: ENTRY_FEE}(
            predictions,
            "Group2",
            "password2",
            "TestUser"
        );

        // Verify alice is in both groups
        assertTrue(
            betting.hasSubmittedGroupBracket(alice, "Group1", "password1")
        );
        assertTrue(
            betting.hasSubmittedGroupBracket(alice, "Group2", "password2")
        );

        // But can't submit twice to same group
        vm.prank(alice);
        vm.expectRevert(SportsBetting.BracketAlreadySubmitted.selector);
        betting.createBracket{value: ENTRY_FEE}(
            predictions,
            "Group1",
            "password1",
            "TestUser"
        );
    }

    function testCustomEntryFees() public {
        string[] memory predictions = new string[](13);
        for (uint256 i = 0; i < 13; i++) {
            predictions[i] = string(abi.encodePacked("team", vm.toString(i)));
        }

        uint256 customFee = 0.0005 ether; // 0.5 milliETH

        // Create group with custom entry fee
        vm.prank(alice);
        betting.createGroup("CustomFeeGroup", "password123", customFee);

        vm.prank(alice);
        betting.createBracket{value: customFee}(
            predictions,
            "CustomFeeGroup",
            "password123",
            "Alice"
        );

        // Verify group was created with correct entry fee
        assertEq(
            betting.getGroupEntryFee("CustomFeeGroup", "password123"),
            customFee
        );
        assertEq(
            betting.getGroupPrizePool("CustomFeeGroup", "password123"),
            (customFee * 97) / 100
        );

        // Bob joins with correct fee
        vm.prank(bob);
        betting.createBracket{value: customFee}(
            predictions,
            "CustomFeeGroup",
            "password123",
            "TestUser"
        );

        assertEq(
            betting.getGroupMemberCount("CustomFeeGroup", "password123"),
            2
        );
        assertEq(
            betting.getGroupPrizePool("CustomFeeGroup", "password123"),
            (customFee * 2 * 97) / 100
        );
    }

    function testInvalidEntryFees() public {
        string[] memory predictions = new string[](13);
        for (uint256 i = 0; i < 13; i++) {
            predictions[i] = string(abi.encodePacked("team", vm.toString(i)));
        }

        // Test entry fee of 0
        vm.prank(alice);
        vm.expectRevert(SportsBetting.InvalidEntryFee.selector);
        betting.createGroup("ZeroFeeGroup", "password123", 0);

        // Test entry fee above maximum
        uint256 tooHighFee = 0.2 ether; // Above 0.1 ETH limit
        vm.prank(alice);
        vm.expectRevert(SportsBetting.InvalidEntryFee.selector);
        betting.createGroup("HighFeeGroup", "password123", tooHighFee);

        // Test maximum allowed fee (should work)
        uint256 maxFee = betting.getMaxEntryFee();
        vm.prank(alice);
        betting.createGroup("MaxFeeGroup", "password123", maxFee);

        vm.prank(alice);
        betting.createBracket{value: maxFee}(
            predictions,
            "MaxFeeGroup",
            "password123",
            "Alice"
        );

        assertEq(
            betting.getGroupEntryFee("MaxFeeGroup", "password123"),
            maxFee
        );
    }

    function testWrongEntryFeeForExistingGroup() public {
        string[] memory predictions = new string[](13);
        for (uint256 i = 0; i < 13; i++) {
            predictions[i] = string(abi.encodePacked("team", vm.toString(i)));
        }

        uint256 groupFee = 0.0003 ether;

        // Create group with specific fee
        vm.prank(alice);
        betting.createGroup("FixedFeeGroup", "password123", groupFee);

        // Alice joins
        vm.prank(alice);
        betting.createBracket{value: groupFee}(
            predictions,
            "FixedFeeGroup",
            "password123",
            "TestUser"
        );

        // Bob tries to join with wrong fee amount
        vm.prank(bob);
        vm.expectRevert(SportsBetting.IncorrectEntryFeeAmount.selector);
        betting.createBracket{value: ENTRY_FEE}(
            predictions,
            "FixedFeeGroup",
            "password123",
            "Alice1"
        );

        // Bob joins with correct fee
        vm.prank(bob);
        betting.createBracket{value: groupFee}(
            predictions,
            "FixedFeeGroup",
            "password123",
            "Bob1"
        );

        assertEq(
            betting.getGroupMemberCount("FixedFeeGroup", "password123"),
            2
        );
    }

    function testGetGroupInfo() public {
        string[] memory predictions = new string[](13);
        for (uint256 i = 0; i < 13; i++) {
            predictions[i] = string(abi.encodePacked("team", vm.toString(i)));
        }

        // Test non-existent group
        (
            bool exists,
            uint256 entryFee,
            uint256 memberCount,
            bool isFull
        ) = betting.getGroupInfo("NonExistentGroup", "password123");
        assertFalse(exists);
        assertEq(entryFee, 0);
        assertEq(memberCount, 0);
        assertFalse(isFull);

        uint256 customFee = 0.0007 ether;

        // Create group and check info
        vm.prank(alice);
        betting.createGroup("InfoTestGroup", "password123", customFee);

        vm.prank(alice);
        betting.createBracket{value: customFee}(
            predictions,
            "InfoTestGroup",
            "password123",
            "Alice3"
        );

        (exists, entryFee, memberCount, isFull) = betting.getGroupInfo(
            "InfoTestGroup",
            "password123"
        );
        assertTrue(exists);
        assertEq(entryFee, customFee);
        assertEq(memberCount, 1);
        assertFalse(isFull);

        // Add more members
        vm.prank(bob);
        betting.createBracket{value: customFee}(
            predictions,
            "InfoTestGroup",
            "password123",
            "Bob3"
        );

        (exists, entryFee, memberCount, isFull) = betting.getGroupInfo(
            "InfoTestGroup",
            "password123"
        );
        assertTrue(exists);
        assertEq(entryFee, customFee);
        assertEq(memberCount, 2);
        assertFalse(isFull);

        // Test that anyone can call this function (no password required)
        address randomUser = makeAddr("randomUser");
        vm.prank(randomUser);
        (exists, entryFee, memberCount, isFull) = betting.getGroupInfo(
            "InfoTestGroup",
            "password123"
        );
        assertTrue(exists);
        assertEq(entryFee, customFee);
        assertEq(memberCount, 2);
        assertFalse(isFull);
    }

    function testGetGroupDataByOwner() public {
        string[] memory predictions = new string[](13);
        for (uint256 i = 0; i < 13; i++) {
            predictions[i] = string(abi.encodePacked("team", vm.toString(i)));
        }

        vm.prank(alice);
        betting.createGroup("OwnerGroup", "secretPassword", ENTRY_FEE);

        vm.prank(alice);
        betting.createBracket{value: ENTRY_FEE}(
            predictions,
            "OwnerGroup",
            "secretPassword",
            "AliceUser"
        );

        // Owner can access without password
        (address[] memory users, , , ) = betting.getGroupDataByOwner(
            "OwnerGroup"
        );
        assertEq(users.length, 1);
        assertEq(users[0], alice);

        // Non-owner cannot access
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                alice
            )
        );
        betting.getGroupDataByOwner("OwnerGroup");
    }

    function testViewFunctionsPasswordProtection() public {
        vm.prank(alice);
        betting.createGroup("ProtectedGroup", "correctPassword", ENTRY_FEE);

        // Test getGroupData with wrong password
        vm.expectRevert(SportsBetting.InvalidPassword.selector);
        betting.getGroupData("ProtectedGroup", "wrongPassword");

        // Test getGroupMembers with wrong password
        vm.expectRevert(SportsBetting.InvalidPassword.selector);
        betting.getGroupMembers("ProtectedGroup", "wrongPassword");

        // Test getGroupPrizePool with wrong password
        vm.expectRevert(SportsBetting.InvalidPassword.selector);
        betting.getGroupPrizePool("ProtectedGroup", "wrongPassword");

        // Test getGroupEntryFee with wrong password
        vm.expectRevert(SportsBetting.InvalidPassword.selector);
        betting.getGroupEntryFee("ProtectedGroup", "wrongPassword");

        // Test hasSubmittedGroupBracket with wrong password
        vm.expectRevert(SportsBetting.InvalidPassword.selector);
        betting.hasSubmittedGroupBracket(
            alice,
            "ProtectedGroup",
            "wrongPassword"
        );

        // Test getGroupMemberCount with wrong password
        vm.expectRevert(SportsBetting.InvalidPassword.selector);
        betting.getGroupMemberCount("ProtectedGroup", "wrongPassword");
    }

    function testDuplicateUsernameInGroup() public {
        string[] memory predictions = new string[](13);
        for (uint256 i = 0; i < 13; i++) {
            predictions[i] = string(abi.encodePacked("team", vm.toString(i)));
        }

        // Alice creates a group and joins with username "Player1"
        vm.prank(alice);
        betting.createGroup("UniqueNameGroup", "password123", ENTRY_FEE);

        vm.prank(alice);
        betting.createBracket{value: ENTRY_FEE}(
            predictions,
            "UniqueNameGroup",
            "password123",
            "Player1"
        );

        // Bob tries to join with the same username "Player1" - should fail
        vm.prank(bob);
        vm.expectRevert(SportsBetting.DuplicateUsername.selector);
        betting.createBracket{value: ENTRY_FEE}(
            predictions,
            "UniqueNameGroup",
            "password123",
            "Player1"
        );

        // Bob joins with a different username "Player2" - should succeed
        vm.prank(bob);
        betting.createBracket{value: ENTRY_FEE}(
            predictions,
            "UniqueNameGroup",
            "password123",
            "Player2"
        );

        // Verify both users are in the group
        assertEq(
            betting.getGroupMemberCount("UniqueNameGroup", "password123"),
            2
        );

        // Verify usernames are different in different groups
        vm.prank(alice);
        betting.createGroup("AnotherGroup", "pass456", ENTRY_FEE);

        // Charlie can use "Player1" in a different group
        address charlie = makeAddr("charlie");
        vm.deal(charlie, 1 ether);
        vm.prank(charlie);
        betting.createBracket{value: ENTRY_FEE}(
            predictions,
            "AnotherGroup",
            "pass456",
            "Player1"
        );

        assertEq(betting.getGroupMemberCount("AnotherGroup", "pass456"), 1);
    }

    function testDistributeGroupPrizesBatch() public {
        string[] memory predictions = new string[](13);
        for (uint256 i = 0; i < 13; i++) {
            predictions[i] = "TeamA";
        }

        // Create 5 groups with different participants
        for (uint256 g = 0; g < 5; g++) {
            string memory groupName = string(
                abi.encodePacked("BatchGroup", vm.toString(g))
            );
            string memory password = string(
                abi.encodePacked("pass", vm.toString(g))
            );

            vm.prank(alice);
            betting.createGroup(groupName, password, ENTRY_FEE);

            // Alice joins each group
            vm.prank(alice);
            betting.createBracket{value: ENTRY_FEE}(
                predictions,
                groupName,
                password,
                string(abi.encodePacked("Alice", vm.toString(g)))
            );

            // Bob joins groups 0, 1, 2 (not 3 and 4)
            if (g < 3) {
                vm.prank(bob);
                betting.createBracket{value: ENTRY_FEE}(
                    predictions,
                    groupName,
                    password,
                    string(abi.encodePacked("Bob", vm.toString(g)))
                );
            }
        }

        // Set all winners to complete the bracket
        string[] memory winners = new string[](13);
        for (uint256 i = 0; i < 13; i++) {
            winners[i] = "TeamA";
        }
        betting.setAllWinners(winners);

        // Record balances before payout
        uint256 aliceBalanceBefore = alice.balance;

        // Get total group count
        uint256 totalGroups = betting.getTotalGroupCount();
        assertEq(totalGroups, 5);

        // Distribute prizes for first 3 groups (batch 0-2)
        betting.distributeGroupPrizesBatch(0, 3);

        // Alice and Bob should have won groups 0, 1, 2 (tied, Alice joined first)
        assertGt(alice.balance, aliceBalanceBefore);

        // Verify first 3 groups have been paid out (totalPot = 0)
        assertEq(betting.getGroupPrizePool("BatchGroup0", "pass0"), 0);
        assertEq(betting.getGroupPrizePool("BatchGroup1", "pass1"), 0);
        assertEq(betting.getGroupPrizePool("BatchGroup2", "pass2"), 0);

        // Verify groups 3 and 4 still have prize pools
        assertGt(betting.getGroupPrizePool("BatchGroup3", "pass3"), 0);
        assertGt(betting.getGroupPrizePool("BatchGroup4", "pass4"), 0);

        // Record balance after first batch
        uint256 aliceBalanceAfterBatch1 = alice.balance;

        // Distribute remaining groups (batch 3-4)
        betting.distributeGroupPrizesBatch(3, 2);

        // Alice should have won groups 3 and 4 (only participant)
        assertGt(alice.balance, aliceBalanceAfterBatch1);

        // Verify all groups have been paid out
        assertEq(betting.getGroupPrizePool("BatchGroup3", "pass3"), 0);
        assertEq(betting.getGroupPrizePool("BatchGroup4", "pass4"), 0);

        // Test calling batch again - should not fail (skips groups with 0 pot)
        betting.distributeGroupPrizesBatch(0, 5);

        // Test with batch size larger than remaining groups
        betting.distributeGroupPrizesBatch(0, 100);
    }
}
