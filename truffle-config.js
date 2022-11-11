require("dotenv").config()
const HDWalletProvider = require("@truffle/hdwallet-provider");

const DELTA_PKEY = process.env.DELTA_PKEY || "";
const DELTA_ADDR = process.env.DELTA_ADDR || "";

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*", // Match any network id
    },
    delta: {
      provider: () => {
        return new HDWalletProvider(DELTA_PKEY, "ws://127.0.0.1:9933")
      },
      from: DELTA_ADDR,
      network_id: "42",
    }
  },
  compilers: {
    solc: {
      version: "0.8.13", // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      settings: {
        // See the solidity docs for advice about optimization and evmVersion
        optimizer: {
          enabled: true,
          runs: 200,
        },
        // evmVersion: "byzantium",
      },
    },
  },
};
