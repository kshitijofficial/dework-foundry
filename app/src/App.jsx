import { useState, useEffect, useRef } from "react";
import { ethers } from "ethers";
import abi from "../src/contractAbi/Dework.json";
import "./App.css";

const contractAddress = "0x5fbdb2315678afecb367f032d93f642f64180aa3";

function App() {
  const [address, setAddress] = useState("");
  const [contract, setContract] = useState(null);
  const [refreshKey, setRefreshKey] = useState(0);
  const nameRef = useRef(null);
  const experienceYearsRef = useRef(null);
  const hourlyRateWeiRef = useRef(null);
  const employerNameRef = useRef(null);
  const jobEmployerIdRef = useRef(null);
  const jobTitleRef = useRef(null);
  const jobDescriptionRef = useRef(null);
  const jobDeadlineRef = useRef(null);
  const jobFixedPriceRef = useRef(null);
  const hireEmployerIdRef = useRef(null);
  const hireFreelancerIdRef = useRef(null);
  const hireJobIdRef = useRef(null);
  const releaseEmployerIdRef = useRef(null);
  const releaseJobIdRef = useRef(null);
  const releaseFreelancerIdRef = useRef(null);
  const withdrawEmployerIdRef = useRef(null);
  const withdrawalAmountRef = useRef(null);
  const newOwnerRef = useRef(null);
  const freelancerProfileIdRef = useRef(null);
  const jobListEmployerIdRef = useRef(null);
  const createdJobCountEmployerIdRef = useRef(null);
  const employerBalanceIdRef = useRef(null);

  async function connectWallet() {
    if (!window.ethereum) {
      alert("Ethereum Wallet is not installed");
    } else {
      const addresses = await window.ethereum.request({
        method: "eth_requestAccounts",
      });

      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const network = await provider.getNetwork();
      const code = await provider.getCode(contractAddress);

      console.log("Connected chain id:", network.chainId);
      console.log("Contract address:", contractAddress);
      console.log("Contract code found:", code !== "0x");
      if (code === "0x") {
        console.log("No contract found at this address on the connected network");
        return;
      }

      const contract = new ethers.Contract(contractAddress, abi, signer);
      setContract(contract);
      setAddress(addresses[0]);
    }
  }

  useEffect(() => {
    if (!contract) return;

    async function getContractDetails() {
      try {
        const owner = await contract.owner();
        const freelancerCount =
          await contract.getNumberOfRegisteredFreelancers();
        const employerCount = await contract.getNumberOfRegisteredEmployers();

        console.log("Owner:", owner);
        console.log("Registered freelancers:", freelancerCount);
        console.log("Registered employers:", employerCount);
      } catch (error) {
        console.error("Failed to read contract details:", error);
      }
    }

    getContractDetails();
  }, [contract, refreshKey]);

  function logConnectWalletMessage() {
    console.log("Connect wallet before calling contract function");
  }

  async function waitForTx(tx, successMessage) {
    console.log(`${successMessage} transaction sent:`, tx.hash);
    const receipt = await tx.wait();
    console.log(`${successMessage} done:`, receipt);
    setRefreshKey((currentRefreshKey) => currentRefreshKey + 1);
  }

  async function registerFreelancer(e) {
    e.preventDefault();
    if (!contract) {
      logConnectWalletMessage();
      return;
    }

    try {
      const name = nameRef.current.value;
      const experienceYears = Number(experienceYearsRef.current.value);
      const hourlyRateWei = BigInt(hourlyRateWeiRef.current.value);

      const tx = await contract.registerFreelancerProfile(
        name,
        experienceYears,
        hourlyRateWei,
      );
      await waitForTx(tx, "Freelancer registration");
    } catch (error) {
      console.error("Freelancer registration failed:", error);
    }
  }

  async function registerEmployer(e) {
    e.preventDefault();
    if (!contract) {
      logConnectWalletMessage();
      return;
    }

    try {
      const employerName = employerNameRef.current.value;
      const tx = await contract.registerEmployerProfile(employerName);
      await waitForTx(tx, "Employer registration");
    } catch (error) {
      console.error("Employer registration failed:", error);
    }
  }

  async function createJobListing(e) {
    e.preventDefault();
    if (!contract) {
      logConnectWalletMessage();
      return;
    }

    try {
      const employerId = BigInt(jobEmployerIdRef.current.value);
      const fixedPriceInWei = BigInt(jobFixedPriceRef.current.value);
      const jobListingInput = {
        title: jobTitleRef.current.value,
        description: jobDescriptionRef.current.value,
        deadlineTimestamp: BigInt(jobDeadlineRef.current.value),
        fixedPriceInWei,
      };

      const tx = await contract.createJobListing(employerId, jobListingInput, {
        value: fixedPriceInWei,
      });
      await waitForTx(tx, "Job listing creation");
    } catch (error) {
      console.error("Job listing creation failed:", error);
    }
  }

  async function hireFreelancer(e) {
    e.preventDefault();
    if (!contract) {
      logConnectWalletMessage();
      return;
    }

    try {
      const employerId = BigInt(hireEmployerIdRef.current.value);
      const freelancerId = BigInt(hireFreelancerIdRef.current.value);
      const jobId = BigInt(hireJobIdRef.current.value);

      const tx = await contract.hireFreelancer(employerId, freelancerId, jobId);
      await waitForTx(tx, "Freelancer hire");
    } catch (error) {
      console.error("Freelancer hire failed:", error);
    }
  }

  async function releaseEscrowPayment(e) {
    e.preventDefault();
    if (!contract) {
      logConnectWalletMessage();
      return;
    }

    try {
      const employerId = BigInt(releaseEmployerIdRef.current.value);
      const jobId = BigInt(releaseJobIdRef.current.value);
      const freelancerId = BigInt(releaseFreelancerIdRef.current.value);

      const tx = await contract.releaseEscrowPayment(
        employerId,
        jobId,
        freelancerId,
      );
      await waitForTx(tx, "Escrow payment release");
    } catch (error) {
      console.error("Escrow payment release failed:", error);
    }
  }

  async function withdrawAmount(e) {
    e.preventDefault();
    if (!contract) {
      logConnectWalletMessage();
      return;
    }

    try {
      const employerId = BigInt(withdrawEmployerIdRef.current.value);
      const withdrawalAmount = BigInt(withdrawalAmountRef.current.value);

      const tx = await contract.withdrawAmount(employerId, withdrawalAmount);
      await waitForTx(tx, "Withdrawal");
    } catch (error) {
      console.error("Withdrawal failed:", error);
    }
  }

  async function modifyOwner(e) {
    e.preventDefault();
    if (!contract) {
      logConnectWalletMessage();
      return;
    }

    try {
      const newOwner = newOwnerRef.current.value;
      const tx = await contract.modifyOwner(newOwner);
      await waitForTx(tx, "Owner update");
    } catch (error) {
      console.error("Owner update failed:", error);
    }
  }

  async function getFreelancerProfile(e) {
    e.preventDefault();
    if (!contract) {
      logConnectWalletMessage();
      return;
    }

    try {
      const freelancerId = BigInt(freelancerProfileIdRef.current.value);
      const freelancerCount =
        await contract.getNumberOfRegisteredFreelancers();

      console.log("Registered freelancers:", freelancerCount);
      if (freelancerId >= freelancerCount) {
        console.log("Invalid freelancer id:", freelancerId);
        return;
      }

      const freelancerProfile =
        await contract.getFreelancerProfile(freelancerId);
      console.log("Freelancer profile:", freelancerProfile);
    } catch (error) {
      console.error("Get freelancer profile failed:", error);
    }
  }

  async function getJobList(e) {
    e.preventDefault();
    if (!contract) {
      logConnectWalletMessage();
      return;
    }

    try {
      const employerId = BigInt(jobListEmployerIdRef.current.value);
      const jobList = await contract.getJobList(employerId);
      console.log("Job list:", jobList);
    } catch (error) {
      console.error("Get job list failed:", error);
    }
  }

  async function getCreatedJobCount(e) {
    e.preventDefault();
    if (!contract) {
      logConnectWalletMessage();
      return;
    }

    try {
      const employerId = BigInt(createdJobCountEmployerIdRef.current.value);
      const createdJobCount =
        await contract.getNumberOfCreatedJobList(employerId);
      console.log("Created job count:", createdJobCount);
    } catch (error) {
      console.error("Get created job count failed:", error);
    }
  }

  async function getEmployerBalance(e) {
    e.preventDefault();
    if (!contract) {
      logConnectWalletMessage();
      return;
    }

    try {
      const employerId = BigInt(employerBalanceIdRef.current.value);
      const balance = await contract.employerBalance(employerId);
      console.log("Employer balance:", balance);
    } catch (error) {
      console.error("Get employer balance failed:", error);
    }
  }

  return (
    <>
      <button onClick={connectWallet}>Connect Wallet</button>
      <p>Connected Account: {address}</p>

      <form onSubmit={registerFreelancer}>
        <input ref={nameRef} placeholder="freelancer name" />
        <input
          ref={experienceYearsRef}
          placeholder="experience years"
          type="number"
        />
        <input ref={hourlyRateWeiRef} placeholder="hourly rate wei" />
        <button type="submit">Register Freelancer</button>
      </form>

      <form onSubmit={registerEmployer}>
        <input ref={employerNameRef} placeholder="employer name" />
        <button type="submit">Register Employer</button>
      </form>

      <form onSubmit={createJobListing}>
        <input ref={jobEmployerIdRef} placeholder="employer id" />
        <input ref={jobTitleRef} placeholder="job title" />
        <input ref={jobDescriptionRef} placeholder="job description" />
        <input ref={jobDeadlineRef} placeholder="deadline seconds" />
        <input ref={jobFixedPriceRef} placeholder="fixed price wei" />
        <button type="submit">Create Job Listing</button>
      </form>

      <form onSubmit={hireFreelancer}>
        <input ref={hireEmployerIdRef} placeholder="employer id" />
        <input ref={hireFreelancerIdRef} placeholder="freelancer id" />
        <input ref={hireJobIdRef} placeholder="job id" />
        <button type="submit">Hire Freelancer</button>
      </form>

      <form onSubmit={releaseEscrowPayment}>
        <input ref={releaseEmployerIdRef} placeholder="employer id" />
        <input ref={releaseJobIdRef} placeholder="job id" />
        <input ref={releaseFreelancerIdRef} placeholder="freelancer id" />
        <button type="submit">Release Escrow Payment</button>
      </form>

      <form onSubmit={withdrawAmount}>
        <input ref={withdrawEmployerIdRef} placeholder="employer id" />
        <input ref={withdrawalAmountRef} placeholder="withdrawal amount wei" />
        <button type="submit">Withdraw Amount</button>
      </form>

      <form onSubmit={modifyOwner}>
        <input ref={newOwnerRef} placeholder="new owner address" />
        <button type="submit">Modify Owner</button>
      </form>

      <form onSubmit={getFreelancerProfile}>
        <input ref={freelancerProfileIdRef} placeholder="freelancer id" />
        <button type="submit">Get Freelancer Profile</button>
      </form>

      <form onSubmit={getJobList}>
        <input ref={jobListEmployerIdRef} placeholder="employer id" />
        <button type="submit">Get Job List</button>
      </form>

      <form onSubmit={getCreatedJobCount}>
        <input ref={createdJobCountEmployerIdRef} placeholder="employer id" />
        <button type="submit">Get Created Job Count</button>
      </form>

      <form onSubmit={getEmployerBalance}>
        <input ref={employerBalanceIdRef} placeholder="employer id" />
        <button type="submit">Get Employer Balance</button>
      </form>
    </>
  );
}

export default App;
