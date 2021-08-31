import compile from "./compile.js";
import * as linker from 'solc/linker.js'
import web3 from "./eth.js";
import txData from './tx.js'
import jsonfile from 'jsonfile'
import * as path from 'path'
import * as fs from 'fs'

const __dirname = path.resolve();

function Contract(name) {
    this.name = name;
    this.get()
    this.at()
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
        let filePath = path.resolve(__dirname, "compile");
        let file = path.join(filePath, this.name + '.json');
        try {
            await jsonfile.writeFile(file, this)
        } catch (err) {
            console.log(this.name + '保存失败：', err)
        }
    },
    load: function () {
        let filePath = path.resolve(__dirname, "compile");
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
            } catch (err) {
                console.log(this.name + '.json加载失败：', err)
            }
        } else {
            console.log(file, '不存在')
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
                    this.save().then(() => {
                    });
                    return
                }
            }
        }
        console.log(this.name + ' 合约编译数据获取失败！');
        process.exit();
    },
    at: function (address) {
        if (!address) {
            address = this.address
        } else {
            this.address = address
        }
        if (address) {
            this.contract = new web3.eth.Contract(this.abi, address);
            return true
        } else {
            return false
        }
    },
    deployData: async function (args = [], opt = null, nonce = 0) {
        let contract = new web3.eth.Contract(this.abi);
        let abiData = contract.deploy({
            data: '0x' + this.byteCode,
            arguments: args
        }).encodeABI();
        return await txData(abiData, '', nonce, opt);
    },
    deploy: async function (args = [], opt = null, nonce = 0) {
        try {
            let serializedTx = await this.deployData(args, opt, nonce);
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
                await this.save()
            } else {
                console.log(this.name + ' 部署失败！');
                process.exit();
            }
        } catch (e) {
            console.log('deploy: ', e)
        }

    },
    notDeployed: function () {
        return !this.address;
    },
    methodData: async function (methodName, args = [], gasConfig = null, nonce = 0) {
        if (this.at()) {
            let method = this.contract.methods[methodName](...args);
            let data = method.encodeABI()
            return await txData(data, this.address, nonce, gasConfig);
        } else {
            throw 'methodData: no deployed contract'
        }
    },
    method: async function (methodName, args = [], gasConfig = null, nonce = 0) {
        try {
            let serializedTx = await this.methodData(methodName, args, gasConfig, nonce);
            let receipt = await web3.eth.sendSignedTransaction(serializedTx, (err, hash) => {
                if (err) {
                    console.log("发送交易数据失败：" + err)
                }
                console.log(this.name + ' 调用方法 ' + methodName + " txHash:" + hash)
            });
            if (receipt.status) {
                console.log(this.name + ' 调用方法 ' + methodName + " 成功！");
                this.logs = receipt.logs;
                return receipt;
            } else {
                console.log('调用方法 ' + methodName + ' 失败！');
                return null;
            }
        } catch (e) {
            console.log('method: ', e)
        }

    },
    decodeEvent: function (logs = null) {
        if (logs == null) {
            logs = this.logs
        }
        for (let log of logs) {
            const topics = log.topics;
            const data = log.data;
            for (let abi of this.abi) {
                if (abi.hasOwnProperty('signature') && topics.includes(abi.signature)) {
                    let log = web3.eth.abi.decodeLog(abi.inputs, data, topics.slice(1));
                    log.name = abi.name
                    console.log("事件数据：", log);
                    return log
                }
            }
        }
        console.log("event log 未找到！");
        return null
    },
    call: async function (methodName, args = []) {
        try {
            if (this.at()) {
                const method = this.contract.methods[methodName];
                return await method(...args).call()
            }
        } catch (e) {
            console.log('contract.call: ', e)
        }
    }
};

export default Contract;
