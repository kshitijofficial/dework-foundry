// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.34;
import {FreelancerProfile, EmployerProfile, CreateJobListingInput, JobListing} from "./types/DeworkTypes.sol";


contract Dework {
    uint256 public constant LATE_PENALITY_BPS_PER_DAY = 500; //500/10000 = 5%
    uint256 public constant BPS_DENOMINATOR = 10000; //100%

    uint256 connectFee;
    address public owner;

    FreelancerProfile[] public freelancerProfiles;
    EmployerProfile[] public employerProfiles;

    mapping(uint256 => address) public freelancerIdToAddress;
    mapping(uint256 => address) public employerIdToAddress;
    mapping(uint256 => uint256) public employerBalance;

    event FreelancerProfileRegistered(uint256 freelancerId, address caller);
    event EmployerProfileRegistered(uint256 employerId, address caller);
    
    error Dework_IncorrectJobCreationFee(uint256 expectedFee, uint256 actualFee);
    error Dework_JobClosed(uint256 jobId);
    error Dework_UnauthourizedEmployer(uint256 employerId, address caller);
    error Dework_UnauthourizedFreelancer(uint256 freelancerId, address caller);
    error Dework_InvalidJobId(uint256 employerId, uint256 jobId);
    error Dework_NotEnoughBalance(uint256 employerId, uint256 employerBalance);
    error Dework_FreelancerIdMismatch(uint256 expectedFreelancerId, uint256 actualFeelancerId);
    error Dework_JobIsAlreadyPaid(uint256 jobId);
    error Dework_PaymentToFreelancerFailed(address freelancer, uint256 amountSent);
    error Dework_NotAuthourisedOwner();


    constructor(address _initialOwner) {
        owner = _initialOwner;
    }

    modifier onlyAuthourizedOwner(address newOwner) {
        if (owner != msg.sender) {
            revert Dework_NotAuthourisedOwner();
        }
        _;
    }

    modifier onlyAuthourizedEmployer(uint256 employerId) {
        address employer = employerIdToAddress[employerId];
        if (employer != msg.sender || employer == address(0)) {
            revert Dework_UnauthourizedEmployer(employerId, msg.sender);
        }
        _;
    }

    modifier validateFreelancerId(uint256 freelancerId) {
        if (freelancerId >= getNumberOfRegisteredFreelancers() || freelancerIdToAddress[freelancerId] == address(0)) {
            revert Dework_UnauthourizedFreelancer(freelancerId, msg.sender);
        }
        _;
    }

    modifier validateJobId(uint256 employerId, uint256 jobId) {
        if (jobId >= getNumberOfCreatedJobList(employerId)) {
            revert Dework_InvalidJobId(employerId, jobId);
        }
        _;
    }

    function getFreelancerProfile(uint256 freelancerId) public view returns (FreelancerProfile memory) {
        return freelancerProfiles[freelancerId];
    }

    function getNumberOfRegisteredFreelancers() public view returns (uint256) {
        return freelancerProfiles.length;
    }

    function registerFreelancerProfile(string calldata name, uint8 experienceYears, uint256 hourlyRateWei) external {
        uint256 freelancerId = getNumberOfRegisteredFreelancers();

        FreelancerProfile memory freelancerProfile = FreelancerProfile({
            id: freelancerId,
            name: name,
            wallet: msg.sender,
            experienceYears: experienceYears,
            isAvailableHire: true,
            hourlyRateWei: hourlyRateWei
        });
        freelancerProfiles.push(freelancerProfile);
        freelancerIdToAddress[freelancerId] = msg.sender;

        emit FreelancerProfileRegistered(freelancerId, msg.sender);
    }

    function getNumberOfRegisteredEmployers() public view returns (uint256) {
        return employerProfiles.length;
    }

    function registerEmployerProfile(string calldata employerName) external {
        uint256 employerId = getNumberOfRegisteredEmployers();
        EmployerProfile memory employerProfile = EmployerProfile({
            id: employerId, name: employerName, isHiring: false, wallet: msg.sender, jobListing: new JobListing[](0)
        });
        employerProfiles.push(employerProfile);
        employerIdToAddress[employerId] = msg.sender;
        emit FreelancerProfileRegistered(employerId, msg.sender);
    }

    function getNumberOfCreatedJobList(uint256 employerId) public view returns (uint256) {
        return employerProfiles[employerId].jobListing.length;
    }

    function _getEmployerProfile(uint256 employerId) internal view returns (EmployerProfile storage) {
        return employerProfiles[employerId];
    }

    function createJobListing(uint256 employerId, CreateJobListingInput calldata jobListingInput)
        external
        payable
        onlyAuthourizedEmployer(employerId)
    {
        uint256 fixedPriceForJob = jobListingInput.fixedPriceInWei;

        if (msg.value != fixedPriceForJob) {
            revert Dework_IncorrectJobCreationFee(fixedPriceForJob, msg.value);
        }

        EmployerProfile storage employerProfile = _getEmployerProfile(employerId);
        uint256 jobId = getNumberOfCreatedJobList(employerId);

        JobListing memory newJob = JobListing({
            id: jobId,
            title: jobListingInput.title,
            description: jobListingInput.description,
            deadlineTimestamp: block.timestamp + jobListingInput.deadlineTimestamp,
            isOpen: true,
            fixedPriceInWei: jobListingInput.fixedPriceInWei,
            hiredFreelancerId: 0,
            hasHiredFreelancer: false,
            isPaid: false
        });

        employerBalance[employerId] += jobListingInput.fixedPriceInWei;
        employerProfile.jobListing.push(newJob);
        //    employerProfiles[employerId].jobListing.push(newJob);
    }

    function _requireJobIsOpen(JobListing memory job) internal pure {
        if (job.isOpen != true) {
            revert Dework_JobClosed(job.id);
        }
    }

    function _getJob(uint256 employerId, uint256 jobId) internal view returns (JobListing storage) {
        return employerProfiles[employerId].jobListing[jobId];
    }

    function getJobList(uint256 employerId) external view returns (JobListing[] memory) {
        return employerProfiles[employerId].jobListing;
    }

    function hireFreelancer(uint256 employerId, uint256 freelancerId, uint256 jobId)
        public
        onlyAuthourizedEmployer(employerId)
        validateJobId(employerId, jobId)
        validateFreelancerId(freelancerId)
    {
        JobListing storage job = _getJob(employerId, jobId);
        _requireJobIsOpen(job);
        job.hiredFreelancerId = freelancerId;
        job.hasHiredFreelancer = true;
        job.isOpen = false;
    }

    function _sendPaymentToFreelancer(address freelancer, uint256 amountToSend) internal {
        (bool success,) = freelancer.call{value: amountToSend}("");
        if (success == false) {
            revert Dework_PaymentToFreelancerFailed(freelancer, amountToSend);
        }
    }

    function _calculatePayment(uint256 amountToSend, uint256 jobDeadlineTimestamp) internal view returns (uint256) {
        if (block.timestamp <= jobDeadlineTimestamp) {
            return amountToSend;
        }
        uint256 delayInCompletion = block.timestamp - jobDeadlineTimestamp;

        // Ceil division: rounds up to the next full day instead of truncating
        uint256 delayInDays = (delayInCompletion + 1 days - 1) / 1 days;

        uint256 deductionBps = delayInDays * LATE_PENALITY_BPS_PER_DAY; //500

        if (deductionBps > BPS_DENOMINATOR) {
            deductionBps = BPS_DENOMINATOR;
        }

        uint256 deductionAmount = (amountToSend * deductionBps) / BPS_DENOMINATOR; //(2000 * 500)/10000 = 100

        return amountToSend - deductionAmount; //2000 - 100 = 19000
    }

    function releaseEscrowPayment(uint256 employerId, uint256 jobId, uint256 freelancerId)
        public
        onlyAuthourizedEmployer(employerId)
        validateJobId(employerId, jobId)
        validateFreelancerId(freelancerId)
    {
        JobListing storage job = _getJob(employerId, jobId);
        uint256 amountToSend = job.fixedPriceInWei;

        if (employerBalance[employerId] < amountToSend) {
            revert Dework_NotEnoughBalance(employerId, employerBalance[employerId]);
        }

        if (freelancerId != job.hiredFreelancerId) {
            revert Dework_FreelancerIdMismatch(job.hiredFreelancerId, freelancerId);
        }

        if (job.isPaid == true) {
            revert Dework_JobIsAlreadyPaid(job.id);
        }

        job.isPaid = true;
        employerBalance[employerId] -= amountToSend;
        uint256 paymentAmount = _calculatePayment(amountToSend, job.deadlineTimestamp);
        _sendPaymentToFreelancer(freelancerIdToAddress[freelancerId], paymentAmount);
    }

    function modifyOwner(address newOwner) external onlyAuthourizedOwner(newOwner) {
        owner = newOwner;
    }

    function withdrawAmount(uint256 employerId, uint256 withdrawalAmount) external onlyAuthourizedEmployer(employerId) {
        if (employerBalance[employerId] < withdrawalAmount) {
            revert Dework_NotEnoughBalance(employerId, employerBalance[employerId]);
        }
        employerBalance[employerId] -= withdrawalAmount;
        (bool success,) = employerIdToAddress[employerId].call{value: withdrawalAmount}("");
        //TODO: Change it with revert statement
        require(success == false, "Transfer failed to employer");
    }
}

