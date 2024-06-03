// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract SmartQA {
    address public owner;
    User[] public users;
    string[] public accountNames;

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
    Question[] public questions;

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
    function getQuestion(uint256 q_id) public view returns (string memory) {
        Question memory question = questionMap[q_id];
        return (question.content);
    }
    function getAnswers(uint256 a_id) public view returns (string memory) {
        Answer memory answer = answerMap[a_id];
        return (answer.content);
    }
    function getNumOfEndorse(uint256 a_id) public view returns (uint256) {
        Answer memory answer = answerMap[a_id];
        return (answer.endorsers.length);
    }
    function isAnswerSelected(uint a_id) public view returns (bool) {
        Answer memory answer = answerMap[a_id];
        return answer.isSelected;
    }
    function getDuration(uint256 q_id) public view returns (uint256) {
        Question memory question = questionMap[q_id];
        return (question.expiration_time);
    }
    function getParticipantCount(uint q_id) public view returns (uint256) {
        Question memory question = questionMap[q_id];
        return question.answer_ids.length;
    }
    function getParticipantAddr () public view returns (address){
        return msg.sender; 
    }
    function getNumOfEndorsement(uint256 a_id) public view returns (uint256) {
        Answer memory answer = answerMap[a_id];
        return answer.endorsers.length;
    }
    // ------------------------------------------- Update functions ----------------------------------------------
    function selectAnswer(uint256 a_id) public {
        require(
            hasRegistered[msg.sender],
            "User must be registered to select an answer"
        );
        answerMap[a_id].isSelected = true;
    }
    function closeQuestion(uint256 q_id) public {
        require(
            hasRegistered[msg.sender],
            "User must be registered to close a question"
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
        string memory _content,
        uint256 _reward,
        uint256 _expirationTime
    ) public {
        require(
            hasRegistered[msg.sender],
            "User must be registered to ask a question"
        );
        require(_reward > 0, "Reward must be greater than 0");
        require(bytes(_content).length > 0, "Question content cannot be empty");

        Question memory newQuestion = Question(
            msg.sender,
            _content,
            _reward,
            block.timestamp + _expirationTime,
            questionCount,
            false,
            new uint256[](0)
        );
        questions.push(newQuestion);
        questionCount++;
    }

    function postAnswer(
        uint256 answer_id,
        uint256 question_id,
        string memory content
    ) public {
        require(
            hasRegistered[msg.sender],
            "User must be registered to answer a question"
        );
        require(bytes(content).length > 0, "Answer content cannot be empty");
        address[] memory endorsers;
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
        answerCount++;
    }

    function endorse(
        uint256 answer_id,
        uint256 question_id
    ) public {
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
        require(
            !hasEndorsed,
            "User can not endorse an answer twice"
        );

        answerMap[answer_id].endorsers.push(msg.sender);
    }

    
}
