const txData = require('./tx');
const compileOutput = require('./compile');
const web3 = require('./eth');
const linker = require('solc/linker');
async function contractTxData(contractName, contractFile='', libs=null, args, nonce=0) {
    if (contractFile === '') {
        contractFile = contractName + '.sol';
    }
    let contractOutput = compileOutput.contracts[contractFile];
    let abi = contractOutput[contractName].abi;
    let byteCode = '0x' + contractOutput[contractName].evm.bytecode.object;
    if (libs !== null) {
       byteCode =  '0x' + linker.linkBytecode(contractOutput[contractName].evm.bytecode.object, libs)
    }
    linker.linkBytecode(contractOutput[contractName].evm.bytecode.object, libs);
    let contract = new web3.eth.Contract(abi);
    let abiData = contract.deploy({
        data: byteCode,
        arguments: args
    }).encodeABI();
    return await txData(abiData, '', nonce);
}

async function methodTxData(contractName, contractAddress, methodName, args, nonce=0) {
    let contractFile = contractName + '.sol';
    let contract = new web3.eth.Contract(compileOutput.contracts[contractFile][contractName].abi, contractAddress);
    let method = contract.methods[methodName](...args);
    let abiData = method.encodeABI();
    return await txData(abiData, contractAddress, nonce);
}
module.exports = {contractTxData, methodTxData};
