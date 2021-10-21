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
        try clientA.joinRound(0xd83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e00,1,
                              0xd83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e00,
                              0xd83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e02)
        {
            Assert.ok(false,"should throw exception1");
        } catch Error (string memory error) {
            Assert.equal(error,"Task not exists","joinRoundTests failed");
        }
        try clientA.joinRound(t_id,0,
                              0xd83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e00,
                              0xd83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e02)
        {
            Assert.ok(false,"should throw exception2");
        } catch Error (string memory error) {
            Assert.equal(error,"join phase has passed","joinRoundTests failed");
        }
        clientA.joinRound(t_id,1,0xd83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e03,0xd83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e04);
        try clientA.joinRound(t_id,1,0xe83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e00,0xe83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e02) {
            Assert.ok(false,"should throw exception");
        } catch Error (string memory error) {
            Assert.equal(error,"Cannot join the same round multiple times","joinRoundTests failed");
        }
        address[] memory lst = new address[](1);
        lst[0] = address(clientA);
        taskDeveloper.selectCandidates(t_id,1,lst);
        try clientB.joinRound(t_id,1,0xd83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e00,0xd83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e02) {
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
        clientA.joinRound(t_id,1,0xe83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e01,0xe83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e02);
        clientB.joinRound(t_id,1,0xf83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e08,0xf83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e09);
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
    
    function uploadSeedCommitmentTests() public {
        bytes32 t_id = taskDeveloper.createTask("myDataSet",0x183da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e09);
        taskDeveloper.startRound(t_id,1,3000,300);
        clientA.joinRound(t_id,1,0xe83da96c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e01,0xe83da96c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e02);
        address[] memory lst = new address[](1);
        lst[0] = address(clientA);
        bytes memory seed = new bytes(1);
        seed[0] = 0x01;
        bytes memory seedCmmt = new bytes(1);
        seedCmmt[0] = 0x02;
        try clientA.uploadSSeed(t_id,1,address(clientB),seed,seedCmmt) {
            Assert.ok(false,"should throw exception1");
        } catch Error(string memory error) {
            Assert.equal(error,"not in secret sharing phase","uploadSeedCommitmentTests failed");
        }
        taskDeveloper.selectCandidates(t_id,1,lst);
        dContract.setMaxSSCommitmentLength(256);
        clientA.uploadSSeed(t_id,1,address(clientB),seed,seedCmmt);
        try clientA.uploadSSeed(t_id,1,address(clientB),seed,seedCmmt) {
            Assert.ok(false,"should throw exception2");
        } catch Error(string memory error) {
            Assert.equal(error,"cannot upload seed multiple times","uploadSeedCommitmentTests failed");
        }
        bytes memory seed2 = new bytes(257);
        seed2[256] = 0x01;
        try clientB.uploadSSeed(t_id,1,address(clientA),seed2,seedCmmt) {
            Assert.ok(false,"should throw exception3");
        }catch Error(string memory error) {
            Assert.equal(error,"commitment length exceeds limit or it is empty","uploadSeedCommitmentTests failed");
        }
        taskDeveloper.startCalculate(t_id,1);
        try clientB.uploadSSeed(t_id,1,address(clientA),seed,seedCmmt) {
            Assert.ok(false,"should throw exception4");
        } catch Error(string memory error) {
            Assert.equal(error,"not in secret sharing phase","uploadSeedCommitmentTests failed");
        }
       
        DeltaContract.SSData memory ssdata =  taskDeveloper.getSSData(t_id,1,address(clientA),address(clientB));
        bytes memory seedCmtData = ssdata.ssSeedCmmtmnt;
        bytes memory seedData = ssdata.ssSeed;
        uint8 v1;
        uint8 v2;
        assembly {
            v1 := byte(0,mload(add(seedData,32)))
            v2 := byte(0,mload(add(seedCmtData,32)))
        }
        Assert.equal(seedCmtData.length,1,"uploadSeedCommitmentTests Failed");
        Assert.equal(seedData.length,1,"uploadSeedCommitmentTests Failed");
        Assert.equal(v1,0x01,"uploadSeedCommitmentTests Failed");
        Assert.equal(v2,0x02,"uploadSeedCommitmentTests Failed");
    }
    
    
     function uploadSkMaskCommitmentTests() public {
        bytes32 t_id = taskDeveloper.createTask("myDataSet",0x183da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e09);
        taskDeveloper.startRound(t_id,1,3000,300);
        clientA.joinRound(t_id,1,0xe83da96c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e01,0xe83da96c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e02);
        address[] memory lst = new address[](1);
        lst[0] = address(clientA);
        bytes memory seed = new bytes(1);
        seed[0] = 0x01;
        bytes memory seedCmmt = new bytes(1);
        seedCmmt[0] = 0x02;
        try clientA.uploadSkMask(t_id,1,address(clientB),seed,seedCmmt) {
            Assert.ok(false,"should throw exception");
        } catch Error(string memory error) {
            Assert.equal(error,"not in secret sharing phase","uploadSkMaskCommitmentTests failed");
        }
        taskDeveloper.selectCandidates(t_id,1,lst);
        dContract.setMaxSSCommitmentLength(256);
        clientA.uploadSkMask(t_id,1,address(clientB),seed,seedCmmt);
        try clientA.uploadSkMask(t_id,1,address(clientB),seed,seedCmmt) {
            Assert.ok(false,"should throw exception");
        } catch Error(string memory error) {
            Assert.equal(error,"cannot upload seed multiple times","uploadSkMaskCommitmentTests failed");
        }
        bytes memory seed2 = new bytes(257);
        seed2[256] = 0x01;
        try clientB.uploadSkMask(t_id,1,address(clientA),seed2,seedCmmt) {
            Assert.ok(false,"should throw exception");
        }catch Error(string memory error) {
            Assert.equal(error,"commitment length exceeds limit or it is empty","uploadSkMaskCommitmentTests failed");
        }
        taskDeveloper.startCalculate(t_id,1);
        try clientB.uploadSkMask(t_id,1,address(clientA),seed,seedCmmt) {
            Assert.ok(false,"should throw exception");
        } catch Error(string memory error) {
            Assert.equal(error,"not in secret sharing phase","uploadSkMaskCommitmentTests failed");
        }
        DeltaContract.SSData memory ssdata =  taskDeveloper.getSSData(t_id,1,address(clientA),address(clientB));
        bytes memory skMaskCmtData = ssdata.ssSecretKeyMaskCmmtmnt;
        bytes memory skMaskData = ssdata.ssSecretKey;
        uint8 v1;
        uint8 v2;
        assembly {
            v1 := byte(0,mload(add(skMaskData,32)))
            v2 := byte(0,mload(add(skMaskCmtData,32)))
        }
        Assert.equal(skMaskCmtData.length,1,"uploadSkMaskCommitmentTests Failed");
        Assert.equal(skMaskData.length,1,"uploadSkMaskCommitmentTests Failed");
        Assert.equal(v1,0x01,"uploadSkMaskCommitmentTests Failed");
        Assert.equal(v2,0x02,"uploadSkMaskCommitmentTests Failed");
    }
    
    function startCalculateTest() public {
        bytes32 t_id = taskDeveloper.createTask("myDataSet",0xa83da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e09);
        taskDeveloper.startRound(t_id,1,3000,300);
        clientA.joinRound(t_id,1,0xe83da96c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e01,0xe83da96c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e02);
        try taskDeveloper.startCalculate(t_id,1) {
            Assert.ok(false,"should throw exception");
        } catch Error(string memory error) {
            Assert.equal(error,"This round is not running now","selectCandidatesTest failed");
        }
    }
    
    function uploadWeightCommitmentTests() public {
        bytes32 t_id = taskDeveloper.createTask("myDataSet",0x683da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e09);
        taskDeveloper.startRound(t_id,1,3000,300);
        clientA.joinRound(t_id,1,0xe83da96c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e01,0xe83da96c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e02);
        address[] memory lst = new address[](1);
        lst[0] = address(clientA);
        bytes memory theBytes = new bytes(1);
        theBytes[0] = 0x01;
        try clientA.uploadWeightCommitment(t_id,1,theBytes) {
            Assert.ok(false,"should throw exception");
        } catch Error(string memory error) {
            Assert.equal(error,"not in uploading phase","uploadWeightCommitmentTests failed");
        }
        taskDeveloper.selectCandidates(t_id,1,lst);
        bytes memory seed = new bytes(1);
        seed[0] = 0x01;
        bytes memory seedCmmt = new bytes(1);
        seedCmmt[0] = 0x02;
        clientA.uploadSkMask(t_id,1,address(clientB),seed,seedCmmt);
        clientA.uploadSSeed(t_id,1,address(clientB),seed,seedCmmt);
        dContract.setMaxWeightCommitmentLength(10);
        bytes memory exceedslimit = new bytes(11);
        taskDeveloper.startCalculate(t_id,1);
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
        bytes memory cmmt =  taskDeveloper.getWeightCommitment(t_id,address(clientA),1);
        uint8 v;
        assembly {
            v := byte(0,mload(add(cmmt,32)))
        }
        Assert.equal(cmmt.length,1,"uploadWeightCommitmentShouldSuccess Failed");
        Assert.equal(v,0x01,"uploadWeightCommitmentShouldSuccess Failed");
    }
    
}
