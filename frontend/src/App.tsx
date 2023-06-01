import React from 'react';
import { ethers } from "ethers";
import { useState, useEffect } from "react";
import rockPaperSatoshiABI from './contractABIs/RockPaperSatoshi.abi.json';
import RPSatoshiTokenABI from './contractABIs/RPSatoshiToken.abi.json';
import RPSHashHealTokenABI from './contractABIs/RPSHashHealToken.abi.json';
import RPSRareItemsTokenABI from './contractABIs/RPSRareItemsToken.abi.json';

import logo from './logo.svg';
import './App.css';
import { RockPaperSatoshi } from '../../typechain-types/contracts/RockPaperSatoshi';

const RockPaperSatoshiAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
const RPSatoshiTokenAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
const RPSHashHealTokenAddress = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";
const RPSRareItemsTokenAddress = "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9";

function App() {


  const [provider, setProvider] = useState(new ethers.providers.Web3Provider(window.ethereum));//Hook for getting and setting the provider. Initialized on first run.
  const [signer, setSigner] = useState(provider.getSigner());//Hook for getting and setting the signer. Initialized on first run.
  const [walletAddress, setWalletAddress] = useState("");//Hook for getting and setting the connected wallet address.
  const [role, setRole] = useState("");//Hook for getting and setting the role of the wallet connected in regard to contract interaction. i.e better, verifier, organizer, unregistered, etc. Used for conditional rendering.
  const [ethBalance, setEthBalance] = useState("");//Hook for getting and setting the connected wallet address' Eth balance.
  const [RPSatoshiBalance, setRPSatoshiBalance] = useState("");//Hook for getting and setting the connected wallet address' RPSatoshi balance.
  const [RPSHashHealBalance, setRPSHashHealBalance] = useState("");//Hook for getting and setting the connected wallet address' RPSHashHeal balance.
  const [RPSRareItemsBalance, setRPSRareItemsBalance] = useState("");//Hook for getting and setting the connected wallet address' RPSRareItems balance.

  const [connected, setConnected] = useState(false);//Hook for getting and setting if we are connected to the contract for conditional rendering of the page. Initialized to false.

  useEffect(() => {//Hook for handing when the user changes Meta Mask accounts.
    const handleAccountsChanged = () => {//Handler that executes when the account change takes place.
      console.log("Handling Account Change");
      setConnected(false);
      setProvider(new ethers.providers.Web3Provider(window.ethereum));//Update the provider to the new wallet.
      setSigner(provider.getSigner());//Update the signer to the new wallet.
  };
  window.ethereum.on('accountsChanged', handleAccountsChanged);//Listens if the user changes accounts in Meta Mask.
  return() => {
    window.ethereum.removeListener('accountsChanged', handleAccountsChanged);//Cleanes-up/removes the listener.
  };
},[])

  async function connectWallet() {//The main function that connects the front end to the user wallet and contract.
    console.log("Connecting to wallet...");

    if(window.ethereum) {//Detect if Meta Mask exists.
      console.log("detected!");
      if(await provider.getCode(RockPaperSatoshiAddress) === '0x') { //Check if the contract has been destroyed
        console.log("Contract has been destroyed!!");
        setRole("destroyed")//Update the role hook to render the page to show that the contract has been destroyed.
        setTimeout(() => setConnected(true),100);//Delayed slightly to make sure other hooks update first and we don't flash any incorrect information on the users screen.
        const accounts = await window.ethereum.request({method: "eth_requestAccounts"});//Get the connected accounts from Meta Mask.
        setWalletAddress(accounts[0]);//Update this hook with the first (aka active) account.
        const accountBalance = await provider.getBalance(accounts[0]);//Get the active account's balance in wei.
        setEthBalance(String(ethers.utils.formatEther(accountBalance)));//Update this hook to store the active account's balance in eth.
      }
      else { //If the contract is not destroyed...
        try {
          setTimeout(() => setConnected(true),100);//Delayed slightly to make sure other hooks update first and we don't flash any incorrect information on the users screen.
          const accounts = await window.ethereum.request({method: "eth_requestAccounts"});//Get the connected accounts from Meta Mask.
          setWalletAddress(accounts[0]);//Update this hook with the first (aka active) account.
          const walletAddress_ = String(accounts[0]).toLowerCase();//So we don't have to wait for the hook to update to use.
          const accountBalance = await provider.getBalance(accounts[0]);//Get the active account's balance in wei.
          setEthBalance(String(ethers.utils.formatEther(accountBalance)));//Update this hook to store the active account's balance in eth.
          const RockPaperSatoshi = new ethers.Contract(RockPaperSatoshiAddress,rockPaperSatoshiABI,provider);//Get instance of the contract (for interaction purposes) as a provider (read-only).
          const RPSatoshiToken = new ethers.Contract(RPSatoshiTokenAddress,RPSatoshiTokenABI,provider);//Get instance of the contract (for interaction purposes) as a provider (read-only).
          const RPSHashHealToken = new ethers.Contract(RPSHashHealTokenAddress,RPSHashHealTokenABI,provider);//Get instance of the contract (for interaction purposes) as a provider (read-only).
          const RPSRareItemsToken = new ethers.Contract(RPSRareItemsTokenAddress,RPSRareItemsTokenABI,provider);//Get instance of the contract (for interaction purposes) as a provider (read-only).

          
          
          const contractName = await RockPaperSatoshi.contractName();//Get the contract name from the contract.
          console.log("contract name: ", contractName); //Left off here
          
          //****const betOrganizer_ = String(await bettingGame.betOrganizer()).toLowerCase();//Get betOrganizer address from contract and ensure it's all lower case for comparison purposes.
          

/*           if(walletAddress_ === betOrganizer_) {//Check if connected wallet is the bet organizer listed in the contract (aka the account which deployed the contract).
            //setRole("organizer");//This hook will be used for conditional rendering of the page based on permissions of interaction with the contract.
            //console.log("Role: Organizer");
          } else if ((await rockPaperSatoshi.verifiers(walletAddress_)).registered) {//Check if the connected wallet is a registered verifier.
            //setRole("verifier");//Update this hook accordingly.
            //console.log("Role: Verifier");
          } else if ((await rockPaperSatoshi.betters(walletAddress_)).registered) {//Check if the connected wallet is a registered better.
            //setRole("better");//Update this hook accordingly.
            //setBetAmount(ethers.utils.formatEther((String((await bettingGame.betters(walletAddress_)).betAmount))));
            //console.log("Role: Registered Better");
            //console.log("Amount bet: ", ethers.utils.formatEther((String((await bettingGame.betters(walletAddress_)).betAmount))),"eth");
          }
          else {//If none of the roles above, then then connected wallet must be unregistered.
            //setRole("unregistered");//Update this hook accordingly.
            console.log("Unregistered");
          } */

        } catch (error) {//Catch any errors we get when trying to connect to the users wallet and the contract.
          setConnected(false);//Set this hook to false for conditional rendering purposes.
          console.log("Error connecting...",error);
        }
      }
        } else {//We were not able to connect to Meta Mask.
          setConnected(false);//Set this hook to false for conditional rendering purposes.
          alert("Meta Mask not detected")
        }
  
  }


  return (
    <div className="App">
      <header className="App-header">
        Welcome to Rock Paper Satoshi
        <img src={logo} className="App-logo" alt="logo" />
        <p>
          The blockchain based rock paper scissors game.
        </p>
        <button onClick={() => connectWallet()}>{/* Button to run the connectWallet function */}
        {connected ? "Connected" : "Connect Wallet"}{/* Conditionally display the button based on the 'connected' hook */}
        </button>
      </header>
    </div>
  );
}

export default App;
