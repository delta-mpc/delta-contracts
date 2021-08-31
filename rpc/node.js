import Contract from "../src/contract.js";

class Node {
    constructor() {
        console.log('new node instance')
        this.contract = new Contract('Mpc');
    }

    async method(call, methodName, ...params) {
        let receipt = await this.contract.method(methodName, params)
        let res = this.contract.decodeEvent(receipt.logs)
        if (call) {
            call.write(res)
            call.end()
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
