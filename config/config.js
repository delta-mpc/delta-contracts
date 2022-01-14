import {default as common} from '@ethereumjs/common';

const Common = common.default
let customChain = Common.custom({chainId: 42, name: 'delta'})

const conf = {
    accounts: [
      //   {
      //       address: process.env.ADDRESS ? process.env.ADDRESS : '0x6e28858bc01946c924d3255588a7e2f727f58c7a',
      //       privateKey: process.env.PRIVATE_KEY ? process.env.PRIVATE_KEY : 'e3f9efed5e1708662faf73b55ea3f175bfb0a53dfd892dbe4e86402ec07c81d5',
      //   },
      //   {
      //       address: '0x242b7c50babbf087d4a73fe669bd0ffa1208233a',
      //       privateKey: '4c37340e31bd665979a875a211ad47905c041b3b821b67e7d416bd97fc58a8e6',
      //   }
      {
        address: "0xcae73102154059DF0cdb628413A866b15cE81cd9",
        privateKey: "1c86b422d4a23bffc9107c6818e2566395f4a8802e93a175049e6307b12c9d51"
      },
      {
         address:'0x4CeDC9148aA38cc9636ddEC16a7a0bDC3c0c756F',
         privateKey:"18755a8c9ecf090505333ea5ff5a065415bbd312ed3eb8bca571892f212eab9c"
      },
      {
         address:'0x8d734c8993C6fFfa9E2f82F56FC54241058c9061',
         privateKey:"9de403bb54cc12778070a0574e5bfd8e7a0e91a05c2a45c9d3a210ffcd11e931"
      }
    ],
    web3ProviderURL: process.env.WS_URL ? process.env.WS_URL : 'wss://node.delta.yuanben.org',
    ethOpts: {
        common: customChain
    },
    gasPrice: 1,
    gasLimit: 4294967294,
};
export default conf;
