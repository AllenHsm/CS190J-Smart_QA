// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {Test} from "forge-std/Test.sol";
import {QuestionManagement} from "../src/QuestionManagement.sol";

contract QuestionManagementTest is Test {
    QuestionManagement questionManagement;
    address alice = address(0x1);
    address bob = address(0x2);

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

    function testAskQuestion() public {
        vm.startPrank(alice);
        uint256 qId = questionManagement.askQuestion("What is the meaning of life?", 1, 0, 0);
        (, string memory content, uint256 reward, , , bool closed, ,) = questionManagement.questionMap(qId);

        assertEq(content, "What is the meaning of life?");
        assertEq(reward, 0.1 ether);
        assertFalse(closed);
        vm.stopPrank();
    }

    function testFailAskQuestionWithoutRegistration() public {
        vm.startPrank(address(0x3));
        vm.expectRevert("User not registered");
        questionManagement.askQuestion("How does blockchain work?", 1, 0, 0, {value: 0.01 ether});
    }

    function testFailAskQuestionWithInsufficientCredit() public {
        vm.startPrank(alice);
        vm.expectRevert("Reward must be greater than 0 and less than credit limit");
        questionManagement.askQuestion("How to increase gas efficiency?", 1, 0, 0);
    }

    function testCloseQuestion() public {
        vm.startPrank(alice);
        uint256 qId = questionManagement.askQuestion("What is DeFi?", 1, 0, 0);
        questionManagement.closeQuestion(qId);
        assertTrue(questionManagement.questionMap(qId).closed);
        vm.stopPrank();
    }

    function testFailCloseQuestionByNonAsker() public {
        vm.startPrank(alice);
        uint256 qId = questionManagement.askQuestion("What is Ethereum?", 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(bob);
        vm.expectRevert("Only the asker can close the question");
        questionManagement.closeQuestion(qId);
    }

    function testIsExpired() public {
        vm.startPrank(alice);
        uint256 qId = questionManagement.askQuestion("What is the best crypto?", 0, 0, 1);
        skip(61);  // Skip 61 seconds to ensure the question is expired
        bool expired = questionManagement.isExpired(qId);
        assertTrue(expired);
        vm.stopPrank();
    }

    receive() external payable {}
}
