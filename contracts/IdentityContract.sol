// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract IdentityContract {
    uint256 constant aliveTimeout = 120;

    struct Node {
        address addr;
        string url;
        string name;
        uint256 timeout;
    }

    struct NodeInfo {
        address addr;
        string url;
        string name;
    }

    address private onwer;
    mapping(address => uint256) addrs;
    mapping(uint256 => Node) nodes;
    uint256 count;

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    // triggered when node joined
    event NodeJoined(address addr, string url, string name);
    // triggered when node info updated
    event NodeUpdated(address addr, string url, string name);
    // triggered when node leaved
    event NodeLeaved(address addr, string url, string name);

    modifier nodeExists(address addr) {
        require(addrs[addr] > 0, "node does not exist");
        _;
    }

    modifier nodeAlive(address addr) {
        require(
            addrs[addr] > 0 && nodes[addrs[addr]].timeout >= block.timestamp,
            "node has not joined in"
        );
        _;
    }

    constructor() {
        onwer = msg.sender;
        emit OwnerSet(address(0), onwer);
    }

    function join(string calldata url, string calldata name) public {
        uint256 timeout = block.timestamp + aliveTimeout;
        if (addrs[msg.sender] > 0) {
            uint256 id = addrs[msg.sender];
            nodes[id] = Node({
                addr: msg.sender,
                url: url,
                name: name,
                timeout: timeout
            });
        } else {
            count++;
            addrs[msg.sender] = count;
            nodes[count] = Node({
                addr: msg.sender,
                url: url,
                name: name,
                timeout: timeout
            });
        }
        emit NodeJoined(msg.sender, url, name);
    }

    function updateUrl(string calldata url) public nodeAlive(msg.sender) {
        nodes[addrs[msg.sender]].url = url;
        emit NodeUpdated(msg.sender, url, nodes[addrs[msg.sender]].name);
    }

    function updateName(string calldata name) public nodeAlive(msg.sender) {
        nodes[addrs[msg.sender]].name = name;
        emit NodeUpdated(msg.sender, nodes[addrs[msg.sender]].url, name);
    }

    function leave() public nodeExists(msg.sender) {
        string memory url = nodes[addrs[msg.sender]].url;
        string memory name = nodes[addrs[msg.sender]].name;
        addrs[msg.sender] = 0;
        emit NodeLeaved(msg.sender, url, name);
    }

    function getNodeInfo(address addr)
        public
        view
        nodeAlive(addr)
        returns (NodeInfo memory node)
    {
        node = NodeInfo({
            addr: nodes[addrs[addr]].addr,
            url: nodes[addrs[addr]].url,
            name: nodes[addrs[addr]].name
        });
    }

    function getNodes(uint256 page, uint256 pageSize)
        public
        view
        returns (NodeInfo[] memory, uint256)
    {
        uint256 offset = (page - 1) * pageSize;
        uint256 size = 0;
        uint256 aliveCount = 0;
        uint256[] memory ids = new uint256[](pageSize);
        for (uint256 i = 1; i <= count; i++) {
            if (
                nodes[i].timeout >= block.timestamp && addrs[nodes[i].addr] > 0
            ) {
                aliveCount++;
                if (aliveCount > offset && size < pageSize) {
                    ids[size] = addrs[nodes[i].addr];
                    size++;
                }
            }
        }

        NodeInfo[] memory res = new NodeInfo[](size);
        for (uint256 i = 0; i < size; i++) {
            res[i] = NodeInfo({
                addr: nodes[ids[i]].addr,
                url: nodes[ids[i]].url,
                name: nodes[ids[i]].name
            });
        }
        return (res, aliveCount);
    }
}
