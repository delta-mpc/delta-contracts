const web3 = require('./eth');
const contractTxData = require('./data').contractTxData;
async function deploy(contractName, contractFile, libs, args) {
    let serializedTx = await contractTxData(contractName, contractFile, libs, args);
    let receipt = await web3.eth.sendSignedTransaction(serializedTx, (err, hash) => {
        if (err) {
            console.log(err)
        }
        console.log("部署合约：" + contractName + " txHash:" + hash)
    });
    if (receipt.status) {
        console.log(contractName + " 合约已成功部署，地址为:", receipt.contractAddress);
        return receipt
    } else {
        console.log(contractName + ' 部署失败！');
        return 0
    }
}
module.exports = deploy;






