const GenericDB = artifacts.require('GenericDB')
const EndowmentFund = artifacts.require('EndowmentFund')
const EndowmentDB = artifacts.require('EndowmentDB')
const KFProxy = artifacts.require('KFProxy')

module.exports = async (deployer, callback) => {
    proxy = await KFProxy.deployed()
    genericDB = await GenericDB.deployed()
  	await deployer.deploy(EndowmentDB, genericDB.address)
    await deployer.deploy(EndowmentFund)

    endowmentDB = await EndowmentDB.deployed()
    endowmentFund = await EndowmentFund.deployed()
    await endowmentFund.setProxy(proxy.address)
    await endowmentDB.setProxy(proxy.address)

    await endowmentFund.initialize()
}