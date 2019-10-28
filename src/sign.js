const ecdsa = require('secp256k1');
const web3 = require('./eth');
function sign(address, amount, nonce, privKey) {
    let msg = web3.utils.soliditySha3({t: 'address', v: address},
        {t: 'uint256', v: amount}, {t: 'string', v: nonce});
    let digest = new Buffer.from(msg.substring(2), 'hex');
    const key = new Buffer.from(privKey, 'hex');
    const sig = ecdsa.sign(digest, key);
    let sigStr = sig.signature.toString('hex');
    if (sig.recovery === 1) {
        sigStr += "01"
    }
    if (sig.recovery === 0) {
        sigStr += "00"
    }
    return sigStr;
}
module.exports = sign;
