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
    
}
