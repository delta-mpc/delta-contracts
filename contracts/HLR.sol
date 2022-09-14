// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./IdentityContract.sol";
import "./DataHub.sol";

contract Verifier {
    uint256 public constant q = 0;

    function verifyProof(bytes memory proof, uint256[] memory pubSignals)
        public
        view
        returns (bool)
    {}
}

/**
 * @title HLR Contract
 * @dev Contract for delta horizontal logistic regression
 */
contract HLR {
    IdentityContract public idContract;
    DataHub public dataContract;

    address private owner;
    enum RoundStatus {
        Started,
        Running,
        Calculating,
        Aggregating,
        Finished
    }
    mapping(bytes32 => Task) createdTasks;
    mapping(bytes32 => VerifierState) verifierStates;
    mapping(bytes32 => TaskRound[]) taskRounds;
    mapping(bytes32 => RoundModelCommitments[]) roundModelCommitments;
    uint64 private maxWeightCommitmentLength = 10485760;
    uint64 private maxSSComitmentLength = 256;
    struct RoundModelCommitments {
        bytes32 weightCommitment;
        mapping(address => bytes) resultCommitment;
        mapping(address => mapping(address => SSData)) ssdata;
    }
    struct Task {
        address creator;
        string creatorUrl;
        string dataSet;
        bytes32 commitment;
        string taskType;
        uint64 currentRound;
        bool finished;
        bool enableVerify;
        uint256 tolerance;
    }

    struct Candidate {
        bytes pk1;
        bytes pk2;
    }

    struct TaskRound {
        uint64 currentRound;
        uint32 maxSample;
        uint32 minSample;
        RoundStatus status;
        mapping(address => Candidate) candidates;
        address[] joinedAddrs;
        address[] finishedAddrs;
    }

    struct ExtCallTaskRoundStruct {
        uint64 currentRound;
        uint32 maxSample;
        uint32 minSample;
        uint8 status;
        address[] joinedAddrs;
        address[] finishedAddrs;
    }

    struct SSData {
        bytes seedPiece;
        bytes seedCommitment;
        bytes secretKeyPiece;
        bytes secretKeyMaskCommitment;
    }

    struct VerifierState {
        uint256[] gradients;
        uint256 precision;
        mapping(address => bool) unfinishedClients;
        uint256 unfinishedCount;
        bool valid;
    }

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    // triggered when task created
    event TaskCreated(
        address indexed creator,
        bytes32 taskId,
        string dataSet,
        string creatorUrl,
        bytes32 commitment,
        string taskType,
        bool enableVerify,
        uint256 tolerance
    );
    // triggered when task finished
    event TaskFinished(bytes32 taskId);
    // triggered when task developer call startRound
    event RoundStart(bytes32 taskId, uint64 round);

    // triggered when task developer call startRound
    event RoundEnd(bytes32 taskId, uint64 round);

    // triggered when task developer call selectCandidates
    event PartnerSelected(bytes32 taskId, uint64 round, address[] addrs);

    // triggered when task developer call startAggregateUpload
    event AggregateStarted(bytes32 taskId, uint64 round, address[] addrs);

    // triggered when task developer call startAggregate
    event CalculateStarted(bytes32 taskId, uint64 round, address[] addrs);

    // triggered when client call uploadWeightCommitment , uploadSeedCommitment ,uploadSkMaskCommitment
    event ContentUploaded(
        bytes32 taskId,
        uint64 round,
        address sender,
        address reciver,
        string contentType,
        bytes content
    );

    // triggered when client call verify method
    event TaskMemberVerified(bytes32 taskId, address addr, bool verified);
    // triggered when all clients pass the verification or any client is rejected by the verification
    event TaskVerified(bytes32 taskId, bool verified);

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
        require(createdTasks[task_id].creator != address(0), "Task not exists");
        _;
    }

    modifier roundExists(bytes32 task_id, uint64 round) {
        TaskRound[] storage rounds = taskRounds[task_id];
        require(
            rounds.length > 1 && rounds.length > round,
            "this round does not exist"
        );
        _;
    }

    modifier roundcmmtExists(bytes32 task_id, uint64 round) {
        RoundModelCommitments[] storage cmmts = roundModelCommitments[task_id];
        require(cmmts.length > round, "The Task Round Must exists");
        _;
    }

    modifier taskOwner(bytes32 task_id) {
        require(
            createdTasks[task_id].creator == msg.sender,
            "Must called by the task owner"
        );
        _;
    }

    /**
     * @dev Set contract deployer as owner
     */
    constructor(IdentityContract idAddr, DataHub dbAddr) {
        idContract = idAddr;
        dataContract = dbAddr;
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev get task info data
     * @param taskId taskId
     */
    function getTaskData(bytes32 taskId)
        public
        view
        taskExists(taskId)
        returns (Task memory task)
    {
        task = createdTasks[taskId];
    }

    /**
     * @dev called by task developer, notifying all clients that a new learning task has been published
     * @param dataSet data set name (file/folder name of training data)
     * @param commitment training code hash (client validation purpose)
     * @return taskId taskId
     */
    function createTask(
        string calldata dataSet,
        bytes32 commitment,
        bool enableVerify,
        uint256 tolerance
    ) public payable returns (bytes32 taskId) {
        string memory taskType = "hlr";
        bytes32 task_id = keccak256(
            abi.encode(block.number, msg.sender, dataSet, commitment, taskType)
        );
        IdentityContract.Node memory node = idContract.getNodeInfo(msg.sender);
        createdTasks[task_id] = Task({
            creatorUrl: node.url,
            creator: msg.sender,
            dataSet: dataSet,
            commitment: commitment,
            taskType: taskType,
            currentRound: 0,
            finished: false,
            enableVerify: enableVerify,
            tolerance: tolerance
        });
        taskId = task_id;
        TaskRound[] storage rounds = taskRounds[taskId];
        rounds.push();
        emit TaskCreated(
            msg.sender,
            task_id,
            dataSet,
            node.url,
            commitment,
            taskType,
            enableVerify,
            tolerance
        );
    }

    function finishTask(bytes32 taskId)
        public
        taskExists(taskId)
        taskOwner(taskId)
    {
        Task storage task = createdTasks[taskId];
        task.finished = true;
        if (task.enableVerify) {
            TaskRound storage finalRound = taskRounds[taskId][
                task.currentRound
            ];
            VerifierState storage state = verifierStates[taskId];
            for (uint256 i = 0; i < finalRound.finishedAddrs.length; i++) {
                state.unfinishedClients[finalRound.finishedAddrs[i]] = true;
            }
            state.unfinishedCount = finalRound.finishedAddrs.length;
            state.valid = true;
        }
        emit TaskFinished(taskId);
    }

    function getTask(bytes32 taskId)
        public
        view
        taskExists(taskId)
        returns (Task memory task)
    {
        task = createdTasks[taskId];
    }

    /**
     * @dev called by task developer, notifying all clients that a new computing round is started and open for joining
     * @param taskId taskId
     * @param round the round to start
     */
    function startRound(
        bytes32 taskId,
        uint64 round,
        uint32 maxSample,
        uint32 minSample,
        bytes32 weightCommitment
    ) public taskExists(taskId) taskOwner(taskId) {
        TaskRound[] storage rounds = taskRounds[taskId];
        require(
            rounds.length == round,
            "the round has been already started or the pre round does not exist"
        );
        Task storage task = createdTasks[taskId];
        task.currentRound = round;
        while (rounds.length == 0 || rounds.length - 1 < round) {
            rounds.push();
        }
        rounds[round].currentRound = round;
        rounds[round].maxSample = maxSample;
        rounds[round].minSample = minSample;
        rounds[round].status = RoundStatus.Started;
        RoundModelCommitments[] storage cmmts = roundModelCommitments[taskId];
        while (cmmts.length == 0 || cmmts.length - 1 < round) {
            cmmts.push();
        }
        RoundModelCommitments storage cmmt = cmmts[round];
        cmmt.weightCommitment = weightCommitment;
        emit RoundStart(taskId, round);
    }

    /**
     * @dev called by anyone, get weight commitment of a task round
     * @param taskId taskId
     * @param round the round to start
     */
    function getWeightCommitment(bytes32 taskId, uint64 round)
        public
        view
        taskExists(taskId)
        roundExists(taskId, round)
        roundcmmtExists(taskId, round)
        returns (bytes32)
    {
        RoundModelCommitments[] storage cmmts = roundModelCommitments[taskId];
        RoundModelCommitments storage cmmt = cmmts[round];
        return cmmt.weightCommitment;
    }

    /**
     * @dev called by client, join for that round of computation
     * @param taskId taskId
     * @param round the round to join
     * @param pk1 used for secure communication channel establishment
     * @param pk2 used for mask generation
     */
    function joinRound(
        bytes32 taskId,
        uint64 round,
        bytes calldata pk1,
        bytes calldata pk2
    ) public taskExists(taskId) roundExists(taskId, round) returns (bool) {
        TaskRound[] storage rounds = taskRounds[taskId];
        TaskRound storage thisRound = rounds[rounds.length - 1];
        require(
            rounds.length - 1 == round &&
                thisRound.status == RoundStatus.Started,
            "join phase has passed"
        );
        require(
            thisRound.candidates[msg.sender].pk1.length == 0,
            "Cannot join the same round multiple times"
        );
        thisRound.candidates[msg.sender] = Candidate({pk1: pk1, pk2: pk2});
        thisRound.joinedAddrs.push(msg.sender);
        return true;
    }

    /**
     * @dev called by anyone, get Client Pks
     * @return candidate  (pk1,pk2)
     */
    function getClientPublickeys(
        bytes32 taskId,
        uint64 round,
        address[] calldata candidateAddrs
    ) public view roundExists(taskId, round) returns (Candidate[] memory) {
        Candidate[] memory candidates = new Candidate[](candidateAddrs.length);
        for (uint256 i = 0; i < candidateAddrs.length; i++) {
            candidates[i] = taskRounds[taskId][round].candidates[
                candidateAddrs[i]
            ];
        }
        return candidates;
    }

    /**
     * @dev getting task round infos
     * @param taskId taskId
     * @param round the round to fetch
     * @return taskround the task round infos
     */
    function getTaskRound(bytes32 taskId, uint64 round)
        public
        view
        roundExists(taskId, round)
        returns (ExtCallTaskRoundStruct memory taskround)
    {
        TaskRound storage temp = taskRounds[taskId][round];
        taskround = ExtCallTaskRoundStruct({
            currentRound: temp.currentRound,
            maxSample: temp.maxSample,
            minSample: temp.minSample,
            status: (uint8)(temp.status),
            joinedAddrs: temp.joinedAddrs,
            finishedAddrs: temp.finishedAddrs
        });
    }

    /**
     * @dev called by task developer, randomly choose candidates to be computation nodes
     * @dev clients now should start secret sharing phase
     * @param addrs selected client addresses
     */
    function selectCandidates(
        bytes32 taskId,
        uint64 round,
        address[] calldata addrs
    ) public taskOwner(taskId) roundExists(taskId, round) {
        require(addrs.length > 0, "Must provide addresses");
        TaskRound storage curRound = taskRounds[taskId][round];
        for (uint256 i = 0; i < addrs.length; i++) {
            require(
                curRound.candidates[addrs[i]].pk1.length > 0,
                "Candidate must exist"
            );
        }
        curRound.status = RoundStatus.Running;
        emit PartnerSelected(taskId, round, addrs);
    }

    /**
     * @dev called by task developer, get commitments from blockchain
     * @dev (Server has to call this method for every clients to get their commiments as the return value couldn't contain mapping type in solidity(damn it))
     * @param taskId taskId
     * @param clientaddress the client that publish the commitments
     * @param round the round of that commitment
     * @return commitment commitment data
     */
    function getResultCommitment(
        bytes32 taskId,
        uint64 round,
        address clientaddress
    )
        public
        view
        roundExists(taskId, round)
        roundcmmtExists(taskId, round)
        returns (bytes memory commitment)
    {
        RoundModelCommitments[] storage cmmts = roundModelCommitments[taskId];
        require(cmmts.length >= round, "The Task Round Must exists");
        RoundModelCommitments storage cmmt = cmmts[round];
        commitment = cmmt.resultCommitment[clientaddress];
    }

    /**
     * @dev called by any participants
     */
    function getSecretSharingDatas(
        bytes32 taskId,
        uint64 round,
        address[] calldata senders,
        address receiver
    )
        public
        view
        roundExists(taskId, round)
        roundcmmtExists(taskId, round)
        returns (SSData[] memory)
    {
        RoundModelCommitments[] storage cmmts = roundModelCommitments[taskId];
        require(cmmts.length >= round, "The Task Round Must exists");
        RoundModelCommitments storage cmmt = cmmts[round];
        SSData[] memory ssdatas = new SSData[](senders.length);
        for (uint256 i = 0; i < senders.length; i++) {
            ssdatas[i] = (cmmt.ssdata[senders[i]][receiver]);
        }
        return ssdatas;
    }

    /**
     * @dev called by task developer, notifying all participants that the ss and gradient transfer phase has finished
     * @dev client now should send corresponded ss share pieces to task developer according to the online status given by the task developer
     * @param taskId taskId
     * @param round the task round
     * @param onlineClients clients that has transfered gradient to task developer
     */
    function startAggregate(
        bytes32 taskId,
        uint64 round,
        address[] calldata onlineClients
    ) public taskOwner(taskId) roundExists(taskId, round) {
        TaskRound storage curRound = taskRounds[taskId][round];
        require(
            curRound.status == RoundStatus.Calculating,
            "Calculating has not started"
        );
        curRound.status = RoundStatus.Aggregating;
        for (uint256 i = 0; i < onlineClients.length; i++) {
            require(
                curRound.candidates[onlineClients[i]].pk1.length > 0,
                "Candidate must exist"
            );
        }
        for (uint256 i = 0; i < onlineClients.length; i++) {
            curRound.finishedAddrs.push(onlineClients[i]);
        }
        emit AggregateStarted(taskId, round, onlineClients);
    }

    /**
     * @dev called by task developer, notifying all participants that the secret sharing phase is finished  to transfer masked gradient to task server
     * @param taskId taskId
     * @param round the task round
     */
    function startCalculate(
        bytes32 taskId,
        uint64 round,
        address[] calldata onlineClients
    ) public taskOwner(taskId) roundExists(taskId, round) {
        TaskRound storage curRound = taskRounds[taskId][round];
        require(
            curRound.status == RoundStatus.Running,
            "This round is not running now"
        );
        curRound.status = RoundStatus.Calculating;
        emit CalculateStarted(taskId, round, onlineClients);
    }

    /**
     * @dev called by task developer, close round
     * @param taskId taskId
     * @param round the task round
     */
    function endRound(bytes32 taskId, uint64 round)
        public
        taskOwner(taskId)
        roundExists(taskId, round)
    {
        TaskRound storage curRound = taskRounds[taskId][round];
        curRound.status = RoundStatus.Finished;
        emit RoundEnd(taskId, round);
    }

    /**
     * @dev called by client, upload weight commitment
     * @param taskId taskId
     * @param round the task round
     * @param resultCommitment masked model incremental commitment
     */
    function uploadResultCommitment(
        bytes32 taskId,
        uint64 round,
        bytes calldata resultCommitment
    ) public roundExists(taskId, round) {
        require(
            resultCommitment.length > 0 &&
                resultCommitment.length <= maxWeightCommitmentLength,
            "commitment length exceeds limit or it is empty"
        );
        TaskRound storage curRound = taskRounds[taskId][round];
        require(
            curRound.status == RoundStatus.Calculating,
            "not in uploading phase"
        );
        RoundModelCommitments[] storage commitments = roundModelCommitments[
            taskId
        ];
        RoundModelCommitments storage commitment = commitments[round];
        require(
            commitment.resultCommitment[msg.sender].length == 0,
            "cannot upload resultCommitment multiple times"
        );
        commitment.resultCommitment[msg.sender] = resultCommitment;
        emit ContentUploaded(
            taskId,
            round,
            msg.sender,
            address(0),
            "WEIGHT",
            resultCommitment
        );
    }

    /**
     * @dev called by client, upload secret sharing seed commitment
     * @param taskId taskId
     * @param round the task round
     * @param receivers the receiver addresses
     * @param seedCommitments seedCommitments[i] is the commitment send to receivers[i]
     */
    function uploadSeedCommitment(
        bytes32 taskId,
        uint64 round,
        address[] calldata receivers,
        bytes[] calldata seedCommitments
    ) public roundExists(taskId, round) {
        require(
            receivers.length == seedCommitments.length,
            "receivers length is not equal to seedCommitments length"
        );
        for (uint256 i = 0; i < seedCommitments.length; i++) {
            require(
                seedCommitments[i].length > 0 &&
                    seedCommitments[i].length <= maxSSComitmentLength,
                "commitment length exceeds limit or it is empty"
            );
        }
        TaskRound storage curRound = taskRounds[taskId][round];
        require(
            curRound.status == RoundStatus.Running,
            "not in secret sharing phase"
        );
        RoundModelCommitments[] storage commitments = roundModelCommitments[
            taskId
        ];
        RoundModelCommitments storage commitment = commitments[round];
        for (uint256 i = 0; i < seedCommitments.length; i++) {
            require(
                commitment
                    .ssdata[msg.sender][receivers[i]]
                    .seedCommitment
                    .length == 0,
                "cannot upload seed cmmt multiple times"
            );
            commitment
            .ssdata[msg.sender][receivers[i]].seedCommitment = seedCommitments[
                i
            ];
            emit ContentUploaded(
                taskId,
                round,
                msg.sender,
                receivers[i],
                "SEEDCMMT",
                seedCommitments[i]
            );
        }
    }

    /**
     * @dev called by client, upload secret sharing seed commitment
     * @param taskId taskId
     * @param round the task round
     * @param senders senders address
     * @param seeds seeds[i] is the seed send by senders[i]
     */
    function uploadSeed(
        bytes32 taskId,
        uint64 round,
        address[] calldata senders,
        bytes[] calldata seeds
    ) public roundExists(taskId, round) {
        require(
            senders.length == seeds.length,
            "senders length is not equal to seeds length"
        );
        for (uint256 i = 0; i < seeds.length; i++) {
            require(
                seeds[i].length > 0 && seeds[i].length <= maxSSComitmentLength,
                "commitment length exceeds limit or it is empty"
            );
        }
        TaskRound storage curRound = taskRounds[taskId][round];
        require(
            curRound.status == RoundStatus.Aggregating,
            "not in upload ss phase"
        );
        RoundModelCommitments[] storage commitments = roundModelCommitments[
            taskId
        ];
        RoundModelCommitments storage commitment = commitments[round];
        for (uint256 i = 0; i < seeds.length; i++) {
            require(
                commitment
                    .ssdata[senders[i]][msg.sender]
                    .seedCommitment
                    .length > 0,
                "must upload commitment first"
            );
            require(
                commitment.ssdata[senders[i]][msg.sender].seedPiece.length == 0,
                "cannot upload seed multiple times"
            );
            commitment.ssdata[senders[i]][msg.sender].seedPiece = seeds[i];
            emit ContentUploaded(
                taskId,
                round,
                senders[i],
                msg.sender,
                "SEED",
                seeds[i]
            );
        }
    }

    /**
     * @dev called by client, upload secret sharing sk commitment
     * @param taskId taskId
     * @param round the task round
     * @param receivers the receiver addresses
     * @param secretKeyCommitments secretKeyCommitments[i] is the commitment send to receivers[i]
     */
    function uploadSecretKeyCommitment(
        bytes32 taskId,
        uint64 round,
        address[] calldata receivers,
        bytes[] calldata secretKeyCommitments
    ) public roundExists(taskId, round) {
        require(
            receivers.length == secretKeyCommitments.length,
            "receivers length is not equal to secretKeyCommitments length"
        );
        for (uint256 i = 0; i < secretKeyCommitments.length; i++) {
            require(
                secretKeyCommitments[i].length > 0 &&
                    secretKeyCommitments[i].length <= maxSSComitmentLength,
                "commitment length exceeds limit or it is empty"
            );
        }
        TaskRound storage curRound = taskRounds[taskId][round];
        require(
            curRound.status == RoundStatus.Running,
            "not in secret sharing phase"
        );
        RoundModelCommitments[] storage commitments = roundModelCommitments[
            taskId
        ];
        RoundModelCommitments storage commitment = commitments[round];
        for (uint256 i = 0; i < secretKeyCommitments.length; i++) {
            require(
                commitment
                    .ssdata[msg.sender][receivers[i]]
                    .secretKeyMaskCommitment
                    .length == 0,
                "cannot upload seed cmmt multiple times"
            );
            commitment
            .ssdata[msg.sender][receivers[i]]
                .secretKeyMaskCommitment = secretKeyCommitments[i];
            emit ContentUploaded(
                taskId,
                round,
                msg.sender,
                receivers[i],
                "SKMASKCMMT",
                secretKeyCommitments[i]
            );
        }
    }

    /**
     * @dev called by client, upload secret sharing sk commitment
     * @param taskId taskId
     * @param round the task round
     * @param senders senders address
     * @param secretkeyMasks secretkeyMasks[i] is the secretKeyMask send by senders[i]
     */
    function uploadSecretkeyMask(
        bytes32 taskId,
        uint64 round,
        address[] calldata senders,
        bytes[] calldata secretkeyMasks
    ) public roundExists(taskId, round) {
        require(
            senders.length == secretkeyMasks.length,
            "senders length is not equal to secretkeyMasks length"
        );
        for (uint256 i = 0; i < secretkeyMasks.length; i++) {
            require(
                secretkeyMasks[i].length > 0 &&
                    secretkeyMasks[i].length <= maxSSComitmentLength,
                "commitment length exceeds limit or it is empty"
            );
        }
        TaskRound storage curRound = taskRounds[taskId][round];
        require(
            curRound.status == RoundStatus.Aggregating,
            "not in upload ss phase"
        );
        RoundModelCommitments[] storage commitments = roundModelCommitments[
            taskId
        ];
        RoundModelCommitments storage commitment = commitments[round];
        for (uint256 i = 0; i < secretkeyMasks.length; i++) {
            require(
                commitment
                    .ssdata[senders[i]][msg.sender]
                    .secretKeyMaskCommitment
                    .length > 0,
                "must upload commitment first"
            );
            require(
                commitment
                    .ssdata[senders[i]][msg.sender]
                    .secretKeyPiece
                    .length == 0,
                "cannot upload seed multiple times"
            );
            commitment
            .ssdata[senders[i]][msg.sender].secretKeyPiece = secretkeyMasks[i];
            emit ContentUploaded(
                taskId,
                round,
                senders[i],
                msg.sender,
                "SKMASK",
                secretkeyMasks[i]
            );
        }
    }

    function verify(
        bytes32 taskId,
        address verifierAddr,
        bytes memory proof,
        uint256[] memory pubSignals
    ) public taskExists(taskId) returns (bool) {
        Task storage task = createdTasks[taskId];
        require(task.finished);
        VerifierState storage state = verifierStates[taskId];
        require(state.valid);
        require(state.unfinishedClients[msg.sender]);
        state.unfinishedClients[msg.sender] = false;
        state.unfinishedCount--;

        Verifier v = Verifier(verifierAddr);
        try v.verifyProof(proof, pubSignals) returns (bool valid) {
            if (!valid) {
                state.valid = false;
                emit TaskMemberVerified(taskId, msg.sender, false);
                emit TaskVerified(taskId, false);
                return false;
            }
        } catch {
            state.valid = false;
            emit TaskMemberVerified(taskId, msg.sender, false);
            emit TaskVerified(taskId, false);
            return false;
        }

        bytes32 weightCommitment = bytes32(pubSignals[pubSignals.length - 2]);
        bytes32 dataCommitment = bytes32(pubSignals[pubSignals.length - 1]);

        // check gradient norm
        for (uint256 i = 0; i < pubSignals.length - 2; i++) {
            if (i % 2 == 0) {
                state.gradients.push(pubSignals[i]);
            } else {
                if (state.precision == 0) {
                    state.precision = pubSignals[i];
                    require(state.precision > task.tolerance);
                } else {
                    require(state.precision == pubSignals[i]);
                }
            }
        }

        if (state.unfinishedCount == 0) {
            uint256 minGradient;
            for (uint256 i = 0; i < state.gradients.length; i++) {
                uint256 abs = v.q() - state.gradients[i];
                if (state.gradients[i] < abs) {
                    abs = state.gradients[i];
                }
                if (abs < minGradient) {
                    minGradient = abs;
                }
            }
            if (minGradient >= 10**(state.precision - task.tolerance)) {
                state.valid = false;
                emit TaskMemberVerified(taskId, msg.sender, false);
                emit TaskVerified(taskId, false);
                return false;
            }
        }

        // check weight commitment
        RoundModelCommitments[] storage cmmts = roundModelCommitments[taskId];
        require(cmmts.length > task.currentRound);
        RoundModelCommitments storage cmmt = cmmts[task.currentRound];
        if (cmmt.weightCommitment != weightCommitment) {
            state.valid = false;
            emit TaskMemberVerified(taskId, msg.sender, false);
            emit TaskVerified(taskId, false);
            return false;
        }
        // check data commitment

        try dataContract.getDataCommitment(msg.sender, task.dataSet) returns (
            bytes32 trueDataCommitment
        ) {
            if (dataCommitment != trueDataCommitment) {
                state.valid = false;
                emit TaskMemberVerified(taskId, msg.sender, false);
                emit TaskVerified(taskId, false);
                return false;
            }
        } catch {
            state.valid = false;
            emit TaskMemberVerified(taskId, msg.sender, false);
            emit TaskVerified(taskId, false);
            return false;
        }

        emit TaskMemberVerified(taskId, msg.sender, true);
        if (state.unfinishedCount == 0) {
            emit TaskVerified(taskId, true);
        }

        return true;
    }

    function setMaxWeightCommitmentLength(uint64 maxLength) public isOwner {
        maxWeightCommitmentLength = maxLength;
    }

    function setMaxSSCommitmentLength(uint64 maxLength) public isOwner {
        maxSSComitmentLength = maxLength;
    }

    function getMaxCommitmentsLength()
        public
        view
        returns (uint64 sslength, uint64 weightLength)
    {
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
