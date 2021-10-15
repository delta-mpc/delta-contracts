// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "./lib/Test_Participant.sol";
import "../contracts/DeltaContract.sol";

contract DeltaContractTest {
   
    DeltaContract dContract;
    Participant taskDeveloper;
    Participant clientA;
    Participant clientB;
    Participant clientC;
    function beforeAll () public {
        dContract = new DeltaContract();
        taskDeveloper = new Participant(dContract);
        clientA = new Participant(dContract);
        clientB = new Participant(dContract);
        clientC = new Participant(dContract);
    }
    function CreateTaskShouldBeSuccessful () public {
        bytes32 t_id = taskDeveloper.createTask("myDataSet",0xd83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e00);
        DeltaContract.Task memory taskData = dContract.getTaskData(t_id);
        Assert.equal(taskData.dataSet,"myDataSet", "CreateTaskFailed");
        Assert.equal(taskData.commitment,0xd83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e00, "CreateTaskFailed");
        Assert.equal(taskData.currentRound,0, "CreateTaskFailed");
    }
    
    function StartRoundTests () public {
        bytes32 t_id = taskDeveloper.createTask("myDataSet",0xd83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e01);
        try taskDeveloper.startRound(0xd83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e00,0,3000,300)
         {
            Assert.ok(false,"should throw exception");
         } catch Error (string memory error) {
            Assert.equal(error,"Task not exists","StartRoundBatches failed");
        }
        try clientA.startRound(t_id,1,3000,300)
         {
            Assert.ok(false,"should throw exception");
         } catch Error (string memory error) {
            Assert.equal(error,"Must called by the task owner","StartRoundBatches failed");
        }
        try taskDeveloper.startRound(t_id,0,3000,300)
         {
            Assert.ok(false,"should throw exception");
         } catch Error (string memory error) {
            Assert.equal(error,"the round has been already started or the pre round does not exist","StartRoundBatches failed");
        }
        taskDeveloper.startRound(t_id,1,3000,300);
        DeltaContract.ExtCallTaskRoundStruct memory tRound = dContract.getTaskRound(t_id,1);
        Assert.equal(tRound.currentRound,1,"StartRoundBatches failed");
        Assert.equal(tRound.maxSample,3000,"StartRoundBatches failed");
        Assert.equal(tRound.minSample,300,"StartRoundBatches failed");
    }
    function joinRoundTests() public {
        bytes32 t_id = taskDeveloper.createTask("myDataSet",0xd83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e02);
        taskDeveloper.startRound(t_id,1,3000,300);
        try clientA.joinRound(0xd83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e00,1,"1",
                              0xd83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e00,
                              0xd83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e02)
        {
            Assert.ok(false,"should throw exception");
        } catch Error (string memory error) {
            Assert.equal(error,"Task not exists","joinRoundTests failed");
        }
        try clientA.joinRound(t_id,0,
                              "1",    
                              0xd83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e00,
                              0xd83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e02)
        {
            Assert.ok(false,"should throw exception");
        } catch Error (string memory error) {
            Assert.equal(error,"this round has finished or it hasn't been started yet.","joinRoundTests failed");
        }
        try clientA.joinRound(t_id,1,
                              "",    
                              0xd83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e00,
                              0xd83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e02) {
            Assert.ok(false,"should throw exception");                     
        } catch Error (string memory error) {
            Assert.equal(error,"Must provide url","joinRoundTests failed");
        }
        clientA.joinRound(t_id,1,"1",0xd83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e00,0xd83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e02);
        try clientA.joinRound(t_id,1,"1",0xe83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e00,0xe83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e02) {
            Assert.ok(false,"should throw exception");
        } catch Error (string memory error) {
            Assert.equal(error,"Cannot join the same round multiple times","joinRoundTests failed");
        }
        address[] memory lst = new address[](1);
        lst[0] = address(clientA);
        taskDeveloper.selectCandidates(t_id,1,lst);
        try clientB.joinRound(t_id,1,"1",0xd83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e00,0xd83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e02) {
            Assert.ok(false,"should throw exception");
        } catch Error (string memory error) {
            Assert.equal(error,"join phase has passed","joinRoundTests failed");
        }
        DeltaContract.ExtCallTaskRoundStruct memory round = dContract.getTaskRound(t_id,1);
        Assert.equal(round.joinedAddrs.length,1,"joinRoundTests failed");
        Assert.equal(round.joinedAddrs[0],address(clientA),"joinRoundTests failed");
    }
    function selectCandidatesTests() public {
        bytes32 t_id = taskDeveloper.createTask("myDataSet",0xa83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e02);
        taskDeveloper.startRound(t_id,1,3000,300);
        clientA.joinRound(t_id,1,"1",0xe83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e01,0xe83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e02);
        clientB.joinRound(t_id,1,"1",0xf83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e08,0xf83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e09);
        address[] memory lst = new address[](2);
        lst[0] = address(clientA);
        lst[1] = address(clientB);
        try clientA.selectCandidates(t_id,1,lst) {
            Assert.ok(false,"should throw exception");
        } catch Error (string memory error) {
            Assert.equal(error,"Must called by the task owner","selectCandidatesTest failed");
        }
        lst = new address[](2);
        lst[0] = address(clientA);
        lst[1] = address(clientC);
        try taskDeveloper.selectCandidates(t_id,1,lst) {
            Assert.ok(false,"should throw exception");
        } catch Error (string memory error) {
            Assert.equal(error,"Candidate must exist","selectCandidatesTest failed");
        }
        lst = new address[](2);
        lst[0] = address(clientA);
        lst[1] = address(clientB);
        taskDeveloper.selectCandidates(t_id,1,lst);
    }
    
    function startAggregateUploadTests() public {
        bytes32 t_id = taskDeveloper.createTask("myDataSet",0xa83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e09);
        taskDeveloper.startRound(t_id,1,3000,300);
        clientA.joinRound(t_id,1,"1",0xe83da96c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e01,0xe83da96c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e02);
        address[] memory lst = new address[](1);
        lst[0] = address(clientA);
        try taskDeveloper.startAggregateUpload(t_id,1,lst) {
            Assert.ok(false,"should throw exception");
        } catch Error(string memory error) {
            Assert.equal(error,"This round is not running now","selectCandidatesTest failed");
        }
        taskDeveloper.selectCandidates(t_id,1,lst);
        lst[0] = address(clientB);
        try taskDeveloper.startAggregateUpload(t_id,1,lst) {
            Assert.ok(false,"should throw exception");
        } catch Error(string memory error) {
            Assert.equal(error,"Candidate must exist","selectCandidatesTest failed");
        }
        lst[0] = address(clientA);
        taskDeveloper.startAggregateUpload(t_id,1,lst);
    }
    function uploadWeightCommitmentTests() public {
        bytes32 t_id = taskDeveloper.createTask("myDataSet",0x683da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e09);
        taskDeveloper.startRound(t_id,1,3000,300);
        clientA.joinRound(t_id,1,"1",0xe83da96c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e01,0xe83da96c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e02);
        address[] memory lst = new address[](1);
        lst[0] = address(clientA);
        bytes memory theBytes = new bytes(1);
        theBytes[0] = 0x01;
        try clientA.uploadWeightCommitment(t_id,1,theBytes) {
            Assert.ok(false,"should throw exception");
        } catch Error(string memory error) {
            Assert.equal(error,"This round is not running now or it has expired","uploadWeightCommitmentTests failed");
        }
        taskDeveloper.selectCandidates(t_id,1,lst);
        bytes memory empty = new bytes(0);
        try clientA.uploadWeightCommitment(t_id,1,empty) {
            Assert.ok(false,"should throw exception");
        } catch Error(string memory error) {
            Assert.equal(error,"commitment length exceeds limit or it is empty","uploadWeightCommitmentTests failed");
        }
        
        dContract.setMaxWeightCommitmentLength(10);
        bytes memory exceedslimit = new bytes(11);
        try clientA.uploadWeightCommitment(t_id,1,exceedslimit) {
            Assert.ok(false,"should throw exception");
        } catch Error(string memory error) {
            Assert.equal(error,"commitment length exceeds limit or it is empty","uploadWeightCommitmentTests failed");
        }
        clientA.uploadWeightCommitment(t_id,1,theBytes);
        try clientA.uploadWeightCommitment(t_id,1,theBytes) {
            Assert.ok(false,"should throw exception");
        } catch Error(string memory error) {
            Assert.equal(error,"cannot upload weightCommitment multiple times","uploadWeightCommitmentTests failed");
        }
        DeltaContract.CommitmentData memory cmmt =  taskDeveloper.getCommitment(t_id,address(clientA),1);
        bytes memory cmmtData = cmmt.weightCommitment;
        uint8 v;
        assembly {
            v := byte(0,mload(add(cmmtData,32)))
        }
        Assert.equal(cmmt.weightCommitment.length,1,"uploadWeightCommitmentShouldSuccess Failed");
        Assert.equal(v,0x01,"uploadWeightCommitmentShouldSuccess Failed");
    }
    
    function uploadSeedCommitmentTests() public {
        bytes32 t_id = taskDeveloper.createTask("myDataSet",0x183da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e09);
        taskDeveloper.startRound(t_id,1,3000,300);
        clientA.joinRound(t_id,1,"1",0xe83da96c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e01,0xe83da96c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e02);
        address[] memory lst = new address[](1);
        lst[0] = address(clientA);
        taskDeveloper.selectCandidates(t_id,1,lst);
        dContract.setMaxSSCommitmentLength(256);
        bytes memory theBytes = new bytes(200);
        theBytes[199] = 0x01;
        try clientA.uploadSeedCommitment(t_id,1,theBytes) {
            Assert.ok(false,"should throw exception");
        } catch Error(string memory error) {
            Assert.equal(error,"seed commitment uploading hasn't started","uploadSeedCommitmentTests failed");
        }
        taskDeveloper.startAggregateUpload(t_id,1,lst);
        bytes memory empty = new bytes(0);
        try clientA.uploadSeedCommitment(t_id,1,empty) {
            Assert.ok(false,"should throw exception");
        } catch Error(string memory error) {
            Assert.equal(error,"commitment length exceeds limit or it is empty","uploadSeedCommitmentTests failed");
        }
        theBytes = new bytes(1);
        theBytes[0] = 0x01;
        clientA.uploadSeedCommitment(t_id,1,theBytes);
        try clientA.uploadSeedCommitment(t_id,1,theBytes) {
            Assert.ok(false,"should throw exception");
        } catch Error(string memory error) {
            Assert.equal(error,"cannot upload seedCmmtmnt multiple times","uploadSeedCommitmentTests failed");
        }
        DeltaContract.CommitmentData memory cmmt =  taskDeveloper.getCommitment(t_id,address(clientA),1);
        bytes memory cmmtData = cmmt.seedCmmtmnt;
        uint8 v;
        assembly {
            v := byte(0,mload(add(cmmtData,32)))
        }
        Assert.equal(cmmt.seedCmmtmnt.length,1,"uploadSeedCommitmentTests Failed");
        Assert.equal(v,0x01,"uploadSeedCommitmentTests Failed");
    }
    
    function setCommitmentTest() public {
        try taskDeveloper.setMaxWeightCommitmentLength(1000) {
            Assert.ok(false,"should throw exception");
        } catch Error(string memory error) {
            Assert.equal(error,"Caller is not owner","setCommitmentTest failed");
        }
        
        try taskDeveloper.setMaxSSCommitmentLength(1000) {
            Assert.ok(false,"should throw exception");
        } catch Error(string memory error) {
            Assert.equal(error,"Caller is not owner","setCommitmentTest failed");
        }
        
        dContract.setMaxWeightCommitmentLength(10000);
        dContract.setMaxSSCommitmentLength(257);
        
        (uint64 maxSS,uint64 maxWeight) = dContract.getMaxCommitmentsLength();
        
        Assert.equal(maxSS,257,"setCommitmentTest Failded");
        
        Assert.equal(maxWeight,10000,"setCommitmentTest Failded");
    }
    
    function uploadSkMaskCommitmentTests() public {
        bytes32 t_id = taskDeveloper.createTask("myDataSet",0x183da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e09);
        taskDeveloper.startRound(t_id,1,3000,300);
        clientA.joinRound(t_id,1,"1",0xe83da96c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e01,0xe83da96c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e02);
        address[] memory lst = new address[](1);
        lst[0] = address(clientA);
        taskDeveloper.selectCandidates(t_id,1,lst);
        dContract.setMaxSSCommitmentLength(256);
        bytes memory theBytes = new bytes(200);
        theBytes[199] = 0x01;
        try clientA.uploadSkMaskCommitment(t_id,1,theBytes) {
            Assert.ok(false,"should throw exception");
        } catch Error(string memory error) {
            Assert.equal(error,"sk mask commitment uploading hasn't started","uploadSkMaskCommitmentTests failed");
        }
        taskDeveloper.startAggregateUpload(t_id,1,lst);
        bytes memory empty = new bytes(0);
        try clientA.uploadSkMaskCommitment(t_id,1,empty) {
            Assert.ok(false,"should throw exception");
        } catch Error(string memory error) {
            Assert.equal(error,"commitment length exceeds limit or it is empty","uploadSkMaskCommitmentTests failed");
        }
        theBytes = new bytes(257);
        theBytes[256] = 0x01;
        try clientA.uploadSkMaskCommitment(t_id,1,theBytes) {
            Assert.ok(false,"should throw exception");
        } catch Error(string memory error) {
            Assert.equal(error,"commitment length exceeds limit or it is empty","uploadSkMaskCommitmentTests failed");
        }
        
        theBytes = new bytes(1);
        theBytes[0] = 0x01;
        clientA.uploadSkMaskCommitment(t_id,1,theBytes);
        try clientA.uploadSkMaskCommitment(t_id,1,theBytes) {
            Assert.ok(false,"should throw exception");
        } catch Error(string memory error) {
            Assert.equal(error,"cannot upload seedCmmtmnt multiple times","uploadSkMaskCommitmentTests failed");
        }
        DeltaContract.CommitmentData memory cmmt =  taskDeveloper.getCommitment(t_id,address(clientA),1);
        bytes memory cmmtData = cmmt.secretKeyMaskCmmtmnt;
        uint8 v;
        assembly {
            v := byte(0,mload(add(cmmtData,32)))
        }
        Assert.equal(cmmt.secretKeyMaskCmmtmnt.length,1,"uploadSkMaskCommitmentTests Failed");
        Assert.equal(v,0x01,"uploadSkMaskCommitmentTests Failed");
    }
    
    function startAggregateTest() public {
        bytes32 t_id = taskDeveloper.createTask("myDataSet",0x183da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e09);
        taskDeveloper.startRound(t_id,1,3000,300);
        clientA.joinRound(t_id,1,"1",0xe83da96c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e01,0xe83da96c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e02);
        address[] memory lst = new address[](1);
        lst[0] = address(clientA);
        taskDeveloper.selectCandidates(t_id,1,lst);
        try taskDeveloper.startAggregate(t_id,1) {
            Assert.ok(false,"should throw exception");
        } catch Error(string memory error) {
            Assert.equal(error,"AggregatUploading has not started","startAggregateTest failed");
        }
        taskDeveloper.startAggregateUpload(t_id,1,lst);
        try clientA.startAggregate(t_id,1) {
            Assert.ok(false,"should throw exception");
        } catch Error(string memory error) {
            Assert.equal(error,"Must called by the task owner","startAggregateTest failed");
        }
        taskDeveloper.startAggregate(t_id,1);
    }
}
