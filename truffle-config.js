const HDWalletProvider = require('truffle-hdwallet-provider');


const providerFactory = network => new HDWalletProvider(
  process.env.MNEMONICS || '',     // Mnemonics of the deployer
  `https://${network}.infura.io}`  // Provider URL => web3.HttpProvider
);


module.exports = {
  compilers: {
    solc: {
      version: '^0.5.5'
    }
  },
  networks: {
    'mainnet': {
      provider: providerFactory('mainnet'),
      network_id: 1,
      gas: 7000000,
      gasPrice: 100000000000 // 100 Gwei, Change this value according to price average of the deployment time
    },
    'ropsten': {
      provider: providerFactory('ropsten'),
      network_id: 3,
      gas: 6000000,
      gasPrice: 50000000000 // 50 Gwei
    },
    'rinkeby': {
      provider: providerFactory('rinkeby'),
      network_id: 4,
      gas: 6000000,
      gasPrice: 50000000000 // 50 Gwei
    },
    'kovan': {
      provider: providerFactory('kovan'),
      network_id: 42,
      gas: 6000000,
      gasPrice: 50000000000  // 50 Gwei
    }
  },
  mocha: {
    useColors: true,
    reporter: 'eth-gas-reporter',
    reporterOptions : {
      currency: 'USD',
      gasPrice: 21
    }
  }
};