// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {RewardManagement} from "../src/RewardManagement.sol";
import {AnswerManagement} from "../src/AnswerManagement.sol";
import {UserManagement} from "../src/UserManagement.sol";
import {Test, console2} from "forge-std/Test.sol";
import {Attacker, Attacker2, Attacker3} from "../test/Attacker.sol"; 

contract SecurityTest is Test {
    RewardManagement public rewardManagement;
    Attacker public attacker;
    Attacker2 public attacker2;
    Attacker3 public attacker3; 

    address alice = address(0x1);
    address bob = address(0x2);
    address charlie = address(0x3);
    address dave = address(0x4);

    function setUp() public {
        rewardManagement = new RewardManagement();
        attacker = new Attacker(rewardManagement); 
        attacker2 = new Attacker2(rewardManagement); 
        attacker3 = new Attacker3(rewardManagement); 

        vm.startPrank(alice);
        rewardManagement.registerUser("Alice");
        vm.stopPrank();

        vm.startPrank(bob);
        rewardManagement.registerUser("Bob");
        vm.stopPrank();

        vm.startPrank(dave);
        rewardManagement.registerUser("Dave");
        vm.stopPrank();

        vm.startPrank(address(attacker));
        rewardManagement.registerUser("Attacker");
        vm.stopPrank();

        vm.startPrank(address(attacker2));
        rewardManagement.registerUser("Attacker2");
        vm.stopPrank();

        vm.startPrank(address(attacker3));
        rewardManagement.registerUser("Attacker3");
        vm.stopPrank();

        vm.deal(address(alice), 10 ether);
        vm.deal(bob, 1 ether);
        vm.deal(charlie, 1 ether);
        vm.deal(dave, 1 ether);
        vm.deal(address(attacker), 10 ether); 
        vm.deal(address(rewardManagement), 100 ether); 
        vm.deal(address(attacker2), 10 ether); 
        vm.deal(address(attacker3), 10 ether); 
    }

    // function test_attack() public {
    //     vm.startPrank(address(alice));
    //     reward.registerUser("alice");
    //     //selfdestruct(payable(address(reward)));
    //     uint256 q_id = reward.askQuestion{value: 1 ether}("q1", 1, 2, 3);
    //     vm.stopPrank();

    //     vm.startPrank(address(attacker));
    //     reward.registerUser("attacker");
    //     attacker.selfD(); 
    //     vm.stopPrank();
    //     console2.log(q_id);
    //     assertEq(address(reward).balance, 100 ether, "selfdestruct fail");
    //     assertEq(address(alice).balance, 0 ether, "0");
    // }

    // Test if user can post two answers to the same question
    function testPostAnswerTwice() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = rewardManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(bob);
        rewardManagement.postAnswer(questionId, "Ethereum is a decentralized platform.");
        vm.stopPrank();

        vm.startPrank(bob);
        vm.expectRevert("You cannot answer the same question twice");
        rewardManagement.postAnswer(questionId, "Ethereum is a decentralized platform.");
        vm.stopPrank();
    }
    // Test if the answerer can endorse his own answer
    function testEndorseOwnAnswer() public{
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = rewardManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(bob);
        rewardManagement.postAnswer(questionId, "Ethereum is a decentralized platform.");
        vm.expectRevert("You cannot endorse your own answer");
        rewardManagement.endorse(1, 1);
        vm.stopPrank();
    }
    // Test if Non-registered user can ask a question, post an answer, and endorse an answer
    function testNotRegistered() public{
        vm.startPrank(charlie);
        vm.expectRevert("User not registered" );
        rewardManagement.askQuestion{value: 0.001 ether}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(alice);
        uint256 question_id = rewardManagement.askQuestion{value: 0.001 ether}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(charlie);
        vm.expectRevert("User must be registered to answer a question");
        rewardManagement.postAnswer(question_id, "answer");
        vm.stopPrank();

        vm.startPrank(bob);
        uint256 answer_id = rewardManagement.postAnswer(question_id, "real answer");
        vm.stopPrank();

        vm.startPrank(charlie);
        vm.expectRevert("User must be registered to add endorsements");
        rewardManagement.endorse(answer_id, question_id);
        vm.stopPrank(); 
    }
    // Test the question can be closed by user who does not ask the question
    function testNotClosedByAsker() public{
        vm.startPrank(alice);
        uint256 question_id = rewardManagement.askQuestion{value: 0.001 ether}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(bob);
        vm.expectRevert("Only the asker can close the question");
        rewardManagement.closeQuestion(question_id, true);
        vm.stopPrank();
    }
    // Test if the user can endorse the same answer twice
    function testEndorseAnswerTwice() public {
        vm.startPrank(alice);
        uint256 question_id = rewardManagement.askQuestion{value: 0.001 ether}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(bob);
        uint256 answer_id = rewardManagement.postAnswer(question_id, "real answer");
        vm.stopPrank();

        vm.startPrank(dave);
        rewardManagement.endorse(answer_id, question_id);
        vm.expectRevert("User cannot endorse an answer twice");
        rewardManagement.endorse(answer_id, question_id);
        vm.stopPrank();
    }
    // Test if the user can register twice using the same address
    function testRegisterTwice() public {
        vm.startPrank(alice);
        vm.expectRevert("The address was registered");
        rewardManagement.registerUser("alice");
        vm.stopPrank();
    }
    // Test the closeQuestion function when there is a reentrancy attack
    function testReentrancyOnCloseQuestion() public {
        vm.startPrank(address(attacker));
        uint256 question_id = rewardManagement.askQuestion{value: 0.001 ether}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(address(attacker));
        vm.expectRevert("Reward distribution failed");
        
        rewardManagement.closeQuestion(question_id, false);
        //vm.expectRevert("The question has already been closed");
        vm.stopPrank();
    }
    // Test the rewardDistributeByExpirationTime function when there is a reentrancy attack
    function testReentrancyOnRewardDistributionByExpirationTime() public {
        vm.startPrank(address(attacker2));
        uint256 question_id = rewardManagement.askQuestion{value: 0.001 ether}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();

        vm.warp(block.timestamp + 86400*2); //Two days later
        vm.startPrank(address(attacker2));
        vm.expectRevert("Reward distribution failed");
        rewardManagement.rewardDistributeByExpirationTime(question_id);
        vm.stopPrank();
    }
    // Test if the user can answer his own question
    function testAnswerOwnQuestion () public {
        vm.startPrank(alice);
        uint256 question_id = rewardManagement.askQuestion{value: 0.001 ether}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert("You cannot answer your own question!");
        rewardManagement.postAnswer(question_id, "real answer");
        vm.stopPrank();
        
    }
    // Test if the contract can be attacked by selfdestruct
    function testSelfDestructAttack () public {
        vm.startPrank(address(attacker2));
        uint256 q_id = rewardManagement.askQuestion{value: 0.001 ether}("test selfD question", 1, 0, 0);
        
        attacker3.selfD();
        
        vm.expectRevert("Reward distribution failed");
        rewardManagement.closeQuestion(q_id, false);
        
        assertEq(address(attacker2).balance, 9999000000000000000);
        vm.stopPrank();
    }

}
