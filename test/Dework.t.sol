// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Test} from "forge-std/Test.sol";
import {Dework} from "../src/Dework.sol";
import {FreelancerProfile} from "../src/types/DeworkTypes.sol";

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

    function testRegisterFreelancerProfile() public{
        //Arrange
        string memory name = "Kshitij";
        uint8 experienceYears = 20;
        uint256 hourlyRateWei = 100;
        uint256 freelancerId = dework.getNumberOfRegisteredFreelancers();
        address freelancerAddr = makeAddr("freelancerAddr");
        
        //ACT
        vm.prank(freelancerAddr);
        dework.registerFreelancerProfile(name,experienceYears,hourlyRateWei);
        FreelancerProfile memory freelancer = dework.getFreelancerProfile(freelancerId);
        
        //ASSERT
        assertEq(freelancer.id,freelancerId);
        assertEq(freelancer.hourlyRateWei,hourlyRateWei);
        assertEq(freelancer.experienceYears,experienceYears);
        assertEq(freelancer.isAvailableHire,true);
        assertEq(freelancer.wallet,freelancerAddr);
    }



}
