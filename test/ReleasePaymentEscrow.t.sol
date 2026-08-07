// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Test} from "forge-std/Test.sol";
import {Dework} from "../src/Dework.sol";
import {CreateJobListingInput, JobListing} from "../src/types/DeworkTypes.sol";

contract ReleaseEscrowPayment is Test {
    Dework public dework;
    address employer = makeAddr("employer");
    address freelancer = makeAddr("freelancer");
    address initialOwner = makeAddr("owner");

    uint256 constant EMPLOYER_ID_UNDER_TEST = 0;
    uint256 constant FREELANCER_ID_UNDER_TEST = 0;
    uint256 constant JOB_ID_UNDER_TEST = 0;
    uint256 constant LATE_PENALITY_BPS_PER_DAY = 500;
    uint256 constant BPS_DENOMINATOR = 10000;

    function _hireFreelancer() internal {
        vm.prank(employer);
        dework.hireFreelancer(EMPLOYER_ID_UNDER_TEST, FREELANCER_ID_UNDER_TEST, JOB_ID_UNDER_TEST);
    }

    function _createJobListing() internal {
        CreateJobListingInput memory jobListing = CreateJobListingInput({
            title: "Solidity Developer", description: "Skilled Worker", deadlineTimestamp: 100, fixedPriceInWei: 10
        });
        vm.deal(employer, 1 ether);
        vm.prank(employer);
        dework.createJobListing{value: 10}(EMPLOYER_ID_UNDER_TEST, jobListing);
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

    function test_releaseEscrow_OnTimeSubmission() public {
        uint256 freelancerBeforeBalance = freelancer.balance;
        JobListing[] memory jobList = dework.getJobList(EMPLOYER_ID_UNDER_TEST);

        vm.prank(employer);
        dework.releaseEscrowPayment(EMPLOYER_ID_UNDER_TEST, FREELANCER_ID_UNDER_TEST, JOB_ID_UNDER_TEST);

        uint256 freelancerAfterBalance = freelancer.balance;
        assertEq(freelancerAfterBalance - freelancerBeforeBalance, jobList[JOB_ID_UNDER_TEST].fixedPriceInWei);
    }

    function test_releaseEscrow_AfterDeadlineSubmission() public {
        uint256 freelancerBeforeBalance = freelancer.balance;
        uint256 delayInCompletion = 2 days;
        uint256 delayInDays = _warpPastDeadline(EMPLOYER_ID_UNDER_TEST, JOB_ID_UNDER_TEST, delayInCompletion);

        vm.prank(employer);
        dework.releaseEscrowPayment(EMPLOYER_ID_UNDER_TEST, FREELANCER_ID_UNDER_TEST, JOB_ID_UNDER_TEST);

        uint256 freelancerAfterBalance = freelancer.balance;

        uint256 expectedPay = _calculateExpectedPayment(EMPLOYER_ID_UNDER_TEST, JOB_ID_UNDER_TEST, delayInDays);
        assertEq(freelancerAfterBalance - freelancerBeforeBalance, expectedPay);
    }

    function _warpPastDeadline(uint256 employerId, uint256 jobId, uint256 delay)
        internal
        returns (uint256 delayInDays)
    {
        JobListing[] memory jobList = dework.getJobList(employerId);
        uint256 deadline = jobList[jobId].deadlineTimestamp;
        vm.warp(deadline + delay);
        // Round up to the nearest day
        delayInDays = (delay + 1 days - 1) / 1 days;
    }

    function _calculateExpectedPayment(uint256 employerId, uint256 jobId, uint256 delayInDays)
        internal
        view
        returns (uint256)
    {
        JobListing[] memory jobList = dework.getJobList(employerId);

        uint256 amountToPay = jobList[jobId].fixedPriceInWei;
        uint256 deductionBps = delayInDays * LATE_PENALITY_BPS_PER_DAY;

        return amountToPay - (amountToPay * deductionBps) / BPS_DENOMINATOR;
    }
}
