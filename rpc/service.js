import {Node} from './node.js'

let node;

async function init() {
    node = new Node()
}

function registerNode(call) {
    let url = call.request.url;
    node.method(call, 'registerNode', url).then()
}

function registerTask(call) {
    node.method(call, 'registerTask').then()
}


function joinTask(call) {
    node.method(call, 'joinTask', call.request.taskId).then()
}

function train(call) {
    node.method(call, 'train', call.request.taskId).then()
}

function key(call) {
    let req = call.request
    node.method(call, 'key', req.taskId, req.epoch, [...req.key]).then()
}

function event(call) {
    node.event(call)
}

function getNodes(call) {
    node.getNodes(call)
}

init().then(() => {
    console.log('service initialized')
})

export {
    registerNode,
    registerTask,
    joinTask,
    train,
    key,
    event,
    getNodes
}
