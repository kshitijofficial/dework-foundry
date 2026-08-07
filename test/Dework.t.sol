// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Test} from "forge-std/Test.sol";
import {Dework} from "../src/Dework.sol";
import {FreelancerProfile, CreateJobListingInput, JobListing} from "../src/types/DeworkTypes.sol";
//TODO: create test for employerRegistration
//testCreateJobListingRevertsWhenEmployerSendWrongJobCreationFee
//test hireFreelancer function - different scenerio - happy path testing and sad path testing

contract DeworkTest is Test {
    Dework public dework;
    address initialOwner = makeAddr("owner");

    error Dework_UnauthourizedEmployer(uint256 employerId, address caller);

    function setUp() public {
        dework = new Dework(initialOwner);
    }

    function testOwnerIsInitialized() public view {
        address contractOwner = dework.owner();
        assertEq(initialOwner, contractOwner);
    }

    function testRegisterFreelancerProfile() public {
        //Arrange
        string memory name = "Kshitij";
        uint8 experienceYears = 20;
        uint256 hourlyRateWei = 100;
        uint256 freelancerId = dework.getNumberOfRegisteredFreelancers();
        address freelancerAddr = makeAddr("freelancerAddr");

        //ACT
        vm.prank(freelancerAddr);
        dework.registerFreelancerProfile(name, experienceYears, hourlyRateWei);
        FreelancerProfile memory freelancer = dework.getFreelancerProfile(freelancerId);

        //ASSERT
        assertEq(freelancer.id, freelancerId);
        assertEq(freelancer.hourlyRateWei, hourlyRateWei);
        assertEq(freelancer.experienceYears, experienceYears);
        assertEq(freelancer.isAvailableHire, true);
        assertEq(freelancer.wallet, freelancerAddr);
    }

    function testCreateJobListingRevertsWhenEmployerIsNotRegistered() public {
        address employer = makeAddr("employer");
        uint256 unRegisteredEmployerId = 100;
        CreateJobListingInput memory jobListing = CreateJobListingInput({
            title: "Solidity Developer", description: "Skilled Worker", deadlineTimestamp: 100, fixedPriceInWei: 10
        });

        vm.prank(employer);
        vm.expectRevert(abi.encodeWithSelector(Dework_UnauthourizedEmployer.selector, unRegisteredEmployerId, employer));
        dework.createJobListing(unRegisteredEmployerId, jobListing);
    }

    function testCreateJobListingWhenEmployerIsRegistered() public {
        address employer = makeAddr("employer");
        vm.deal(employer, 1 ether);
        vm.startPrank(employer);
        dework.registerEmployerProfile("Raju");
        uint256 employreIdRaju = 0;
        CreateJobListingInput memory jobListing = CreateJobListingInput({
            title: "Solidity Developer", description: "Skilled Worker", deadlineTimestamp: 100, fixedPriceInWei: 10
        });
        uint256 contractBeforeBalance = address(dework).balance;

        dework.createJobListing{value: 10}(employreIdRaju, jobListing);

        vm.stopPrank();
        uint256 contractAfterBalance = address(dework).balance;
        JobListing[] memory jobList = dework.getJobList(employreIdRaju);
        assertEq(contractAfterBalance - contractBeforeBalance, 10);
        assertEq(jobList[0].title, "Solidity Developer");
        //TODO: assert other fields of jobList
    }
}
