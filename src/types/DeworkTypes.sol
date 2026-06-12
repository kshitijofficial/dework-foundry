// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.34;

struct FreelancerProfile {
    uint256 id;
    string name;
    address wallet;
    uint8 experienceYears;
    bool isAvailableHire;
    uint256 hourlyRateWei;
}

struct EmployerProfile {
    uint256 id;
    string name;
    address wallet;
    bool isHiring;
    JobListing[] jobListing;
}

struct CreateJobListingInput {
    string title;
    string description;
    uint256 deadlineTimestamp;
    uint256 fixedPriceInWei;
}

struct JobListing {
    uint256 id;
    string title;
    string description;
    uint256 deadlineTimestamp;
    bool isOpen;
    uint256 fixedPriceInWei;
    uint256 hiredFreelancerId;
    bool hasHiredFreelancer;
    bool isPaid;
}

