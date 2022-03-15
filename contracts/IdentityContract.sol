// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract IdentityContract {
    struct Node {
        address addr;
        string url;
        string name;
    }

    address private onwer;
    mapping(address => Node) nodes;
    address[] addrs;

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    // triggered when node joined
    event NodeJoined(address addr, string url, string name);
    // triggered when node info updated
    event NodeUpdated(address addr, string url, string name);
    // triggered when node leaved
    event NodeLeaved(address addr, string url, string name);

    modifier nodeNotExists(address addr) {
        require(
            bytes(nodes[addr].name).length == 0 &&
                bytes(nodes[addr].url).length == 0,
            "node has already joined in"
        );
        _;
    }

    modifier nodeExists(address addr) {
        require(
            bytes(nodes[addr].name).length > 0 &&
                bytes(nodes[addr].url).length > 0,
            "node has not joined in"
        );
        _;
    }

    constructor() {
        onwer = msg.sender;
        emit OwnerSet(address(0), onwer);
    }

    function join(string calldata url, string calldata name)
        public
        nodeNotExists(msg.sender)
    {
        nodes[msg.sender] = Node({addr: msg.sender, url: url, name: name});
        addrs.push(msg.sender);
        emit NodeJoined(msg.sender, url, name);
    }

    function updateUrl(string calldata url) public nodeExists(msg.sender) {
        nodes[msg.sender].url = url;
        emit NodeUpdated(msg.sender, url, nodes[msg.sender].name);
    }

    function updateName(string calldata name) public nodeExists(msg.sender) {
        nodes[msg.sender].name = name;
        emit NodeUpdated(msg.sender, nodes[msg.sender].url, name);
    }

    function leave() public nodeExists(msg.sender) {
        string memory url = nodes[msg.sender].url;
        string memory name = nodes[msg.sender].name;
        delete nodes[msg.sender];
        uint256 removeIndex;
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addrs[i] == msg.sender) {
                removeIndex = i;
                break;
            }
        }
        for (uint256 i = removeIndex; i < addrs.length - 1; i++) {
            addrs[i] = addrs[i + 1];
        }
        addrs.pop();
        emit NodeLeaved(msg.sender, url, name);
    }

    function getNodeInfo(address addr)
        public
        view
        nodeExists(addr)
        returns (Node memory node)
    {
        node = nodes[addr];
    }

    function getNodes(uint256 page, uint256 pageSize)
        public
        view
        returns (Node[] memory, uint256)
    {
        uint256 offset = (page - 1) * pageSize;
        if (offset < addrs.length) {
            uint256 size = addrs.length - offset > pageSize
                ? pageSize
                : addrs.length - offset;
            Node[] memory result = new Node[](size);
            for (uint256 i = 0; i < size; i++) {
                result[i] = nodes[addrs[i]];
            }
            return (result, addrs.length);
        } else {
            return (new Node[](0), addrs.length);
        }
    }
}
