// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SportsBetting} from "../contracts/SportsBetting.sol";

contract Deploy is Script {
    SportsBetting public sportsBetting;

    function run() public {
        vm.startBroadcast();
        sportsBetting = new SportsBetting();
        vm.stopBroadcast();
    }
}
