
const BigNumber = web3.utils.BN;
require('chai')
  .use(require('chai-shallow-deep-equal'))
  .use(require('chai-bignumber')(BigNumber))
  .use(require('chai-as-promised'))
  .should();

const jKFProxy = require("../build/contracts/KFProxy.json");
const jGenericDB = require("../build/contracts/GenericDB.json");
const jProfileDB = require("../build/contracts/ProfileDB.json");
const jRoleDB = require("../build/contracts/RoleDB.json");
const jGMSetterDB = require("../build/contracts/GMSetterDB.json");
const jGMGetterDB = require("../build/contracts/GMGetterDB.json");
const jGameManager = require("../build/contracts/GameManager.json");
const jGameStore = require("../build/contracts/GameStore.json");
const jGameCreation = require("../build/contracts/GameCreation.json");
const jGameVarAndFee = require("../build/contracts/GameVarAndFee.json");
const jForfeiter = require("../build/contracts/Forfeiter.json");
const jDateTime = require("../build/contracts/DateTime.json");
const jScheduler = require("../build/contracts/Scheduler.json");
const jBetting = require("../build/contracts/Betting.json");
const jHitsResolve = require("../build/contracts/HitsResolve.json");
const jRarityCalculator = require("../build/contracts/RarityCalculator.json");
const jRegister = require("../build/contracts/Register.json");
const jEndowmentFund = require("../build/contracts/EndowmentFund.json");
const jEndowmentDB = require("../build/contracts/EndowmentDB.json");
const jEscrow = require("../build/contracts/Escrow.json");
const jKittieHell = require("../build/contracts/KittieHell.json");
const jKittieHellDB = require("../build/contracts/KittieHellDB.json");
const jCronJob = require("../build/contracts/CronJob.json");
const jFreezeInfo = require("../build/contracts/FreezeInfo.json");
const jCronJobTarget = require("../build/contracts/CronJobTarget.json");
const jKittieFightToken = require("../build/contracts/KittieFightToken.json");
const jCryptoKitties = require("../build/contracts/MockERC721Token.json");
const jSuperDaoToken = require("../build/contracts/MockERC20Token.json");
  

const KFProxy = artifacts.require('KFProxy')
const GenericDB = artifacts.require('GenericDB');
const ProfileDB = artifacts.require('ProfileDB')
const RoleDB = artifacts.require('RoleDB')
const GMSetterDB = artifacts.require('GMSetterDB')
const GMGetterDB = artifacts.require('GMGetterDB')
const GameManager = artifacts.require('GameManager')
const GameStore = artifacts.require('GameStore')
const GameCreation = artifacts.require('GameCreation')
const GameVarAndFee = artifacts.require('GameVarAndFee')
const Forfeiter = artifacts.require('Forfeiter')
const DateTime = artifacts.require('DateTime')
const Scheduler = artifacts.require('Scheduler')
const Betting = artifacts.require('Betting')
const HitsResolve = artifacts.require('HitsResolve')
const RarityCalculator = artifacts.require('RarityCalculator')
const Register = artifacts.require('Register')
const EndowmentFund = artifacts.require('EndowmentFund')
const EndowmentDB = artifacts.require('EndowmentDB')
const Escrow = artifacts.require('Escrow')
const KittieHELL = artifacts.require('KittieHell')
const KittieHellDB = artifacts.require('KittieHellDB')
const SuperDaoToken = artifacts.require('MockERC20Token');
const KittieFightToken = artifacts.require('KittieFightToken');
const CryptoKitties = artifacts.require('MockERC721Token');
const CronJob = artifacts.require('CronJob');
const FreezeInfo = artifacts.require('FreezeInfo');
const CronJobTarget = artifacts.require('CronJobTarget');

//Contract instances
let proxy, dateTime, genericDB, profileDB, roleDB, superDaoToken,
  kittieFightToken, cryptoKitties, register, gameVarAndFee, endowmentFund,
  endowmentDB, forfeiter, scheduler, betting, hitsResolve,
  rarityCalculator, kittieHELL, kittieHellDB, getterDB, setterDB, gameManager,
  cronJob, escrow

//Kitty Ids
const kitties = [0, 1001, 1555108, 1267904, 454545, 333, 6666];

//Civic Ids
const cividIds = [0, 1, 2, 3, 4, 5, 6];

gameStates = ['WAITING', 'PREGAME', 'MAINGAME', 'GAMEOVER', 'CLAIMING', 'CANCELLED'];
potStates = ['CREATED', 'ASSIGNED', 'SCHEDULED', 'STARTED', 'FORFEITED', 'CLAIMING', 'DISSOLVED']
const GameState = {
  WAITING: 0,
  PRE_GAME: 1,
  MAIN_GAME: 2,
  GAME_OVER: 3,
  CLAIMING: 4,
  CANCELLED: 5
}

const ETH_PER_GAME = new BigNumber(web3.utils.toWei("10", "ether"));
const FINALIZE_REWARDS = new BigNumber(web3.utils.toWei("500", "ether")); //500 KTY

//If you change endowment initial tokens, need to change deployment file too

// ======== INITIAL AMOUNTS ================ //
const TOKENS_FOR_USERS = new BigNumber(
  web3.utils.toWei("5000", "ether") //5.000 KTY 
);

const INITIAL_KTY_ENDOWMENT = new BigNumber(
  web3.utils.toWei("10000", "ether") //50.000 KTY
);

const INITIAL_ETH_ENDOWMENT = new BigNumber(
  web3.utils.toWei("650", "ether") //1.000 ETH
);
// ============================================== //


//Object used throughout the test, to store playing game details
let gameDetails;

// BETTING
let redBetStore = new Map()
let blackBetStore = new Map()
let totalBetAmount = 0;

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

function randomValue() {
  return Math.floor(Math.random() * 30) + 1; // 0-30ETH
}

function timeout(s) {
  // console.log(`~~~ Timeout for ${s} seconds`);
  return new Promise(resolve => setTimeout(resolve, s * 1000));
}

function formatDate(timestamp) {
  let date = new Date(null);
  date.setSeconds(timestamp);
  return date.toTimeString().replace(/.*(\d{2}:\d{2}:\d{2}).*/, "$1");
}

/*
  Simulation of 2 games created, 4 kitties listed. All bettors must register but only
  users that want to list kitties are going to 

*/
contract('GameManager', (accounts) => {

  it('instantiate contracts', async () => {

    proxy = await KFProxy.at(jKFProxy.networks["999"].address);
    genericDB = await GenericDB.at(jGenericDB.networks["999"].address);
    profileDB = await ProfileDB.at(jProfileDB.networks["999"].address);
    roleDB = await RoleDB.at(jRoleDB.networks["999"].address);
    endowmentDB = await EndowmentDB.at(jEndowmentDB.networks["999"].address);
    getterDB = await GMGetterDB.at(jGMGetterDB.networks["999"].address);
    setterDB = await GMSetterDB.at(jGMSetterDB.networks["999"].address);
    kittieHellDB = await KittieHellDB.at(jKittieHellDB.networks["999"].address);
    cronJob = await CronJob.at(jCronJob.networks["999"].address);
    freezeInfo = await FreezeInfo.at(jFreezeInfo.networks["999"].address);
    cronJobTarget = await CronJobTarget.at(
      jCronJobTarget.networks["999"].address
    );
    superDaoToken = await SuperDaoToken.at(
      jSuperDaoToken.networks["999"].address
    );
    kittieFightToken = await KittieFightToken.at(
      jKittieFightToken.networks["999"].address
    );
    cryptoKitties = await CryptoKitties.at(
      jCryptoKitties.networks["999"].address
    );
    gameManager = await GameManager.at(jGameManager.networks["999"].address);
    gameStore = await GameStore.at(jGameStore.networks["999"].address);
    gameCreation = await GameCreation.at(jGameCreation.networks["999"].address);
    register = await Register.at(jRegister.networks["999"].address);
    dateTime = await DateTime.at(jDateTime.networks["999"].address);
    gameVarAndFee = await GameVarAndFee.at(
      jGameVarAndFee.networks["999"].address
    );
    forfeiter = await Forfeiter.at(jForfeiter.networks["999"].address);
    scheduler = await Scheduler.at(jScheduler.networks["999"].address);
    betting = await Betting.at(jBetting.networks["999"].address);
    hitsResolve = await HitsResolve.at(jHitsResolve.networks["999"].address);
    rarityCalculator = await RarityCalculator.at(
      jRarityCalculator.networks["999"].address
    );
    endowmentFund = await EndowmentFund.at(
      jEndowmentFund.networks["999"].address
    );
    kittieHELL = await KittieHELL.at(jKittieHell.networks["999"].address);
    escrow = await Escrow.at(jEscrow.networks["999"].address);


  })

  it('mint some kitties for the test addresses', async () => {
    for (let i = 1; i < 5; i++) {
      await cryptoKitties.mint(accounts[i], kitties[i]).should.be.fulfilled;
    }
  })

  it('approve transfer operation', async () => {
    for (let i = 1; i < 5; i++) {
      await cryptoKitties.approve(kittieHELL.address, kitties[i], { from: accounts[i] }).should.be.fulfilled;
    }
  })

  it('transfer some KTY for the test addresses', async () => {
    for (let i = 1; i < 20; i++) {
      await kittieFightToken.transfer(accounts[i], TOKENS_FOR_USERS).should.be.fulfilled;
    }
  })

  it('approves erc20 token transfer operation by endowment contract', async () => {
    for (let i = 1; i < 20; i++) {
      await kittieFightToken.approve(endowmentFund.address, TOKENS_FOR_USERS, { from: accounts[i] }).should.be.fulfilled;
    }
  })

  it('correct initial endowment/escrow funds', async () => {
    let balanceKTY = await escrow.getBalanceKTY();
    let balanceETH = await escrow.getBalanceETH();

    balanceKTY.toString().should.be.equal(INITIAL_KTY_ENDOWMENT.toString());
    balanceETH.toString().should.be.equal(INITIAL_ETH_ENDOWMENT.toString());
  })

  it('registers user to the system', async () => {
    for (let i = 1; i < 20; i++) {
      await proxy.execute('Register', setMessage(register, 'register', []), {
        from: accounts[i]
      }).should.be.fulfilled;
    }
  })

  it('verify users civid Id', async () => {
    for (let i = 1; i < 5; i++) {
      await proxy.execute('Register', setMessage(register, 'verifyAccount', [cividIds[i]]), {
        from: accounts[i]
      }).should.be.fulfilled;
    }
  })

  it('verified users have player role', async () => {
    let hasRole = await roleDB.hasRole('player', accounts[1]);
    hasRole.should.be.true;

    hasRole = await roleDB.hasRole('player', accounts[2]);
    hasRole.should.be.true;
  })

  it('unverified users cannot list kitties', async () => {
    //account 5 not verified
    await proxy.execute('GameCreation', setMessage(gameCreation, 'listKittie',
      [156]), { from: accounts[5] }).should.be.rejected;
  })

  it('is not able to list kittie without kitty ownership', async () => {
    //account 3 not owner of kittie1
    await proxy.execute('GameCreation', setMessage(gameCreation, 'listKittie',
      [kitties[1]]), { from: accounts[3] }).should.be.rejected;
  })

  it('cannot list kitties without proxy', async () => {
    await gameCreation.listKittie(kitties[1], { from: accounts[1] }).should.be.rejected;
  })

  it('list 3 kitties to the system', async () => {
    for (let i = 1; i < 4; i++) {
      await proxy.execute('GameCreation', setMessage(gameCreation, 'listKittie',
        [kitties[i]]), { from: accounts[i] }).should.be.fulfilled;
    }
  })

  it('get correct amount of unmatched/listed kitties', async () => {
    let listed = await scheduler.getListedKitties();
    console.log('\n==== LISTED KITTIES: ', listed.length);
  })

  it('list 1 more kittie to the system', async () => {
    await proxy.execute('GameCreation', setMessage(gameCreation, 'listKittie',
      [kitties[4]]), { from: accounts[4] }).should.be.fulfilled;
  })

  //Change here to select what game to play
  //Currently playing first game created
  it('correctly creates 2 games', async () => {
    let newGameEvents = await gameCreation.getPastEvents("NewGame", {
      fromBlock: 0,
      toBlock: "latest"
    });
    // assert.equal(newGameEvents.length, 2);

    newGameEvents.map(async (e) => {
      let gameInfo = await getterDB.getGameTimes(e.returnValues.gameId);

      console.log('\n==== NEW GAME CREATED ===');
      console.log('    GameId ', e.returnValues.gameId)
      console.log('    Red Fighter ', e.returnValues.kittieRed)
      console.log('    Red Player ', e.returnValues.playerRed)
      console.log('    Black Fighter ', e.returnValues.kittieBlack)
      console.log('    Black Player ', e.returnValues.playerBlack)
      console.log('    Start Time ', formatDate(e.returnValues.gameStartTime))
      console.log('    Prestart Time:', formatDate(gameInfo.preStartTime));
      console.log('    End Time:', formatDate(gameInfo.endTime));
      console.log('========================\n')
    })

    //Assign variable to game that is going to be played in the test
    // gameDetails = newGameEvents[newGameEvents.length -1].returnValues
    gameDetails = newGameEvents[0].returnValues

    let gameTimes = await getterDB.getGameTimes(gameDetails.gameId);

    gameDetails.endTime = gameTimes.endTime.toNumber();

    gameDetails.preStartTime = gameTimes.preStartTime.toNumber();
  })

  it('get correct fighter details ', async () => {
    let { kittieBlack, kittieRed} = gameDetails;

    let detailsBlack = await getterDB.getFighterByKittieID(kittieBlack)
    console.log(` Kittie ${kittieBlack} playing in game ${detailsBlack.gameId.toString()}`)

    let detailsRed = await getterDB.getFighterByKittieID(kittieRed)
    console.log(` Kittie ${kittieRed} playing in game ${detailsRed.gameId.toString()}`)
  })

  it('listed kitties array emptied', async () => {
    let listed = await scheduler.getListedKitties();
    console.log('\n==== LISTED KITTIES: ', listed.length);
    listed.length.should.be.equal(0);
  })

  it('bettors can participate in a created game', async () => {

    let { gameId, playerRed, playerBlack } = gameDetails;

    console.log(`\n==== PLAYING GAME ${gameId} ===`);

    let currentState = await getterDB.getGameState(gameId)
    console.log('\n==== NEW GAME STATE: ', gameStates[currentState.toNumber()])

    let block = await dateTime.getBlockTimeStamp();
    console.log('\nblocktime: ', formatDate(block))

    console.log('\n==== ADDING SUPPORTERS TO THE GAME ');

    await proxy.execute('GameManager', setMessage(gameManager, 'participate',
      [gameId, playerRed]), { from: accounts[5] }).should.be.fulfilled;

    //New Supporter added
    let events = await gameManager.getPastEvents("NewSupporter", { fromBlock: 0, toBlock: "latest" });
    assert.equal(events.length, 1);


    //Cannot support the opponent too
    await proxy.execute('GameManager', setMessage(gameManager, 'participate',
      [gameId, playerBlack]), { from: accounts[5] }).should.be.rejected;


    let players = [playerRed, playerBlack];

    // adds bettors with random supported player
    for (let i = 6; i < 18; i++) {
      let index = Math.floor(Math.random() * 2)
      await proxy.execute('GameManager', setMessage(gameManager, 'participate',
        [gameId, players[index]]), { from: accounts[i] }).should.be.fulfilled;
    }

    //Check NewSupporter events
    events = await gameManager.getPastEvents("NewSupporter", { fromBlock: 0, toBlock: "latest" });
    assert.equal(events.length, 13);


  })


  it.skip('player cant start a game before reaching PRE_GAME', async () => {
    const gene1 = "512955438081049600613224346938352058409509756310147795204209859701881294";

    let { gameId, playerRed } = gameDetails;
    await proxy.execute('GameManager', setMessage(gameManager, 'startGame',
      [gameId, 99, gene1]), { from: playerRed }).should.be.rejected;
  })

  it('should move gameState to PRE_GAME', async () => {

    let { gameId, playerRed, playerBlack, preStartTime } = gameDetails;
    console.log('\n==== WAITING FOR PREGAME TIME: ', formatDate(preStartTime))

    let block = await dateTime.getBlockTimeStamp();
    console.log('\nblocktime: ', formatDate(block))

    while (block < preStartTime) {
      block = await dateTime.getBlockTimeStamp();
      await timeout(3);
    }

    let currentState = await getterDB.getGameState(gameId)
    currentState.toNumber().should.be.equal(GameState.WAITING)

    //IDEA: Player can hit button to change state, and have benefits in kittie redemption

    //Should be able to participate in prestart state (this one wont bet)
    await proxy.execute('GameManager', setMessage(gameManager, 'participate',
      [gameId, playerBlack]), { from: accounts[18] }).should.be.fulfilled;

    //Show supporters
    let redSupporters = await getterDB.getSupporters(gameId, playerRed);
    console.log(`\n==== SUPPORTERS FOR RED CORNER: ${redSupporters.toNumber()}`);

    let blackSupporters = await getterDB.getSupporters(gameId, playerBlack);
    console.log(`\n==== SUPPORTERS FOR BLACK CORNER: ${blackSupporters.toNumber()}`);


    let newState = await getterDB.getGameState(gameId)
    console.log('\n==== NEW STATE: ', gameStates[newState.toNumber()])
    newState.toNumber().should.be.equal(GameState.PRE_GAME)

    events = await gameManager.getPastEvents("NewSupporter", { fromBlock: 0, toBlock: "latest" });
    assert.equal(events.length, 14);


  })

  it('should move gameState to MAIN_GAME', async () => {

    let { gameId, playerRed, playerBlack } = gameDetails

    let block = await dateTime.getBlockTimeStamp();
    console.log('\nblocktime: ', formatDate(block))

    const gene1 = "512955438081049600613224346938352058409509756310147795204209859701881294";
    const gene2 = "24171491821178068054575826800486891805334952029503890331493652557302916";

    await timeout(1);
    await proxy.execute('GameManager', setMessage(gameManager, 'startGame',
      [gameId, 2456, gene1]), { from: playerRed }).should.be.fulfilled;
    console.log(`\n==== PLAYER RED STARTS`);

    await timeout(1);

    await proxy.execute('GameManager', setMessage(gameManager, 'startGame',
      [gameId, 1148, gene2]), { from: playerBlack }).should.be.fulfilled;
    console.log(`\n==== PLAYER BLACK STARTS`);

    await timeout(1);

    let gameInfo = await getterDB.getGameInfo(gameId)
    console.log('\n==== NEW GAME STATE: ', gameStates[gameInfo.state.toNumber()])

    //Check players start button
    gameInfo.pressedStart[0].should.be.true
    gameInfo.pressedStart[1].should.be.true

    //Game starts
    gameInfo.state.toNumber().should.be.equal(GameState.MAIN_GAME)
  })

  it('get defense level for both players', async () => {
    let { gameId, playerRed, playerBlack } = gameDetails;

    // await betting.setDefenseLevel(gameId, playerRed, 4).should.be.fulfilled;
    // await betting.setDefenseLevel(gameId, playerBlack, 5).should.be.fulfilled;

    let defense = await betting.defenseLevel(gameId, playerBlack);
    console.log(`\n==== DEFENSE BLACK: ${defense}`);

    defense = await betting.defenseLevel(gameId, playerRed);
    console.log(`\n==== DEFENSE RED: ${defense}`);
  })

  it('kittie hell contracts is now owner of fighting kitties', async () => {
    let { kittieRed, kittieBlack } = gameDetails;

    //Red Kitty
    let owner = await cryptoKitties.ownerOf(kittieRed);
    owner.should.be.equal(kittieHELL.address)
    //Black kitty
    owner = await cryptoKitties.ownerOf(kittieBlack);
    owner.should.be.equal(kittieHELL.address)
  })

  it('escrow contract should have KTY funds from fees', async () => {
    let balanceKTY = await escrow.getBalanceKTY()
    // 10.000 + 4*1250 + 14*37.5
    let expected = new BigNumber(web3.utils.toWei("15525", "ether"));
    balanceKTY.toString().should.be.equal(expected.toString())

    await timeout(1);
  })

  it('betting algo creates a fight map', async () => {
    let { gameId } = gameDetails;

    let attack;
    console.log('\n==== FIGHT MAP CREATED')
    for (let i = 0; i < 7; i++) {
      attack = await betting.fightMap(gameId, i)
      console.log(`Name: ${attack.attack}`);
      console.log(`Hash: ${attack.hash}\n`);
    }
    console.log('=================\n')
  })

  it('players should be able to make bets', async () => {
    let { gameId, playerRed, playerBlack } = gameDetails;

    let currentState = await getterDB.getGameState(gameId)
    currentState.toNumber().should.be.equal(GameState.MAIN_GAME)

    let betDetails;

    let opponentRed = await gameStore.getOpponent(gameId, playerRed);
    console.log('\n==== OPPONENT RED: ', opponentRed);
    let opponentBlack = await gameStore.getOpponent(gameId, playerBlack);
    console.log('\n==== OPPONENT BLACK: ', opponentBlack);

    let betsBlack = [];
    let betsRed = [];

    for (let i = 6; i < 29; i++) {
      j = i;
      if (i >= 18) j = j - 12;

      let betAmount = randomValue()
      let bettor = accounts[j]
      let supporterInfo = await getterDB.getSupporterInfo(gameId, accounts[j])
      let supportedPlayer = supporterInfo.supportedPlayer;
      let player;

      if (supportedPlayer == playerRed) {
        player = 'RED';
        betsRed.push(betAmount);
        (redBetStore.has(bettor)) ?
          redBetStore.set(bettor, redBetStore.get(bettor) + betAmount) :
          redBetStore.set(bettor, betAmount)

      } else {
        player = 'BLACK';
        //This line make bets in black be incremental
        //betAmount = 1 + i
        betsBlack.push(betAmount);
        (blackBetStore.has(bettor)) ?
          blackBetStore.set(bettor, blackBetStore.get(bettor) + betAmount) :
          blackBetStore.set(bettor, betAmount)
      }


      await proxy.execute('GameManager', setMessage(gameManager, 'bet',
        [gameId, randomValue()]), { from: bettor, value: web3.utils.toWei(String(betAmount)) }).should.be.fulfilled;

      let betEvents = await betting.getPastEvents('BetPlaced', {
        filter: { gameId },
        fromBlock: 0,
        toBlock: "latest"
      })

      betDetails = betEvents[betEvents.length - 1].returnValues;
      console.log(`\n==== NEW BET FOR ${player} ====`);
      console.log(' Amount:', web3.utils.fromWei(betDetails._lastBetAmount), 'ETH');
      console.log(' Bettor:', betDetails._bettor);
      console.log(' Attack Hash:', betDetails.attackHash);
      console.log(' Blocked?:', betDetails.isBlocked);
      console.log(` Defense ${player}:`, betDetails.defenseLevelSupportedPlayer);
      console.log(' Defense Opponent:', betDetails.defenseLevelOpponent);

      let lastBetTimestamp = await betting.lastBetTimestamp(gameId, supportedPlayer);
      console.log(' Timestamp last Bet: ', formatDate(lastBetTimestamp));

      totalBetAmount = totalBetAmount + betAmount;
      await timeout(Math.floor(Math.random() * 5) + 1);
    }

    //Log all bets    
    console.log('\nBets Black: ', betsBlack)
    console.log('Bets Red: ', betsRed)
  })

  it('correctly adds all bets for each corner', async () => {
    let block = await dateTime.getBlockTimeStamp();
    console.log('\nblocktime: ', formatDate(block))

    let { gameId, playerRed, playerBlack } = gameDetails;

    let redTotal = await getterDB.getTotalBet(gameId, playerRed)
    let blackTotal = await getterDB.getTotalBet(gameId, playerBlack)
    let actualTotalBet = redTotal.add(blackTotal)

    console.log(`\n==== TOTAL AMOUNT BET: ${totalBetAmount} ETH `)

    actualTotalBet.toString().should.be.equal(String(web3.utils.toWei(String(totalBetAmount))));
    await timeout(1);
  })

  it('correctly computes the top bettors for each corner', async () => {
    let { gameId, playerRed, playerBlack } = gameDetails;

    let redSortMap = new Map([...redBetStore.entries()].sort((a, b) => b[1] - a[1]));
    let blackSortMap = new Map([...blackBetStore.entries()].sort((a, b) => b[1] - a[1]));

    console.log('\n==== RED SORTED MAP ====')
    console.log(redSortMap)
    console.log('\n==== BLACK SORTED MAP ====')
    console.log(blackSortMap)
    await timeout(1);

    let redSorted = Array.from(redSortMap.keys())
    let blackSorted = Array.from(blackSortMap.keys())

    let redTopBettor = await gameStore.getTopBettor(gameId, playerRed)
    let redSecondTopBettor = await gameStore.getSecondTopBettor(gameId, playerRed)

    let blackTopBettor = await gameStore.getTopBettor(gameId, playerBlack)
    let blackSecondTopBettor = await gameStore.getSecondTopBettor(gameId, playerBlack)

    console.log('\n==== RED TOP BETTORS ====')
    console.log(`Top: ${redTopBettor} \nSecond: ${redSecondTopBettor}`)

    console.log('\n-==== BLACK TOP BETTORS ====')
    console.log(`Top: ${blackTopBettor} \nSecond: ${blackSecondTopBettor}`)
    await timeout(1);

    redTopBettor.should.be.equal(redSorted[0])
    redSecondTopBettor.should.be.equal(redSorted[1])
    blackTopBettor.should.be.equal(blackSorted[0])
    blackSecondTopBettor.should.be.equal(blackSorted[1])

    let block = await dateTime.getBlockTimeStamp();
    console.log('\nblocktime: ', formatDate(block))

    let gameTimes = await getterDB.getGameTimes(gameId);

    console.log('\nGame end time: ', formatDate(gameTimes.endTime))

    await timeout(1);
  })

  it('get final defense level for both players', async () => {
    let { gameId, playerRed, playerBlack } = gameDetails;

    let defense = await betting.defenseLevel(gameId, playerBlack);
    console.log(`\n==== FINAL DEFENSE BLACK: ${defense}`);

    defense = await betting.defenseLevel(gameId, playerRed);
    console.log(`\n==== FINAL DEFENSE RED: ${defense}`);
  })

  it('game ends', async () => {

    let { gameId, endTime } = gameDetails;

    console.log('\n==== WAITING FOR GAME OVER: ', formatDate(endTime))

    let block = await dateTime.getBlockTimeStamp();
    console.log('\nblocktime: ', formatDate(block))

    while (block < endTime) {
      block = await dateTime.getBlockTimeStamp();
      await timeout(3);
    }

    await proxy.execute('GameManager', setMessage(gameManager, 'bet',
      [gameId, randomValue()]), { from: accounts[7], value: web3.utils.toWei('1') }).should.be.fulfilled;

    let currentState = await getterDB.getGameState(gameId)
    currentState.toNumber().should.be.equal(3);

    console.log('\n==== NEW GAME STATE: ', gameStates[currentState.toNumber()])

    block = await dateTime.getBlockTimeStamp();
    console.log('\nblocktime: ', formatDate(block))

    await timeout(1);


  })

  it('get correct fighter details ', async () => {
    let { kittieBlack, kittieRed} = gameDetails;

    let detailsBlack = await getterDB.getFighterByKittieID(kittieBlack)
    console.log(` Kittie ${kittieBlack} playing in game ${detailsBlack.gameId.toString()}`)

    let detailsRed = await getterDB.getFighterByKittieID(kittieRed)
    console.log(` Kittie ${kittieRed} playing in game ${detailsRed.gameId.toString()}`)
  })

  it('can call finalize game', async () => {

    let { gameId, playerRed, playerBlack } = gameDetails;

    let user = accounts[10];

    let balance = await kittieFightToken.balanceOf(user);
    console.log("\n==== PREVIOUS BALANCE: ",web3.utils.fromWei(balance.toString()), "KTY")

    await proxy.execute('GameManager', setMessage(gameManager, 'finalize',
      [gameId, randomValue()]), { from: user }).should.be.fulfilled;
    
    let newBalance = await kittieFightToken.balanceOf(user);
    console.log("\n====FINALIZE REWARD: ", web3.utils.fromWei(FINALIZE_REWARDS.toString()), "KTY")
    console.log("\n==== NEW BALANCE: ", web3.utils.fromWei(newBalance.toString()), "KTY")

    let gameEnd = await gameManager.getPastEvents('GameEnded', {
      filter: { gameId },
      fromBlock: 0,
      toBlock: 'latest'
    })

    let { pointsBlack, pointsRed, loser } = gameEnd[0].returnValues;

    let winners = await getterDB.getWinners(gameId);

    gameDetails.winners = winners;
    gameDetails.loser = loser;

    let corner = (winners.winner === playerBlack) ? "Black Corner" : "Red Corner"

    console.log(`\n==== WINNER: ${corner} ==== `)
    console.log(`   Winner: ${winners.winner}   `);
    console.log(`   TopBettor: ${winners.topBettor}   `)
    console.log(`   SecondTopBettor: ${winners.secondTopBettor}   `)
    console.log('')
    console.log(`   Points Black: ${pointsBlack / 100}   `);
    console.log(`   Point Red: ${pointsRed / 100}   `);
    console.log('=======================\n')

    await timeout(1);

  })

  it('correct honeypot info', async () => {

    let { gameId } = gameDetails;

    let honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `)
    console.log(`     InitialEtH: ${web3.utils.fromWei(honeyPotInfo.initialEth.toString())}   `);
    console.log(`     TotalETH: ${web3.utils.fromWei(honeyPotInfo.ethTotal.toString())}   `);
    console.log(`     TotalKTY: ${web3.utils.fromWei(honeyPotInfo.ktyTotal.toString())}   `);
    console.log('=======================\n')

    //1 ether from the last bet that ended game
    honeyPotInfo.ethTotal.toString().should.be.equal(
      String(ETH_PER_GAME.add(new BigNumber(web3.utils.toWei(String(totalBetAmount + 1)))))
    )

    await timeout(1);
  })

  it('state changes to CLAIMING', async () => {

    let { gameId } = gameDetails;

    let currentState = await getterDB.getGameState(gameId)
    currentState.toNumber().should.be.equal(4);
    console.log('\n==== NEW STATE: ', gameStates[currentState.toNumber()])

    let potState = await endowmentDB.getHoneypotState(gameId);
    console.log('\n==== HONEYPOT STATE: ', potStates[potState.state.toNumber()]);

    await timeout(1);

  })

  it('show distribution details', async () => {

    let { gameId, winners } = gameDetails;

    let rates = await gameStore.getDistributionRates(gameId);

    console.log('\n==== DISTRIBUTION STRUCTURE ==== \n');
    let winnerShare = await endowmentFund.getWinnerShare(gameId, winners.winner);
    console.log(` WINNER SHARE: ${rates[0].toString()} %`);
    console.log('    ETH: ', web3.utils.fromWei(winnerShare.winningsETH.toString()));
    console.log('    KTY: ', web3.utils.fromWei(winnerShare.winningsKTY.toString()));
    let topShare = await endowmentFund.getWinnerShare(gameId, winners.topBettor);
    console.log(`  TOP BETTOR SHARE: ${rates[1].toString()} %`);
    console.log('    ETH: ', web3.utils.fromWei(topShare.winningsETH.toString()));
    console.log('    KTY: ', web3.utils.fromWei(topShare.winningsKTY.toString()));
    let secondTopShare = await endowmentFund.getWinnerShare(gameId, winners.secondTopBettor);
    console.log(`  SECOND TOP BETTOR SHARE: ${rates[2].toString()} %`);
    console.log('    ETH: ', web3.utils.fromWei(secondTopShare.winningsETH.toString()));
    console.log('    KTY: ', web3.utils.fromWei(secondTopShare.winningsKTY.toString()))
    let endowmentShare = await endowmentFund.getEndowmentShare(gameId);
    console.log(`  ENDOWMENT SHARE: ${rates[4].toString()} %`);
    console.log('    ETH: ', web3.utils.fromWei(endowmentShare.winningsETH.toString()));
    console.log('    KTY: ', web3.utils.fromWei(endowmentShare.winningsKTY.toString()));

    let bettors = await gameManager.getPastEvents("NewSupporter", {
      filter: { gameId },
      fromBlock: 0,
      toBlock: "latest"
    });

    //Get list of other bettors
    supporters = bettors
      .map(e => e.returnValues)
      .filter(e => e.playerSupported === winners.winner)
      .filter(e => e.supporter !== winners.topBettor)
      .filter(e => e.supporter !== winners.secondTopBettor)
      .map(e => e.supporter)

    gameDetails.supporters = supporters;

    console.log(`\n  OTHER BETTORS SHARE: ${rates[3].toString()} %`);
    console.log('   List: ', supporters)
    for (let i = 0; i < supporters.length; i++) {
      let share = await endowmentFund.getWinnerShare(gameId, supporters[i]);
      // let supporterInfo = await getterDB.getSupporterInfo(gameId, supporters[i]);
      console.log(`\n  Bettor ${supporters[i]}: `);
      // console.log('    Amount Bet:', web3.utils.fromWei( supporterInfo.betAmount.toString()), 'ETH')      
      console.log('    ETH: ', web3.utils.fromWei(share.winningsETH.toString()));
      console.log('    KTY: ', web3.utils.fromWei(share.winningsKTY.toString()))
    }

    await timeout(1);

    //Get list of losers
    let losers = bettors
      .map(e => e.returnValues)
      .filter(e => e.playerSupported !== winners.winner)

    gameDetails.losers = losers;

    // //Bettor from Black Corner
    let opponentShare = await endowmentFund.getWinnerShare(gameId, losers[0].supporter);
    opponentShare.winningsETH.toString().should.be.equal('0');


  })

  it('winners can claim their share', async () => {
    console.log('\n==== STARTING CLAIMING PROCESS: ') 
    let { gameId, supporters } = gameDetails;

    let block = await dateTime.getBlockTimeStamp();
    console.log('\nblocktime: ', formatDate(block))

    let potState = await endowmentDB.getHoneypotState(gameId);
    console.log('HONEYPOT DISSOLUTION TIME: ', formatDate(potState.claimTime.toNumber()))

    let winners = await getterDB.getWinners(gameId);
    let winnerShare = await endowmentFund.getWinnerShare(gameId, winners.winner);

    let balance = await kittieFightToken.balanceOf(winners.winner)
    balance = Number(web3.utils.fromWei(balance.toString()));

    // WINNER CLAIMING
    let share = await endowmentFund.getWinnerShare(gameId, winners.winner);
    console.log('\nWinner withdrawing ', String(web3.utils.fromWei(share.winningsETH.toString())), 'ETH')
    await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'claim',
      [gameId]), { from: winners.winner }).should.be.fulfilled;
    let withdrawalState = await endowmentFund.getWithdrawalState(gameId, winners.winner);
    console.log('Withdrew funds? ', withdrawalState)

    let claims = await endowmentFund.getPastEvents('WinnerClaimed', {
      filter: { gameId },
      fromBlock: 0,
      toBlock: "latest"
    });
    claims.length.should.be.equal(1);

    let newBalance = await kittieFightToken.balanceOf(winners.winner)
    // balance.should.be.equal(newBalance.add(winnerShare.winningsKTY))
    newBalance = Number(web3.utils.fromWei(newBalance.toString()));
    let winningsKTY = Number(web3.utils.fromWei(winnerShare.winningsKTY.toString()));

    newBalance.should.be.equal(balance + winningsKTY);

    await timeout(1);

    // TOP BETTOR CLAIMING
    share = await endowmentFund.getWinnerShare(gameId, winners.topBettor);
    console.log('\nTop Bettor withdrawing ', String(web3.utils.fromWei(share.winningsETH.toString())), 'ETH')
    await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'claim',
      [gameId]), { from: winners.topBettor }).should.be.fulfilled;
    withdrawalState = await endowmentFund.getWithdrawalState(gameId, winners.topBettor);
    console.log('Withdrew funds? ', withdrawalState)

    await timeout(1);

    // SECOND TOP BETTOR CLAIMING
    share = await endowmentFund.getWinnerShare(gameId, winners.secondTopBettor);
    console.log('\nSecond Top Bettor withdrawing ',String(web3.utils.fromWei(share.winningsETH.toString())), 'ETH')
    await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'claim',
      [gameId]), { from: winners.secondTopBettor }).should.be.fulfilled;
    withdrawalState = await endowmentFund.getWithdrawalState(gameId, winners.secondTopBettor);
    console.log('Withdrew funds? ', withdrawalState)

    await timeout(1);

    // OTHER BETTOR CLAIMING
    share = await endowmentFund.getWinnerShare(gameId, supporters[1]);
    console.log('\nOther Bettor 1 withdrawing ',String(web3.utils.fromWei(share.winningsETH.toString())), 'ETH')
    await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'claim',
      [gameId]), { from: supporters[1] }).should.be.fulfilled;
    withdrawalState = await endowmentFund.getWithdrawalState(gameId, supporters[1]);
    console.log('Withdrew funds? ', withdrawalState)

    await timeout(1);

    // OTHER BETTOR 2 CLAIMING
    share = await endowmentFund.getWinnerShare(gameId, supporters[2]);
    console.log('\nOther Bettor 2 withdrawing ',String(web3.utils.fromWei(share.winningsETH.toString())), 'ETH')
    await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'claim',
      [gameId]), { from: supporters[2] }).should.be.fulfilled;
    withdrawalState = await endowmentFund.getWithdrawalState(gameId, supporters[2]);
    console.log('Withdrew funds? ', withdrawalState)

    claims = await endowmentFund.getPastEvents('WinnerClaimed', {
      filter: { gameId },
      fromBlock: 0,
      toBlock: "latest"
    });

    claims.length.should.be.equal(5);
    
  })

  it('check game kitties dead status', async () => {

    let { playerBlack, kittieBlack, kittieRed, winners } = gameDetails;

    if (gameDetails.loser === playerBlack) {
      loserKitty = kittieBlack;
      winnerKitty = kittieRed;
    }
    else {
      loserKitty = kittieRed;
      winnerKitty = kittieBlack
    }

    gameDetails.loserKitty = loserKitty;

    //Loser Kittie Dead
    let isKittyDead = await kittieHELL.isKittyDead(loserKitty);
    isKittyDead.should.be.true;

    winnerOwner = await cryptoKitties.ownerOf(winnerKitty);
    winnerOwner.should.be.equal(winners.winner);

  })

  it('pay for resurrection', async () => {

    console.log('\n==== KITTIE HELL: ')

    let { gameId, loserKitty, loser } = gameDetails;

    let resurrectionCost = await kittieHELL.getResurrectionCost(loserKitty, gameId);

    console.log('Resurrection Cost: ', String(web3.utils.fromWei(resurrectionCost.toString())), 'KTY')

    await kittieFightToken.approve(endowmentFund.address, resurrectionCost,
      { from: loser }).should.be.fulfilled;

    await proxy.execute('KittieHell', setMessage(kittieHELL, 'payForResurrection',
      [loserKitty, gameId]), { from: loser }).should.be.fulfilled;

    let owner = await cryptoKitties.ownerOf(loserKitty)
    //Ownership back to address, not kittieHell
    owner.should.be.equal(loser);

  })

  it('game 2 should be cancelled ', async () => {
    console.log('\n==== GAME 2 ====')

    console.log('\n==== WAITING FOR PREGAME TIME OF GAME 2')

    let block = await dateTime.getBlockTimeStamp();
    console.log('\nblocktime: ', formatDate(block))

    let newState = await getterDB.getGameState(2)
    console.log('\n==== GAME STATE: ', gameStates[newState.toNumber()])
    //TODO: Game should be cancelled by now

    let gameTimes = await getterDB.getGameTimes(2);
    let gamePlayers = await getterDB.getGamePlayers(2);

    while (block.toNumber() < gameTimes.preStartTime.toNumber()) {
      block = await dateTime.getBlockTimeStamp();
      await timeout(3);
    }

    //This will trigger Forfeiter
    //This should not be fulfilled, as cronjob should have cancelled game
    console.log('\n==== PARTICIPATING... ')
    await proxy.execute('GameManager', setMessage(gameManager, 'participate',
      [2, gamePlayers.playerBlack]), { from: accounts[18] }).should.not.be.fulfilled;

    let potState = await endowmentDB.getHoneypotState(2);
    console.log('\n==== HONEYPOT STATE: ', potStates[potState.state.toNumber()]);

    let cancelledEvents = await forfeiter.getPastEvents('GameCancelled', {
      fromBlock: 0,
      toBlock: "latest"
    })

    cancelledEvents.length.should.be.equal(1);
    console.log('\n==== CANCELLED GAME EVENTS: ', cancelledEvents.length)
    cancelledEvents.map(e => {      
      console.log('\n GameId: ', e.returnValues.gameId)
      console.log(' Reason: ', e.returnValues.reason)
    })

    newState = await getterDB.getGameState(2)
    console.log('\n==== NEW GAME STATE: ', gameStates[newState.toNumber()])

    newState.toNumber().should.be.equal(5)

  })

})

