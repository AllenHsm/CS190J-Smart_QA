// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "src/AnswerManagement.sol";

contract RewardManagement is AnswerManagement {
    uint256 private balance = 0;
    mapping(address => Queue) public rewardRecordsMap;

    event RewardDistributed(uint256 q_id, address[] recipients);
    event MoneyReceived(address payer, uint256 value);
    event UserCreditUpdate(address user_addr, uint256 prev_credit, uint256 new_credit);

    constructor() payable {
        balance = msg.value;
    }

    function calculate_credit(address userAddress) public returns (uint256) {
        uint256 sqr_sum = rewardRecordsMap[userAddress].sqr_sum();
        emit UserCreditUpdate(userAddress, getCredit(userAddress), sqr_sum);
        return sqrt(sqr_sum);
    }

    function sqrt(uint256 x) public pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    function rewardDistribute(uint256 question_id, bool giveReward) public payable {
        require(questionMap[question_id].asker == msg.sender, "Only the asker can distribute the reward");
        require(questionMap[question_id].closed, "The question has not been closed");
        require(questionMap[question_id].distributed == false, "The reward has already been distributed");

        if (questionMap[question_id].selected && questionMap[question_id].closed) {
            uint256 reward = questionMap[question_id].reward;
            address selectedAnswerer = getSelectedAnswerAddress(question_id);
            address[] memory selectedAnswer;
            selectedAnswer[0] = selectedAnswerer;
            (bool r, ) = selectedAnswerer.call{value: reward}("");
            require(r, "Failed to transfer the reward.");
            emit RewardDistributed(question_id, selectedAnswer);
        } else if (questionMap[question_id].closed && !questionMap[question_id].selected && giveReward) {
            address[] memory recipients = checkEndorsement(question_id);
            rewardDistributeByExpirationTime(question_id, recipients);
            emit RewardDistributed(question_id, recipients);
        }

        Queue rewardHistory = rewardRecordsMap[msg.sender];
        rewardHistory.dequeue();
        rewardHistory.enqueue(questionMap[question_id].reward);
        rewardRecordsMap[msg.sender] = rewardHistory;
        calculate_credit(msg.sender);
    }

    function rewardDistributeByExpirationTime(uint256 question_id, address[] memory recipients) private {
        require(isExpired(question_id), "The question has not been expired");
        require(questionMap[question_id].closed, "The question has not been closed");
        require(questionMap[question_id].asker == msg.sender, "Only the asker can distribute the reward");

        uint256 reward = questionMap[question_id].reward;
        uint256 average_reward = reward / recipients.length;
        for (uint i = 0; i < recipients.length; i++) {
            (bool r, ) = recipients[i].call{value: average_reward}("");
            require(r, "Failed to transfer the reward.");
        }
    }

    function getSelectedAnswerAddress(uint256 q_id) private view returns (address) {
        require(q_id <= questionCount, "The input question id is invalid");
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
        require(hasRegistered[msg.sender], "User must be registered to check endorsement");
        require(questionMap[q_id].closed, "The question has not been closed");
        require(questionMap[q_id].asker == msg.sender, "Only the asker can check the endorsement");

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

    receive() external payable {
        balance += msg.value;
    }
}
