// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {Test} from "forge-std/Test.sol";
import {AnswerManagement} from "../src/AnswerManagement.sol";

contract AnswerManagementTest is Test {
    AnswerManagement answerManagement;
    address alice = address(0x1);
    address bob = address(0x2);
    address charlie = address(0x3);

    function setUp() public {
        answerManagement = new AnswerManagement();
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
        vm.deal(charlie, 1 ether);
        
        vm.startPrank(alice);
        answerManagement.registerUser("Alice");
        vm.stopPrank();
        
        vm.startPrank(bob);
        answerManagement.registerUser("Bob");
        vm.stopPrank();

        vm.startPrank(charlie);
        answerManagement.registerUser("Charlie");
        vm.stopPrank();
    }

    function testPostAnswer() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = answerManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(bob);
        uint256 answerId = answerManagement.postAnswer(questionId, "Ethereum is a decentralized platform.");
        
        (, , uint256 q_id, string memory content, ) = answerManagement.answerMap(answerId);
        
        assertEq(q_id, questionId);
        assertEq(content, "Ethereum is a decentralized platform.");
        vm.stopPrank();
    }
    function testPostAnswerExpiredQuestion() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = answerManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();
        vm.warp(block.timestamp + 86400*2 ); //Two days later

        vm.startPrank(bob);
        vm.expectRevert("This question is closed");
        answerManagement.postAnswer(questionId, "Ethereum is a decentralized platform.");
        vm.stopPrank();
    }
    function testQuestionerPostAnswer() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = answerManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert("You cannot answer your own question!");
        answerManagement.postAnswer(questionId, "Ethereum is a decentralized platform.");
        vm.stopPrank();
    }
    function testPostAnswerEmptyContent() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = answerManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(bob);
        vm.expectRevert("Answer content cannot be empty");
        answerManagement.postAnswer(questionId, "");
        vm.stopPrank();
    }
    function testPostAnswerTwice() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = answerManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(bob);
        answerManagement.postAnswer(questionId, "Ethereum is a decentralized platform.");
        vm.stopPrank();

        vm.startPrank(bob);
        vm.expectRevert("You cannot answer the same question twice");
        answerManagement.postAnswer(questionId, "Ethereum is a decentralized platform.");
        vm.stopPrank();
    }
    function testSelectAnswer() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = answerManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(bob);
        uint256 answerId = answerManagement.postAnswer(questionId, "Ethereum is a decentralized platform.");
        vm.stopPrank();

        vm.startPrank(alice);
        answerManagement.selectAnswer(questionId, answerId);
        (, , uint256 q_id, , bool isSelected) = answerManagement.answerMap(answerId);
        assertEq(q_id, questionId);
        assertTrue(isSelected);
        vm.stopPrank();
    }
    function testSelectAnswerExpiredQuestion() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = answerManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();
        vm.warp(block.timestamp + 86400*2 ); //Two days later

        vm.startPrank(bob);
        vm.expectRevert("The question has already been closed");
        answerManagement.selectAnswer(questionId, 1);
        vm.stopPrank();
    }
    function testCancelSelection() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = answerManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(bob);
        uint256 answerId = answerManagement.postAnswer(questionId, "Ethereum is a decentralized platform.");
        vm.stopPrank();

        vm.startPrank(alice);
        answerManagement.selectAnswer(questionId, answerId);
        (, , uint256 q_id, , bool isSelected) = answerManagement.answerMap(answerId);
        assertEq(q_id, questionId);
        assertTrue(isSelected);
        vm.stopPrank();

        vm.startPrank(alice);
        answerManagement.cancelSelection(questionId);
        (, , , , isSelected) = answerManagement.answerMap(answerId);
        assertFalse(isSelected);
        vm.stopPrank();
    }
    function testNonQuestionerCancelSelection() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = answerManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(bob);
        uint256 answerId = answerManagement.postAnswer(questionId, "Ethereum is a decentralized platform.");
        vm.stopPrank();

        vm.startPrank(bob);
        vm.expectRevert("Only the asker can cancel the selection of the best answer");
        answerManagement.cancelSelection(questionId);
        vm.stopPrank();
    }
    function testCancelSelectionExpiredQuestion() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = answerManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();
        vm.warp(block.timestamp + 86400*2 ); //Two days later

        vm.startPrank(alice);
        vm.expectRevert("The question has already been closed");
        answerManagement.cancelSelection(questionId);
        vm.stopPrank();
    }
    function testNonQuestionerSelectAnswer() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = answerManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(bob);
        uint256 answerId = answerManagement.postAnswer(questionId, "Ethereum is a decentralized platform.");
        vm.stopPrank();

        vm.startPrank(bob);
        vm.expectRevert("Only the asker can select the best answer");
        answerManagement.selectAnswer(questionId, answerId);
        vm.stopPrank();
    }
}
