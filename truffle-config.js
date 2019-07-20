const HDWalletProvider = require("truffle-hdwallet-provider");

const providerFactory = network =>
  new HDWalletProvider(
    process.env.MNEMONICS || "", // Mnemonics of the deployer
    `https://${network}.infura.io}` // Provider URL => web3.HttpProvider
  );

module.exports = {
  compilers: {
    solc: {
      version: "^0.5.5",
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    mainnet: {
      provider: providerFactory("mainnet"),
      network_id: 1,
      gas: 7000000,
      gasPrice: 100000000000 // 100 Gwei, Change this value according to price average of the deployment time
    },
    ropsten: {
      provider: providerFactory("ropsten"),
      network_id: 3,
      gas: 6000000,
      gasPrice: 50000000000 // 50 Gwei
    },
    rinkeby: {
      provider: providerFactory("rinkeby"),
      network_id: 4,
      gas: 6000000,
      gasPrice: 50000000000 // 50 Gwei
    },
    kovan: {
      provider: providerFactory("kovan"),
      network_id: 42,
      gas: 6000000,
      gasPrice: 50000000000 // 50 Gwei
    },
    development: {
      host: "127.0.0.1",
      port: 8544,
      network_id: 999,
      gas: 15000000
    },
    live: {
      host: "127.0.0.1",
      port: 8545,
      network_id: 1 // Ethereum public network
      // optional config values:
      // gas
      // gasPrice
      // from - default address to use for any transaction Truffle makes during migrations
      // provider - web3 provider instance Truffle should use to talk to the Ethereum network.
      //          - function that returns a web3 provider instance (see below.)
      //          - if specified, host and port are ignored.
    },
    coverage: {
      host: "localhost",
      network_id: "*",
      port: 8555, // <-- If you change this, also set the port option in .solcover.js.
      gas: 0xfffffffffff, // <-- Use this high gas value
      gasPrice: 0x01 // <-- Use this low gas price
    }
  },
  mocha: {
    enableTimeouts: false,
    useColors: true,
    reporter: "eth-gas-reporter",
    reporterOptions: {
      currency: "USD",
      gasPrice: 21
    }
  }
};
