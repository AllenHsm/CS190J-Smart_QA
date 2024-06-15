// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {Test, console2} from "forge-std/Test.sol";

import {UserManagement} from "../src/UserManagement.sol";

contract UserManagementTest is Test {
    UserManagement userManagement;
    address alice = address(0x1);
    address bob = address(0x2);
    address charlie = address(0x3);

    function setUp() public {
        userManagement = new UserManagement();
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
        vm.deal(charlie, 1 ether);
    }
    // Test the registerUser function
    function testRegisterUser() public {

        vm.prank(alice);
        userManagement.registerUser("Alice");

        (string memory username, address userAddress, uint256 credit) = userManagement.userAddrMap(alice);
        assertEq(username, "Alice");
        assertEq(userAddress, alice);
        assertEq(credit, 0.01 ether);
    }
    // Test the user with duplicated names
    function testUserWithDuplicatedNames() public {
        vm.prank(alice);
        userManagement.registerUser("Alice");

        vm.expectRevert(bytes("duplicate username"));
        vm.prank(bob);
        userManagement.registerUser("Alice");
        (string memory username, address userAddress, uint256 credit) = userManagement.userAddrMap(bob);
        assertEq(username, "");
        assertEq(userAddress, address(0));
        assertEq(credit, 0);
    }
    // Test the user with empty username
    function testEmptyUsername() public {
        vm.expectRevert(bytes("Username is empty"));
        vm.prank(alice);
        userManagement.registerUser("");
        (string memory username, address userAddress, uint256 credit) = userManagement.userAddrMap(alice);
        assertEq(username, "");
        assertEq(userAddress, address(0));
        assertEq(credit, 0);
    }
    // Test the user with invalid username
    function testCreditUpdate() public {
        vm.prank(bob);
        userManagement.registerUser("Bob");

        userManagement.rewardRecordsMap(bob).dequeue();
        userManagement.rewardRecordsMap(bob).enqueue(0.01 ether);
        uint256 sqr_sum = 179923600000000000000000000000000;
        uint256 updatedCredit = userManagement.calculate_credit(bob);
        uint256 expectedCredit = userManagement.sqrt(sqr_sum);
        assertEq(updatedCredit, expectedCredit);
    }
}