const web3 = require('./eth');
const methodTxData = require('./data').methodTxData;

async function method(contractName, contractAddress, methodName, args) {
    let serializedTx = await methodTxData(contractName, contractAddress, methodName, args);
    let receipt = await web3.eth.sendSignedTransaction(serializedTx, (err, hash) => {
        if (err) {
            console.log(err)
        }
        console.log(contractName + ' call ' + methodName + " txHash:" + hash)
    });
    if (receipt.status) {
        console.log(contractName + ' call ' + methodName + " successfully");
        return receipt
    } else {
        console.log('method ' + methodName + ' call failed!');
        return 0
    }

}
module.exports = method;
