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

    // Test the PostAnswer function
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
    // Test the PostAnswer function with expired question
    function testPostAnswerExpiredQuestion() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = answerManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();
        vm.warp(block.timestamp + 86400*2 ); //Two days later

        vm.startPrank(bob);
        vm.expectRevert("The question is closed");
        answerManagement.postAnswer(questionId, "Ethereum is a decentralized platform.");
        vm.stopPrank();
    }
    // Test the PostAnswer function with questioner post answer
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
    // Test the PostAnswer function with empty content
    function testPostAnswerEmptyContent() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = answerManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(bob);
        vm.expectRevert("Answer cannot be empty");
        answerManagement.postAnswer(questionId, "");
        vm.stopPrank();
    }
    // Test the SelectAnswer function
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
    // Test the SelectAnswer function with expired question
    function testSelectAnswerExpiredQuestion() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = answerManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();
        vm.warp(block.timestamp + 86400*2 ); //Two days later

        vm.startPrank(bob);
        vm.expectRevert("The question is closed");
        answerManagement.selectAnswer(questionId, 1);
        vm.stopPrank();
    }
    // Test CalcelSelection function
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
    // Test if the cancelSelection can be called by non-questioner
    function testNonQuestionerCancelSelection() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = answerManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(bob);
        uint256 answerId = answerManagement.postAnswer(questionId, "Ethereum is a decentralized platform.");
        vm.stopPrank();

        vm.startPrank(bob);
        vm.expectRevert("Only the asker can cancel selection");
        answerManagement.cancelSelection(questionId);
        vm.stopPrank();
    }
    // Test the CancelSelection function with expired question
    function testCancelSelectionExpiredQuestion() public {
        vm.startPrank(alice);
        uint256 reward = 0.01 ether;
        uint256 questionId = answerManagement.askQuestion{value: reward}("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();
        vm.warp(block.timestamp + 86400*2 ); //Two days later

        vm.startPrank(alice);
        vm.expectRevert("The question is closed");
        answerManagement.cancelSelection(questionId);
        vm.stopPrank();
    }
    // Test if the selectAnswer can be called by non-questioner
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
