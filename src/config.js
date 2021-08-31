import {default as common} from '@ethereumjs/common';

const Common = common.default
let customChain = Common.custom({chainId: 42, name: 'delta'})

const conf = {
    accounts: [
        {
            address: '0x6e28858bc01946c924d3255588a7e2f727f58c7a',
            privateKey: 'e3f9efed5e1708662faf73b55ea3f175bfb0a53dfd892dbe4e86402ec07c81d5',
        },
        {
            address: '0x242b7c50babbf087d4a73fe669bd0ffa1208233a',
            privateKey: '4c37340e31bd665979a875a211ad47905c041b3b821b67e7d416bd97fc58a8e6',
        }
    ],
    web3ProviderURL: 'wss://node.delta.yuanben.org',
    ethOpts: {
        common: customChain
    },
    gasPrice: 1,
    gasLimit: 4294967294,
};
export default conf;
