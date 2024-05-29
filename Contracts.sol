// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract SurveyList {
    
    address owner;
    string[] public survey_titles;
    address[] participant_list;
    string[] accountNames; 
    
    // These are for our models' ids.
    uint public SurveyCount = 0;
    uint public questionCount = 0;
    uint public ParticipantCount = 0;
    uint public AnswerCount = 0;
    uint public EndorsementCount = 0;

    // ---------- These are our models. Such as Survey, Question, Participant, Answer ----------
    struct Survey{
        uint id;
        string title;
        uint particapant_number;
        bool s_isfull;
    }
    
    struct Question{
        uint id;
        string content;
        string[] options;
        bool q_isfull;
        uint start_time;
        uint end_time;
    }
    
    struct Participant{
        address p_address;
        string name;
        uint age;
        bool isfull;
    }
    
    struct Answer{
        uint answer_id;
        address who_participated;
        uint survey_id;
        string[] a_answer;
        bool isSelected; 
    }

    struct Endorsement{
        uint endorsement_id;
        address who_endorsed;
        uint survey_id;
        uint question_id; 
    }
    
    
    // ---------- Events for creating question, survey and participant ----------
    event QuestionCreated(uint id, string _content, string[] answer);
    event SurveyCreated(uint id, string _title, uint particapant_number, bool s_isfull);
    event ParticipantCreated(address p_address, string name, uint age , bool isfull);
    event AnswerCreated(uint answer_id, address who_participated, uint survey_id, string[] a_answer, bool isSelected);
    event EndorsementCreated(uint endorsement_id, address who_endorsed, uint survey_id, uint question_id);

    
    // ---------- Mappings to save relevant data for Question, Survey, Participant, Answer, Endorsement ----------
    mapping(uint => Question) public questions;
    mapping(uint => Survey) public surveys;  
    mapping(address => Participant) public participants;
    mapping(uint => Answer) public answers;
    mapping (uint => Endorsement) public endorsements; 
    
    // ---------- Mappings to save questions for survey, surveylist for participant, endorsements for question ----------
    mapping(address => uint[]) public surveylist_of_participant;
    mapping(uint => uint[]) public questions_of_anysurvey;
    mapping (uint => uint[]) public endorsements_of_question;
    
    
    constructor(){
        owner = msg.sender;
    }
    
    modifier ownerOnly {
        require(msg.sender == owner, "You are not an owner.");
        _;
    }
    
    modifier joinedBefore(address _address, uint survey_id){
        bool flag = true;
        for(uint i = 0; i<surveylist_of_participant[_address].length; i++){
            if(surveylist_of_participant[_address][i] == survey_id){
                flag = false;
            }
        }
        require(flag, "You have already joined this survey before!");
        _;
    }
    
    
    
    modifier createdQuestionBefore(string memory _content, string[] memory answer){
        bool flag = true;
        for(uint i = 0; i <= questionCount; i++){
            if(keccak256(abi.encodePacked(questions[i].content)) == keccak256(abi.encodePacked(_content)) && answer.length ==  questions[i].options.length){
                flag = false;
            }
        }
        require(flag, "This question created before!");
        _;
    }   
    
    
    
    modifier createdSurveyBefore(string memory _title, uint[] memory QuestionId){
        bool flag = true;
        for(uint i = 0; i <= SurveyCount ; i++){
            if(keccak256(abi.encodePacked(surveys[i].title)) == keccak256(abi.encodePacked(_title)) && QuestionId.length ==  questions_of_anysurvey[i].length){
            flag = false;
            }
            }
        require(flag, "This survey created before!");
        _;
    }

    modifier endorsedBefore(address _address, uint QuestionId, uint AnswerId){
        bool flag = true;
        for (uint i = 0; i < endorsements_of_question[QuestionId].length; i++){
            if(endorsements_of_question[QuestionId][i] == AnswerId){
                flag = false;
            }
        }
        require(flag, "You have endorsed this answer before!"); 
        _; 
    }
    

    
    // ---------- Creating functions ----------
    function createQuestion(string memory _content, string[] memory answer) public ownerOnly createdQuestionBefore(_content,answer){
        require(bytes(_content).length > 0 && answer.length>0, "Please Fill In The Blanks");
        questions[questionCount] = Question(questionCount, _content, answer ,true);
        emit QuestionCreated(questionCount, _content, answer);
        questionCount++;
    }
    
    function createSurvey(string memory _title,uint[] memory Questionid) public ownerOnly createdSurveyBefore(_title, Questionid) returns(uint) {
        require(bytes(_title).length > 0 && Questionid.length>0, "Please Fill In The Blanks");
        questions_of_anysurvey[SurveyCount] = Questionid;
        surveys[SurveyCount] = Survey(SurveyCount,_title, 0, true);
        emit SurveyCreated(SurveyCount, _title, 0, true);
        SurveyCount++;
        survey_titles.push(_title);
        return SurveyCount-1;

    }
    
    function joinTheSurvey(uint survey_id, string[] memory answer) public joinedBefore(msg.sender, survey_id) {
        require(answer.length>0, "Please Fill In The Blanks");
        require(participants[msg.sender].isfull == true, "To join survey, you should log in first.");
        require(surveys[survey_id].s_isfull == true, "Given survey id not found!");
        Survey memory the_survey = surveys[survey_id];
        bool isSelected = false; 
        answers[AnswerCount] = Answer(AnswerCount, msg.sender, survey_id, answer, isSelected);
        AnswerCount++;
        surveylist_of_participant[msg.sender].push(survey_id);
        the_survey.particapant_number +=1;

    }
    
    function createParticipant(string memory name, uint age) public{
        require(bytes(name).length > 0 && age > 0, "Please Fill In The Blanks");
        require(participants[msg.sender].isfull == false, "You don't have participant account / You can't create duplicate account.");
        participants[msg.sender] = Participant(msg.sender, name, age, true);
        emit ParticipantCreated(msg.sender, name, age ,true);
        participant_list.push(msg.sender);
    }
    
    function EndorseAnswer(uint answer, uint QuestionId) public{
        require(answers[answer].who_participated == msg.sender, "You can't endorse this answer!");
        require(answers[answer].isSelected == false, "You have already endorsed this answer!");
        endorsements[EndorsementCount] = Endorsement(EndorsementCount, msg.sender, answers[answer].survey_id, QuestionId);
        endorsements_of_question[QuestionId].push(answer);
        answers[answer].isSelected = true; 
        EndorsementCount++;
        emit EndorsementCreated(EndorsementCount, msg.sender, answers[answer].survey_id, QuestionId);
    }
    function AdwardEther(address _address, uint amount) public ownerOnly {
        payable(_address).transfer(amount);
    }
    
    // ---------- Getter functions ----------
    
    function getSurvey(uint id) public view returns (string memory title, uint[] memory _survayquestions){
        Survey memory survey = surveys[id];
        return (survey.title, questions_of_anysurvey[id]);
    }
    
    
    function getQuestion(uint id) public view returns (string memory, string[] memory q_answers){
        Question memory question = questions[id];
        return (question.content,question.options);
    }
    
    function getParticipantCount() public view returns (uint){
        return participant_list.length;
    } 
    
    function getParticipantAddress() public view returns (address){
        return msg.sender;
    } 
    
    function getSurveyCount() public view returns (uint){
        return SurveyCount;
    } 
    
    function getAnswer(uint a_id) public view returns (string[] memory ans){
        ans = answers[a_id].a_answer;
        return ans;
    }
    
    function getQuestionCount() public view returns (uint){
        return questionCount;
    }
    
    function participantsJoinedSurveys(address _address) public view returns (uint[] memory data){
        return surveylist_of_participant[_address];
    }
    function getEndorsement(uint id) public view returns (address, uint, uint){
        Endorsement memory endorsement = endorsements[id];
        return (endorsement.who_endorsed, endorsement.survey_id, endorsement.question_id);
    }

    
}