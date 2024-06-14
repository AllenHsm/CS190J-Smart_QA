// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "src/QuestionManagement.sol";

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
        require(!isExpired(question_id), "This question is closed");
        require(hasRegistered[msg.sender], "User must be registered to answer a question");
        require(bytes(content).length > 0, "Answer content cannot be empty");
        require(questionMap[question_id].asker != msg.sender, "You cannot answer your own question!");
        require(question_id <= questionCount, "The input question id is invalid");

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
        require(!isExpired(question_id), "This question is closed");
        require(hasRegistered[msg.sender], "User must be registered to add endorsements");
        require(questionMap[question_id].answer_ids.length > 0, "There is no answer to endorse");
        require(answerMap[answer_id].answerer != msg.sender, "You cannot endorse your own answer");
        require(answer_id <= answerCount, "The input answer id is invalid");
        require(answerMap[answer_id].question_id == question_id, "The answer does not belong to the question");

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
        require(!isExpired(q_id), "The question has already been closed");
        require(hasRegistered[msg.sender], "User must be registered to select an answer");
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
        require(hasRegistered[msg.sender], "User must be registered to cancel the selection of an answer");
        require(questionMap[q_id].asker == msg.sender, "Only the asker can cancel the selection of the best answer");
        require(!isExpired(q_id), "The question has already been closed");
        require(questionMap[q_id].selected, "No answer for this question has been selected");

        uint256[] memory answerIds = questionMap[q_id].answer_ids;
        if (questionMap[q_id].selected) {
            for (uint256 i = 0; i < answerIds.length; i++) {
                if (answerMap[answerIds[i]].isSelected == true) {
                    answerMap[answerIds[i]].isSelected = false;
                    break;
                }
            }
        }
        questionMap[q_id].selected = false;
        emit CancelSelection(q_id);
    }
}
