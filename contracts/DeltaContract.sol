// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Delta Contract
 * @dev Delta Contract For Mpc
 */
contract DeltaContract {

    address private owner;
    enum RoundStatus {Started,Running,Calculating,Aggregating,Finished}
    mapping(bytes32 => Task) createdTasks;
    mapping(bytes32 => TaskRound[]) taskRounds;
    mapping(bytes32 => RoundModelCommitments[]) roundModelCommitments;
    uint64 private maxWeightCommitmentLength = 10485760;
    uint64 private maxSSComitmentLength = 256;
    struct RoundModelCommitments {
        mapping(address=>bytes) weightCommitment;
        mapping(address=>mapping(address=>SSData)) ssdata;
    }
    struct Task {
        address creator;
        string creatorUrl;
        string dataSet;
        bytes32 commitment;
        uint64 currentRound;
    }
    
    struct Candidate {
        bytes32 pk1;
        bytes32 pk2;
    }
    
    struct TaskRound {
        uint64 currentRound;
        uint32 maxSample;
        uint32 minSample;
        RoundStatus status;
        mapping(address=>Candidate) candidates;
        address[] joinedAddrs;
    }
    
    struct ExtCallTaskRoundStruct {
        uint64 currentRound;
        uint32 maxSample;
        uint32 minSample;
        uint8 status;
        address[] joinedAddrs;
    }
    
    struct SSData {
        bytes seedPiece;
        bytes seedCommitment;
        bytes secretKeyPiece;
        bytes secretKeyMaskCommitment;
    }
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    // triggered when task created 
    event TaskCreated(address indexed creator,bytes32 taskId,string dataSet,string creatorUrl,bytes32 commitment);
    // triggered when task developer call startRound
    event RoundStart(bytes32 taskId,uint64 round);

     // triggered when task developer call startRound
    event RoundEnd(bytes32 taskId,uint64 round);

    // triggered when task developer call selectCandidates
    event PartnerSelected(bytes32 taskId,uint64 round,address[] addrs);
    
    // triggered when task developer call startAggregateUpload
    event AggregateStarted(bytes32 taskId,uint64 round,address[] addrs);
    
    
    // triggered when task developer call startAggregate
    event CalculateStarted(bytes32 taskId,uint64 round,address[] addrs);
    
    // triggered when client call uploadWeightCommitment , uploadSeedCommitment ,uploadSkMaskCommitment
    event ContentUploaded(bytes32 taskId,uint64 round,address owner,address sharer,string contentType,bytes content);

    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    modifier taskExists(bytes32 task_id) {
        require (createdTasks[task_id].creator != address(0), "Task not exists");
        _;
    }
    
    modifier roundExists(bytes32 task_id,uint64 round) {
        TaskRound[] storage rounds = taskRounds[task_id];
        require(rounds.length > 1 && rounds.length > round,"this round does not exist");
        _;
    }

    modifier roundcmmtExists(bytes32 task_id,uint64 round) {
        RoundModelCommitments[] storage cmmts = roundModelCommitments[task_id];
        require(cmmts.length > round,"The Task Round Must exists");
        _;
    }
    
    modifier taskOwner(bytes32 task_id) {
        require(createdTasks[task_id].creator == msg.sender,"Must called by the task owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }
    
    /**
      * @dev get task info data
      * @param taskId taskId
      */
    function getTaskData(bytes32 taskId) taskExists(taskId) public view returns (Task memory task) {
        task = createdTasks[taskId];
    }
    
     /**
      * @dev called by task developer, notifying all clients that a new learning task has been published 
      * @param dataSet data set name (file/folder name of training data)
      * @param commitment training code hash (client validation purpose)
      * @return taskId taskId
      */
    function createTask(string calldata creatorUrl,string calldata dataSet ,bytes32 commitment) payable public returns(bytes32 taskId){
         bytes32 task_id = keccak256(abi.encode(block.timestamp,msg.sender,dataSet,commitment));
         createdTasks[task_id] = Task({creatorUrl:creatorUrl,creator:msg.sender,dataSet:dataSet,commitment:commitment,currentRound:0});
         taskId = task_id;
         TaskRound[] storage rounds = taskRounds[taskId];
         rounds.push();
         emit TaskCreated(msg.sender,task_id,dataSet,creatorUrl,commitment);
    }
    
    /**
     * @dev called by task developer, notifying all clients that a new computing round is started and open for joining
     * @param taskId taskId
     * @param round the round to start
     */
    function startRound(bytes32 taskId,uint64 round,uint32 maxSample,uint32 minSample) taskExists(taskId) taskOwner(taskId) public {
        TaskRound[] storage rounds = taskRounds[taskId];
        require(rounds.length == round,"the round has been already started or the pre round does not exist");
        Task storage task = createdTasks[taskId];
        task.currentRound = round;
        while(rounds.length == 0 || rounds.length - 1 < round) {
            rounds.push();   
        }
        rounds[round].currentRound = round;
        rounds[round].maxSample = maxSample;
        rounds[round].minSample = minSample;
        rounds[round].status = RoundStatus.Started;
        RoundModelCommitments[] storage cmmts = roundModelCommitments[taskId];
        while(cmmts.length == 0 || cmmts.length - 1 < round) {
            cmmts.push();   
        }
        emit RoundStart(taskId,round);
    }
    
    /**
      * @dev called by client, join for that round of computation
      * @param taskId taskId
      * @param round the round to join
      * @param pk1 used for secure communication channel establishment
      * @param pk2 used for mask generation
      */
    function joinRound(bytes32 taskId,uint64 round,bytes32 pk1,bytes32 pk2) taskExists(taskId) roundExists(taskId,round) public returns(bool){
        TaskRound[] storage rounds = taskRounds[taskId];
        TaskRound storage thisRound = rounds[rounds.length - 1];
        require(rounds.length - 1 == round && thisRound.status == RoundStatus.Started,"join phase has passed");
        require(thisRound.candidates[msg.sender].pk1 == 0x0,"Cannot join the same round multiple times");
        thisRound.candidates[msg.sender] = Candidate({pk1:pk1,pk2:pk2});
        thisRound.joinedAddrs.push(msg.sender);
        return true;
    }
    
    /**
      * @dev called by anyone, get Client Pks
      * @return candidate  (pk1,pk2)
      */
    function getClientPublickeys(bytes32 taskId,uint64 round,address candidateAddr) roundExists(taskId,round) public view returns (Candidate memory candidate) {
        candidate = taskRounds[taskId][round].candidates[candidateAddr];
    }
    
    /**
      * @dev getting task round infos
      * @param taskId taskId
      * @param round the round to fetch
      * @return taskround the task round infos
      */
    function getTaskRound(bytes32 taskId,uint64 round) roundExists(taskId,round) public view returns(ExtCallTaskRoundStruct memory taskround) {
        TaskRound storage temp = taskRounds[taskId][round];
        taskround = ExtCallTaskRoundStruct({currentRound:temp.currentRound,maxSample:temp.maxSample,minSample:temp.minSample,status:(uint8)(temp.status),
            joinedAddrs:temp.joinedAddrs
        });
    }
    
     /**
      * @dev called by task developer, randomly choose candidates to be computation nodes
      * @dev clients now should start secret sharing phase 
      * @param addrs selected client addresses
      */
    function selectCandidates(bytes32 taskId,uint64 round,address[] calldata addrs) taskOwner(taskId) roundExists(taskId,round) public {
        require(addrs.length > 0,"Must provide addresses");
        TaskRound storage curRound = taskRounds[taskId][round];
        for(uint i = 0; i < addrs.length; i ++) {
            require(curRound.candidates[addrs[i]].pk1 != 0x00,"Candidate must exist");
        }
        curRound.status = RoundStatus.Running;
        emit PartnerSelected(taskId,round,addrs);
    }
    
     /**
      * @dev called by task developer, get commitments from blockchain
      * @dev (Server has to call this method for every clients to get their commiments as the return value couldn't contain mapping type in solidity(damn it))
      * @param taskId taskId
      * @param clientaddress the client that publish the commitments  
      * @param round the round of that commitment
      * @return commitment commitment data
      */
    function getResultCommitment(bytes32 taskId,address clientaddress,uint64 round) roundExists(taskId,round) roundcmmtExists(taskId,round) public view returns(bytes memory commitment) {
        RoundModelCommitments[] storage cmmts = roundModelCommitments[taskId];
        require(cmmts.length >= round,"The Task Round Must exists");
        RoundModelCommitments storage cmmt = cmmts[round];
        commitment = cmmt.weightCommitment[clientaddress];
    }
    
    /**
      * @dev called by any participants
      */
    function getSecretSharingData(bytes32 taskId,uint64 round,address owner,address sharee) roundExists(taskId,round) roundcmmtExists(taskId,round) public view returns(SSData memory ssdata) {
        RoundModelCommitments[] storage cmmts = roundModelCommitments[taskId];
        require(cmmts.length >= round,"The Task Round Must exists");
        RoundModelCommitments storage cmmt = cmmts[round];
        ssdata = cmmt.ssdata[owner][sharee];
    }
    
    /**
     * @dev called by task developer, notifying all participants that the ss and gradient transfer phase has finished
     * @dev client now should send corresponded ss share pieces to task developer according to the online status given by the task developer
     * @param taskId taskId
     * @param round the task round
     * @param onlineClients clients that has transfered gradient to task developer
     */
    function startAggregate(bytes32 taskId,uint64 round,address[] calldata onlineClients) taskOwner(taskId) roundExists(taskId,round) public {
        TaskRound storage curRound = taskRounds[taskId][round];
        require(curRound.status == RoundStatus.Calculating,"Calculating has not started");
        curRound.status = RoundStatus.Aggregating;
        for(uint i = 0; i < onlineClients.length; i ++) {
            require(curRound.candidates[onlineClients[i]].pk1 != 0x00,"Candidate must exist");
        }
        emit AggregateStarted(taskId,round,onlineClients);
    }
    
    
     /**
     * @dev called by task developer, notifying all participants that the secret sharing phase is finished  to transfer masked gradient to task server
     * @param taskId taskId
     * @param round the task round
     */
    function startCalculate(bytes32 taskId,uint64 round,address[] calldata onlineClients) taskOwner(taskId) roundExists(taskId,round) public {
        TaskRound storage curRound = taskRounds[taskId][round];
        require(curRound.status == RoundStatus.Running,"This round is not running now");
        curRound.status = RoundStatus.Calculating;
        emit CalculateStarted(taskId,round,onlineClients);
    }
    
    /**
     * @dev called by task developer, close round
     * @param taskId taskId
     * @param round the task round
     */
    function endRound(bytes32 taskId,uint64 round) taskOwner(taskId) roundExists(taskId,round) public {
        TaskRound storage curRound = taskRounds[taskId][round];
        curRound.status = RoundStatus.Finished;
        emit RoundEnd(taskId,round);
    }
    
    /**
     * @dev called by client, upload weight commitment
     * @param taskId taskId
     * @param round the task round
     * @param resultCommitment masked model incremental commitment
     */
    function uploadResultCommitment(bytes32 taskId,uint64 round,bytes calldata resultCommitment) roundExists(taskId,round) public {
        require(resultCommitment.length > 0 && resultCommitment.length <= maxWeightCommitmentLength,"commitment length exceeds limit or it is empty");
        TaskRound storage curRound = taskRounds[taskId][round];
        require(curRound.status == RoundStatus.Calculating ,"not in uploading phase");
        RoundModelCommitments[] storage commitments = roundModelCommitments[taskId];
        RoundModelCommitments storage commitment = commitments[round];
        require(commitment.weightCommitment[msg.sender].length == 0,"cannot upload weightCommitment multiple times");
        commitment.weightCommitment[msg.sender] = resultCommitment;
        emit ContentUploaded(taskId,round,msg.sender,address(0),"WEIGHT",resultCommitment);
    }
    
    
    /**
     * @dev called by client, upload secret sharing seed commitment
     * @param taskId taskId
     * @param round the task round
     * @param sharee the sharee address
     * @param seedCommitment secret sharing piece of seed mask
     */
    function uploadSeedCommitment(bytes32 taskId,uint64 round,address sharee,bytes calldata seedCommitment) roundExists(taskId,round) public {
        require(seedCommitment.length > 0 && seedCommitment.length <= maxSSComitmentLength,"commitment length exceeds limit or it is empty");
        TaskRound storage curRound = taskRounds[taskId][round];
        require(curRound.status == RoundStatus.Running,"not in secret sharing phase");
        RoundModelCommitments[] storage commitments = roundModelCommitments[taskId];
        RoundModelCommitments storage commitment = commitments[round];
        require(commitment.ssdata[msg.sender][sharee].seedCommitment.length == 0,"cannot upload seed cmmt multiple times");
        commitment.ssdata[msg.sender][sharee].seedCommitment = seedCommitment;
        emit ContentUploaded(taskId,round,msg.sender,sharee,"SEEDCMMT",seedCommitment);
    }
    
    
    /**
     * @dev called by client, upload secret sharing seed commitment
     * @param taskId taskId
     * @param round the task round
     * @param sharee the sharee address
     * @param seed the seed piece
     */
    function uploadSeed(bytes32 taskId,uint64 round,address sharee,bytes calldata seed) roundExists(taskId,round) public {
        require(seed.length > 0 && seed.length <= maxSSComitmentLength ,"commitment length exceeds limit or it is empty");
        TaskRound storage curRound = taskRounds[taskId][round];
        require(curRound.status == RoundStatus.Aggregating,"not in upload ss phase");
        RoundModelCommitments[] storage commitments = roundModelCommitments[taskId];
        RoundModelCommitments storage commitment = commitments[round];
        require(commitment.ssdata[msg.sender][sharee].seedCommitment.length > 0,"must upload commitment first");
        require(commitment.ssdata[msg.sender][sharee].seedPiece.length == 0,"cannot upload seed multiple times");
        commitment.ssdata[msg.sender][sharee].seedPiece = seed;
        emit ContentUploaded(taskId,round,msg.sender,sharee,"SEED",seed);
    }
    
    /**
     * @dev called by client, upload secret sharing sk commitment
     * @param taskId taskId
     * @param round the task round
     * @param sharee the sharee address
     * @param secretKeyCommitment secret sharing piece of seed mask
     */
    function uploadSecretKeyCommitment(bytes32 taskId,uint64 round,address sharee,bytes calldata secretKeyCommitment) roundExists(taskId,round) public {
        require(secretKeyCommitment.length > 0 && secretKeyCommitment.length <= maxSSComitmentLength,"commitment length exceeds limit or it is empty");
        TaskRound storage curRound = taskRounds[taskId][round];
        require(curRound.status == RoundStatus.Running,"not in secret sharing phase");
        RoundModelCommitments[] storage commitments = roundModelCommitments[taskId];
        if(commitments.length == round) {
            commitments.push();
        }
        RoundModelCommitments storage commitment = commitments[round];
        require(commitment.ssdata[msg.sender][sharee].secretKeyMaskCommitment.length == 0,"cannot upload seed multiple times");
        commitment.ssdata[msg.sender][sharee].secretKeyMaskCommitment = secretKeyCommitment;
        emit ContentUploaded(taskId,round,msg.sender,sharee,"SKMASKCMMT",secretKeyCommitment);
        // commitment.data[msg.sender].seedCmmtmnt = seedCmmtmnt;
    }
    
    
    /**
     * @dev called by client, upload secret sharing sk commitment
     * @param taskId taskId
     * @param round the task round
     * @param secretkeyMask the crypted skmask
     * @param owner the owner address
     */
    function uploadSecretkeyMask(bytes32 taskId,uint64 round,address owner,bytes calldata secretkeyMask) roundExists(taskId,round) public {
        require(secretkeyMask.length > 0 && secretkeyMask.length <= maxSSComitmentLength,"commitment length exceeds limit or it is empty");
        TaskRound storage curRound = taskRounds[taskId][round];
        require(curRound.status == RoundStatus.Aggregating,"not in upload ss phase");
        RoundModelCommitments[] storage commitments = roundModelCommitments[taskId];
        if(commitments.length == round) {
            commitments.push();
        }
        RoundModelCommitments storage commitment = commitments[round];
        require(commitment.ssdata[owner][msg.sender].secretKeyMaskCommitment.length > 0,"must upload commitment first");
        require(commitment.ssdata[owner][msg.sender].secretKeyPiece.length == 0,"cannot upload skmask multiple times");
        commitment.ssdata[owner][msg.sender].secretKeyPiece = secretkeyMask;
        emit ContentUploaded(taskId,round,owner,msg.sender,"SKMASK",secretkeyMask);
        // commitment.data[msg.sender].seedCmmtmnt = seedCmmtmnt;
    }
    
    function setMaxWeightCommitmentLength(uint64 maxLength) isOwner public {
        maxWeightCommitmentLength = maxLength;
    }
    
    function setMaxSSCommitmentLength(uint64 maxLength) isOwner public {
        maxSSComitmentLength = maxLength;
    }
    
    function getMaxCommitmentsLength() public view returns (uint64 sslength,uint64 weightLength) {
        sslength = maxSSComitmentLength;
        weightLength = maxWeightCommitmentLength;
    }
    
    
    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}