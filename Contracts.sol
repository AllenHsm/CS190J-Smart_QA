// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ReentrancyGuard.sol";
import {Test, console2} from "forge-std/Test.sol";

contract SmartQA {
    address public owner;
    User[] public users;
    string[] public accountNames;
    Question[] public questions;

    // State mappings
    mapping(address => User) public userAddrMap;
    mapping(address => bool) public hasRegistered;
    mapping(uint256 => Question) public questionMap;
    mapping(uint256 => Answer) public answerMap;

    // Models' ids.
    uint256 public questionCount = 0;
    uint256 public userCount = 0;
    uint256 public answerCount = 0;
    // Event declaration
    event UserRegistered(string username, address userAddress);

    // Structs for data models
    struct Question {
        address asker;
        string content;
        uint256 reward;
        uint256 expiration_time;
        uint256 question_id;
        bool closed;
        uint256[] answer_ids;
    }

    struct User {
        string user_name;
        address user_address;
    }

    struct Answer {
        address answerer;
        uint256 answer_id;
        uint256 question_id;
        string content;
        bool isSelected;
        address[] endorsers;
    }

    constructor() {
        owner = msg.sender;
    }
    //  -------------------------------------------- events  --------------------------------------------
    event QuestionCreated(
        address asker,
        string content,
        uint256 reward,
        uint256 expiration_time,
        uint256 question_id,
        bool closed,
        uint256[] answer_ids
    );
    event AnswerCreated(uint256 a_id, string content, address answerer);
    event Endorse(uint256 a_id, address endorser);
    event AnswerSelected(uint256 a_id);
    event QuestionClosed(uint256 q_id);
    //  -------------------------------------------- modifiers  --------------------------------------------
    modifier isRegistered(address addr) {
        bool flag = true;
        for (uint i = 0; i < userCount; i++) {
            if (users[i].user_address == addr) {
                flag = false;
            }
        }
        require(flag, "The address was registered");
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
        require(flag, "The username is duplicate, please try another one");
        _;
    }

    modifier isEndorsedBySameUser(address addr, uint256 answer_id) {
        bool flag = true;
        for (uint i = 0; i < answerMap[answer_id].endorsers.length; i++) {
            if (answerMap[answer_id].endorsers[i] == addr) {
                flag = false;
            }
        }
        require(flag, "You can only endorse the same question once");
        _;
    }

    //  -------------------------------------------- Accesser  --------------------------------------------
    function getUserQuestions(
        address addr
    ) public view returns (Question[] memory) {
        Question[] memory userQuestions;
        uint256 count = 0;
        for (uint i = 0; i < questionCount; i++) {
            if (questionMap[i].asker == addr) {
                userQuestions[count] = questionMap[i];
                count++;
            }
        }
        return userQuestions;
    }
    function getQuestion(uint256 q_id) public view returns (string memory) {
        // user should not call this
        require(q_id <= questionCount, "The input question id is invalid");
        Question memory question = questionMap[q_id];
        return (question.content);
    }
    function getAnswers(uint256 a_id) public view returns (string memory) {
        require(a_id < answerCount, "The input answer id is invalid");
        Answer memory answer = answerMap[a_id];
        return (answer.content);
    }
    function getNumOfEndorse(uint256 a_id) public view returns (uint256) {
        require(a_id < answerCount, "The input answer id is invalid");
        Answer memory answer = answerMap[a_id];
        return (answer.endorsers.length);
    }
    function isAnswerSelected(uint a_id) public view returns (bool) {
        require(a_id < answerCount, "The input answer id is invalid");
        Answer memory answer = answerMap[a_id];
        return answer.isSelected;
    }
    function getDuration(uint256 q_id) public view returns (uint256) {
        require(q_id < questionCount, "The input question id is invalid");
        Question memory question = questionMap[q_id];
        return (question.expiration_time);
    }
    function getParticipantCount(uint256 q_id) public view returns (uint256) {
        require(q_id < questionCount, "The input question id is invalid");
        Question memory question = questionMap[q_id];
        return question.answer_ids.length;
    }
    function getParticipantAddr() public view returns (address) {
        return msg.sender;
    }
    function getNumOfEndorsement(uint256 a_id) public view returns (uint256) {
        require(a_id < answerCount, "The input answer id is invalid");
        Answer memory answer = answerMap[a_id];
        return answer.endorsers.length;
    }
    function isExpired(uint256 q_id) public view returns (bool) {
        require(q_id < questionCount, "The input question id is invalid");
        Question memory question = questionMap[q_id];
        return ((block.timestamp > question.expiration_time) ||
            question.closed);
    }
    // ------------------------------------------- Update functions ----------------------------------------------
    function selectAnswer(uint256 q_id, uint256 a_id) public {
        require(
            hasRegistered[msg.sender],
            "User must be registered to select an answer"
        );
        uint256[] memory answerIds = questionMap[q_id].answer_ids;
        for (uint256 i = 0; i < answerIds.length; i++) {
            if (answerMap[answerIds[i]].isSelected == true) {
                answerMap[answerIds[i]].isSelected = false;
                break;
            }
        }
        answerMap[a_id].isSelected = true;
    }
    function closeQuestion(uint256 q_id) public {
        require(
            hasRegistered[msg.sender],
            "User must be registered to close a question"
        );
        require(
            !questionMap[q_id].closed,
            "The question has already been closed"
        );
        questionMap[q_id].closed = true;
    }
    // ------------------------------------------- Create functions ----------------------------------------------
    function registerUser(string memory _username) public {
        require(bytes(_username).length > 0, "Username cannot be empty");
        require(!hasRegistered[msg.sender], "Address already registered");

        User memory newUser = User(_username, msg.sender);
        users.push(newUser);
        userAddrMap[msg.sender] = newUser;
        accountNames.push(_username);
        hasRegistered[msg.sender] = true;
        userCount++;

        emit UserRegistered(_username, msg.sender);
    }

    function askQuestion(
        // todo: duration input should be day, hour, minutes respectively and convert to seconds
        string memory _content,
        uint256 _reward,
        uint256 _day,
        uint256 _hour,
        uint256 _min
    ) public payable returns (uint256) {
        require(
            hasRegistered[msg.sender],
            "User must be registered to ask a question"
        );
        require(_reward > 0, "Reward must be greater than 0");
        require(bytes(_content).length > 0, "Question content cannot be empty");
        uint256 question_id = ++questionCount;
        uint256 _expirationTime = _day * 86400 + _hour * 3600 + _min * 60;
        Question memory newQuestion = Question(
            msg.sender,
            _content,
            _reward,
            block.timestamp + _expirationTime,
            question_id,
            false,
            new uint256[](0)
        );
        questions.push(newQuestion);
        return question_id;
    }

    function postAnswer(
        uint256 question_id,
        string memory content
    ) public returns (uint256) {
        require(
            !isExpired(question_id),
            "This question is closed"
        );
        require(
            hasRegistered[msg.sender],
            "User must be registered to answer a question"
        );
        require(bytes(content).length > 0, "Answer content cannot be empty");
        address[] memory endorsers;
        uint256 answer_id = ++answerCount;
        Answer memory newAnswer = Answer(
            msg.sender,
            answer_id,
            question_id,
            content,
            false,
            endorsers
        );
        answerMap[answer_id] = newAnswer;
        questionMap[question_id].answer_ids.push(answer_id);
        return answer_id;
    }

    function endorse(uint256 answer_id, uint256 question_id) public {
        require(!isExpired(question_id), "This question is closed");
        require(
            hasRegistered[msg.sender],
            "User must be registered to add endorsements"
        );
        require(
            questionMap[question_id].answer_ids.length > 0,
            "There is no answer to endorse"
        );
        address[] memory ansEndorsers = answerMap[answer_id].endorsers;
        bool hasEndorsed = false;
        for (uint i = 0; i < ansEndorsers.length; i++) {
            if (ansEndorsers[i] == msg.sender) {
                hasEndorsed = true;
            }
        }
        require(!hasEndorsed, "User can not endorse an answer twice");

        answerMap[answer_id].endorsers.push(msg.sender);
    }
}
