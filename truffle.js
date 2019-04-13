module.exports = {
    compilers: {
      solc: {
        version: '^0.5.5'
      }
    },
    networks: {
        development: {
            host: "127.0.0.1",
            port: 8544,
            network_id: 999,
            gas: 2000000
        },
        live: {
            host: "127.0.0.1",
            port: 8545,
            network_id: 1        // Ethereum public network
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
            port: 8555,         // <-- If you change this, also set the port option in .solcover.js.
            gas: 0xfffffffffff, // <-- Use this high gas value
            gasPrice: 0x01      // <-- Use this low gas price
        }
    }
};
