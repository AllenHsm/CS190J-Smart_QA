// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {Test, console2} from "forge-std/Test.sol";
import {SmartQA} from "../src/Contracts.sol";
import {Queue} from "../src/Queue.sol";

contract SmartQATest is Test {
    SmartQA smartQA;
    address alice = address(0x1);
    address bob = address(0x2);
    address charlie = address(0x3);

    function setUp() public {
        smartQA = new SmartQA{value: 1 ether}();
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
        vm.deal(charlie, 1 ether);
    }

    function testRegisterUser() public {
        console2.log("Test: Register User");

        vm.prank(alice);
        smartQA.registerUser("Alice");

        (string memory username, address userAddress, uint256 credit) = smartQA.userAddrMap(alice);
        assertEq(username, "Alice");
        assertEq(userAddress, alice);
        assertEq(credit, 0.01 ether);
    }
    

}
