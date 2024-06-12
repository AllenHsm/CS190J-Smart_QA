// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ReentrancyGuard.sol";
import {SmartQA as ImportedSmartQA} from "./Contracts.sol";
import {Test, console2} from "forge-std/Test.sol";

contract SmartQA is Test {
    ImportedSmartQA public smartQA;

    address public alice = address(0x1);
    address public bob = address(0x2);
    address public carol = address(0x3);

    function setUp() public {
        smartQA = new ImportedSmartQA();
    }

    // Example test function
    function testUserRegistration() public {
        vm.prank(alice);
        smartQA.registerUser("Alice");
        bool isRegistered = smartQA.hasRegistered(alice);
        assert(isRegistered);
    }
    

    // Additional test functions can be added here

}


