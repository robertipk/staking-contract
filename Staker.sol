// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  uint256 public constant threshold = 1 wei;

  // Staking deadline. After this deadline, anyone send the funds
  // to the other contract
  uint256 public deadline = block.timestamp + 180 seconds;

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )

  // emit event each time
  event Stake(address indexed sender, uint256 amount);

  // Balances of the users' staked funds
  mapping(address => uint256) public balances;

  function stake() public payable {
    // update the user's balance
    balances[msg.sender] += msg.value;
    
    // emit the event to notify the blockchain that we have correctly Staked some fund for the user
    emit Stake(msg.sender, msg.value);
  }


  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  //function execute() public stakeNotCompleted deadlineReached(false) {
  function execute() public {

    require(timeLeft() == 0, "Deadline not yet expired");

    uint256 contractBalance = address(this).balance;

    // check the contract has enough ETH to reach the threshold
    require(contractBalance >= threshold, "Threshold is not reached");

    // Execute the external contract, transfer all the balance to the contract
    // (bool sent, bytes memory data) = exampleExternalContract.complete{value: contractBalance}();
    (bool sent,) = address(exampleExternalContract).call{value: contractBalance}(abi.encodeWithSignature("complete()"));
    require(sent, "exampleExternalContract.complete failed :(");
  }


  // if the `threshold` was not met, allow everyone to call a `withdraw()` function


  // Add a `withdraw(address payable)` function lets users withdraw their balance
  // function withdraw() public deadlineReached(true) stakeNotCompleted {
  function withdraw(address payable depositor) public {
    uint256 userBalance = balances[depositor];

    // only allow withdrawals if the deadline has expired
    require(timeLeft() == 0, "Deadline not yet expired");

    // check if the user has balance to withdraw
    require(userBalance > 0, "No balance to withdraw");

    // reset the balance of the user.
    // Do this before transferring balance to prevent re-entrancy attacks.
    balances[depositor] = 0;

    // Transfer balance back to the user
    (bool sent,) = depositor.call{value: userBalance}("");
    require(sent, "Failed to send user balance back to the user");
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256 timeleft) {
    return deadline >= block.timestamp ? deadline - block.timestamp: 0;
  }

  // Add the `receive()` special function that receives eth and calls stake()
  function receive() public {
    stake();
  }
}
