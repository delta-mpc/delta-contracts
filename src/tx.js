const Tx = require('@ethereumjs/tx').TransactionFactory;
const conf = require('./config');

const web3 = require('./eth');

async function txData(data, toAddress = '', nonce = 0, gasConfig = null) {

    let key = new Buffer.from(conf.accounts[0].privateKey, 'hex');
    let tra = {
        gasPrice: '0x' + conf.gasPrice.toString(16),
        gasLimit: '0x' + conf.gasLimit.toString(16),
        data: data,
        from: conf.accounts[0].address,
    };
    if (gasConfig !== null) {
        if (gasConfig.hasOwnProperty('gasLimit')) {
            tra.gasLimit = '0x' + gasConfig.gasLimit.toString(16);
        }
        if (gasConfig.hasOwnProperty('gasPrice')) {
            tra.gasPrice = '0x' + gasConfig.gasPrice.toString(16)
        }
        if (gasConfig.hasOwnProperty('from')) {
            for (let account of conf.accounts) {
                if (account.address === gasConfig.from) {
                    tra.from = gasConfig.from;
                    key = new Buffer.from(account.privateKey, 'hex');
                    break
                }
            }
            if (tra.from !== gasConfig.from) {
                console.log('地址', gasConfig.from, '不存在');
                process.exit();
            }
        }
    }
    if (toAddress !== '') {
        tra['to'] = toAddress
    }
    if (nonce === 0) {
        nonce = await web3.eth.getTransactionCount(tra.from);
    }
    tra.nonce = web3.utils.toHex(nonce);
    let tx = Tx.fromTxData(tra, conf.ethOpts);
    return `0x${tx.sign(key).serialize().toString('hex')}`;
}

module.exports = txData;
