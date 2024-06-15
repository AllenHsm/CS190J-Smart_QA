// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {Test} from "forge-std/Test.sol";
import {QuestionManagement} from "../src/QuestionManagement.sol";

contract QuestionManagementTest is Test {
    QuestionManagement questionManagement;
    address alice = address(0x1);
    address bob = address(0x2);
    address charlie = address(0x3);

    function setUp() public {
        questionManagement = new QuestionManagement();
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
        vm.startPrank(alice);
        questionManagement.registerUser("Alice");
        vm.stopPrank();
        vm.startPrank(bob);
        questionManagement.registerUser("Bob");
        vm.stopPrank();
    }

    // Test the askQuestion function
    function testAskQuestion() public {
        vm.startPrank(alice);
        uint256 questionId = questionManagement.askQuestion{value: 0.005 ether}("What is Solidity?", 1, 0, 0);
        (address asker, , uint256 reward, , , bool closed, ,) = questionManagement.questionMap(questionId);
        assertEq(asker, alice);
        assertEq(reward, 0.005 ether);
        assertFalse(closed);
        vm.stopPrank();
    }
    // Test the askQuestion function with invalid reward
    function testAskQuestionInvalidReward() public {
        vm.startPrank(alice);
        vm.expectRevert("Reward must be greater than 0 and less than credit limit");
        questionManagement.askQuestion{value: 0.02 ether}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();
    }
    // Test the askQuestion function with empty content
    function testAskQuestionEmptyContent() public {
        vm.startPrank(alice);
        vm.expectRevert("Question cannot be empty");
        questionManagement.askQuestion{value: 0.005 ether}("", 1, 0, 0);
        vm.stopPrank();
    }
    // Test the askQuestion function with invalid expiration time
    function testAskQuestionInvalidExpirationTime() public {
        vm.startPrank(alice);
        vm.expectRevert("Expiration time must be greater than 1 day and less than 7 days");
        questionManagement.askQuestion{value: 0.005 ether}("What is Solidity?", 0, 0, 0);
        vm.stopPrank();
    }
    // Test IsExpired function
    function testIsExpired() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = questionManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        vm.warp(block.timestamp + 86400*2 ); //Two days later
        bool expired = questionManagement.isExpired(questionId);
        assertEq(expired, true);
        vm.stopPrank();
    }

    //Test getQuestion Content function
    function testGetQuestionContent() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = questionManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        string memory content = questionManagement.getQuestionContent(questionId);
        assertEq(content, "What is Ethereum?");
        vm.stopPrank();
    }
    // Test getQuestionReward function
    function testGetQuestionReward() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = questionManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        uint256 rewardget = questionManagement.getQuestionReward(questionId);
        assertEq(rewardget, 0.01 ether);
        vm.stopPrank();
    }
    // Test getQuestionExpirationTime function
    function testGetQuestionExpirationTime() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = questionManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        uint expirationTime = questionManagement.getQuestionExpirationTime(questionId);
        assertEq(expirationTime, block.timestamp + 86400);
        vm.stopPrank();
    }
    // Test getQuestionCurrentID function
    function testGetQuestionCurrentID() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = questionManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        uint currentID = questionManagement.getQuestionCurrentID();
        assertEq(currentID, 1);
        vm.stopPrank();
    }


}
