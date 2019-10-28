const Tx = require('ethereumjs-tx').Transaction;
const conf = require('./config');
const key = new Buffer.from(conf.privateKey, 'hex');
const web3 = require('./eth');
async function txData(data, toAddress='', nonce=0) {
    if (nonce === 0) {
        nonce = await web3.eth.getTransactionCount(conf.account);
    }
    const nonceHex = web3.utils.toHex(nonce);
    let tra = {
        nonce: nonceHex,
        gasPrice: conf.gasPrice,
        gasLimit: conf.gasLimit,
        data: data,
        from: conf.account,
    };
    if (toAddress !== '') {
        tra['to'] = toAddress
    }
    const tx = new Tx(tra, conf.ethOpts);
    tx.sign(key);
    return `0x${tx.serialize().toString('hex')}`;
}
module.exports = txData;
