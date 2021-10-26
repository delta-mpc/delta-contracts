import path from "path";
import {loadPackageDefinition, Server, ServerCredentials} from '@grpc/grpc-js'
import {loadSync} from '@grpc/proto-loader'

const PROTO_PATH = path.resolve('rpc/Mpc', 'mpc.proto')
import {registerNode, event, registerTask, joinTask, train, key, getNodes} from './service.js'

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
    server.addService(mpc_proto.deltacontract.Mpc.service,
        {
            registerNode: registerNode,
            registerTask: registerTask,
            joinTask: joinTask,
            train: train,
            key: key,
            event: event,
            getNodes: getNodes,
        }
    );
    server.bindAsync('0.0.0.0:4500', ServerCredentials.createInsecure(), () => {
        server.start();
    });
}

main();
