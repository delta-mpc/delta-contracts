import { ClientDuplexStreamImpl } from "@grpc/grpc-js/build/src/call.js";
import Contract from "../src/contract.js";

class Node {
    constructor() {
        console.log('new node instance')
        this.contract = new Contract('DeltaContract');
    }
    async method(call, methodName, ...params) {
        try {
            let receipt = await this.contract.method(methodName, params);
            let res = this.contract.decodeEvent(receipt.logs)
            if (call) {
               await call.write({data:res})
               await call.end()
            }
         }catch(e) {
            if(call) {
               await call.write({error:e.toString()});
               await call.end()
            }
         }
    }
    
    event(call) {
        this.contract.contract.events.allEvents({fromBlock: 'latest'}).on('data', (event) => {
            let res = event.returnValues
            res.name = event.event
            call.write(res)
        }).on('error', (error) => {
            console.log('event error: ', error)
        })
    }
    async callMethod(call,methodName,...args) {
      try {
         let res =  await this.contract.call(methodName,args);
         console.log(res);
         if(call) {
            await call.write({data:res});
            await call.end()
         }
      } catch(e) {
         if (call) {
            await call.write({error:e.toString()});
            await call.end()
         }
      }
    }
    
    async getNodes(call) {
        let total = await this.contract.call('NodeTotal')
        for (let i = 0; i < total; i++) {
            let node = await this.contract.call("nodeList", [i])
            call.write(node)
        }
        call.end()
    }
}

export {Node}
