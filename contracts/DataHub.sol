// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract DataHub {
    address private owner;
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    struct DataRecord {
        bytes32 commitment;
        uint32 version;
    }
    mapping(address => mapping(string => DataRecord)) datahub;

    event DataRegistered(
        address indexed owner,
        string name,
        bytes32 commitment,
        uint32 version
    );

    constructor() {
        owner = msg.sender;
        emit OwnerSet(address(0), owner);
    }

    function register(string calldata name, bytes32 commitment) public {
        datahub[msg.sender][name].commitment = commitment;
        datahub[msg.sender][name].version += 1;

        emit DataRegistered(
            msg.sender,
            name,
            commitment,
            datahub[msg.sender][name].version
        );
    }

    modifier dataExists(address addr, string calldata name) {
        require(datahub[addr][name].version > 0);
        _;
    }

    function getDataCommitment(address addr, string calldata name)
        public
        view
        dataExists(addr, name)
        returns (bytes32 commitment)
    {
        commitment = datahub[addr][name].commitment;
    }

    function getDataVersion(address addr, string calldata name)
        public
        view
        dataExists(addr, name)
        returns (uint32 version)
    {
        version = datahub[addr][name].version;
    }
}
