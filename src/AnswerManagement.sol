// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./QuestionManagement.sol";

contract AnswerManagement is QuestionManagement {
    struct Answer {
        address answerer;
        uint256 answer_id;
        uint256 question_id;
        string content;
        bool isSelected;
        address[] endorsers;
    }

    mapping(uint256 => Answer) public answerMap;
    uint256 public answerCount = 0;

    event AnswerCreated(uint256 q_id, uint256 a_id, string content, uint256 reward);
    event Endorse(uint256 a_id, address endorser, uint256 q_id);
    event AnswerSelected(uint256 q_id, uint256 a_id);
    event CancelSelection(uint256 q_id);

    function postAnswer(uint256 question_id, string memory content) public returns (uint256) {
        require(!isExpired(question_id), "The question is closed");
        require(hasRegistered[msg.sender], "User must be registered to answer a question");
        require(bytes(content).length > 0, "Answer cannot be empty");
        require(questionMap[question_id].asker != msg.sender, "You cannot answer your own question!");
        // require(question_id <= questionCount, "The input question id is invalid");

        for (uint i = 0; i < questionMap[question_id].answer_ids.length; i++) {
            require(answerMap[questionMap[question_id].answer_ids[i]].answerer != msg.sender, "You cannot answer the same question twice");
        }

        address[] memory endorsers;
        uint256 answer_id = ++answerCount;
        Answer memory newAnswer = Answer(msg.sender, answer_id, question_id, content, false, endorsers);
        answerMap[answer_id] = newAnswer;
        questionMap[question_id].answer_ids.push(answer_id);

        emit AnswerCreated(question_id, answer_id, content, questionMap[question_id].reward);
        return answer_id;
    }

    function endorse(uint256 answer_id, uint256 question_id) external {
        require(!isExpired(question_id), "The question is closed");
        require(hasRegistered[msg.sender], "User must be registered to add endorsements");
        require(answerMap[answer_id].answerer != msg.sender, "You cannot endorse your own answer");
        require(answerMap[answer_id].question_id == question_id, "The answer does not belong to the question"); // todo answerid nonexist

        address[] memory ansEndorsers = answerMap[answer_id].endorsers;
        bool hasEndorsed = false;
        for (uint i = 0; i < ansEndorsers.length; i++) {
            if (ansEndorsers[i] == msg.sender) {
                hasEndorsed = true;
            }
        }
        require(!hasEndorsed, "User cannot endorse an answer twice");

        emit Endorse(answer_id, msg.sender, question_id);
        answerMap[answer_id].endorsers.push(msg.sender);
    }

    function selectAnswer(uint256 q_id, uint256 a_id) public {
        require(!isExpired(q_id), "The question is closed");
        require(questionMap[q_id].asker == msg.sender, "Only the asker can select the best answer");
        require(answerMap[a_id].question_id == q_id, "The answer does not belong to this question");

        uint256[] memory answerIds = questionMap[q_id].answer_ids;
        if (questionMap[q_id].selected) {
            for (uint256 i = 0; i < answerIds.length; i++) {
                if (answerMap[answerIds[i]].isSelected == true) {
                    answerMap[answerIds[i]].isSelected = false;
                    break;
                }
            }
        }
        questionMap[q_id].selected = true;
        answerMap[a_id].isSelected = true;
        emit AnswerSelected(q_id, a_id);
    }

    function cancelSelection(uint256 q_id) public {
        require(questionMap[q_id].asker == msg.sender, "Only the asker can cancel selection");
        require(!isExpired(q_id), "The question is closed");
        require(questionMap[q_id].selected, "No answer is selected");

        uint256[] memory answerIds = questionMap[q_id].answer_ids;
        
        for (uint256 i = 0; i < answerIds.length; i++) {
            if (answerMap[answerIds[i]].isSelected == true) {
                answerMap[answerIds[i]].isSelected = false;
                break;
            }
        }
        
        questionMap[q_id].selected = false;
        emit CancelSelection(q_id);
    }
    function getAnswerID(uint256 q_id) public view returns(uint256[] memory){
        return questionMap[q_id].answer_ids;
    }
    function getAnswerContent(uint256 a_id) public view returns(string memory){
        return answerMap[a_id].content;
    }
    function getNumberOfEndorsements(uint256 a_id) public view returns(uint256){
        return answerMap[a_id].endorsers.length;
    }

}
