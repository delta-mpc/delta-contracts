// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "../../contracts/DeltaContract.sol";
contract Participant {
    DeltaContract theContract;
    constructor(DeltaContract ct) {
        theContract =  ct;
    }
    function createTask(string calldata dataSet ,bytes32 tskCmmtmnt) payable public returns(bytes32 taskId){
        taskId = theContract.createTask("dummyUrl",dataSet,tskCmmtmnt);
    }
    function startRound(bytes32 taskId,uint64 round,uint32 maxSample,uint32 minSample) public {
        theContract.startRound(taskId,round,maxSample,minSample);
    }
    function joinRound(bytes32 taskId,uint64 round,bytes32 pk1,bytes32 pk2) public returns(bool){
        return theContract.joinRound(taskId,round,pk1,pk2);
    }
    function nop() public returns(bool){
        return true;
    }
    function selectCandidates(bytes32 taskId,uint64 round,address[] calldata cltaddrs) public {
        theContract.selectCandidates(taskId,round,cltaddrs);
    }
    
    function startAggregate(bytes32 taskId,uint64 round,address[] calldata onlineClients) public {
        theContract.startAggregate(taskId,round,onlineClients);
    }
    
    function startCalculate(bytes32 taskId,uint64 round,address[] calldata onlineClients) public {
        theContract.startCalculate(taskId,round,onlineClients);
    }
    
    function uploadResultCommitment(bytes32 taskId,uint64 round,bytes calldata weightCommitment) public {
        theContract.uploadResultCommitment(taskId,round,weightCommitment);
    }
    
    function uploadSeedCommitment(bytes32 taskId,uint64 round,address sharee,bytes calldata sseedcmmt) public {
        theContract.uploadSeedCommitment(taskId,round,sharee,sseedcmmt);
    }
    function uploadSKCommitment(bytes32 taskId,uint64 round,address sharee,bytes calldata skmaskcmmt)  public {
        theContract.uploadSKCommitment(taskId,round,sharee,skmaskcmmt);
    }
    
    function uploadSeed(bytes32 taskId,uint64 round,address sharee,bytes calldata sseed) public {
        theContract.uploadSeed(taskId,round,sharee,sseed);
    }
    function uploadSecretkeyMask(bytes32 taskId,uint64 round,address sharee,bytes calldata skmask)  public {
        theContract.uploadSecretkeyMask(taskId,round,sharee,skmask);
    }
    
    function setMaxWeightCommitmentLength(uint64 maxLength) public {
        theContract.setMaxWeightCommitmentLength(maxLength);
    }
    
    function setMaxSSCommitmentLength(uint64 maxLength) public {
        theContract.setMaxSSCommitmentLength(maxLength);
    }
    
    function getResultCommitment(bytes32 taskId,address clientaddress,uint64 round) public view returns(bytes memory commitment) {
        commitment =  theContract.getResultCommitment(taskId,clientaddress,round);
    }
    
    function getSecretSharingData(bytes32 taskId,uint64 round,address owner,address sharee) public view returns(DeltaContract.SSData memory ssdata)  {
        ssdata =  theContract.getSecretSharingData(taskId,round,owner,sharee);
    }
}
