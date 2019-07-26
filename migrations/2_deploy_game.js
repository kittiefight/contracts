const RarityCalculator = artifacts.require('RarityCalculator')

module.exports = (deployer, network, accounts) => {
  deployer.deploy(RarityCalculator, {from: accounts[0]})
};
