// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

<<<<<<< HEAD:Contracts.sol
=======
import {Test, console2} from "forge-std/Test.sol";
>>>>>>> 4bef2aabcbb787071672304f71ffb15072e2a016:src/Contracts.sol

// If 1 ether = $3500, $5 = 0.001428 ether = 1.428 * 10^15

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
    mapping(address => uint256[5]) public records;
    

    // Models' ids.
    uint256 public questionCount = 0;
    uint256 public userCount = 0;
    uint256 public answerCount = 0;
    uint256 private  balance = 0; 
    // Event declaration

    // Structs for data models
    struct Question {
        address asker;
        string content;
        uint256 reward;
        uint256 expiration_time;
        uint256 question_id;
        bool selected;
        bool closed;
        uint256[] answer_ids;
    }

    struct User {
        string user_name;
        address user_address;
        uint256 credit;
    }

    struct Answer {
        address answerer;
        uint256 answer_id;
        uint256 question_id;
        string content;
        bool isSelected;
        address[] endorsers;
    }

    constructor() payable  {
        owner = msg.sender;
        balance = msg.value;
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

<<<<<<< HEAD:Contracts.sol
    event UserRegistered(string username, address userAddress);
    event AnswerCreated(uint256 q_id, uint256 a_id, string content, uint256 reward);
=======
    event UserRegistered(string username, address userAddress, uint256 default_credit);
    event AnswerCreated(
        uint256 q_id,
        uint256 a_id,
        string content,
        uint256 reward
    );
>>>>>>> 4bef2aabcbb787071672304f71ffb15072e2a016:src/Contracts.sol
    event Endorse(uint256 a_id, address endorser, uint256 q_id);
    event AnswerSelected(uint256 q_id, uint256 a_id);
    event CancelSelection(uint256 q_id);
    event QuestionClosed(uint256 q_id);
    event MoneyReceived(address payer, uint256 value);
    event CheckExpiration(uint256 curr_ts, uint256 expiration_time, bool isClosedByPoster); 
    event RewardDistributed(uint256 q_id, uint256[] a_ids, uint256[] receipients, uint256 average_reward); 
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
        for (uint i = 1; i <= questionCount; i++) {
            if (questionMap[i].asker == addr) {
                userQuestions[count] = questionMap[i];
                count++;
            }
        }
        return userQuestions;
    }

    function getQuestion(
        uint256 q_id
    ) public view returns (string memory, uint256, uint256) {
        // question content, reward, expiration time
        // user should not call this
        require(q_id <= questionCount, "The input question id is invalid");
        Question memory question = questionMap[q_id];
        return (question.content, question.reward, question.expiration_time);
    }
    function getAnswers(uint256 a_id) public view returns (string memory) {
        require(a_id <= answerCount, "The input answer id is invalid");
        Answer memory answer = answerMap[a_id];
        return (answer.content);
    }
    function getNumOfEndorse(uint256 a_id) public view returns (uint256) {
        require(a_id <= answerCount, "The input answer id is invalid");
        Answer memory answer = answerMap[a_id];
        return (answer.endorsers.length);
    }
    function isAnswerSelected(uint a_id) public view returns (bool) {
        require(a_id <= answerCount, "The input answer id is invalid");
        Answer memory answer = answerMap[a_id];
        return answer.isSelected;
    }
    function getDuration(uint256 q_id) public view returns (uint256) {
        require(q_id <= questionCount, "The input question id is invalid");
        Question memory question = questionMap[q_id];
        return (question.expiration_time);
    }
    function getParticipantCount(uint256 q_id) public view returns (uint256) { 
        require(q_id <= questionCount, "The input question id is invalid");
        Question memory question = questionMap[q_id];
        return question.answer_ids.length;
    }
    function getParticipantAddr() public view returns (address) {
        return msg.sender;
    }
    function isExpired(uint256 q_id) public  returns (bool) {
        require(q_id <= questionCount, "The input question id is invalid");
        Question memory question = questionMap[q_id];
        emit CheckExpiration(block.timestamp, question.expiration_time, question.closed); 
        return ((block.timestamp > question.expiration_time) ||
            question.closed);
    }
    function getCredit(address userAddress) public view returns (uint256) {
        return userAddrMap[userAddress].credit;
        
    }
    function calculate_credit(uint256[] memory rewardHistory) public pure returns (uint256){
        uint256 sqr_sum = 0; 
        for (uint256 i = 0; i < rewardHistory.length; i++){
            sqr_sum += (rewardHistory[i]) * (rewardHistory[i]); 
        }
        return sqrt(sqr_sum);
    }
    function sqrt(uint256 x)public pure returns (uint256 y) {    // Function From: https://ethereum.stackexchange.com/questions/2910/can-i-square-root-in-solidity
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y; 
    }
    // ------------------------------------------- Update functions ----------------------------------------------
    // todo 校验a_id, q_id 功能有问题 校验是否为poster answer id 是否归属于此question id
    function selectAnswer(uint256 q_id, uint256 a_id, bool giveReward) public {
        require(
            hasRegistered[msg.sender],
            "User must be registered to select an answer"
        );
        require(
            questionMap[q_id].asker == msg.sender,
            "Only the asker can select the best answer"
        );
        require(
            !questionMap[q_id].closed,
            "The question has already been closed"
            );
        require(
            answerMap[a_id].question_id == q_id,
            "The answer does not belong to this question"
        );    
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
        if (giveReward) {
            rewardDistributeByAssignedRecipent(q_id, answerMap[a_id].answerer);
        }
        emit AnswerSelected(q_id, a_id);
    }

<<<<<<< HEAD:Contracts.sol
    // todo: 校验question id 是否存在，question是否属于此地址
=======
    function cancelSelection(uint256 q_id) public {
        require(
            hasRegistered[msg.sender],
            "User must be registered to cancel the selection of an answer"
        );
        require(
            questionMap[q_id].asker == msg.sender,
            "Only the asker can cancel the selection of the best answer"
        );
        require(
            !questionMap[q_id].closed,
            "The question has already been closed"
            );
        require(
            questionMap[q_id].selected,
            "No answer for this question has been selected"
        );
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

    // 校验question id 是否存在，question是否属于此地址
>>>>>>> 4bef2aabcbb787071672304f71ffb15072e2a016:src/Contracts.sol
    function closeQuestion(uint256 q_id) public {
        require(
            hasRegistered[msg.sender],
            "User must be registered to close a question"
        );
        require(
            questionMap[q_id].asker == msg.sender,
            "Only the asker can close the question"
        );
        require(
            !questionMap[q_id].closed,
            "The question has already been closed"
        );
        //Check if the question_id is valid
        require(q_id <= questionCount, "The input question id is invalid");
        questionMap[q_id].closed = true;

        emit QuestionClosed(q_id);
    }
    // ------------------------------------------- Create functions ----------------------------------------------
    function registerUser(string memory _username) public {
        require(bytes(_username).length > 0, "Username cannot be empty");
        require(!hasRegistered[msg.sender], "Address already registered");

        User memory newUser = User(_username, msg.sender, 0.01 ether);
        users.push(newUser);
        userAddrMap[msg.sender] = newUser;
        accountNames.push(_username);
        hasRegistered[msg.sender] = true;
        userCount++;

        emit UserRegistered(_username, msg.sender, 0.01 ether);
    }

    function askQuestion(
        string memory _content,
        uint256 _day,
        uint256 _hour,
        uint256 _min
    ) external payable returns (uint256) {
        require(
            hasRegistered[msg.sender],
            "User must be registered to ask a question"
        );
        require(msg.value > 0, "Reward must be greater than 0");
        require(bytes(_content).length > 0, "Question content cannot be empty");
    
        // require(
        //     getUserBalance(msg.sender) > _reward,
        //     "Reward higher than user balance"
        // );


        uint256 _expirationTime = _day * 86400 + _hour * 3600 + _min * 60;

        require(_expirationTime >= 86400, "Expiration time must be greater than 1 day");

        uint256 question_id = ++questionCount;
        Question memory newQuestion = Question(
            msg.sender,
            _content,
            msg.value,
            block.timestamp + _expirationTime,
            question_id,
            false,
            false,
            new uint256[](0)
        );
        questions.push(newQuestion);
        questionMap[question_id] = newQuestion; 
        emit MoneyReceived(msg.sender, msg.value);
        
        return question_id;
    }

    // function deposite(uint expected_amount) external payable returns (bool) {
    //     require(
    //         hasRegistered[msg.sender],
    //         "User must be registered to deposit"
    //     );
    //     if (msg.value > expected_amount) {
    //         returnMoney(msg.sender, msg.value - expected_amount);
    //         return false;
    //     } else if (msg.value < expected_amount) {
    //         returnMoney(msg.sender, msg.value);
    //         return false;
    //     }
    //     return true;
    // }

    function returnMoney(address recipient, uint256 money) internal {
        (bool r, ) = recipient.call{value: money}("");
        require(r, "The money is not returned successfully");
    }

    function postAnswer( // todo: 不能回答一个问题两次.    finish
        uint256 question_id,
        string memory content
    ) public returns (uint256) {
        require(!isExpired(question_id), "This question is closed");
        require(
            hasRegistered[msg.sender],
            "User must be registered to answer a question"
        );
        require(bytes(content).length > 0, "Answer content cannot be empty");
        require(
            questionMap[question_id].asker != msg.sender,
            "You cannot answer your own question!"
        );
<<<<<<< HEAD:Contracts.sol
        bool answered_before = false;
        for (uint256 i = 0; i <= questionMap[question_id].answer_ids.length; i ++){
            uint256 a_id = questionMap[question_id].answer_ids[i]; 
            if (answerMap[a_id].answerer == msg.sender){
                answered_before = true;
            }
        }
        require(!answered_before, "You cannot answer the same question twice");
=======
        //check if the question_id is valid
        require(question_id <= questionCount, "The input question id is invalid");
        //check if user has already answered the question
        for (uint i = 0; i < questionMap[question_id].answer_ids.length; i++) {
            require(
                answerMap[questionMap[question_id].answer_ids[i]].answerer !=
                    msg.sender,
                "You cannot answer the same question twice"
            );
        }

>>>>>>> 4bef2aabcbb787071672304f71ffb15072e2a016:src/Contracts.sol
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
        if (questionMap[question_id].answer_ids.length == 50) {
            closeQuestion(question_id);
        }

        emit AnswerCreated(question_id, answer_id, content, questionMap[question_id].reward);
        return answer_id;
    }


    // todo: answer id 是否归属于此question.  // finish
    function endorse(uint256 answer_id, uint256 question_id) external {
        require(!isExpired(question_id), "This question is closed");
        require(
            hasRegistered[msg.sender],
            "User must be registered to add endorsements"
        );
        require(
            questionMap[question_id].answer_ids.length > 0,
            "There is no answer to endorse"
        );
        require(
            answerMap[answer_id].answerer != msg.sender,
            "You cannot endorse your own answer"
        );
<<<<<<< HEAD:Contracts.sol
        bool a_belong_to_q = false;
        for (uint256 i = 0; i <= questionMap[question_id].answer_ids.length; i ++){
            uint256 a_id = questionMap[question_id].answer_ids[i]; 
            if (a_id == answer_id){
                a_belong_to_q = true;
            }
        }
        require(
            a_belong_to_q,
            "The answer you want to endorse does not belong to this question"
        );
=======
        //check if the answer_id is valid
        require(answer_id <= answerCount, "The input answer id is invalid");
        //check if the answer_id is belong to the question_id
        require(
            answerMap[answer_id].question_id == question_id,
            "The answer does not belong to the question"
        );


>>>>>>> 4bef2aabcbb787071672304f71ffb15072e2a016:src/Contracts.sol
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
    function rewardDistributeByAssignedRecipent(uint256 question_id, address recipient) private {
        require(
            hasRegistered[msg.sender],
            "User must be registered to distribute reward"
        );
        require(
            questionMap[question_id].closed,
            "The question has not been closed"
        );
        require(
            questionMap[question_id].asker == msg.sender,
            "Only the asker can distribute the reward"
        );
        uint256 reward = questionMap[question_id].reward;
        (bool r, ) = recipient.call{value: reward}("");
        require(r, "Failed to transfer the reward.");
        
        // todo: emit RewardDistributed(q_id, a_ids, recipients, average_reward); 
    }
    function rewardDistributeByExperitionTime(uint256 question_id, address[] memory recipients) private{
        bool expired = isExpired(question_id);

        require(
            hasRegistered[msg.sender],
            "User must be registered to distribute reward"
        );
        require(expired, "The question has not been expired");
        require(
            questionMap[question_id].closed,
            "The question has not been closed"
        );
        require(
            questionMap[question_id].asker == msg.sender,
            "Only the asker can distribute the reward"
        );
        uint256 reward = questionMap[question_id].reward;
        uint256 average_reward = reward / recipients.length;
        for (uint i = 0; i < recipients.length; i++) {
            (bool r, ) = recipients[i].call{value: average_reward}("");
            require(r, "Failed to transfer the reward.");
        }
    }
    // function check if two answers has same amount of endorsements
    function checkEndorsement(uint256 q_id) public view returns (address[] memory) {
    require(
        hasRegistered[msg.sender],
        "User must be registered to check endorsement"
    );
    require(
        questionMap[q_id].closed,
        "The question has not been closed"
    );
    require(
        questionMap[q_id].asker == msg.sender,
        "Only the asker can check the endorsement"
    );

    uint256[] memory answerIds = questionMap[q_id].answer_ids;
    uint256 maxEndorsement = 0;

    // First loop to find the maximum number of endorsements
    for (uint i = 0; i < answerIds.length; i++) {
        if (answerMap[answerIds[i]].endorsers.length > maxEndorsement) {
            maxEndorsement = answerMap[answerIds[i]].endorsers.length;
        }
    }

    // Count how many answers have the maximum endorsements
    uint256 count = 0;
    for (uint i = 0; i < answerIds.length; i++) {
        if (answerMap[answerIds[i]].endorsers.length == maxEndorsement) {
            count++;
        }
    }

    // Create a fixed-size array to hold the endorsers
    address[] memory endorsers = new address[](count);
    uint256 index = 0;

    // Second loop to populate the endorsers array
    for (uint i = 0; i < answerIds.length; i++) {
        if (answerMap[answerIds[i]].endorsers.length == maxEndorsement) {
            endorsers[index] = answerMap[answerIds[i]].answerer;
            index++;
        }
    }

    return endorsers;
    }
    receive() external payable {
        balance += msg.value ; 
    }
}
