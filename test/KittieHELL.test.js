const utils = require('./utils/utils.js')
const chai = require('chai')
const chaiAsPromised = require('chai-as-promised')
const assert = chai.assert
chai.use(chaiAsPromised)


const Proxy = artifacts.require('KFProxy')
const KittieHELL = artifacts.require('KittieHELL')
const KittieFightToken = artifacts.require('MockERC20Token')
const CryptoKitties = artifacts.require('MockERC721Token')
const CronJob = artifacts.require('CronJob')
const GenericDB = artifacts.require('GenericDB')
const GameVarAndFee = artifacts.require('GameVarAndFee')
const EndowmentFund = artifacts.require('EndowmentFund')
const KittieHellDB = artifacts.require('KittieHellDB')

const CONTRACT_NAME_KITTIEHELL = 'KittieHell'

const sleep = ms => new Promise(res => setTimeout(res, ms));

let ProxyInst
let KittieHELLinst
let kittieFightToken
let cronJob
let GenericDBinst
let cryptoKitties
let gameVarAndFee
let EndowmentFundInst 
let KittieHellDBinst


before(async () => {
    ProxyInst = await Proxy.new()
    kittieFightToken = await KittieFightToken.new(10000000000)
    cryptoKitties = await CryptoKitties.new()
    cronJob = await CronJob.new()
    GenericDBinst = await GenericDB.new()
    gameVarAndFee = await GameVarAndFee.new(GenericDBinst.address)
    KittieHELLinst = await KittieHELL.new()
    EndowmentFundInst = await EndowmentFund.new()
    KittieHellDBinst= await KittieHellDB.new(GenericDBinst.address)

    await ProxyInst.addContract('KittieHell', KittieHELLinst.address)
    await ProxyInst.addContract('KittieFightToken', kittieFightToken.address)
    await ProxyInst.addContract('CryptoKitties', cryptoKitties.address)
    await ProxyInst.addContract('CronJob', cronJob.address)
    await ProxyInst.addContract('GenericDB', GenericDBinst.address)
    await ProxyInst.addContract('GameVarAndFee', gameVarAndFee.address)
    await ProxyInst.addContract('EndowmentFund', EndowmentFundInst.address)
    await ProxyInst.addContract('KittieHellDB', KittieHellDBinst.address)
    
    await KittieHELLinst.setProxy(ProxyInst.address)
    await GenericDBinst.setProxy(ProxyInst.address)
    await cronJob.setProxy(ProxyInst.address)
    await gameVarAndFee.setProxy(ProxyInst.address)
    await EndowmentFundInst.setProxy(ProxyInst.address)
    await KittieHellDBinst.setProxy(ProxyInst.address)

    await KittieHELLinst.initialize()

    await cronJob.setKittieHell(KittieHELLinst.address)
})

contract('KittieHELL', (accounts) => {

     it('is able to acquire a kitty', async () => {
        await cryptoKitties.mint(accounts[0], 123)
        const ownerOfBefore = await cryptoKitties.ownerOf(123)
        await cryptoKitties.approve(KittieHELLinst.address, 123)
        await KittieHELLinst.acquireKitty(123, accounts[0])
        const ownerOfAfter = await cryptoKitties.ownerOf(123)
        assert.equal(ownerOfBefore, accounts[0])
        assert.equal(ownerOfAfter, KittieHELLinst.address)
      })

      it('is able to tell whether a kitty is dead or not', async () => {
        const isKittyDead = await KittieHELLinst.isKittyDead(123)
        assert.isFalse(isKittyDead)
      })

      it('is able to kill a kitty only via CronJob', async () => {
        await cronJob.killKitty(123)
        const kitty123 = await KittieHELLinst.kitties.call(123)
        assert.isTrue(kitty123.dead)
      })

      it('is not able to kill a kitty without through CronJob', async () => {
        let errorMessage
    
        await cryptoKitties.mint(accounts[0], 220)
        await cryptoKitties.approve(KittieHELLinst.address, 220)
        await KittieHELLinst.acquireKitty(220, accounts[0])
    
        try {
          await KittieHELLinst.killKitty(220)
        } catch (error) {
          errorMessage = error.toString()
        }
    
        assert.include(errorMessage, 'revert Access is only allowed from specific contract')
      })

      it('is able to tell the time and date when a kitty was dead, if the kitty was dead', async () => {
        const deadTime = await KittieHELLinst.kittyDeathTime(123)
        assert.isAtLeast(deadTime.toNumber(), 1554474000)
      })

      it('is able to display the resurrection cost for a dead kitty', async () => {
        await sleep(1000)
        const ressrectionCost = await KittieHELLinst.getResurrectionCost(123)
        const kittieRessrectionCost = ressrectionCost.toNumber()
        assert.isAtLeast(kittieRessrectionCost, 100000000)
      })

      it('is able to release a kitty back to its owner via CronJob', async () => {
        await cronJob.releaseKitty(220)
        assert.eventually.equal(cryptoKitties.ownerOf(220), accounts[0])
      })

      it('is not able to release a kitty back to its owner without through CronJob', async () => {
        let errorMessage
        await cryptoKitties.mint(accounts[0], 6)
        await cryptoKitties.approve(KittieHELLinst.address, 6)
        await KittieHELLinst.acquireKitty(6, accounts[0])
        assert.eventually.notEqual(cryptoKitties.ownerOf(6), accounts[0])
    
        try {
          await KittieHELLinst.releaseKitty(6)
        } catch (error) {
          errorMessage = error.toString()
        }
    
        assert.include(errorMessage, 'revert Access is only allowed from specific contract')
      })

      it('is able to resurrect a dead kittie via proxy', async () => {
        await cryptoKitties.mint(accounts[0], 7)
        await cryptoKitties.approve(KittieHELLinst.address, 7)
        await KittieHELLinst.acquireKitty(7, accounts[0])
        await cronJob.killKitty(7)
        await sleep(1000)
        await kittieFightToken.approve(KittieHELLinst.address, 1000000000)
        let arg = 7
        let message = web3.eth.abi.encodeFunctionCall(
          KittieHELL.abi.find((f) => { return f.name == 'payForResurrection' }), 
          [arg]
        )
        await ProxyInst.execute(CONTRACT_NAME_KITTIEHELL, message)
      
        // verify that the right amount of kittieFightTokens have gone to EndowmentFund
        const ownerToken = await kittieFightToken.balanceOf(accounts[0])
        const kittieFightTokenByOwner = ownerToken.toNumber()
        const kittieHellToken = await kittieFightToken.balanceOf(KittieHELLinst.address)
        const kittieFightTokenByKittieHELL = kittieHellToken.toNumber()
        const endowmentToken = await kittieFightToken.balanceOf(EndowmentFundInst.address)
        const kittieFightTokenByEndowmentFund = endowmentToken.toNumber()
        assert.isAtMost(kittieFightTokenByOwner, 9900000000)
        assert.equal(kittieFightTokenByKittieHELL, 0)
        assert.isAtLeast(kittieFightTokenByEndowmentFund, 100000000)
        // verify the kittie goes back to its owner
        assert.eventually.equal(cryptoKitties.ownerOf(7), accounts[0])
      })

      it('is not able to resurrect a dead kittie without through proxy', async () => {
        let errorMessage
        await cryptoKitties.mint(accounts[0], 8)
        await cryptoKitties.approve(KittieHELLinst.address, 8)
        await KittieHELLinst.acquireKitty(8, accounts[0])
        await cronJob.killKitty(8)
        await sleep(1000)
    
        try {
          await KittieHELLinst.payForResurrection(8)
        } catch (error) {
          errorMessage = error.toString()
        }
        assert.include(errorMessage, 'revert Only through Proxy -- Reason given: Only through Proxy')
      })

      it('is able to make a dead kitty ghost and send the kitty ghost to KittieHellDB via CronJob', async () => {
        await cryptoKitties.mint(accounts[0], 9)
        await cryptoKitties.approve(KittieHELLinst.address, 9)
        await KittieHELLinst.acquireKitty(9, accounts[0])
        await cronJob.killKitty(9);
        await sleep(2000);
        await cronJob.becomeGhost(9);
        const ownerOfKittyGhost = await cryptoKitties.ownerOf(9);
        assert.equal(ownerOfKittyGhost, KittieHellDBinst.address);
      })

      it('can neither make a dead kitty ghost nor send the kitty ghost to KittieHellDB without through CronJob', async () => {
        await cryptoKitties.mint(accounts[0], 10)
        await cryptoKitties.approve(KittieHELLinst.address, 10)
        await KittieHELLinst.acquireKitty(10, accounts[0])
        await cronJob.killKitty(10);
        await sleep(2000);
    
        try {
          await KittieHELLinst.becomeGhost(10);
        } catch (error) {
          errorMessage = error.toString();
        }
        assert.include(errorMessage, 'revert Access is only allowed from specific contract');
      })

})