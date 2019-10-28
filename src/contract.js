const compileOutput = require('./compile');
const linker = require('solc/linker');
const web3 = require('./eth');
const txData = require('./tx');

function Contract(name, source = '', abi = '', byteCode = '', address='') {
    this.name = name;
    this.source = source;
    this.abi = abi;
    this.byteCode = byteCode;
    this.address = address;
    this.txHash = '';
    this.receipt = null;
    if (byteCode === '') {
        this.get(name)
    }
}

Contract.prototype = {
    constructor: Contract,
    link: function (libContract) {
        let lib = {};
        let address = {};
        address[libContract.name] = libContract.address;
        lib[libContract.source] = address;
        this.byteCode = linker.linkBytecode(this.byteCode, lib)
    },
    get: function (contractName) {
        for (const sourceName in compileOutput.contracts) {
            if (compileOutput.contracts.hasOwnProperty(sourceName)) {
                let contractOutput = compileOutput.contracts[sourceName];
                if (contractOutput.hasOwnProperty(contractName)) {
                    this.name = contractName;
                    this.source = sourceName;
                    this.abi = contractOutput[contractName].abi;
                    this.byteCode = contractOutput[contractName].evm.bytecode.object;
                    console.log(contractName + ' 合约数据获取成功！');
                    return
                }
            }
        }
    },
    deployData: async function(args=[], nonce = 0) {
        let contract = new web3.eth.Contract(this.abi);
        let abiData = contract.deploy({
            data: '0x' + this.byteCode,
            arguments: args
        }).encodeABI();
        return await txData(abiData, '', nonce);
    },
    deploy: async function (args=[], nonce = 0) {
        let serializedTx = await this.deployData(args, nonce);
        this.receipt = await web3.eth.sendSignedTransaction(serializedTx, (err, hash) => {
            if (err) {
                console.log("发送交易数据失败：" + err)
            }
            this.txHash = hash;
            console.log("部署合约：" + this.name + " txHash:" + this.txHash)
        });
        if (this.receipt.status) {
            this.address = this.receipt.contractAddress;
            console.log(this.name + " 合约已成功部署，地址为:", this.address);
        } else {
            console.log(this.name + ' 部署失败！');
            process.exit();
        }
    },
    methodData: async function(methodName, args=[], nonce=0) {
        let contract = new web3.eth.Contract(this.abi, this.address);
        let method = contract.methods[methodName](...args);
        return await txData(method.encodeABI(), this.address, nonce);
    },
    method: async function(methodName, args=[], nonce=0) {
        let serializedTx = await this.methodData(methodName, args, nonce);
        this.receipt = await web3.eth.sendSignedTransaction(serializedTx, (err, hash) => {
            if (err) {
                console.log("发送交易数据失败：" + err)
            }
            console.log(this.name + ' 调用 ' + methodName + " txHash:" + hash)
        });
        if (this.receipt.status) {
            console.log(this.name + ' 调用 ' + methodName + " successfully");
        } else {
            console.log('方法 ' + methodName + ' 调用失败！');
        }
    }
};

module.exports = Contract;
