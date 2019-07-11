
const Betting = artifacts.require('Betting')
//const Proxy = artifacts.require('KFProxy')
//const GenericDB = artifacts.require('GenericDB')
//const GetterDB = artifacts.require('GetterDB')

const chai = require('chai')
const chaiAsPromised = require('chai-as-promised')
const assert = chai.assert
chai.use(chaiAsPromised)

//let ProxyInst
let BettingInst
//let GetterDBInst
//let GenericDBInst

const sleep = ms => new Promise(res => setTimeout(res, ms));

before(async () => {
    BettingInst = await Betting.new()
})

contract('Betting', (accounts) => {
    it('is able to set all values in the array attacksColumn', async () => {
        await BettingInst.setAttacksColumn()
        const res0 = await BettingInst.attacksColumn.call(0)
        const res1 = await BettingInst.attacksColumn.call(1)
        const res2 = await BettingInst.attacksColumn.call(2)
        const res3 = await BettingInst.attacksColumn.call(3)
        const res4 = await BettingInst.attacksColumn.call(4)
        const res5 = await BettingInst.attacksColumn.call(5)
        const res6 = await BettingInst.attacksColumn.call(6)
        assert.equal(res0, 'lowPunch')
        assert.equal(res1, 'lowKick')
        assert.equal(res2, 'lowThunder')
        assert.equal(res3, 'hardPunch')
        assert.equal(res4, 'hardKick')
        assert.equal(res5, 'hardThunder')
        assert.equal(res6, 'slash') 
    })

    it('is able to set fight map for a game with a specific gameId', async () => {
        await BettingInst.setFightMap(123, 34, 89)
        const hash0 = await BettingInst.hashes.call(0)
        const hash1 = await BettingInst.hashes.call(1)
        const hash2 = await BettingInst.hashes.call(2)
        const hash3 = await BettingInst.hashes.call(3)
        const hash4 = await BettingInst.hashes.call(4)
        const hash5 = await BettingInst.hashes.call(5)
        const hash6 = await BettingInst.hashes.call(6)
        const res0 = await BettingInst.fightMap.call(123, hash0)
        const res1 = await BettingInst.fightMap.call(123, hash1)
        const res2 = await BettingInst.fightMap.call(123, hash2)
        const res3 = await BettingInst.fightMap.call(123, hash3)
        const res4 = await BettingInst.fightMap.call(123, hash4)
        const res5 = await BettingInst.fightMap.call(123, hash5)
        const res6 = await BettingInst.fightMap.call(123, hash6)
        assert.equal(res0, 'lowPunch')
        assert.equal(res1, 'lowKick')
        assert.equal(res2, 'lowThunder')
        assert.equal(res3, 'hardPunch')
        assert.equal(res4, 'hardKick')
        assert.equal(res5, 'hardThunder')
        assert.equal(res6, 'slash')
    })

    it('is able to record the total number of direct attacks of each hitType of the given corner in a game with sepcific gameId', async () => {
        await BettingInst.setDirectAttacksScored(123, accounts[0], 1)
        await BettingInst.setDirectAttacksScored(123, accounts[0], 5)
        await BettingInst.setDirectAttacksScored(123, accounts[0], 6)
        await BettingInst.setDirectAttacksScored(123, accounts[0], 6)
        const res0 = await BettingInst.directAttacksScored.call(123, accounts[0],0)
        const res1 = await BettingInst.directAttacksScored.call(123, accounts[0], 1)
        const res2 = await BettingInst.directAttacksScored.call(123, accounts[0], 2)
        const res3 = await BettingInst.directAttacksScored.call(123, accounts[0], 3)
        const res4 = await BettingInst.directAttacksScored.call(123, accounts[0], 4)
        const res5 = await BettingInst.directAttacksScored.call(123, accounts[0], 5)
        const res6 = await BettingInst.directAttacksScored.call(123, accounts[0], 6)
        const numLowPunch = res0.toNumber()
        const numLowKick = res1.toNumber()
        const numLowThunder = res2.toNumber()
        const numHardPunch = res3.toNumber()
        const numHardKick = res4.toNumber()
        const numHardThuner = res5.toNumber()
        const numSlash = res6.toNumber()
        assert.equal(numLowPunch, 0)
        assert.equal(numLowKick, 1)
        assert.equal(numLowThunder, 0)
        assert.equal(numHardPunch, 0)
        assert.equal(numHardKick, 0)
        assert.equal(numHardThuner, 1)
        assert.equal(numSlash, 2)
        
    })

    it('is able to record the total number of blocked attacks of each hitType of the given corner in a game with sepcific gameId', async () => {
        await BettingInst.setBlockedAttacksScored(123, accounts[0], 1)
        await BettingInst.setBlockedAttacksScored(123, accounts[0], 3)
        await BettingInst.setBlockedAttacksScored(123, accounts[0], 5)
        await BettingInst.setBlockedAttacksScored(123, accounts[0], 6)
        await BettingInst.setBlockedAttacksScored(123, accounts[0], 6)
        const res0 = await BettingInst.blockedAttacksScored.call(123, accounts[0],0)
        const res1 = await BettingInst.blockedAttacksScored.call(123, accounts[0], 1)
        const res2 = await BettingInst.blockedAttacksScored.call(123, accounts[0], 2)
        const res3 = await BettingInst.blockedAttacksScored.call(123, accounts[0], 3)
        const res4 = await BettingInst.blockedAttacksScored.call(123, accounts[0], 4)
        const res5 = await BettingInst.blockedAttacksScored.call(123, accounts[0], 5)
        const res6 = await BettingInst.blockedAttacksScored.call(123, accounts[0], 6)
        const numLowPunch = res0.toNumber()
        const numLowKick = res1.toNumber()
        const numLowThunder = res2.toNumber()
        const numHardPunch = res3.toNumber()
        const numHardKick = res4.toNumber()
        const numHardThuner = res5.toNumber()
        const numSlash = res6.toNumber()
        assert.equal(numLowPunch, 0)
        assert.equal(numLowKick, 1)
        assert.equal(numLowThunder, 0)
        assert.equal(numHardPunch, 1)
        assert.equal(numHardKick, 0)
        assert.equal(numHardThuner, 1)
        assert.equal(numSlash, 2)
        
    })

    it('is able to get the total number of direct attacks of each hitType of the given corner in a game with sepcific gameId', async () => {
        const res = await BettingInst.getDirectAttacksScored(123, accounts[0])
    
        const numLowPunch = res[0].toNumber()
        const numLowKick = res[1].toNumber()
        const numLowThunder = res[2].toNumber()
        const numHardPunch = res[3].toNumber()
        const numHardKick = res[4].toNumber()
        const numHardThuner = res[5].toNumber()
        const numSlash = res[6].toNumber()
        assert.equal(numLowPunch, 0)
        assert.equal(numLowKick, 1)
        assert.equal(numLowThunder, 0)
        assert.equal(numHardPunch, 0)
        assert.equal(numHardKick, 0)
        assert.equal(numHardThuner, 1)
        assert.equal(numSlash, 2)
    })

    it('is able to get the total number of blocked attacks of each hitType of the given corner in a game with sepcific gameId', async () => {
        const res = await BettingInst.getBlockedAttacksScored(123, accounts[0])
    
        const numLowPunch = res[0].toNumber()
        const numLowKick = res[1].toNumber()
        const numLowThunder = res[2].toNumber()
        const numHardPunch = res[3].toNumber()
        const numHardKick = res[4].toNumber()
        const numHardThuner = res[5].toNumber()
        const numSlash = res[6].toNumber()
        assert.equal(numLowPunch, 0)
        assert.equal(numLowKick, 1)
        assert.equal(numLowThunder, 0)
        assert.equal(numHardPunch, 1)
        assert.equal(numHardKick, 0)
        assert.equal(numHardThuner, 1)
        assert.equal(numSlash, 2)
    })

    it('is able to record the bet amount of each individual bet of the given corner of a game with a specific gameId', async () => {
        await BettingInst.fillBets(123, accounts[0], 2)
        const res = await BettingInst.bets.call(123, accounts[0], 0)
        const bet = res.toNumber()
        assert.equal(bet, 2)
    })

    it('is able to get last 5 bet amount of the given corner of a game with a specific gameId', async () => {
        await BettingInst.fillBets(123, accounts[0], 3)
        await BettingInst.fillBets(123, accounts[0], 4)
        await BettingInst.fillBets(123, accounts[0], 5)
        await BettingInst.fillBets(123, accounts[0], 6)
        await BettingInst.fillBets(123, accounts[0], 7)
        const {lastBet1, lastBet2, lastBet3, lastBet4, lastBet5} = await BettingInst.getLastFiveBets(123, accounts[0])
        assert.equal(lastBet1.toNumber(), 3)
        assert.equal(lastBet2.toNumber(), 4)
        assert.equal(lastBet3.toNumber(), 5)
        assert.equal(lastBet4.toNumber(), 6)
        assert.equal(lastBet5.toNumber(), 7)
    })

    it('is able to record the last bet timestamp for the given corner in a game with a specific gameId', async () => {
        const now = Math.floor(new Date().getTime() / 1000)
        await BettingInst.setLastBetTimestamp(123, accounts[0], now)
        const res = await BettingInst.lastBetTimestamp.call(123, accounts[0])
        const lastBetTimeStamp = res.toNumber()
        assert.isNumber(lastBetTimeStamp)
    })

    it('randomly selects attack types from low values column bet ether amount is lower than previous bet', async () => {
        const {lastBet1, lastBet2, lastBet3, lastBet4, lastBet5} = await BettingInst.getLastFiveBets(123, accounts[0])
        const {attackType, index} = await BettingInst.getAttackType.call(123, accounts[0], 1, 308)
        const indexLowVal = index.toNumber()
        assert.oneOf(attackType, ['lowPunch', 'lowKick', 'lowThunder'])
        assert.isAtMost(indexLowVal, 2)
    })

    it('randomly selects attack types from high values column if the bet ether amount is higher than previous bet', async () => {
        const {lastBet1, lastBet2, lastBet3, lastBet4, lastBet5} = await BettingInst.getLastFiveBets(123, accounts[0])
        const {attackType, index} = await BettingInst.getAttackType.call(123, accounts[0], 9, 888)
        const indexHardVal = index.toNumber()
        assert.oneOf(attackType, ['hardPunch', 'hardKick', 'hardThunder', 'slash'])
        assert.isAtLeast(indexHardVal, 3)
    })

    it('is able to determine whether the attack type is blocked or direct', async () => {
        const now = Math.floor(new Date().getTime() / 1000)
        await BettingInst.setLastBetTimestamp(123, accounts[1], now)
        await sleep(2000);
        const isBlocked = await BettingInst.isAttackBlocked.call(123, accounts[1])
        assert.isTrue(isBlocked)
    })

    it('is able to generate a random number between 0 and 100', async () => {
        const res = await BettingInst.randomGen(398)
        const randomNumber = res.toNumber()
        assert.isAtLeast(randomNumber, 0)
        assert.isAtMost(randomNumber, 100)
    })

})

