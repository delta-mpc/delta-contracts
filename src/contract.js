const compile = require('./compile');
const linker = require('solc/linker');
const web3 = require('./eth');
const txData = require('./tx');
const jsonfile = require('jsonfile');
const path = require('path');
const fs = require('fs');


function Contract(name, source = '', abi = '', byteCode = '', address = '') {
    this.name = name;
    this.source = source;
    this.abi = abi;
    this.byteCode = byteCode;
    this.address = address;
    this.txHash = '';
    this.receipt = null;
    if (byteCode === '') {
        this.get()
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
    save: async function () {
        let filePath = path.resolve(__dirname, '..', "compile");
        let file = path.join(filePath, this.name + '.json');
        try {
            await jsonfile.writeFile(file, this)
        } catch (err) {
            console.log(this.name + '保存失败：', err)
        }
    },
    load: function () {
        let filePath = path.resolve(__dirname, '..', "compile");
        let file = path.join(filePath, this.name + '.json');
        if (fs.existsSync(file)) {
            try {
                let contractData = jsonfile.readFileSync(file);
                if (!!contractData) {
                    this.name = contractData.name;
                    this.source = contractData.source;
                    this.abi = contractData.abi;
                    this.byteCode = contractData.byteCode;
                    this.address = contractData.address;
                    this.txHash = contractData.txHash;
                    return true
                }
            }
            catch (err) {
                console.log(this.name + '.json加载失败：')
            }
        }
        return false
    },
    get: function () {
        if (this.load()) {
            console.log(this.name + ' 合约编译数据加载成功！');
            return
        }
        let compileOutput = compile();
        for (const sourceName in compileOutput.contracts) {
            if (compileOutput.contracts.hasOwnProperty(sourceName)) {
                let contractOutput = compileOutput.contracts[sourceName];
                if (contractOutput.hasOwnProperty(this.name)) {
                    this.source = sourceName;
                    this.abi = contractOutput[this.name].abi;
                    this.byteCode = contractOutput[this.name].evm.bytecode.object;
                    console.log(this.name + ' 合约编译数据获取成功！');
                    this.save();
                    return
                }
            }
        }
        console.log(this.name + ' 合约编译数据获取失败！');
        process.exit();
    },
    deployData: async function (args = [], gasConfig = null, nonce = 0) {
        let contract = new web3.eth.Contract(this.abi);
        let abiData = contract.deploy({
            data: '0x' + this.byteCode,
            arguments: args
        }).encodeABI();
        return await txData(abiData, '', nonce, gasConfig);
    },
    deploy: async function (args = [], gasConfig = null, nonce = 0) {
        let serializedTx = await this.deployData(args, gasConfig, nonce);
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
            this.save()
        } else {
            console.log(this.name + ' 部署失败！');
            process.exit();
        }
    },
    deployed: function() {
      return this.address !== '';
    },
    methodData: async function (methodName, args = [], gasConfig = null, nonce = 0) {
        let contract = new web3.eth.Contract(this.abi, this.address);
        let method = contract.methods[methodName](...args);
        return await txData(method.encodeABI(), this.address, nonce, gasConfig);
    },
    method: async function (methodName, args = [], gasConfig = null, nonce = 0) {
        let serializedTx = await this.methodData(methodName, args, gasConfig, nonce);
        let receipt = await web3.eth.sendSignedTransaction(serializedTx, (err, hash) => {
            if (err) {
                console.log("发送交易数据失败：" + err)
            }
            console.log(this.name + ' 调用方法 ' + methodName + " txHash:" + hash)
        });
        if (receipt.status) {
            console.log(this.name + ' 调用方法 ' + methodName + " 成功！");
            return receipt;
        } else {
            console.log('调用方法 ' + methodName + ' 失败！');
            return null;
        }
    }
};

module.exports = Contract;
