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
    
    function startCalculate(bytes32 taskId,uint64 round) public {
        theContract.startCalculate(taskId,round);
    }
    
    function uploadWeightCommitment(bytes32 taskId,uint64 round,bytes calldata weightCommitment) public {
        theContract.uploadWeightCommitment(taskId,round,weightCommitment);
    }
    function uploadSSeed(bytes32 taskId,uint64 round,address sharee,bytes calldata sseed,bytes calldata seedCmmtmnt) public {
        theContract.uploadSSeed(taskId,round,sharee,sseed,seedCmmtmnt);
    }
    function uploadSkMask(bytes32 taskId,uint64 round,address sharee,bytes calldata skmask,bytes calldata skCmmtmnt)  public {
        theContract.uploadSkMask(taskId,round,sharee,skmask,skCmmtmnt);
    }
    
    function setMaxWeightCommitmentLength(uint64 maxLength) public {
        theContract.setMaxWeightCommitmentLength(maxLength);
    }
    
    function setMaxSSCommitmentLength(uint64 maxLength) public {
        theContract.setMaxSSCommitmentLength(maxLength);
    }
    
    function getWeightCommitment(bytes32 taskId,address clientaddress,uint64 round) public view returns(bytes memory commitment) {
        commitment =  theContract.getWeightCommitment(taskId,clientaddress,round);
    }
    
    function getSSData(bytes32 taskId,uint64 round,address owner,address sharee) public view returns(DeltaContract.SSData memory ssdata)  {
        ssdata =  theContract.getSSData(taskId,round,owner,sharee);
    }
}
