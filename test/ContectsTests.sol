// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "forge-std/Test.sol";
import "../src/Contracts.sol";

contract TestSmartQA is Test {
    SmartQA public smartQA;
    address public owner;
    address public addr1 = address(0x10);
    address public addr2 = address(0x11);
    address public addr3 = address(0x12);
    address public addr4 = address(0x13);
    address public addr5 = address(0x14);

    function setUp() public {
        owner = address(this);
        addr1 = vm.addr(1);
        addr2 = vm.addr(2);
        smartQA = new SmartQA{value: 1 ether}();
    }

    function testRegisterUser() public {
        vm.prank(addr1);
        smartQA.registerUser("Alice");

        (string memory username, address userAddress) = smartQA.userAddrMap(addr1);
        bool isRegistered = smartQA.hasRegistered(addr1);

        assertEq(username, "Alice", "Username should be Alice");
        assertEq(userAddress, addr1, "User address should match");
        assertTrue(isRegistered, "User should be registered");
    }

    function testCannotRegisterTwice() public {
        vm.prank(addr1);
        smartQA.registerUser("Alice");

        vm.expectRevert("Address already registered");
        vm.prank(addr1);
        smartQA.registerUser("Alice");
    }

    function testCannotRegisterWithEmptyUsername() public {
        vm.expectRevert("Username cannot be empty");
        vm.prank(addr2);
        smartQA.registerUser("");
    }
    
    function testAskQuestion() public {
        vm.prank(addr2);
        smartQA.registerUser("Bob");

        string memory questionContent = "How does blockchain work?";
        uint256 questionId;

        vm.deal(addr2, 1 ether);
        vm.prank(addr2);
        questionId = smartQA.askQuestion{value: 0.1 ether}(questionContent, 1, 0, 0);

        (string memory content, uint256 reward, uint256 expiration_time) = smartQA.getQuestion(questionId);
        assertTrue(reward == 0.1 ether, "Reward should be 0.1 ether");
        assertEq(content, questionContent, "Content should match the input");
        assertTrue(expiration_time > block.timestamp, "Expiration time should be set correctly");
    }

    function testAskQuestionWithoutPayment() public {
        vm.prank(addr2);
        smartQA.registerUser("Bob");

        vm.expectRevert("Reward must be greater than 0");
        vm.prank(addr2);
        smartQA.askQuestion("What is Solidity?", 1, 0, 0);
    }

    function testPostAnswer() public {
        // Setup a question 
        vm.prank(addr3);
        smartQA.registerUser("Charlie");
        vm.prank(addr3);
        deal(addr3, 1 ether);
        uint256 questionId = smartQA.askQuestion{value: 1 ether}("What is DeFi?", 1, 0, 0);

        // Post an answer
        string memory answerContent = "Decentralized Finance";
        uint256 answerId;

        vm.prank(addr4);
        smartQA.registerUser("Dave");
        vm.prank(addr4);
        answerId = smartQA.postAnswer(questionId, answerContent);

        // Check answer details
        string memory storedContent = smartQA.getAnswers(answerId);
        assertEq(storedContent, answerContent, "Answer content should match the input");
    }

    function testCannotAnswerOwnQuestion() public {
        vm.prank(addr5);
        smartQA.registerUser("Eve");
        vm.prank(addr5);
        deal(addr5, 1 ether);
        uint256 questionId = smartQA.askQuestion{value: 1 ether}("What is Ethereum?", 1, 0, 0);

        vm.expectRevert("You cannot answer your own question!");
        vm.prank(addr5);
        smartQA.postAnswer(questionId, "A blockchain platform.");
    }

    function testSelectAnswerAndReward() public {
        vm.prank(addr1);
        smartQA.registerUser("Frank");
        vm.prank(addr2);
        smartQA.registerUser("Grace");
        vm.prank(addr1);
        deal(addr1, 1 ether);
        uint256 questionId = smartQA.askQuestion{value: 1 ether}("What is Bitcoin?", 2, 0, 0);
        vm.prank(addr2);
        uint256 answerId = smartQA.postAnswer(questionId, "A cryptocurrency.");

        vm.prank(addr1);
        smartQA.selectAnswer(questionId, answerId, true);

        bool isSelected = smartQA.isAnswerSelected(answerId);
        assertTrue(isSelected, "Answer should be marked as selected");

        assertEq(addr2.balance, 1 ether, "Reward should be transferred to the answerer.");
    }




}
