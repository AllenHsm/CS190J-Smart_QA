// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./AnswerManagement.sol";

contract RewardManagement is AnswerManagement {
    uint256 private balance = 0;

    event RewardDistributed(uint256 q_id, address[] recipients);
    event MoneyReceived(address payer, uint256 value);

    constructor() payable {
        balance = msg.value;
    }

    function rewardDistribute(uint256 question_id, bool giveReward) public payable {
        require(questionMap[question_id].asker == msg.sender);
        require(questionMap[question_id].closed);
        require(!questionMap[question_id].distributed);
        if (questionMap[question_id].selected){
            require(giveReward, "If you select the best answer, you have to give out reward"); 
        }
        uint256 reward = questionMap[question_id].reward;
        if (questionMap[question_id].selected && questionMap[question_id].closed) {
            
            address selectedAnswerer = getSelectedAnswerAddress(question_id);
            address[] memory selectedAnswer = new address[](1);
            selectedAnswer[0] = selectedAnswerer;
            require(address(this).balance >= reward);
            (bool r, ) = selectedAnswerer.call{value: reward}("");
            require(r);
            emit RewardDistributed(question_id, selectedAnswer);
        } else if (questionMap[question_id].closed && !questionMap[question_id].selected && giveReward) {
            address[] memory recipients = checkEndorsement(question_id);
            rewardDistributeByExpirationTime(question_id, recipients);
            emit RewardDistributed(question_id, recipients);
        } else {
            (bool r, ) = (msg.sender).call{value: reward}("");
            reward = 0;
            require(r);
        }
        Queue rewardHistory = rewardRecordsMap[msg.sender];
        rewardHistory.dequeue();
        rewardHistory.enqueue(reward);
        rewardRecordsMap[msg.sender] = rewardHistory;
        calculate_credit(msg.sender);
    }

    function rewardDistributeByExpirationTime(uint256 question_id, address[] memory recipients) private {
        require(isExpired(question_id));
        require(questionMap[question_id].closed);
        require(questionMap[question_id].asker == msg.sender);

        uint256 reward = questionMap[question_id].reward;
        uint256 average_reward = reward / recipients.length;
        for (uint i = 0; i < recipients.length; i++) {
            require(address(this).balance >= average_reward);
            (bool r, ) = recipients[i].call{value: average_reward}("");
            require(r);
        }
    }

    function getSelectedAnswerAddress(uint256 q_id) private view returns (address) {
        require(q_id <= questionCount);
        Question memory question = questionMap[q_id];
        uint256[] memory answerIds = question.answer_ids;
        for (uint256 i = 0; i < answerIds.length; i++) {
            if (answerMap[answerIds[i]].isSelected) {
                return answerMap[answerIds[i]].answerer;
            }
        }
        return address(0);
    }

    function checkEndorsement(uint256 q_id) public view returns (address[] memory) {
        require(hasRegistered[msg.sender]);
        require(questionMap[q_id].closed);
        require(questionMap[q_id].asker == msg.sender);

        uint256[] memory answerIds = questionMap[q_id].answer_ids;
        uint256 maxEndorsement = 0;

        for (uint i = 0; i < answerIds.length; i++) {
            if (answerMap[answerIds[i]].endorsers.length > maxEndorsement) {
                maxEndorsement = answerMap[answerIds[i]].endorsers.length;
            }
        }

        uint256 count = 0;
        for (uint i = 0; i < answerIds.length; i++) {
            if (answerMap[answerIds[i]].endorsers.length == maxEndorsement) {
                count++;
            }
        }

        address[] memory endorsers = new address[](count);
        uint256 index = 0;

        for (uint i = 0; i < answerIds.length; i++) {
            if (answerMap[answerIds[i]].endorsers.length == maxEndorsement) {
                endorsers[index] = answerMap[answerIds[i]].answerer;
                index++;
            }
        }

        return endorsers;
    }

}
