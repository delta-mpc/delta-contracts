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
        try clientA.uploadSeedCommitment(t_id,1,address(clientB),seedCmmt) {
            Assert.ok(false,"should throw exception1");
        } catch Error(string memory error) {
            Assert.equal(error,"not in secret sharing phase","uploadSeedCommitmentTests failed");
        }
        taskDeveloper.selectCandidates(t_id,1,lst);
        dContract.setMaxSSCommitmentLength(256);
        clientA.uploadSeedCommitment(t_id,1,address(clientB),seedCmmt);
        try clientA.uploadSeedCommitment(t_id,1,address(clientB),seedCmmt) {
            Assert.ok(false,"should throw exception2");
        } catch Error(string memory error) {
            Assert.equal(error,"cannot upload seed cmmt multiple times","uploadSeedCommitmentTests failed");
        }
        bytes memory seedCmmt2 = new bytes(257);
        seedCmmt2[256] = 0x01;
        try clientB.uploadSeedCommitment(t_id,1,address(clientA),seedCmmt2) {
            Assert.ok(false,"should throw exception3");
        }catch Error(string memory error) {
            Assert.equal(error,"commitment length exceeds limit or it is empty","uploadSeedCommitmentTests failed");
        }
        taskDeveloper.startCalculate(t_id,1);
        try clientB.uploadSeedCommitment(t_id,1,address(clientA),seedCmmt) {
            Assert.ok(false,"should throw exception4");
        } catch Error(string memory error) {
            Assert.equal(error,"not in secret sharing phase","uploadSeedCommitmentTests failed");
        }
       
        DeltaContract.SSData memory ssdata =  taskDeveloper.getSecretSharingData(t_id,1,address(clientA),address(clientB));
        bytes memory seedCmtData = ssdata.seedCommitment;
        uint8 v1;
        assembly {
            v1 := byte(0,mload(add(seedCmtData,32)))
        }
        Assert.equal(seedCmtData.length,1,"uploadSeedCommitmentTests Failed");
        Assert.equal(v1,0x02,"uploadSeedCommitmentTests Failed");
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
        try clientA.uploadSKCommitment(t_id,1,address(clientB),seedCmmt) {
            Assert.ok(false,"should throw exception1");
        } catch Error(string memory error) {
            Assert.equal(error,"not in secret sharing phase","uploadSkMaskCommitmentTests failed");
        }
        taskDeveloper.selectCandidates(t_id,1,lst);
        dContract.setMaxSSCommitmentLength(256);
        clientA.uploadSKCommitment(t_id,1,address(clientB),seedCmmt);
        try clientA.uploadSKCommitment(t_id,1,address(clientB),seedCmmt) {
            Assert.ok(false,"should throw exception2");
        } catch Error(string memory error) {
            Assert.equal(error,"cannot upload seed multiple times","uploadSkMaskCommitmentTests failed");
        }
        bytes memory seed2 = new bytes(257);
        seed2[256] = 0x01;
        try clientB.uploadSKCommitment(t_id,1,address(clientA),seed2) {
            Assert.ok(false,"should throw exception3");
        }catch Error(string memory error) {
            Assert.equal(error,"commitment length exceeds limit or it is empty","uploadSkMaskCommitmentTests failed");
        }
        taskDeveloper.startCalculate(t_id,1);
        try clientB.uploadSKCommitment(t_id,1,address(clientA),seedCmmt) {
            Assert.ok(false,"should throw exception4");
        } catch Error(string memory error) {
            Assert.equal(error,"not in secret sharing phase","uploadSkMaskCommitmentTests failed");
        }
        DeltaContract.SSData memory ssdata =  taskDeveloper.getSecretSharingData(t_id,1,address(clientA),address(clientB));
        bytes memory skMaskCmtData = ssdata.secretKeyMaskCommitment;
        uint8 v1;
        assembly {
            v1 := byte(0,mload(add(skMaskCmtData,32)))
        }
        Assert.equal(skMaskCmtData.length,1,"uploadSkMaskCommitmentTests Failed");
        Assert.equal(v1,0x02,"uploadSkMaskCommitmentTests Failed");
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
        try clientA.uploadResultCommitment(t_id,1,theBytes) {
            Assert.ok(false,"should throw exception");
        } catch Error(string memory error) {
            Assert.equal(error,"not in uploading phase","uploadWeightCommitmentTests failed");
        }
        taskDeveloper.selectCandidates(t_id,1,lst);
        bytes memory seed = new bytes(1);
        seed[0] = 0x01;
        bytes memory seedCmmt = new bytes(1);
        seedCmmt[0] = 0x02;
        clientA.uploadSKCommitment(t_id,1,address(clientB),seedCmmt);
        clientA.uploadSeedCommitment(t_id,1,address(clientB),seedCmmt);
        dContract.setMaxWeightCommitmentLength(10);
        bytes memory exceedslimit = new bytes(11);
        taskDeveloper.startCalculate(t_id,1);
        try clientA.uploadResultCommitment(t_id,1,exceedslimit) {
            Assert.ok(false,"should throw exception");
        } catch Error(string memory error) {
            Assert.equal(error,"commitment length exceeds limit or it is empty","uploadWeightCommitmentTests failed");
        }
        clientA.uploadResultCommitment(t_id,1,theBytes);
        try clientA.uploadResultCommitment(t_id,1,theBytes) {
            Assert.ok(false,"should throw exception");
        } catch Error(string memory error) {
            Assert.equal(error,"cannot upload weightCommitment multiple times","uploadWeightCommitmentTests failed");
        }
        bytes memory cmmt =  taskDeveloper.getResultCommitment(t_id,address(clientA),1);
        uint8 v;
        assembly {
            v := byte(0,mload(add(cmmt,32)))
        }
        Assert.equal(cmmt.length,1,"uploadWeightCommitmentShouldSuccess Failed");
        Assert.equal(v,0x01,"uploadWeightCommitmentShouldSuccess Failed");
    }
    
    function uploadSeedTests() public {
        bytes32 t_id = taskDeveloper.createTask("myDataSet",0x683da95c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e09);
        taskDeveloper.startRound(t_id,1,3000,300);
        clientA.joinRound(t_id,1,0xe83da96c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e01,0xe83da96c058c118d61c20dba7a15f44fa0a4c079eff4ca94932f2baf31135e02);
        address[] memory lst = new address[](1);
        lst[0] = address(clientA);
        taskDeveloper.selectCandidates(t_id,1,lst);
        bytes memory theBytes = new bytes(1);
        theBytes[0] = 0x01;
        bytes memory seed = new bytes(1);
        seed[0] = 0x01;
        bytes memory seedCmmt = new bytes(1);
        seedCmmt[0] = 0x02;
        bytes memory skmask = new bytes(1);
        skmask[0] = 0x02;
        clientA.uploadSKCommitment(t_id,1,address(clientB),seedCmmt);
        clientA.uploadSeedCommitment(t_id,1,address(clientB),seedCmmt);
        Assert.ok(true,'should throw exception1');
        dContract.setMaxWeightCommitmentLength(10);
        bytes memory exceedslimit = new bytes(11);
        taskDeveloper.startCalculate(t_id,1);
        clientA.uploadResultCommitment(t_id,1,theBytes);
        try clientA.uploadSeed(t_id,1,address(clientB),seed) {
            Assert.ok(false,'should throw exception1');
        } catch Error(string memory error) {
            Assert.equal(error,"not in upload ss phase","uploadWeightCommitmentTests failed");
        }
        try clientA.uploadSecretkeyMask(t_id,1,address(clientB),skmask) {
            Assert.ok(false,'should throw exception2');
        } catch Error(string memory error) {
            Assert.equal(error,"not in upload ss phase","uploadWeightCommitmentTests failed");
        }
        taskDeveloper.startAggregate(t_id,1,lst);
        clientA.uploadSeed(t_id,1,address(clientB),seed);
        try clientA.uploadSeed(t_id,1,address(clientB),seed) {
            Assert.ok(false,'should throw exception');
        } catch Error(string memory error) {
            Assert.equal(error,"cannot upload seed multiple times","uploadWeightCommitmentTests failed");
        }
        clientA.uploadSecretkeyMask(t_id,1,address(clientB),skmask);
        try clientA.uploadSecretkeyMask(t_id,1,address(clientB),skmask) {
            Assert.ok(false,'should throw exception');
        } catch Error(string memory error) {
            Assert.equal(error,"cannot upload skmask multiple times","uploadWeightCommitmentTests failed");
        }
    } 
    
}