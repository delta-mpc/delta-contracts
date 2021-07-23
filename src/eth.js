const Web3 = require('web3');
let connected = false;

let web3 = new Web3();

function Connect() {
    if (!connected) {
        console.log('Blockchain Connecting ...');
        connected = true
        const conf = require('./config');
        let provider = new Web3.providers.WebsocketProvider(conf.web3ProviderURL);
        provider.on('error', (e) => {
            console.error(e.reason)
        });
        provider.on('connect', () => console.log('Blockchain Connected ...'));
        provider.on('end', (e) => {
            console.error(e.reason)
        });
        web3.setProvider(provider);
    }
}

Connect()

module.exports = web3;
