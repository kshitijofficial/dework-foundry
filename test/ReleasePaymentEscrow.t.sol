// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Test} from "forge-std/Test.sol";
import {Dework} from "../src/Dework.sol";
import {FreelancerProfile, CreateJobListingInput,JobListing} from "../src/types/DeworkTypes.sol";
import "forge-std/console.sol"; 

contract ReleaseEscrowPayment is Test {
    Dework public dework;
    address employer = makeAddr("employer");
    address freelancer = makeAddr("freelancer");
    address initialOwner = makeAddr("owner");

    uint256 constant EMPLOYER_ID_UNDER_TEST = 0;
    uint256 constant FREELANCER_ID_UNDER_TEST = 0;
    uint256 constant JOB_ID_UNDER_TEST = 0;
    uint256 constant LATE_PENALITY_BPS_PER_DAY = 500;
    uint256 public BPS_DENOMINATOR = 10000;
    

    function _hireFreelancer() internal {
        vm.prank(employer);
        dework.hireFreelancer(EMPLOYER_ID_UNDER_TEST,FREELANCER_ID_UNDER_TEST,JOB_ID_UNDER_TEST);
    }
    function _createJobListing() internal {
        CreateJobListingInput memory jobListing = CreateJobListingInput({
            title: "Solidity Developer", description: "Skilled Worker", deadlineTimestamp: 100, fixedPriceInWei: 10
        });
        vm.deal(employer,1 ether);
        vm.prank(employer);
        dework.createJobListing{value:10}(EMPLOYER_ID_UNDER_TEST,jobListing);
    }
    function _registerFreelancer() internal {
        string memory name = "Kshitij";
        uint8 experienceYears = 20;
        uint256 hourlyRateWei = 100;

        vm.prank(freelancer);
        dework.registerFreelancerProfile(name, experienceYears, hourlyRateWei);
    }

    function _registerEmployer() internal {
         vm.prank(employer);
         dework.registerEmployerProfile("Raju");
    }

    function setUp() public {
        dework = new Dework(initialOwner);
        _registerEmployer();
        _registerFreelancer();
        _createJobListing();
        _hireFreelancer();
    }

    function test_releaseOfEscrowPaymentToFreelancerWhenWorkIsSubmittedOnTime() public{
        uint256 freelancerBeforeBalance = freelancer.balance;
        
        vm.prank(employer);
        dework.releaseEscrowPayment(EMPLOYER_ID_UNDER_TEST,FREELANCER_ID_UNDER_TEST,JOB_ID_UNDER_TEST);
        
        uint256 freelancerAfterBalance = freelancer.balance;
        JobListing[] memory jobList = dework.getJobList(EMPLOYER_ID_UNDER_TEST);
        assertEq(freelancerAfterBalance-freelancerBeforeBalance,jobList[JOB_ID_UNDER_TEST].fixedPriceInWei);
    }

    function test_releaseOfEscrowPaymentToFreelancerWhenWorkIsSubmittedOnAfterDeadline() public{
        uint256 freelancerBeforeBalance = freelancer.balance;
        JobListing[] memory jobList = dework.getJobList(EMPLOYER_ID_UNDER_TEST);
        uint256 jobDeadline = jobList[JOB_ID_UNDER_TEST].deadlineTimestamp;
        uint256 delayInCompletion = 2 days;
        uint256 delayInDays = (delayInCompletion + 1 days - 1) / 1 days;
        vm.warp(jobDeadline+delayInCompletion);

        vm.prank(employer);
        dework.releaseEscrowPayment(EMPLOYER_ID_UNDER_TEST,FREELANCER_ID_UNDER_TEST,JOB_ID_UNDER_TEST);
        
        uint256 freelancerAfterBalance = freelancer.balance;
        uint256 amountToPay = jobList[JOB_ID_UNDER_TEST].fixedPriceInWei;
        uint256 deductionBps = delayInDays * LATE_PENALITY_BPS_PER_DAY;
        uint256 expectedPay = amountToPay - (amountToPay * deductionBps) / BPS_DENOMINATOR;
        assertEq(freelancerAfterBalance-freelancerBeforeBalance,expectedPay);
    }
    

}
   