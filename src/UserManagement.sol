// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {Queue} from "./Queue.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";

contract UserManagement is ReentrancyGuard {
    address public owner;
    User[] public users;
    string[] public accountNames;
    mapping(address => User) public userAddrMap;
    mapping(address => bool) public hasRegistered;
    mapping(address => Queue) public rewardRecordsMap;

    uint256 public userCount = 0;

    struct User {
        string user_name;
        address user_address;
        uint256 credit;
    }

    event UserRegistered(string username, address userAddress, uint256 default_credit);
    event UserCreditUpdate(address user_addr, uint256 prev_credit, uint256 new_credit);

    modifier isRegistered(address addr) {
        require(!hasRegistered[addr], "The address was registered");
        _;
    }

    modifier isNameDuplicate(string memory name) {
        bool flag = true;
        for (uint i = 0; i < userCount; i++) {
            if (
                keccak256(bytes(users[i].user_name)) == keccak256(bytes(name))
            ) {
                flag = false;
            }
        }
        require(flag, "duplicate username");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function registerUser(string memory _username) public isRegistered(msg.sender) isNameDuplicate(_username) {
        require(bytes(_username).length > 0, "Username is empty");

        User memory newUser = User(_username, msg.sender, 0.01 ether);
        users.push(newUser);
        userAddrMap[msg.sender] = newUser;
        accountNames.push(_username);
        hasRegistered[msg.sender] = true;
        userCount++;

        Queue rewardHistory = new Queue();
        for (uint256 i = 0; i < 5; i++){
            rewardHistory.enqueue(0.00447 ether);  // initialize the default reward history, such that the default credit is 0.01 ether
        }
        rewardRecordsMap[msg.sender] = rewardHistory;
        emit UserRegistered(_username, msg.sender, 0.01 ether);
    }

    function calculate_credit(address userAddress) public returns (uint256) {
        uint256 sqr_sum = rewardRecordsMap[userAddress].sqr_sum(); 
        emit UserCreditUpdate(userAddress, userAddrMap[userAddress].credit, sqrt(sqr_sum));
        userAddrMap[userAddress].credit = sqrt(sqr_sum); 
        return userAddrMap[userAddress].credit;
    }

    function sqrt(uint256 x) public pure returns (uint256 y) {    // Function From: https://ethereum.stackexchange.com/questions/2910/can-i-square-root-in-solidity
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    function getCredit(address userAddress) public view returns (uint256) {
        require(
            hasRegistered[userAddress],
            "User must be registered to get credit"
        );
        return userAddrMap[userAddress].credit;
    }
}
