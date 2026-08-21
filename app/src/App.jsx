import { useState, useRef } from "react";
import abi from "./deworkAbi/dework.json";
import { ethers } from "ethers";
import "./App.css";

function App() {
  const [address, setAddress] = useState("Not Found");
  const [contract, setContract] = useState("Not Found");
  const nameRef = useRef(null);
  const exprienceRef = useRef(null);
  const hourlyRateRef = useRef(null);
  const idRef = useRef(null);
  async function connectWallet() {
    if (!window.ethereum) {
      alert("Metamask is not installed");
    }
    const addresses = await window.ethereum.request({
      method: "eth_requestAccounts",
    });
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();
    const contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

    const contract = new ethers.Contract(contractAddress, abi, signer);
    setContract(contract);
    setAddress(addresses[0]);
  }

  async function registerFreelancer(e) {
    e.preventDefault();
    const name = nameRef.current.value;
    const experience = Number(exprienceRef.current.value);
    const hourlyRate = BigInt(hourlyRateRef.current.value);
    try {
      await contract.registerFreelancerProfile(name, experience, hourlyRate);
      alert("Transaction Successful");
    } catch (e) {
      console.error("Transaction failed", e);
    }
  }

  async function getFreelancerProfile(e) {
    e.preventDefault();
    const id = BigInt(idRef.current.value);
    try {
      const profile = await contract.getFreelancerProfile(id);
      console.log(profile);
    } catch (e) {
      console.error("Transaction failed", e);
    }
  }
  return (
    <>
      <button onClick={connectWallet}>Connect Wallet</button>
      <p>Connected Address: {address}</p>
      <form onSubmit={registerFreelancer}>
        <input placeholder="name" ref={nameRef}></input>
        <input placeholder="exprience(years)" ref={exprienceRef}></input>
        <input placeholder="hourly rate(in Wei)" ref={hourlyRateRef}></input>
        <button>Register Freelancer</button>
      </form>
      <form onSubmit={getFreelancerProfile}>
        <input placeholder="id" ref={idRef}></input>
        <button>Get Freelancer Profile</button>
      </form>
    </>
  );
}

export default App;
