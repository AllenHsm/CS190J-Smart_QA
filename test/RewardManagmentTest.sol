// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {Test} from "forge-std/Test.sol";
import {RewardManagement} from "../src/RewardManagement.sol";

contract RewardManagementTest is Test {
    RewardManagement rewardManagement;
    address alice = address(0x1);
    address bob = address(0x2);
    address charlie = address(0x3);
    address dave = address(0x4);

    function setUp() public {
        rewardManagement = new RewardManagement{value: 10 ether}();
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
        vm.deal(charlie, 1 ether);
        vm.deal(dave, 1 ether);

        vm.startPrank(alice);
        rewardManagement.registerUser("Alice");
        vm.stopPrank();

        vm.startPrank(bob);
        rewardManagement.registerUser("Bob");
        vm.stopPrank();

        vm.startPrank(charlie);
        rewardManagement.registerUser("Charlie");
        vm.stopPrank();

        vm.startPrank(dave);
        rewardManagement.registerUser("Dave");
        vm.stopPrank();

        
    }

    function testRewardDistributionToSelectedAnswer() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = rewardManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(bob);
        uint256 answerId = rewardManagement.postAnswer(questionId, "Ethereum is a decentralized platform.");
        vm.stopPrank();

        vm.startPrank(alice);
        rewardManagement.selectAnswer(questionId, answerId);
        rewardManagement.closeQuestion(questionId);
        rewardManagement.rewardDistribute(questionId, true);
        
        // Assert that reward is distributed to the selected answerer
        (, , , , , , bool distributed, ) = rewardManagement.questionMap(questionId);
        assertEq(distributed, true);
        vm.stopPrank();
    }

    function testRewardDistributionToEndorsedAnswer() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = rewardManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(bob);
        uint256 answerId = rewardManagement.postAnswer(questionId, "Ethereum is a decentralized platform.");
        vm.stopPrank();

        vm.startPrank(charlie);
        rewardManagement.endorse(questionId, answerId);
        vm.stopPrank();

        vm.startPrank(alice);
        rewardManagement.closeQuestion(questionId);
        rewardManagement.rewardDistribute(questionId, true);
        
        // Assert that reward is distributed to the endorsed answerer
        (, , , , , , bool distributed, ) = rewardManagement.questionMap(questionId);
        assertEq(distributed, true);
        vm.stopPrank();
    }
    function testRewardDistributionByExpirationTime() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = rewardManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();

        vm.warp(block.timestamp + 86400*2); // Two days later

        vm.startPrank(alice);
        rewardManagement.closeQuestion(questionId);
        rewardManagement.rewardDistribute(questionId, true);

        // Assert that reward is distributed to the asker
        (, , , , , , bool distributed, ) = rewardManagement.questionMap(questionId);
        assertEq(distributed, true);
        vm.stopPrank();
    }
    function testRewardDistributionWithoutSelection() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = rewardManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(bob);
        uint256 answerId = rewardManagement.postAnswer(questionId, "Ethereum is a decentralized platform.");
        vm.stopPrank();

        vm.startPrank(alice);
        rewardManagement.closeQuestion(questionId);
        rewardManagement.rewardDistribute(questionId, false);

        // Assert that reward is distributed to the asker
        (, , , , , , bool distributed, ) = rewardManagement.questionMap(questionId);
        assertEq(distributed, true);
        vm.stopPrank();
    }
    function testCreditCalculation() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = rewardManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(bob);
        uint256 answerId = rewardManagement.postAnswer(questionId, "Ethereum is a decentralized platform.");
        vm.stopPrank();

        vm.startPrank(alice);
        rewardManagement.selectAnswer(questionId, answerId);
        rewardManagement.closeQuestion(questionId);
        rewardManagement.rewardDistribute(questionId, true);
        vm.stopPrank();

        // Assert that credit is calculated for the asker
        assertEq(rewardManagement.getCredit(alice), 13413560302917342);
    }
    function testCreditCalculationWithoutGivingReward() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = rewardManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(bob);
        uint256 answerId = rewardManagement.postAnswer(questionId, "Ethereum is a decentralized platform.");
        vm.stopPrank();

        vm.startPrank(alice);
        rewardManagement.closeQuestion(questionId);
        rewardManagement.rewardDistribute(questionId, false);
        vm.stopPrank();

        // Assert that credit is calculated for the asker
        assertEq(rewardManagement.getCredit(alice), 8940000000000000);
    }
    function testCheckEndorsement() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = rewardManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(bob);

        uint256 answerId = rewardManagement.postAnswer(questionId, "Ethereum is a decentralized platform.");
        vm.stopPrank();

        vm.startPrank(charlie);

        rewardManagement.endorse(questionId, answerId);
        vm.stopPrank();

        vm.startPrank(dave);
        rewardManagement.endorse(questionId, answerId);
        vm.stopPrank();

        

        
        vm.startPrank(alice);
        rewardManagement.closeQuestion(questionId);
        address[] memory recipients = rewardManagement.checkEndorsement(questionId);
        assertEq(recipients.length, 2);
        assertEq(recipients[0], charlie);
        assertEq(recipients[1], dave);
        vm.stopPrank();
    }

}