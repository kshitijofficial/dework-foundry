// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.34;
import {FreelancerProfile, EmployerProfile, CreateJobListingInput, JobListing} from "./types/DeworkTypes.sol";

contract Dework {
    uint256 public constant LATE_PENALITY_BPS_PER_DAY = 500;
    uint256 public constant BPS_DENOMINATOR = 10000;

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

    function registerFreelancerProfile(string calldata name, uint8 experienceYears, uint256 hourlyRateWei) external {
        uint256 freelancerId = getNumberOfRegisteredFreelancers();
        FreelancerProfile memory freelancerProfile = _buildFreelancerProfile(
            freelancerId, name, experienceYears, hourlyRateWei
        );
        _storeFreelancerProfile(freelancerProfile);
    }

    function _buildFreelancerProfile(
        uint256 freelancerId,
        string calldata name,
        uint8 experienceYears,
        uint256 hourlyRateWei
    ) internal view returns (FreelancerProfile memory) {
        return FreelancerProfile({
            id: freelancerId,
            name: name,
            wallet: msg.sender,
            experienceYears: experienceYears,
            isAvailableHire: true,
            hourlyRateWei: hourlyRateWei
        });
    }

    function _storeFreelancerProfile(FreelancerProfile memory freelancerProfile) internal {
        freelancerProfiles.push(freelancerProfile);
        freelancerIdToAddress[freelancerProfile.id] = msg.sender;
        emit FreelancerProfileRegistered(freelancerProfile.id, msg.sender);
    }

    function getFreelancerProfile(uint256 freelancerId) public view returns (FreelancerProfile memory) {
        return freelancerProfiles[freelancerId];
    }

    function getNumberOfRegisteredFreelancers() public view returns (uint256) {
        return freelancerProfiles.length;
    }

    function registerEmployerProfile(string calldata employerName) external {
        uint256 employerId = getNumberOfRegisteredEmployers();
        EmployerProfile memory employerProfile = _buildEmployerProfile(employerId, employerName);
        _storeEmployerProfile(employerProfile);
    }

    function _buildEmployerProfile(uint256 employerId, string calldata employerName)
        internal
        view
        returns (EmployerProfile memory)
    {
        return EmployerProfile({
            id: employerId, name: employerName, isHiring: false, wallet: msg.sender, jobListing: new JobListing[](0)
        });
    }

    function _storeEmployerProfile(EmployerProfile memory employerProfile) internal {
        employerProfiles.push(employerProfile);
        employerIdToAddress[employerProfile.id] = msg.sender;
        emit FreelancerProfileRegistered(employerProfile.id, msg.sender);
    }

    function getNumberOfRegisteredEmployers() public view returns (uint256) {
        return employerProfiles.length;
    }

    function createJobListing(uint256 employerId, CreateJobListingInput calldata jobListingInput)
        external
        payable
        onlyAuthourizedEmployer(employerId)
    {
        _requireCorrectJobCreationFee(jobListingInput.fixedPriceInWei);

        EmployerProfile storage employerProfile = _getEmployerProfile(employerId);
        JobListing memory newJob = _buildJobListing(employerId, jobListingInput);

        _fundEmployerEscrow(employerId, jobListingInput.fixedPriceInWei);
        employerProfile.jobListing.push(newJob);
    }

    function _requireCorrectJobCreationFee(uint256 fixedPriceForJob) internal view {
        if (msg.value != fixedPriceForJob) {
            revert Dework_IncorrectJobCreationFee(fixedPriceForJob, msg.value);
        }
    }

    function _buildJobListing(uint256 employerId, CreateJobListingInput calldata jobListingInput)
        internal
        view
        returns (JobListing memory)
    {
        return JobListing({
            id: getNumberOfCreatedJobList(employerId),
            title: jobListingInput.title,
            description: jobListingInput.description,
            deadlineTimestamp: block.timestamp + jobListingInput.deadlineTimestamp,
            isOpen: true,
            fixedPriceInWei: jobListingInput.fixedPriceInWei,
            hiredFreelancerId: 0,
            hasHiredFreelancer: false,
            isPaid: false
        });
    }

    function _fundEmployerEscrow(uint256 employerId, uint256 amount) internal {
        employerBalance[employerId] += amount;
    }

    function getNumberOfCreatedJobList(uint256 employerId) public view returns (uint256) {
        return employerProfiles[employerId].jobListing.length;
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
        _hireFreelancerForJob(job, freelancerId);
    }

    function _hireFreelancerForJob(JobListing storage job, uint256 freelancerId) internal {
        _requireJobIsOpen(job);
        job.hiredFreelancerId = freelancerId;
        job.hasHiredFreelancer = true;
        job.isOpen = false;
    }

    function _requireJobIsOpen(JobListing memory job) internal pure {
        if (job.isOpen != true) {
            revert Dework_JobClosed(job.id);
        }
    }

    function releaseEscrowPayment(uint256 employerId, uint256 jobId, uint256 freelancerId)
        public
        onlyAuthourizedEmployer(employerId)
        validateJobId(employerId, jobId)
        validateFreelancerId(freelancerId)
    {
        JobListing storage job = _getJob(employerId, jobId);
        uint256 amountToSend = job.fixedPriceInWei;

        _requireEnoughEmployerBalance(employerId, amountToSend);
        _requireFreelancerMatchesJob(job, freelancerId);
        _requireJobIsNotPaid(job);
        _markJobPaid(job);
        _releasePaymentToFreelancer(employerId, freelancerId, amountToSend, job.deadlineTimestamp);
    }

    function _requireEnoughEmployerBalance(uint256 employerId, uint256 amountToSend) internal view {
        if (employerBalance[employerId] < amountToSend) {
            revert Dework_NotEnoughBalance(employerId, employerBalance[employerId]);
        }
    }

    function _requireFreelancerMatchesJob(JobListing memory job, uint256 freelancerId) internal pure {
        if (freelancerId != job.hiredFreelancerId) {
            revert Dework_FreelancerIdMismatch(job.hiredFreelancerId, freelancerId);
        }
    }

    function _requireJobIsNotPaid(JobListing memory job) internal pure {
        if (job.isPaid == true) {
            revert Dework_JobIsAlreadyPaid(job.id);
        }
    }

    function _markJobPaid(JobListing storage job) internal {
        job.isPaid = true;
    }

    function _releasePaymentToFreelancer(
        uint256 employerId,
        uint256 freelancerId,
        uint256 amountToSend,
        uint256 jobDeadlineTimestamp
    ) internal {
        employerBalance[employerId] -= amountToSend;
        uint256 paymentAmount = _calculatePayment(amountToSend, jobDeadlineTimestamp);
        _sendPaymentToFreelancer(freelancerIdToAddress[freelancerId], paymentAmount);
    }

    function _calculatePayment(uint256 amountToSend, uint256 jobDeadlineTimestamp) internal view returns (uint256) {
        if (block.timestamp <= jobDeadlineTimestamp) {
            return amountToSend;
        }
        uint256 delayInCompletion = block.timestamp - jobDeadlineTimestamp;
        // Ceil division: rounds up to the next full day instead of truncating
        uint256 delayInDays = (delayInCompletion + 1 days - 1) / 1 days;
        uint256 deductionBps = delayInDays * LATE_PENALITY_BPS_PER_DAY;
        if (deductionBps > BPS_DENOMINATOR) {
            deductionBps = BPS_DENOMINATOR;
        }
        uint256 deductionAmount = (amountToSend * deductionBps) / BPS_DENOMINATOR;
        return amountToSend - deductionAmount;
    }

    function _sendPaymentToFreelancer(address freelancer, uint256 amountToSend) internal {
        (bool success,) = freelancer.call{value: amountToSend}("");
        if (success == false) {
            revert Dework_PaymentToFreelancerFailed(freelancer, amountToSend);
        }
    }

    function modifyOwner(address newOwner) external onlyAuthourizedOwner {
        owner = newOwner;
    }

    function withdrawAmount(uint256 employerId, uint256 withdrawalAmount) external onlyAuthourizedEmployer(employerId) {
        _requireEnoughEmployerBalance(employerId, withdrawalAmount);
        employerBalance[employerId] -= withdrawalAmount;
        _sendWithdrawalToEmployer(employerId, withdrawalAmount);
    }

    function _sendWithdrawalToEmployer(uint256 employerId, uint256 withdrawalAmount) internal {
        (bool success,) = employerIdToAddress[employerId].call{value: withdrawalAmount}("");
        //TODO: Change it with revert statement
        require(success == false, "Transfer failed to employer");
    }

    modifier onlyAuthourizedOwner() {
        _onlyAuthourizedOwner();
        _;
    }

    function _onlyAuthourizedOwner() internal view {
        if (owner != msg.sender) {
            revert Dework_NotAuthourisedOwner();
        }
    }

    modifier onlyAuthourizedEmployer(uint256 employerId) {
        _onlyAuthourizedEmployer(employerId);
        _;
    }

    function _onlyAuthourizedEmployer(uint256 employerId) internal view {
        address employer = employerIdToAddress[employerId];
        if (employer != msg.sender || employer == address(0)) {
            revert Dework_UnauthourizedEmployer(employerId, msg.sender);
        }
    }

    modifier validateFreelancerId(uint256 freelancerId) {
        _validateFreelancerId(freelancerId);
        _;
    }

    function _validateFreelancerId(uint256 freelancerId) internal view {
        if (freelancerId >= getNumberOfRegisteredFreelancers() || freelancerIdToAddress[freelancerId] == address(0)) {
            revert Dework_UnauthourizedFreelancer(freelancerId, msg.sender);
        }
    }

    modifier validateJobId(uint256 employerId, uint256 jobId) {
        _validateJobId(employerId, jobId);
        _;
    }

    function _validateJobId(uint256 employerId, uint256 jobId) internal view {
        if (jobId >= getNumberOfCreatedJobList(employerId)) {
            revert Dework_InvalidJobId(employerId, jobId);
        }
    }

    function _getEmployerProfile(uint256 employerId) internal view returns (EmployerProfile storage) {
        return employerProfiles[employerId];
    }

    function _getJob(uint256 employerId, uint256 jobId) internal view returns (JobListing storage) {
        return employerProfiles[employerId].jobListing[jobId];
    }
}
