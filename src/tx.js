const Tx = require('ethereumjs-tx').Transaction;
const conf = require('./config');
const key = new Buffer.from(conf.privateKey, 'hex');
const web3 = require('./eth');
async function txData(data, toAddress='', nonce=0, gasConfig=null) {
    if (nonce === 0) {
        nonce = await web3.eth.getTransactionCount(conf.account);
    }
    const nonceHex = web3.utils.toHex(nonce);
    let tra = {
        nonce: nonceHex,
        gasPrice: '0x' + conf.gasPrice.toString(16),
        gasLimit: '0x' + conf.gasLimit.toString(16),
        data: data,
        from: conf.account,
    };
    if (gasConfig !== null) {
        if (gasConfig.hasOwnProperty('gasLimit')) {
            tra.gasLimit = '0x' + gasConfig.gasLimit.toString(16);
        }
        if (gasConfig.hasOwnProperty('gasPrice')) {
            tra.gasPrice = '0x' + gasConfig.gasPrice.toString(16)
        }

    }
    if (toAddress !== '') {
        tra['to'] = toAddress
    }
    const tx = new Tx(tra, conf.ethOpts);
    tx.sign(key);
    return `0x${tx.serialize().toString('hex')}`;
}
module.exports = txData;
