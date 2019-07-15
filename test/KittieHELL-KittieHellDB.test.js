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
const CONTRACT_NAME_KITTIEHELL_DB = 'KittieHellDB'

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
    await KittieHellDBinst.setKittieHELL()
    await cronJob.setKittieHell(KittieHELLinst.address)
    await cronJob.setKittieHellDB(KittieHellDBinst.address)
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
        await cronJob.killKitty(10)
        await sleep(2000)
    
        try {
          await KittieHELLinst.becomeGhost(10)
        } catch (error) {
          errorMessage = error.toString()
        }
        assert.include(errorMessage, 'revert Access is only allowed from specific contract')
      })

})


contract('KittieHellDB', (accounts) => {

    it('is NOT able to add a kitty ghost to the GhostsList without through proxy', async () => {
      try {
        await KittieHellDBinst.fallToHell(1);
      } catch (error) {
        errorMessage = error.toString()
      }
      assert.include(errorMessage, 'revert Only through Proxy -- Reason given: Only through Proxy')
    })

    it('is able to add a kitty ghost to the GhostsList via proxy', async () => {
      let arg1 = 1
        let message1 = web3.eth.abi.encodeFunctionCall(
          KittieHellDB.abi.find((f) => { return f.name == 'fallToHell' }), 
          [arg1]
        )
      await ProxyInst.execute(CONTRACT_NAME_KITTIEHELL_DB, message1)
      const ghost1 = await KittieHellDBinst.doesGhostExist(1)
      assert.isTrue(ghost1)
    })

    it('should display the size of the GhostsList', async () => {
      const res = await KittieHellDBinst.getGhostsListSize()
      const listSize = res.toNumber()
      assert.equal(listSize, 1)
    })

    it('tells whether a kitty ghost exist in hell or not', async () => {
      const ghost = await KittieHellDBinst.doesGhostExist(1)
      assert.isTrue(ghost)
    })

    it('is able to get the status of a kitty from KittieHELL contract', async () => {
      await cryptoKitties.mint(accounts[0], 456)
      await cryptoKitties.approve(KittieHELLinst.address, 456)
      await KittieHELLinst.acquireKitty(456, accounts[0])
      await cronJob.killKitty(456)
      await sleep(2000)
      await cronJob.becomeGhost(456)
      const kittieStatus = await KittieHellDBinst.getKittieStatus.call(456)
      const kittieOwner = kittieStatus[0]
      const kittieDead = kittieStatus[1]
      const kittiePlaying = kittieStatus[2]
      const kittieGhost = kittieStatus[3]
      const kittieDeathTime = kittieStatus[4].toNumber()
      assert.equal(kittieOwner, accounts[0])
      assert.isTrue(kittieDead)
      assert.isFalse(kittiePlaying)
      assert.isTrue(kittieGhost)
      assert.isAtLeast(kittieDeathTime, 1554474000)
    })

    it('is NOT able to set the attributes of a kitty ghost without through proxy', async () => {
      try {
        await KittieHellDBinst.setKittieAttributes(1, 456)
      } catch (error) {
        errorMessage = error.toString()
      }
      assert.include(errorMessage, 'revert Only through Proxy -- Reason given: Only through Proxy')
    })

    it('is able to set the attributes of a kitty ghost via proxy', async () => {
      let argument1 = 1
      let argument2 = 456
      let messageSetAttributes = web3.eth.abi.encodeFunctionCall(
        KittieHellDB.abi.find((f) => { return f.name == 'setKittieAttributes' }), 
        [argument1, argument2]
      )
      await ProxyInst.execute(CONTRACT_NAME_KITTIEHELL_DB, messageSetAttributes)
      const ghost1Atrritubtes = await KittieHellDBinst.getKittieAttributes(1)
      const ghost1KittieID = ghost1Atrritubtes[0].toNumber()
      const ghost1Owner = ghost1Atrritubtes[1]
      const ghost1Dead = ghost1Atrritubtes[2]
      const ghost1Playing = ghost1Atrritubtes[3]
      const ghost1Ghost = ghost1Atrritubtes[4]
      const ghost1DeathTime = ghost1Atrritubtes[5].toNumber()
      assert.equal(ghost1KittieID, 456)
      assert.equal(ghost1Owner, accounts[0])
      assert.isTrue(ghost1Dead)
      assert.isFalse(ghost1Playing)
      assert.isTrue(ghost1Ghost)
      assert.isAtLeast(ghost1DeathTime, 1554474000)
    })

    it('is able to show the adjacent kitty ghost', async () => {
      let arg2 = 2
        let message2 = web3.eth.abi.encodeFunctionCall(
          KittieHellDB.abi.find((f) => { return f.name == 'fallToHell' }), 
          [arg2]
        )
      await ProxyInst.execute(CONTRACT_NAME_KITTIEHELL_DB, message2)
      const ajacentGhost = await KittieHellDBinst.getAdjacentGhost(1)
      assert.equal(ajacentGhost[1].toNumber(), 2)
    })

    it('is NOT able to remove a kitty ghost from GhostsList without through CronJob', async () => {
      try {
        await KittieHellDBinst.removeGhostFromHell(2)
      } catch (error) {
        errorMessage = error.toString()
      }
      assert.include(errorMessage, 'revert Access is only allowed from specific contract')
    })

    it('is able to remove a kitty ghost from GhostsList via CronJob', async () => {
      const ghost2Before = await KittieHellDBinst.doesGhostExist(2)
      assert.isTrue(ghost2Before)
      await cronJob.removeGhostFromHell(2)
      const ghost2After = await KittieHellDBinst.doesGhostExist(2)
      assert.isFalse(ghost2After)
    })
  
})