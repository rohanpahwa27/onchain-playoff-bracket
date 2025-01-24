// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Attendance} from "../src/Attendance.sol";

contract Deploy is Script {
    function run() public {
        vm.startBroadcast();

        new Attendance();

        vm.stopBroadcast();
    }
}
