import path from "path";
import {loadPackageDefinition, Server, ServerCredentials} from '@grpc/grpc-js'
import {loadSync} from '@grpc/proto-loader'
const PROTO_PATH = path.resolve('rpc/DeltaContract', 'deltacontract.proto')
import {createTask,getTaskData,startRound,joinRound,getTaskRound,getClientPks,selectCandidates,startCalculate,
   uploadResultCommitment,uploadSeedCommitment,getResultCommitment,
   getSecretSharingData,uploadSeed,uploadSKCommitment,uploadSecretkeyMask,startAggregate,endRound} from './service.js'

let packageDefinition = loadSync(
    PROTO_PATH,
    {
        keepCase: true,
        longs: String,
        enums: String,
        defaults: true,
        oneofs: true
    });
let mpc_proto = loadPackageDefinition(packageDefinition)

function main() {
    let server = new Server();
    server.addService(mpc_proto.deltacontract.DeltaContract.service,
        {
           createTask: createTask,
           getTaskData:getTaskData,
           startRound:startRound,
           joinRound:joinRound,
           getTaskRound:getTaskRound,
           getClientPks:getClientPks,
           selectCandidates:selectCandidates,
           startCalculate:startCalculate,
           uploadResultCommitment:uploadResultCommitment,
           uploadSeedCommitment:uploadSeedCommitment,
           getResultCommitment:getResultCommitment,
           getSecretSharingData:getSecretSharingData,
           uploadSeed:uploadSeed,
           uploadSKCommitment:uploadSKCommitment,
           uploadSecretkeyMask:uploadSecretkeyMask,
           startAggregate:startAggregate,
           endRound:endRound
        }
    );
    server.bindAsync('0.0.0.0:4500', ServerCredentials.createInsecure(), () => {
        server.start();
    });
}

main()