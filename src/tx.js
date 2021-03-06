import conf from '../config/config.js'
import web3 from './eth.js'
import pkg from '@ethereumjs/tx';
const {TransactionFactory} = pkg;

async function txData(data, toAddress = '', nonce = 0, opt = null) {
    let key = new Buffer.from(conf.accounts[0].privateKey, 'hex');
    let tra = {
        gasPrice: '0x' + conf.gasPrice.toString(16),
        gasLimit: '0x' + conf.gasLimit.toString(16),
        data: data,
        from: conf.accounts[0].address,
    };
    if (opt !== null) {
        if (opt.hasOwnProperty('gasLimit')) {
            tra.gasLimit = '0x' + opt.gasLimit.toString(16);
        }
        if (opt.hasOwnProperty('gasPrice')) {
            tra.gasPrice = '0x' + opt.gasPrice.toString(16)
        }
        if (opt.hasOwnProperty('from')) {
            for (let account of conf.accounts) {
                if (account.address === opt.from) {
                    tra.from = opt.from;
                    key = new Buffer.from(account.privateKey, 'hex');
                    break
                }
            }
            if (tra.from !== opt.from) {
                console.log('地址', opt.from, '不存在');
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
    let tx = TransactionFactory.fromTxData(tra, conf.ethOpts);
    return `0x${tx.sign(key).serialize().toString('hex')}`;
}

export default txData;
