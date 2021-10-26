import Web3 from "web3";
import conf from '../config/config.js'
let connected = false;
let web3 = new Web3();

function Connect() {
    if (!connected) {
        console.log('Blockchain Connecting ...');
        connected = true
        const options = {
            // Enable auto reconnection
            reconnect: {
                auto: true,
                delay: 5000, // ms
                maxAttempts: 5,
                onTimeout: false
            }
        };
      //   HTTP://127.0.0.1:7545
      //   conf.web3ProviderURL
        let provider = new Web3.providers.WebsocketProvider("http://127.0.0.1:7545", options);
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

export default web3;
