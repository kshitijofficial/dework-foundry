// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Test} from "forge-std/Test.sol";
import {Dework} from "../src/Dework.sol";

contract DeworkTest is Test {

    Dework public dework;
    address initialOwner = makeAddr("owner");

    function setUp() public { 
         dework = new Dework(initialOwner);
    }

    function testOwnerIsInitialized() public view{
         address contractOwner = dework.owner();
         assertEq(initialOwner,contractOwner);
    }

}
