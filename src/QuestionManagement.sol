// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./UserManagement.sol";

contract QuestionManagement is UserManagement {
    struct Question {
        address asker;
        string content;
        uint256 reward;
        uint256 expiration_time;
        uint256 question_id;
        bool selected;
        bool closed;
        bool distributed;
        uint256[] answer_ids;
    }

    mapping(uint256 => Question) public questionMap;
    Question[] public questions;
    uint256 public questionCount = 0;

    event QuestionCreated(
        address asker,
        string content,
        uint256 reward,
        uint256 expiration_time,
        uint256 question_id,
        bool closed,
        uint256[] answer_ids
    );
    event QuestionClosed(uint256 q_id);

    function askQuestion(string memory _content, uint256 _day, uint256 _hour, uint256 _min) external payable returns (uint256) {
        //UserManagement user; 
        require(hasRegistered[msg.sender], "User not registered");
        require(msg.value > 0 && msg.value <= getCredit(msg.sender), "Reward must be greater than 0 and less than credit limit");
        require(bytes(_content).length > 0, "Question content is empty");

        uint256 _expirationTime = _day * 86400 + _hour * 3600 + _min * 60;
        require(_expirationTime >= 86400 && _expirationTime <= 604800, "Expiration time must be greater than 1 day and less than 7 days");

        uint256 question_id = ++questionCount;
        Question memory newQuestion = Question(
            msg.sender,
            _content,
            msg.value,
            block.timestamp + _expirationTime,
            question_id,
            false,
            false,
            false,
            new uint256[](0)
        );
        questions.push(newQuestion);
        questionMap[question_id] = newQuestion;

        emit QuestionCreated(msg.sender, _content, msg.value, block.timestamp + _expirationTime, question_id, false, new uint256[](0) );
        return question_id;
    }

    function closeQuestion(uint256 q_id) public {
        require(hasRegistered[msg.sender], "User must be registered to close a question");
        require(questionMap[q_id].asker == msg.sender, "Only the asker can close the question");
        require(!isExpired(q_id), "The question has already been closed");
        require(q_id <= questionCount, "The input question id is invalid");

        questionMap[q_id].closed = true;
        emit QuestionClosed(q_id);
    }

    function isExpired(uint256 q_id) public returns (bool) {
        require(q_id <= questionCount, "The input question id is invalid");
        Question memory question = questionMap[q_id];
        if (block.timestamp > question.expiration_time) {
            questionMap[q_id].closed = true;
        }
        return ((block.timestamp > question.expiration_time) || question.closed);
    }
    receive() external payable {}
}
