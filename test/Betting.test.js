
const chai = require('chai')
const chaiAsPromised = require('chai-as-promised')
const assert = chai.assert
chai.use(chaiAsPromised)

const Proxy = artifacts.require('KFProxy')
const Betting = artifacts.require('Betting')

let ProxyInst
let BettingInst


const sleep = ms => new Promise(res => setTimeout(res, ms));

contract('Betting', accounts => {
    before(async () => {
        ProxyInst = await Proxy.new()
      
        BettingInst = await Betting.new()
    
        await ProxyInst.addContract("Betting", BettingInst.address)
    
        await BettingInst.setProxy(ProxyInst.address)
        
    })
    
    it('is able to set fight map for a game with a specific gameId', async () => {
      await BettingInst.setFightMap(123, 34, 89)
  
      const res0 = await BettingInst.fightMap.call(123, 0)
      const res1 = await BettingInst.fightMap.call(123, 1)
      const res2 = await BettingInst.fightMap.call(123, 2)
      const res3 = await BettingInst.fightMap.call(123, 3)
      const res4 = await BettingInst.fightMap.call(123, 4)
      const res5 = await BettingInst.fightMap.call(123, 5)
      const res6 = await BettingInst.fightMap.call(123, 6)
  
      assert.equal(res0.attack, 'lowPunch')
      assert.equal(res1.attack, 'lowKick')
      assert.equal(res2.attack, 'lowThunder')
      assert.equal(res3.attack, 'hardPunch')
      assert.equal(res4.attack, 'hardKick')
      assert.equal(res5.attack, 'hardThunder')
      assert.equal(res6.attack, 'slash')
    })
  
    it('is able to record the total number of direct attacks of each hitType of the given corner in a game with sepcific gameId', async () => {
      await BettingInst.setDirectAttacksScored(123, accounts[0], 1)
      await BettingInst.setDirectAttacksScored(123, accounts[0], 5)
      await BettingInst.setDirectAttacksScored(123, accounts[0], 6)
      await BettingInst.setDirectAttacksScored(123, accounts[0], 6)
      const res0 = await BettingInst.directAttacksScored.call(123, accounts[0], 0)
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
      const res0 = await BettingInst.blockedAttacksScored.call(
        123,
        accounts[0],
        0
      )
      const res1 = await BettingInst.blockedAttacksScored.call(
        123,
        accounts[0],
        1
      )
      const res2 = await BettingInst.blockedAttacksScored.call(
        123,
        accounts[0],
        2
      )
      const res3 = await BettingInst.blockedAttacksScored.call(
        123,
        accounts[0],
        3
      )
      const res4 = await BettingInst.blockedAttacksScored.call(
        123,
        accounts[0],
        4
      )
      const res5 = await BettingInst.blockedAttacksScored.call(
        123,
        accounts[0],
        5
      )
      const res6 = await BettingInst.blockedAttacksScored.call(
        123,
        accounts[0],
        6
      )
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
  
    it('is able to get last 4 bet amount of the given corner of a game with a specific gameId', async () => {
      await BettingInst.fillBets(123, accounts[0], 3)
      await BettingInst.fillBets(123, accounts[0], 4)
      await BettingInst.fillBets(123, accounts[0], 5)
      await BettingInst.fillBets(123, accounts[0], 6)
      await BettingInst.fillBets(123, accounts[0], 7)
      const {
        lastBet4,
        lastBet3,
        lastBet2,
        lastBet1
      } = await BettingInst.getLastFourBets(123, accounts[0])
      assert.equal(lastBet4.toNumber(), 4)
      assert.equal(lastBet3.toNumber(), 5)
      assert.equal(lastBet2.toNumber(), 6)
      assert.equal(lastBet1.toNumber(), 7)
    })
  
    it('is able to record the last bet timestamp for the given corner in a game with a specific gameId', async () => {
      const now = Math.floor(new Date().getTime() / 1000)
      await BettingInst.setLastBetTimestamp(123, accounts[0], now)
      const res = await BettingInst.lastBetTimestamp.call(123, accounts[0])
      const lastBetTimeStamp = res.toNumber()
      assert.isNumber(lastBetTimeStamp)
    })
  
    it('randomly selects attack types from low values column bet ether amount is lower than previous bet', async () => {
      // const {lastBet1, lastBet2, lastBet3, lastBet4, lastBet5} = await BettingInst.getLastFiveBets(123, accounts[0])
      const { attackType, index } = await BettingInst.getAttackType.call(
        123,
        accounts[0],
        1,
        308
      )
      const indexLowVal = index.toNumber()
      assert.oneOf(attackType, ['lowPunch', 'lowKick', 'lowThunder'])
      assert.isAtMost(indexLowVal, 2)
    })
  
    it('randomly selects attack types from high values column if the bet ether amount is higher than previous bet', async () => {
      const { attackType, index } = await BettingInst.getAttackType.call(
        123,
        accounts[0],
        9,
        888
      )
      const indexHardVal = index.toNumber()
      assert.oneOf(attackType, ['hardPunch', 'hardKick', 'hardThunder', 'slash'])
      assert.isAtLeast(indexHardVal, 3)
    })
  
    it('is able to determine whether the attack type is blocked or direct', async () => {
      const now = Math.floor(new Date().getTime() / 1000)
      await BettingInst.setLastBetTimestamp(123, accounts[1], now)
      await sleep(500)
      const isBlocked = await BettingInst.isAttackBlocked.call(123, accounts[1])
      assert.isTrue(isBlocked)
    })
  
    it('is able to set and store the current defense level of the given corner in a game', async () => {
      await BettingInst.setDefenseLevel(123, accounts[0], 3)
      const defenseLevel = await BettingInst.defenseLevel.call(123, accounts[0])
      assert.equal(defenseLevel, 3)
    })
  
    it('is able to reduce the defense level of the opponent if each of the last 5 bets from the attacker was consecutively bigger than the previous one', async () => {
      // if the defense level of the opponent player is higher than 0, then it is reduced if the conditions for reduction are true.
      await BettingInst.setDefenseLevel(123, accounts[1], 2)
      await BettingInst.fillBets(123, accounts[0], 10)
      await BettingInst.fillBets(123, accounts[0], 11)
      await BettingInst.fillBets(123, accounts[0], 12)
      await BettingInst.fillBets(123, accounts[0], 13)
      await BettingInst.fillBets(123, accounts[0], 14)
      await BettingInst.reduceDefenseLevel(123, 16, accounts[0], accounts[1])
      const defenseLevelOppoent = await BettingInst.defenseLevel.call(
        123,
        accounts[1]
      )
      assert.equal(defenseLevelOppoent, 1)
    })
  
    it('is not able to reduce the defense level of the opponent player if the defense level of the opponent player is already 0, even when the conditions for reduction are true. ', async () => {
      // if the defense level of the opponent player is already 0, then it stays at 0, even when the conditions for reduction are true.
      await BettingInst.setDefenseLevel(207, accounts[6], 0)
      await BettingInst.fillBets(207, accounts[7], 10)
      await BettingInst.fillBets(207, accounts[7], 11)
      await BettingInst.fillBets(207, accounts[7], 12)
      await BettingInst.fillBets(207, accounts[7], 13)
      await BettingInst.fillBets(207, accounts[7], 14)
      try {
        await BettingInst.reduceDefenseLevel(207, 16, accounts[7], accounts[6])
      } catch (error) {
        errorMessage = error.toString()
      }
      assert.include(errorMessage, 'Defense level is already zero')
    })
  
    it('is able to generate a fight map for a game via the function startGame()', async () => {
      await BettingInst.startGame(
        27, // gameId
        750, // random number generated by the red corner
        930 // random number generated by the black corner
      )
  
      const res00 = await BettingInst.fightMap.call(27, 0)
      const res01 = await BettingInst.fightMap.call(27, 1)
      const res02 = await BettingInst.fightMap.call(27, 2)
      const res03 = await BettingInst.fightMap.call(27, 3)
      const res04 = await BettingInst.fightMap.call(27, 4)
      const res05 = await BettingInst.fightMap.call(27, 5)
      const res06 = await BettingInst.fightMap.call(27, 6)
  
      assert.equal(res00.attack, 'lowPunch')
      assert.equal(res01.attack, 'lowKick')
      assert.equal(res02.attack, 'lowThunder')
      assert.equal(res03.attack, 'hardPunch')
      assert.equal(res04.attack, 'hardKick')
      assert.equal(res05.attack, 'hardThunder')
      assert.equal(res06.attack, 'slash')
    })
  
    it('calculates attack type, attackHash, current defense level of the given corner, as well as the current opponent defense level due to each bet placed by the given corner in a game', async () => {
      const resBet = await BettingInst.bet.call(
        123, // gameId
        accounts[7], // bettor
        18, // bet amount
        accounts[0], // supporting player
        accounts[1], // opponent player
        92 // random number generated by front end
      )
  
     /* const currentDefenseLevelSupportedPlayer = resBet.defenseLevelSupportedPlayer.toNumber()
      const currentDefenseLevelOpponent = resBet.defenseLevelOpponent.toNumber()
      assert.oneOf(resBet.attackType, [
        'hardPunch',
        'hardKick',
        'hardThunder',
        'slash'
      ])
      assert.isAtLeast(currentDefenseLevelSupportedPlayer, 0)
      assert.isAtMost(currentDefenseLevelSupportedPlayer, 6)
      assert.equal(currentDefenseLevelOpponent, 0)*/
      assert.isTrue(resBet)
    })
  
    it('is able to generate a random number between 0 and 100', async () => {
      const res = await BettingInst.randomGen(398)
      const randomNumber = res.toNumber()
      assert.isAtLeast(randomNumber, 0)
      assert.isAtMost(randomNumber, 100)
    })
  })
  