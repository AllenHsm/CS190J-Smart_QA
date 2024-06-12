// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "forge-std/Test.sol";
import {SmartQA} from "./Contracts.sol";

contract SmartQATest is Test {
    SmartQA public smartQA;
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public carol = address(0x3);

    function setUp() public {
        smartQA = new SmartQA();
        deal(alice, 10 ether);

        // register alice
        vm.startPrank(alice);
        smartQA.registerUser("alice");
        vm.stopPrank();

        // register bob
        vm.startPrank(bob);
        smartQA.registerUser("bob");
        vm.stopPrank();

        // register carol
        vm.startPrank(carol);
        smartQA.registerUser("carol");
        vm.stopPrank();

        // alice ask a question
        vm.startPrank(alice);
        smartQA.askQuestion("What is the meaning of life?", 1, 1, 2);
        vm.stopPrank();

        // bob answer the question
        vm.startPrank(bob);
        smartQA.postAnswer(1, "I think the meaning of life is being happy.");
        vm.stopPrank();

        // carol endorse the answer
        vm.startPrank(carol);
        smartQA.endorse(1, 1);
        vm.stopPrank();

        // alice accept the answer
        











        





    }

    




}
