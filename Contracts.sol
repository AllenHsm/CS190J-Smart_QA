// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract SurveyList {
    
    address owner;
    address[] participant_list;
    string[] accountNames; 
    
    // These are for our models' ids.
    uint256 public questionCount = 0;
    uint256 public ParticipantCount = 0;
    uint256 public AnswerCount = 0;
    uint256 public EndorsementCount = 0;

    // ---------- These are our models. Such as Question, Participant, Answer ----------
    
    struct Question{
        uint256 id;
        string content;
        string[] options;
        bool q_isfull;
        uint256 start_time;
        uint256 end_time;
    }
    
    struct Participant{
        address p_address;
        string name;
        uint256 age;
        bool isfull;
    }
    
    struct Answer{
        uint256 answer_id;
        address who_participated;
        string[] a_answer;
        bool isSelected; 
    }

    struct Endorsement{
        uint256 endorsement_id;
        address who_endorsed;
        uint256 question_id; 
    }
    
    
    // ---------- Events for creating question, and participant ----------
    event QuestionCreated(uint256 id, string _content, string[] answer);
    event ParticipantCreated(address p_address, string name, uint256 age , bool isfull);
    event AnswerCreated(uint256 answer_id, address who_participated, string[] a_answer, bool isSelected);
    event EndorsementCreated(uint256 endorsement_id, address who_endorsed, uint256 question_id);

    
    // ---------- Mappings to save relevant data for Question, Participant, Answer, Endorsement ----------
    mapping(uint256 => Question) public questions;
    mapping(address => Participant) public participants;
    mapping(uint256 => Answer) public answers;
    mapping (uint256 => Endorsement) public endorsements; 
    
    // ---------- Mappings to save questions for survey, surveylist for participant, endorsements for question ----------
    mapping (uint256 => uint256[]) public endorsements_of_question;
    
    
    constructor(){
        owner = msg.sender;
    }
    
    modifier ownerOnly {
        require(msg.sender == owner, "You are not an owner.");
        _;
    }

    modifier createdQuestionBefore(string memory _content, string[] memory answer){
        bool flag = true;
        for(uint256 i = 0; i <= questionCount; i++){
            if(keccak256(abi.encodePacked(questions[i].content)) == keccak256(abi.encodePacked(_content)) && answer.length ==  questions[i].options.length){
                flag = false;
            }
        }
        require(flag, "This question created before!");
        _;
    }   
    

    modifier endorsedBefore(address _address, uint256 QuestionId, uint256 AnswerId){
        bool flag = true;
        for (uint256 i = 0; i < endorsements_of_question[QuestionId].length; i++){
            if(endorsements_of_question[QuestionId][i] == AnswerId){
                flag = false;
            }
        }
        require(flag, "You have endorsed this answer before!"); 
        _; 
    }
    

    
    // ---------- Creating functions ----------
    function createQuestion(string memory _content, string[] memory answer,uint256 start, uint256 end) public ownerOnly createdQuestionBefore(_content,answer){
        require(bytes(_content).length > 0 && answer.length>0, "Please Fill In The Blanks");
        questions[questionCount] = Question(questionCount, _content, answer ,true, start, end);
        emit QuestionCreated(questionCount, _content, answer);
        questionCount++;
    }
    
    function createParticipant(string memory name, uint256 age) public{
        require(bytes(name).length > 0 && age > 0, "Please Fill In The Blanks");
        require(participants[msg.sender].isfull == false, "You don't have participant account / You can't create duplicate account.");
        participants[msg.sender] = Participant(msg.sender, name, age, true);
        emit ParticipantCreated(msg.sender, name, age ,true);
        participant_list.push(msg.sender);
    }
    
    function EndorseAnswer(uint256 answer, uint256 QuestionId) public{
        require(answers[answer].who_participated == msg.sender, "You can't endorse this answer!");
        require(answers[answer].isSelected == false, "You have already endorsed this answer!");
        endorsements[EndorsementCount] = Endorsement(EndorsementCount, msg.sender, QuestionId);
        endorsements_of_question[QuestionId].push(answer);
        answers[answer].isSelected = true; 
        EndorsementCount++;
        emit EndorsementCreated(EndorsementCount, msg.sender, QuestionId);
    }
    function AdwardEther(address _address, uint256 amount) public ownerOnly {
        payable(_address).transfer(amount);
    }
    
    // ---------- Getter functions ----------
    
    
    
    function getQuestion(uint256 id) public view returns (string memory, string[] memory q_answers){
        Question memory question = questions[id];
        return (question.content,question.options);
    }
    
    function getParticipantCount() public view returns (uint256){
        return participant_list.length;
    } 
    
    function getParticipantAddress() public view returns (address){
        return msg.sender;
    } 
    
    
    function getAnswer(uint256 a_id) public view returns (string[] memory ans){
        ans = answers[a_id].a_answer;
        return ans;
    }
    
    function getQuestionCount() public view returns (uint256){
        return questionCount;
    }
    function getUserWithMostEndorsement(uint256 questionId) public view returns (address){
        uint256 max = 0;
        address user;
        for (uint256 i = 0; i < endorsements_of_question[questionId].length; i++){
            uint256 answerId = endorsements_of_question[questionId][i];
            if(answers[answerId].a_answer.length > max){
                max = answers[answerId].a_answer.length;
                user = answers[answerId].who_participated;
            }
        }
        return user;
    }

    
}