
const chai = require('chai');
const chaiAsPromised = require('chai-as-promised');
const assert = chai.assert;
chai.use(chaiAsPromised);

const Proxy = artifacts.require('KFProxy')
const HitsResolve = artifacts.require('HitsResolve')
const Betting = artifacts.require('Betting')

let ProxyInst
let HitsResolveInst
let BettingInst

before(async () => {
    ProxyInst = await Proxy.new()
    HitsResolveInst = await HitsResolve.new()
    BettingInst = await Betting.new()

    await ProxyInst.addContract("HitsResolve", HitsResolveInst.address)
    await ProxyInst.addContract("Betting", BettingInst.address)
  
    await BettingInst.setProxy(ProxyInst.address)
    await HitsResolveInst.setProxy(ProxyInst.address)
  
    await HitsResolveInst.initialize()

})

contract('HitsResolve', (accounts) => {

    it('is able to generate a random number between 0 and 99', async () => {
        const res = await HitsResolveInst.randomGen(298)
        const randomNumber = res.toNumber()
        assert.isAtLeast(randomNumber, 0)
        assert.isAtMost(randomNumber, 99)
    })

  it('is able to generate a random number between 0 and 1', async () => {
    const res = await HitsResolveInst.multiBlockRandomGen(899, 1)
    const randomN = res.toNumber()
    assert.isAtLeast(randomN, 0)
    assert.isAtMost(randomN, 1)
})

it('is able to calculate the most current random variable', async () => {
  const res = await HitsResolveInst.calculateCurrentRandom.call(1, 88)
  const mostCurrentRandom = res.toNumber()
  assert.isNumber(mostCurrentRandom)
})

it('maintains a mapping of Game ID to random seed input combination,', async () => {
  await HitsResolveInst.calculateCurrentRandom(2, 35)
  await HitsResolveInst.calculateCurrentRandom(16, 902)
  const res2 = await HitsResolveInst.currentRandom.call(2)
  const mostCurrentRandomNumber2 = res2.toNumber()
  assert.isNumber(mostCurrentRandomNumber2)
  const res16 = await HitsResolveInst.currentRandom.call(16)
  const mostCurrentRandomNumber16 = res16.toNumber()
  assert.isNumber(mostCurrentRandomNumber16)
})

/*
it('assigns value to Low Punch, Low Kick and Low Thunder,', async () => {
  await HitsResolveInst.calculateCurrentRandom(16, 902)
  const res = await HitsResolveInst.assignLowValues.call(16, 799) 
  const lowPunch = res[0].toNumber()
  const lowKick = res[1].toNumber()
  const lowThunder = res[2].toNumber()
  assert.isAtLeast(lowPunch, 1)
  assert.isAtMost(lowPunch, 100)
  assert.isAtLeast(lowKick, 101)
  assert.isAtMost(lowKick, 200)
  assert.isAtLeast(lowThunder, 201)
  assert.isAtMost(lowThunder, 300)
}) */

it('assigns value to Low Punch, Low Kick and Low Thunder - updated version,', async () => {
  await HitsResolveInst.calculateCurrentRandom(21, 812)
  const res = await HitsResolveInst.assignLowValues.call(21, 799) 
  const lowPunch = res[0].toNumber()
  const lowKick = res[1].toNumber()
  const lowThunder = res[2].toNumber()
  console.log(lowPunch)
  console.log(lowKick)
  console.log(lowThunder)
  assert.isAtLeast(lowPunch, 1)
  assert.isAtMost(lowPunch, 300)
  assert.isAtLeast(lowKick, 1)
  assert.isAtMost(lowKick, 300)
  assert.isAtLeast(lowThunder, 1)
  assert.isAtMost(lowThunder, 300)
})

it('assigns value to Hard Punch, Hard Kick and Hard Thunder - updated version,', async () => {
  await HitsResolveInst.calculateCurrentRandom(20, 890)
  const res = await HitsResolveInst.assignHighValues.call(20, 799) 
  const hardPunch = res[0].toNumber()
  const hardKick = res[1].toNumber()
  const hardThunder = res[2].toNumber()
  assert.isAtLeast(hardPunch, 301)
  assert.isAtMost(hardPunch, 600)
  assert.isAtLeast(hardKick, 301)
  assert.isAtMost(hardKick, 600)
  assert.isAtLeast(hardThunder, 301)
  assert.isAtMost(hardThunder, 600)
})

it('assigns value to slash,', async () => {
  await HitsResolveInst.calculateCurrentRandom(30, 1290)
  const res = await HitsResolveInst.assignSlashValue.call(30, 3298) 
  assert.isNumber(res.toNumber())
})

it('calculates list of 7 values to determine final values of attacks in Betting module,', async () => {
  await HitsResolveInst.calculateCurrentRandom(95, 4390)
  const res = await HitsResolveInst.finalizeHitTypeValues.call(95, 213) 
  const lowPunch = res[0].toNumber()
  const lowKick = res[1].toNumber()
  const lowThunder = res[2].toNumber()
  const hardPunch = res[3].toNumber()
  const hardKick = res[4].toNumber()
  const hardThunder = res[5].toNumber()
  const slash = res[6].toNumber()
  assert.isAtLeast(lowPunch, 1)
  assert.isAtMost(lowPunch, 300)
  assert.isAtLeast(lowKick, 1)
  assert.isAtMost(lowKick, 300)
  assert.isAtLeast(lowThunder, 1)
  assert.isAtMost(lowThunder, 300)
  assert.isAtLeast(hardPunch, 301)
  assert.isAtMost(hardPunch, 600)
  assert.isAtLeast(hardKick, 301)
  assert.isAtMost(hardKick, 600)
  assert.isAtLeast(hardThunder, 301)
  assert.isAtMost(hardThunder, 600)
  assert.isNumber(slash)
})

it('calculates the final points for the given corner,', async () => {
  await BettingInst.setDirectAttacksScored(58, accounts[0], 1)
  await BettingInst.setDirectAttacksScored(58, accounts[0], 2)
  await BettingInst.setDirectAttacksScored(58, accounts[0], 3)
  await BettingInst.setDirectAttacksScored(58, accounts[0], 4)
  await BettingInst.setDirectAttacksScored(58, accounts[0], 5)
  await BettingInst.setDirectAttacksScored(58, accounts[0], 6)
  await BettingInst.setDirectAttacksScored(58, accounts[0], 0)
  await BettingInst.setDirectAttacksScored(58, accounts[0], 5)
  await BettingInst.setDirectAttacksScored(58, accounts[0], 3)

  await BettingInst.setBlockedAttacksScored(58, accounts[0], 1)
  await BettingInst.setBlockedAttacksScored(58, accounts[0], 2)
  await BettingInst.setBlockedAttacksScored(58, accounts[0], 3)
  await BettingInst.setBlockedAttacksScored(58, accounts[0], 4)
  await BettingInst.setBlockedAttacksScored(58, accounts[0], 5)
  await BettingInst.setBlockedAttacksScored(58, accounts[0], 6)
  await BettingInst.setBlockedAttacksScored(58, accounts[0], 1)
  await BettingInst.setBlockedAttacksScored(58, accounts[0], 0)
  await BettingInst.setBlockedAttacksScored(58, accounts[0], 6)
  await BettingInst.setBlockedAttacksScored(58, accounts[0], 1)
  await BettingInst.setBlockedAttacksScored(58, accounts[0], 2)

  await HitsResolveInst.calculateCurrentRandom(58, 267)
  await HitsResolveInst.finalizeHitTypeValues.call(58, 603) 
  const finalPointsBN = await HitsResolveInst.calculateFinalPoints(58, accounts[0], 932)
  const finalPoints = finalPointsBN.toNumber()
  console.log(finalPoints)
  assert.exists(finalPoints)
  assert.isNumber(finalPoints)
})

})

