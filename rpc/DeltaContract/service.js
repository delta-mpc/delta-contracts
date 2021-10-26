import {Node} from '../node.js'

let node;

async function init() {
    node = new Node()
}

function createTask(call) {
    let creatorUrl = call.request.creatorUrl,
        dataSet = call.request.dataSet,
        commitment = `0x${call.request.commitment.toString('hex')}`;
   console.log(commitment)
    node.method(call, 'createTask',creatorUrl,dataSet,commitment).then()
}

async function getTaskData(call) {
   console.log(call.request.taskId)
   try{
   await node.callMethod(call,'getTaskData',call.request.taskId);
   }catch(e) {
      console.log('exception')
   }
}

async function startRound(call) {
   console.log(call.request.taskId)
   let taskId = call.request.taskId,
       round = call.request.round,
       maxSample = call.request.maxSample,
       minSample = call.request.minSample;
   try{
      await node.method(call,'startRound',taskId,round,maxSample,minSample);
   }catch(e) {
      console.log('exception')
   }
}

async function joinRound(call) {
   console.log(call.request)
   let taskId = call.request.taskId,
       round = call.request.round,
       pk1 = `0x${call.request.pk1.toString('hex')}`,
       pk2 = `0x${call.request.pk2.toString('hex')}`;
   try{
      await node.method(call,'joinRound',taskId,round,pk1,pk2);
   }catch(e) {
      console.log('exception')
   }
}

async function getTaskRound(call) {
   let taskId = call.request.taskId,
       round = call.request.round;
   try{
      await node.callMethod(call,'getTaskRound',taskId,round);
   }catch(e) {
      console.log('exception',e)
   }
}
async function getClientPks(call) {
   let taskId = call.request.taskId,
       round = call.request.round,
       address = call.request.address;
   try{
      await node.callMethod(call,'getClientPks',taskId,round,address);
   }catch(e) {
      console.log('exception')
   }
}

async function selectCandidates(call) {
   let taskId = call.request.taskId,
       round = call.request.round,
       addresses = call.request.addrs;
   try{
      await node.method(call,'selectCandidates',taskId,round,addresses);
   }catch(e) {
      console.log('exception')
   }
}

async function startCalculate(call) {
   let taskId = call.request.taskId,
       round = call.request.round,
       addresses = call.request.addrs;
   try{
      await node.method(call,'startCalculate',taskId,round,addresses);
   }catch(e) {
      console.log('exception')
   }
}


async function uploadResultCommitment(call) {
   let taskId = call.request.taskId,
       round = call.request.round,
       content = call.request.commitment;
   try{
      await node.method(call,'uploadResultCommitment',taskId,round,content);
   }catch(e) {
      console.log('exception')
   }
}


async function uploadSeedCommitment(call) {
   let taskId = call.request.taskId,
       round = call.request.round,
       sharee = call.request.sharee,
       content = call.request.content;
   try{
      await node.method(call,'uploadSeedCommitment',taskId,round,sharee,content);
   } catch(e) {
      console.log('exception')
   }
}

async function getResultCommitment(call) {
   let taskId = call.request.taskId,
       round = call.request.round,
       address = call.request.address;
   try{
      await node.callMethod(call,'getResultCommitment',taskId,round,address);
   }catch(e) {
      console.log('exception')
   }
}


async function getSecretSharingData(call) {
   let taskId = call.request.taskId,
       round = call.request.round,
       owner = call.request.owner,
       sharee = call.request.sharee;
   try{
      await node.callMethod(call,'getSecretSharingData',taskId,round,owner,sharee);
   }catch(e) {
      console.log('exception')
   }
}

async function uploadSeed(call) {
   let taskId = call.request.taskId,
       round = call.request.round,
       sharee = call.request.sharee,
       seed = call.request.content;
   try{
      await node.method(call,'uploadSeed',taskId,round,sharee,seed);
   }catch(e) {
      console.log('exception')
   }
}

async function uploadSKCommitment(call) {
   let taskId = call.request.taskId,
       round = call.request.round,
       sharee = call.request.sharee,
       seed = call.request.content;
   try{
      await node.method(call,'uploadSKCommitment',taskId,round,sharee,seed);
   }catch(e) {
      console.log('exception')
   }
}

async function uploadSecretkeyMask(call) {
   let taskId = call.request.taskId,
       round = call.request.round,
       sharee = call.request.sharee,
       seed = call.request.content;
   try{
      await node.method(call,'uploadSecretkeyMask',taskId,round,sharee,seed);
   }catch(e) {
      console.log('exception')
   }
}

async function startAggregate(call) {
   let taskId = call.request.taskId,
       round = call.request.round,
       addresses = call.request.addrs;
   try{
      await node.method(call,'startAggregate',taskId,round,addresses);
   }catch(e) {
      console.log('exception')
   }
}

async function endRound(call) {
   console.log(call.request.taskId)
   let taskId = call.request.taskId,
       round = call.request.round
   try{
      await node.method(call,'endRound',taskId,round);
   }catch(e) {
      console.log('exception')
   }
}

init().then(() => {
    console.log('service initialized')
})

export {
   createTask,
   getTaskData,
   startRound,
   joinRound,
   getTaskRound,
   getClientPks,
   selectCandidates,
   startCalculate,
   uploadResultCommitment,
   uploadSeedCommitment,
   getResultCommitment,
   getSecretSharingData,
   uploadSeed,
   uploadSKCommitment,
   uploadSecretkeyMask,
   startAggregate,
   endRound
}
