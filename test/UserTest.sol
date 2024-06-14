// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {Test, console2} from "forge-std/Test.sol";

import {UserManagement} from "../src/UserManagement.sol";

contract UserManagementTest is Test {
    UserManagement uint104serManagement;
    address alice = address(0x1);
    address bob = address(0x2);
    address charlie = address(0x3);

    function setUp() public {
        userManagement = new UserManagement(vakue);
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
        vm.deal(charlie, 1 ether);
    }
    function testRegisterUser() public {
        console2.log("Test: Register User");

        vm.prank(alice);
        userManagement.registerUser("Alice");

        (string memory username, address userAddress, uint256 credit) = userManagement.userAddrMap(alice);
        assertEq(username, "Alice");
        assertEq(userAddress, alice);
        assertEq(credit, 0.01 ether);
    }


}