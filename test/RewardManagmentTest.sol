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
        rewardManagement = new RewardManagement();
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

    // Test the rewardDistributeByExpirationTime function
    function testRewardDistributeByExpirationTime() public {
        vm.startPrank(alice);
        uint256 question_id = rewardManagement.askQuestion{value: 0.01 ether}(
            "What is Ethereum?",
            1,
            0,
            0
        );
        vm.stopPrank();

        vm.startPrank(bob);
        uint256 answer_id = rewardManagement.postAnswer(
            question_id,
            "Ethereum is a decentralized platform."
        );
        vm.stopPrank();

        vm.startPrank(charlie);
        rewardManagement.endorse(answer_id, question_id);
        vm.stopPrank();

        vm.warp(block.timestamp + 86400 * 2); //Two days later

        vm.startPrank(bob);
        rewardManagement.rewardDistributeByExpirationTime(question_id);
        vm.stopPrank();

        assertEq(address(bob).balance, 1.01 ether);
        assertEq(address(alice).balance, 0.99 ether);
    }

    // Test the reward Distribution with multiple answers
    function testRewardDistributeWithMultipleAnswers() public {
        vm.startPrank(alice);
        uint256 question_id = rewardManagement.askQuestion{value: 0.01 ether}(
            "What is Ethereum?",
            1,
            0,
            0
        );
        vm.stopPrank();

        vm.startPrank(bob);
        uint256 answer_id = rewardManagement.postAnswer(
            question_id,
            "Ethereum is a decentralized platform."
        );
        vm.stopPrank();

        vm.startPrank(charlie);
        rewardManagement.endorse(answer_id, question_id);
        vm.stopPrank();

        vm.startPrank(dave);
        uint256 answer_id2 = rewardManagement.postAnswer(
            question_id,
            "Ethereum is a decentralized platform."
        );
        vm.stopPrank();

        vm.startPrank(charlie);
        rewardManagement.endorse(answer_id2, question_id);
        vm.stopPrank();

        vm.warp(block.timestamp + 86400 * 2);

        vm.startPrank(bob);
        rewardManagement.rewardDistributeByExpirationTime(question_id);
        vm.stopPrank();

        assertEq(address(bob).balance, 1.005 ether);
        assertEq(address(alice).balance, 0.99 ether);
        assertEq(address(dave).balance, 1.005 ether);
    }

    // Test the reward Distribution with no answer
    function testRewardDistributeWithNoAnswer() public {
        vm.startPrank(alice);
        uint256 question_id = rewardManagement.askQuestion{value: 0.01 ether}(
            "What is Ethereum?",
            1,
            0,
            0
        );
        vm.stopPrank();

        vm.warp(block.timestamp + 86400*2);

        vm.startPrank(bob);
        rewardManagement.rewardDistributeByExpirationTime(question_id);
        vm.stopPrank();

        assertEq(address(alice).balance, 1 ether);
    }

    // test user try to call rewardDistributeByExpirationTime before the question is closed
    function testFailRewardDistributionBeforeExpiration() public {
        vm.startPrank(alice);
        uint256 question_id = rewardManagement.askQuestion{value: 0.01 ether}("What is a smart contract?", 1, 0, 0);
        vm.expectRevert("The question is not closed");

        rewardManagement.rewardDistributeByExpirationTime(question_id);
        vm.stopPrank();

        vm.startPrank(bob);
        uint256 answer_id = rewardManagement.postAnswer(
            question_id,
            "Decentralized Finance"
        );
        vm.stopPrank();

        vm.startPrank(alice);
        rewardManagement.selectAnswer(question_id, answer_id);
        rewardManagement.closeQuestion(question_id, true);
        vm.stopPrank();

        assertEq(address(bob).balance, 1.01 ether);
        assertEq(rewardManagement.getCredit(alice), 13413560302917342);
    }

    // Test Reward Distribution without giving reward
    function testRewardDistributionWithoutGive() public {
        vm.startPrank(alice);
        uint256 question_id = rewardManagement.askQuestion{value: 0.01 ether}(
            "What is DeFi?",
            1,
            0,
            0
        );
        vm.stopPrank();

        vm.startPrank(bob);
        uint256 answer_id = rewardManagement.postAnswer(
            question_id,
            "Decentralized Finance"
        );
        vm.stopPrank();

        vm.startPrank(alice);
        rewardManagement.closeQuestion(question_id, false);
        vm.stopPrank();

        assertEq(address(alice).balance, 1 ether);
        assertEq(address(bob).balance, 1 ether);
    }

    receive() external payable {}
}
