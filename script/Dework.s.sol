// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Dework} from "../src/Dework.sol";
import {console2} from "forge-std/console2.sol";

contract DeworkScript is Script {
    Dework public dework;

    function setUp() public {}

    function run() public {
        address owner = makeAddr("owner");
        vm.startBroadcast();
        dework = new Dework(owner);
        vm.stopBroadcast();
        console2.log("Dework deployed at:", address(dework));
    }

}
