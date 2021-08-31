// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Mpc {
    uint32 public task_id;
    mapping(address => string) nodes;
    mapping(address => mapping(uint => uint8)) task_members;
    uint32[] task_train_epoch;

    event Node(address indexed node, string url);
    event Task(address indexed node, uint32 indexed task_id, string url);
    event Join(address indexed node, uint32 indexed task_id);
    event Train(uint32 indexed epoch, uint32 indexed task_id);
    event PublicKey(address indexed node, uint32 indexed epoch, uint32 indexed task_id, bytes key);

    function registerNode(string memory url) public {
        address node = msg.sender;
        nodes[node] = url;
        emit Node(node, url);
    }

    function getNode() public view returns (string memory) {
        return nodes[msg.sender];
    }

    function isNode(address node) public view returns (bool) {
        return bytes(nodes[node]).length > 0;
    }

    function registerTask() public {
        address node = msg.sender;
        require(isNode(node), "Register node before task");

        task_members[node][task_id] = 1;
        task_train_epoch.push(0);
        task_id++;
        emit Task(node, task_id - 1, getNode());
    }

    function joinTask(uint32 id) public {
        address node = msg.sender;
        require(id < task_id, "task id out of range");
        require(isNode(node) && isTaskNone(id), "Can not join task");

        task_members[node][id] = 2;
        emit Join(node, id);
    }

    function isTaskMember(uint32 id) public view returns (bool) {
        return task_members[msg.sender][id] == 2;
    }

    function isTaskOwner(uint32 id) public view returns (bool) {
        return task_members[msg.sender][id] == 1;
    }

    function isTaskNone(uint32 id) public view returns (bool) {
        return task_members[msg.sender][id] == 0;
    }

    function train(uint32 id) public {
        require(id < task_id, "task id out of range");
        require(isTaskOwner(id), "Only the task owner can train");

        uint32 epoch = task_train_epoch[id] + 1;
        task_train_epoch[id] = epoch;
        emit Train(epoch, id);
    }

    function epochNow(uint32 id) public view returns (uint32) {
        return task_train_epoch[id];
    }

    function key(uint32 id, uint32 epoch, bytes memory key_data) public {
        require(!isTaskNone(id), "task none");
        require(epoch > 0 && epoch <= epochNow(id), "epoch out of range");

        emit PublicKey(msg.sender, epoch, id, key_data);
    }
}
