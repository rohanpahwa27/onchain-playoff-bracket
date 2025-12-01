// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SportsBetting} from "../contracts/SportsBetting.sol";

contract GroupDataExample is Test {
    SportsBetting public betting;
    uint256 public constant ENTRY_FEE = 0.000001 ether;

    function setUp() public {
        betting = new SportsBetting();
    }

    function testExampleGetGroupData() public {
        // 1. Setup Users
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        address charlie = makeAddr("charlie");
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
        vm.deal(charlie, 1 ether);

        // 2. Create Group
        vm.prank(alice);
        betting.createGroup("NFL_Playoffs_2025", "password123", ENTRY_FEE);

        // 3. Create dummy predictions based on user's bracket structure
        // WC 1 AFC (BUF v DEN), WC 2 AFC (BAL v PIT), WC 3 AFC (HOU v LAC)
        // WC 1 NFC (PHI v GB), WC 2 NFC (TB v WAS), WC 3 NFC (LAR v MIN)

        string[] memory predictionsA = new string[](13);
        // Alice's Picks (Favorites)
        predictionsA[0] = "BUF"; // WC 1 AFC
        predictionsA[1] = "BAL"; // WC 2 AFC
        predictionsA[2] = "HOU"; // WC 3 AFC
        predictionsA[3] = "PHI"; // WC 1 NFC
        predictionsA[4] = "TB"; // WC 2 NFC
        predictionsA[5] = "LAR"; // WC 3 NFC
        // Divisional
        predictionsA[6] = "BUF";
        predictionsA[7] = "BAL";
        predictionsA[8] = "PHI";
        predictionsA[9] = "TB";
        // Conference
        predictionsA[10] = "BUF";
        predictionsA[11] = "PHI";
        // Super Bowl
        predictionsA[12] = "BUF";

        string[] memory predictionsB = new string[](13);
        // Bob's Picks (Underdogs)
        predictionsB[0] = "DEN"; // WC 1 AFC
        predictionsB[1] = "PIT"; // WC 2 AFC
        predictionsB[2] = "LAC"; // WC 3 AFC
        predictionsB[3] = "GB"; // WC 1 NFC
        predictionsB[4] = "WAS"; // WC 2 NFC
        predictionsB[5] = "MIN"; // WC 3 NFC
        // Divisional
        predictionsB[6] = "DEN";
        predictionsB[7] = "PIT";
        predictionsB[8] = "GB";
        predictionsB[9] = "WAS";
        // Conference
        predictionsB[10] = "DEN";
        predictionsB[11] = "GB";
        // Super Bowl
        predictionsB[12] = "GB";

        // 4. Users join group
        vm.prank(alice);
        betting.createBracket{value: ENTRY_FEE}(
            predictionsA,
            "NFL_Playoffs_2025",
            "password123",
            "Alice_BillsFan"
        );

        vm.prank(bob);
        betting.createBracket{value: ENTRY_FEE}(
            predictionsB,
            "NFL_Playoffs_2025",
            "password123",
            "Bob_PackersFan"
        );

        // 5. Set some winners (Round 1)
        // Let's say BUF, PIT, HOU, GB, TB, LAR won
        betting.updateWinner(1, "BUF");
        betting.updateWinner(1, "PIT");
        betting.updateWinner(1, "HOU");
        betting.updateWinner(1, "GB");
        betting.updateWinner(1, "TB");
        betting.updateWinner(1, "LAR");

        // 6. Pause brackets to view scores and predictions
        betting.pauseBracketCreation();

        // 7. Call getGroupData
        (
            address[] memory users,
            uint256[] memory scores,
            string[] memory usernames,
            string[][][] memory allPredictions
        ) = betting.getGroupData("NFL_Playoffs_2025", "password123");

        // 7. Log Results
        console.log("=== NFL Playoff Group Data ===");
        console.log("Group: NFL_Playoffs_2025");
        console.log("Member Count:", users.length);
        console.log("--------------------------");

        for (uint i = 0; i < users.length; i++) {
            console.log("User:", usernames[i]);
            console.log("Score:", scores[i]);

            console.log("Wildcard Picks:");
            string[] memory r1 = allPredictions[i][0];
            console.log("  AFC 1:", r1[0]);
            console.log("  AFC 2:", r1[1]);
            console.log("  AFC 3:", r1[2]);
            console.log("  NFC 1:", r1[3]);
            console.log("  NFC 2:", r1[4]);
            console.log("  NFC 3:", r1[5]);

            console.log("Divisional Picks:");
            string[] memory r2 = allPredictions[i][1];
            console.log("  AFC 1:", r2[0]);
            console.log("  AFC 2:", r2[1]);
            console.log("  NFC 1:", r2[2]);
            console.log("  NFC 2:", r2[3]);

            console.log("Conference Picks:");
            string[] memory r3 = allPredictions[i][2];
            console.log("  AFC:", r3[0]);
            console.log("  NFC:", r3[1]);

            console.log("Super Bowl Pick:");
            string[] memory r4 = allPredictions[i][3];
            console.log("  Winner:", r4[0]);
            console.log("--------------------------");
        }
    }
}
