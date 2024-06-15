// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./AnswerManagement.sol";

contract RewardManagement is AnswerManagement {

    event RewardDistributed(uint256 q_id, address[] recipients);
    event MoneyReceived(address payer, uint256 value);

    function closeQuestion(uint256 q_id, bool giveReward) public nonReentrant {
        require(!isExpired(q_id), "The question has already been closed");
        require(questionMap[q_id].asker == msg.sender, "Only the asker can close the question");
        //require(q_id <= questionCount, "The input question id is invalid");
        questionMap[q_id].closed = true;
        if (!questionMap[q_id].distributed) {
            rewardDistribute(q_id, giveReward);
        }

        emit QuestionClosed(q_id);
    }

    function rewardDistribute(uint256 question_id, bool giveReward) private  {
        require(isExpired(question_id), "2 4");
        require(!questionMap[question_id].distributed, "2 5");
        if (questionMap[question_id].selected){
            require(giveReward, "If you select the best answer, you have to give out reward"); 
        }
        uint256 reward = questionMap[question_id].reward;
        if (questionMap[question_id].selected) {
            address selectedAnswerer = getSelectedAnswerAddress(question_id);
            address[] memory selectedAnswer = new address[](1);
            selectedAnswer[0] = selectedAnswerer;
            require(address(this).balance >= reward, "3 4");
            (bool r, ) = selectedAnswerer.call{value: reward}("");
            require(r, "Reward distribution failed ");
            questionMap[question_id].distributed = true;
            emit RewardDistributed(question_id, selectedAnswer);
        } else if (!questionMap[question_id].selected && giveReward) {
            rewardDistributeByExpirationTime(question_id);
        } else{
            (bool r, ) = (msg.sender).call{value: reward}("");
            reward = 0;
            require(r, "Reward distribution failed");
            questionMap[question_id].distributed = true;
        }
        if (questionMap[question_id].answer_ids.length ==0){ 
            return; // No answer to the question, do not update usercredit
        }
        Queue rewardHistory = rewardRecordsMap[msg.sender];
        rewardHistory.dequeue();
        rewardHistory.enqueue(reward);
        rewardRecordsMap[msg.sender] = rewardHistory;
        calculate_credit(msg.sender);
    }

    function rewardDistributeByExpirationTime(uint256 question_id) public nonReentrant {
        require(hasRegistered[msg.sender], "The address is not registered");
        require(isExpired(question_id), "5 9");
        require(!questionMap[question_id].distributed, "6 0");
        uint256 reward = questionMap[question_id].reward;
        if (questionMap[question_id].selected) {
            address selectedAnswerer = getSelectedAnswerAddress(question_id);
            address[] memory selectedAnswer = new address[](1);
            selectedAnswer[0] = selectedAnswerer;
            require(address(this).balance >= reward, "6 6");
            (bool r, ) = selectedAnswerer.call{value: reward}("");
            require(r,"Reward distribution failed 68");
            questionMap[question_id].distributed = true;
            emit RewardDistributed(question_id, selectedAnswer);
        }
        else {
            address[] memory recipients = checkEndorsement(question_id);
            if (recipients.length==0) {
                (bool r, ) = (questionMap[question_id].asker).call{value: reward}("");
                require(r, "Reward distribution failed");
                questionMap[question_id].distributed = true;
                emit RewardDistributed(question_id, recipients);
                return;
            }
            uint256 average_reward = reward / recipients.length;
            for (uint i = 0; i < recipients.length; i++) {
                require(address(this).balance >= average_reward);
                (bool r, ) = recipients[i].call{value: average_reward}("");
                require(r,"Reward distribution failed 85");
                questionMap[question_id].distributed = true;
            }
            emit RewardDistributed(question_id, recipients);
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
        require(questionMap[q_id].closed, "The question is not closed");

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
