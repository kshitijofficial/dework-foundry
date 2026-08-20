// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.34;

import {Script} from "forge-std/Script.sol";
import {Dework} from "../src/Dework.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {console2} from "forge-std/console2.sol";

contract DeworkScript is Script {
    function run() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast();
        Dework dework = new Dework(config.initialOwner);
        vm.stopBroadcast();

        console2.log("Dework deployed at:", address(dework));
    }
}
