import { useRef, useState } from "react";
import { ethers } from "ethers";
import abi from "./deworkAbi/dework.json";
import "./App.css";

function App() {
  const [address, setAddress] = useState("Not Connected");
  const [contract, setContract] = useState(null);
  const [message, setMessage] = useState("");
  const [freelancerProfile, setFreelancerProfile] = useState(null);
  const [employerProfile, setEmployerProfile] = useState(null);
  const [jobs, setJobs] = useState([]);
  const [counts, setCounts] = useState({ freelancers: "0", employers: "0" });

  const nameRef = useRef(null);
  const exprienceRef = useRef(null);
  const hourlyRateRef = useRef(null);
  const freelancerIdRef = useRef(null);

  const employerNameRef = useRef(null);
  const employerIdRef = useRef(null);
  const jobTitleRef = useRef(null);
  const jobDescriptionRef = useRef(null);
  const jobDeadlineRef = useRef(null);
  const jobPriceRef = useRef(null);

  const viewEmployerIdRef = useRef(null);
  const jobListEmployerIdRef = useRef(null);
  const hireEmployerIdRef = useRef(null);
  const hireFreelancerIdRef = useRef(null);
  const hireJobIdRef = useRef(null);

  const payEmployerIdRef = useRef(null);
  const payJobIdRef = useRef(null);
  const payFreelancerIdRef = useRef(null);
  const withdrawEmployerIdRef = useRef(null);
  const withdrawAmountRef = useRef(null);
  const ownerRef = useRef(null);

  async function connectWallet() {
    if (!window.ethereum) {
      alert("Metamask is not installed");
      return;
    }

    const addresses = await window.ethereum.request({
      method: "eth_requestAccounts",
    });
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();
    const contractAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
    const deworkContract = new ethers.Contract(contractAddress, abi, signer);

    setContract(deworkContract);
    setAddress(addresses[0]);
    setMessage("Wallet connected");
  }

  function requireContract() {
    if (!contract) {
      alert("Connect wallet first");
      return false;
    }
    return true;
  }

  async function registerFreelancer(e) {
    e.preventDefault();
    if (!requireContract()) return;

    const name = nameRef.current.value;
    const experience = Number(exprienceRef.current.value);
    const hourlyRate = BigInt(hourlyRateRef.current.value);

    try {
      const tx = await contract.registerFreelancerProfile(
        name,
        experience,
        hourlyRate,
      );
      await tx.wait();
      setMessage("Freelancer registered");
      e.target.reset();
    } catch (error) {
      console.error("Transaction failed", error);
      setMessage("Freelancer registration failed");
    }
  }

  async function getFreelancerProfile(e) {
    e.preventDefault();
    if (!requireContract()) return;

    const id = BigInt(freelancerIdRef.current.value);

    try {
      const profile = await contract.getFreelancerProfile(id);
      setFreelancerProfile(profile);
      setMessage("Freelancer profile loaded");
    } catch (error) {
      console.error("Transaction failed", error);
      setMessage("Could not load freelancer profile");
    }
  }

  async function registerEmployer(e) {
    e.preventDefault();
    if (!requireContract()) return;

    const employerName = employerNameRef.current.value;

    try {
      const tx = await contract.registerEmployerProfile(employerName);
      await tx.wait();
      setMessage("Employer registered");
      e.target.reset();
    } catch (error) {
      console.error("Transaction failed", error);
      setMessage("Employer registration failed");
    }
  }

  async function getEmployerProfile(e) {
    e.preventDefault();
    if (!requireContract()) return;

    const id = BigInt(viewEmployerIdRef.current.value);

    try {
      const profile = await contract.employerProfiles(id);
      setEmployerProfile(profile);
      setMessage("Employer profile loaded");
    } catch (error) {
      console.error("Transaction failed", error);
      setMessage("Could not load employer profile");
    }
  }

  async function createJobListing(e) {
    e.preventDefault();
    if (!requireContract()) return;

    const employerId = BigInt(employerIdRef.current.value);
    const fixedPriceInWei = BigInt(jobPriceRef.current.value);
    const jobListingInput = {
      title: jobTitleRef.current.value,
      description: jobDescriptionRef.current.value,
      deadlineTimestamp: BigInt(jobDeadlineRef.current.value),
      fixedPriceInWei,
    };

    try {
      const tx = await contract.createJobListing(employerId, jobListingInput, {
        value: fixedPriceInWei,
      });
      await tx.wait();
      setMessage("Job created");
      e.target.reset();
    } catch (error) {
      console.error("Transaction failed", error);
      setMessage("Job creation failed");
    }
  }

  async function getJobList(e) {
    e.preventDefault();
    if (!requireContract()) return;

    const employerId = BigInt(jobListEmployerIdRef.current.value);

    try {
      const jobList = await contract.getJobList(employerId);
      setJobs(Array.from(jobList));
      setMessage("Job list loaded");
    } catch (error) {
      console.error("Transaction failed", error);
      setMessage("Could not load job list");
    }
  }

  async function hireFreelancer(e) {
    e.preventDefault();
    if (!requireContract()) return;

    const employerId = BigInt(hireEmployerIdRef.current.value);
    const freelancerId = BigInt(hireFreelancerIdRef.current.value);
    const jobId = BigInt(hireJobIdRef.current.value);

    try {
      const tx = await contract.hireFreelancer(employerId, freelancerId, jobId);
      await tx.wait();
      setMessage("Freelancer hired");
      e.target.reset();
    } catch (error) {
      console.error("Transaction failed", error);
      setMessage("Hiring failed");
    }
  }

  async function releaseEscrowPayment(e) {
    e.preventDefault();
    if (!requireContract()) return;

    const employerId = BigInt(payEmployerIdRef.current.value);
    const jobId = BigInt(payJobIdRef.current.value);
    const freelancerId = BigInt(payFreelancerIdRef.current.value);

    try {
      const tx = await contract.releaseEscrowPayment(
        employerId,
        jobId,
        freelancerId,
      );
      await tx.wait();
      setMessage("Payment released");
      e.target.reset();
    } catch (error) {
      console.error("Transaction failed", error);
      setMessage("Payment release failed");
    }
  }

  async function withdrawAmount(e) {
    e.preventDefault();
    if (!requireContract()) return;

    const employerId = BigInt(withdrawEmployerIdRef.current.value);
    const withdrawalAmount = BigInt(withdrawAmountRef.current.value);

    try {
      const tx = await contract.withdrawAmount(employerId, withdrawalAmount);
      await tx.wait();
      setMessage("Withdrawal complete");
      e.target.reset();
    } catch (error) {
      console.error("Transaction failed", error);
      setMessage("Withdrawal failed");
    }
  }

  async function modifyOwner(e) {
    e.preventDefault();
    if (!requireContract()) return;

    const newOwner = ownerRef.current.value;

    try {
      const tx = await contract.modifyOwner(newOwner);
      await tx.wait();
      setMessage("Owner changed");
      e.target.reset();
    } catch (error) {
      console.error("Transaction failed", error);
      setMessage("Owner change failed");
    }
  }

  async function getCounts() {
    if (!requireContract()) return;

    try {
      const freelancers = await contract.getNumberOfRegisteredFreelancers();
      const employers = await contract.getNumberOfRegisteredEmployers();
      setCounts({
        freelancers: freelancers.toString(),
        employers: employers.toString(),
      });
      setMessage("Counts loaded");
    } catch (error) {
      console.error("Transaction failed", error);
      setMessage("Could not load counts");
    }
  }

  return (
    <main className="app">
      <section className="topbar">
        <div>
          <h1>Dework</h1>
          <p>Connected Address: {address}</p>
        </div>
        <button onClick={connectWallet}>Connect Wallet</button>
      </section>

      {message && <p className="message">{message}</p>}

      <section className="grid">
        <form onSubmit={registerFreelancer}>
          <h2>Register Freelancer</h2>
          <input placeholder="name" ref={nameRef} required />
          <input
            placeholder="exprience(years)"
            ref={exprienceRef}
            type="number"
            required
          />
          <input
            placeholder="hourly rate(in Wei)"
            ref={hourlyRateRef}
            type="number"
            required
          />
          <button>Register Freelancer</button>
        </form>

        <form onSubmit={getFreelancerProfile}>
          <h2>Get Freelancer Profile</h2>
          <input
            placeholder="freelancer id"
            ref={freelancerIdRef}
            type="number"
            required
          />
          <button>Get Freelancer Profile</button>
        </form>

        <form onSubmit={registerEmployer}>
          <h2>Register Employer</h2>
          <input placeholder="employer name" ref={employerNameRef} required />
          <button>Register Employer</button>
        </form>

        <form onSubmit={getEmployerProfile}>
          <h2>Get Employer Profile</h2>
          <input
            placeholder="employer id"
            ref={viewEmployerIdRef}
            type="number"
            required
          />
          <button>Get Employer Profile</button>
        </form>

        <form onSubmit={createJobListing}>
          <h2>Create Job</h2>
          <input
            placeholder="employer id"
            ref={employerIdRef}
            type="number"
            required
          />
          <input placeholder="title" ref={jobTitleRef} required />
          <input placeholder="description" ref={jobDescriptionRef} required />
          <input
            placeholder="deadline seconds"
            ref={jobDeadlineRef}
            type="number"
            required
          />
          <input
            placeholder="fixed price(in Wei)"
            ref={jobPriceRef}
            type="number"
            required
          />
          <button>Create Job</button>
        </form>

        <form onSubmit={getJobList}>
          <h2>Get Job List</h2>
          <input
            placeholder="employer id"
            ref={jobListEmployerIdRef}
            type="number"
            required
          />
          <button>Get Jobs</button>
        </form>

        <form onSubmit={hireFreelancer}>
          <h2>Hire Freelancer</h2>
          <input
            placeholder="employer id"
            ref={hireEmployerIdRef}
            type="number"
            required
          />
          <input
            placeholder="freelancer id"
            ref={hireFreelancerIdRef}
            type="number"
            required
          />
          <input
            placeholder="job id"
            ref={hireJobIdRef}
            type="number"
            required
          />
          <button>Hire Freelancer</button>
        </form>

        <form onSubmit={releaseEscrowPayment}>
          <h2>Release Payment</h2>
          <input
            placeholder="employer id"
            ref={payEmployerIdRef}
            type="number"
            required
          />
          <input
            placeholder="job id"
            ref={payJobIdRef}
            type="number"
            required
          />
          <input
            placeholder="freelancer id"
            ref={payFreelancerIdRef}
            type="number"
            required
          />
          <button>Release Payment</button>
        </form>

        <form onSubmit={withdrawAmount}>
          <h2>Withdraw</h2>
          <input
            placeholder="employer id"
            ref={withdrawEmployerIdRef}
            type="number"
            required
          />
          <input
            placeholder="amount(in Wei)"
            ref={withdrawAmountRef}
            type="number"
            required
          />
          <button>Withdraw</button>
        </form>

        <form onSubmit={modifyOwner}>
          <h2>Change Owner</h2>
          <input placeholder="new owner address" ref={ownerRef} required />
          <button>Change Owner</button>
        </form>
      </section>

      <section className="results">
        <button onClick={getCounts}>Refresh Counts</button>
        <p>Freelancers: {counts.freelancers}</p>
        <p>Employers: {counts.employers}</p>

        {freelancerProfile && (
          <div className="result-box">
            <h2>Freelancer Profile</h2>
            <p>Id: {freelancerProfile.id.toString()}</p>
            <p>Name: {freelancerProfile.name}</p>
            <p>Wallet: {freelancerProfile.wallet}</p>
            <p>
              Experience: {freelancerProfile.experienceYears.toString()} years
            </p>
            <p>Available: {freelancerProfile.isAvailableHire ? "Yes" : "No"}</p>
            <p>Hourly Rate: {freelancerProfile.hourlyRateWei.toString()} Wei</p>
          </div>
        )}

        {employerProfile && (
          <div className="result-box">
            <h2>Employer Profile</h2>
            <p>Id: {employerProfile.id.toString()}</p>
            <p>Name: {employerProfile.name}</p>
            <p>Wallet: {employerProfile.wallet}</p>
            <p>Hiring: {employerProfile.isHiring ? "Yes" : "No"}</p>
          </div>
        )}

        {jobs.length > 0 && (
          <div className="result-box">
            <h2>Jobs</h2>
            {jobs.map((job) => (
              <div className="job" key={job.id.toString()}>
                <p>Id: {job.id.toString()}</p>
                <p>Title: {job.title}</p>
                <p>Description: {job.description}</p>
                <p>Deadline: {job.deadlineTimestamp.toString()}</p>
                <p>Price: {job.fixedPriceInWei.toString()} Wei</p>
                <p>Open: {job.isOpen ? "Yes" : "No"}</p>
                <p>Hired Freelancer: {job.hiredFreelancerId.toString()}</p>
                <p>Paid: {job.isPaid ? "Yes" : "No"}</p>
              </div>
            ))}
          </div>
        )}
      </section>
    </main>
  );
}

export default App;
