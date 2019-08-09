
const BigNumber = web3.utils.BN;
require('chai')
  .use(require('chai-shallow-deep-equal'))
  .use(require('chai-bignumber')(BigNumber))
  .use(require('chai-as-promised'))
  .should();

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

// ================ GAME VARS AND FEES ================ //
const LISTING_FEE = new BigNumber(web3.utils.toWei("1000", "ether"));
const TICKET_FEE = new BigNumber(web3.utils.toWei("100", "ether"));
const BETTING_FEE = new BigNumber(web3.utils.toWei("100", "ether"));
const MIN_CONTRIBUTORS = 2
const REQ_NUM_MATCHES = 2
const GAME_PRESTART = 20 // 60 secs for quick test
const GAME_DURATION = 75 // games last  2 min
const ETH_PER_GAME = new BigNumber(web3.utils.toWei("10", "ether"));
const TOKENS_PER_GAME = new BigNumber(web3.utils.toWei("10000", "ether"));
const GAME_TIMES = 60 //Scheduled games 2 min apart
const KITTIE_HELL_EXPIRATION = 300
const HONEY_POT_EXPIRATION = 180
const KITTIE_REDEMPTION_FEE = new BigNumber(web3.utils.toWei("500", "ether"));
const FINALIZE_REWARDS = new BigNumber(web3.utils.toWei("500", "ether")); //500 KTY
//Distribution Rates
const WINNING_KITTIE = 35
const TOP_BETTOR = 25
const SECOND_RUNNER_UP = 10
const OTHER_BETTORS = 15
const ENDOWNMENT = 15
// =================================================== //

//If you change endowment initial tokens, need to change deployment file too

// ======== INITIAL AMOUNTS ================ //
const TOKENS_FOR_USERS = new BigNumber(
  web3.utils.toWei("5000", "ether") //5.000 KTY 
);

const INITIAL_KTY_ENDOWMENT = new BigNumber(
  web3.utils.toWei("50000", "ether") //50.000 KTY
);

const INITIAL_ETH_ENDOWMENT = new BigNumber(
  web3.utils.toWei("1000", "ether") //1.000 ETH
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

let jobIdGame2;

contract('GameManager', (accounts) => {

  it('instantiate contracts', async () => {

    // PROXY
    proxy = await KFProxy.deployed()

    // DATABASES
    genericDB = await GenericDB.deployed()
    profileDB = await ProfileDB.deployed();
    roleDB = await RoleDB.deployed();
    endowmentDB = await EndowmentDB.deployed()
    getterDB = await GMGetterDB.deployed()
    setterDB = await GMSetterDB.deployed()
    kittieHellDB = await KittieHellDB.deployed()

    // CRONJOB
    cronJob = await CronJob.deployed()
    freezeInfo = await FreezeInfo.deployed();
    cronJobTarget = await CronJobTarget.deployed();


    // TOKENS
    superDaoToken = await SuperDaoToken.deployed();
    kittieFightToken = await KittieFightToken.deployed();
    cryptoKitties = await CryptoKitties.deployed();

    // MODULES
    gameManager = await GameManager.deployed()
    gameStore = await GameStore.deployed()
    gameCreation = await GameCreation.deployed()
    register = await Register.deployed()
    dateTime = await DateTime.deployed()
    gameVarAndFee = await GameVarAndFee.deployed()
    forfeiter = await Forfeiter.deployed()
    scheduler = await Scheduler.deployed()
    betting = await Betting.deployed()
    hitsResolve = await HitsResolve.deployed()
    rarityCalculator = await RarityCalculator.deployed()
    endowmentFund = await EndowmentFund.deployed()
    kittieHELL = await KittieHELL.deployed()

    //ESCROW
    escrow = await Escrow.deployed()

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

  it('Set game vars and fees correctly', async () => {
    let names = ['listingFee', 'ticketFee', 'bettingFee', 'gamePrestart', 'gameDuration',
      'minimumContributors', 'requiredNumberMatches', 'ethPerGame', 'tokensPerGame',
      'gameTimes', 'kittieHellExpiration', 'honeypotExpiration', 'kittieRedemptionFee',
      'winningKittie', 'topBettor', 'secondRunnerUp', 'otherBettors', 'endownment', 'finalizeRewards'];

    let bytesNames = [];
    for (i = 0; i < names.length; i++) {
      bytesNames.push(web3.utils.asciiToHex(names[i]));
    }

    let values = [LISTING_FEE.toString(), TICKET_FEE.toString(), BETTING_FEE.toString(), GAME_PRESTART, GAME_DURATION, MIN_CONTRIBUTORS,
      REQ_NUM_MATCHES, ETH_PER_GAME.toString(), TOKENS_PER_GAME.toString(), GAME_TIMES, KITTIE_HELL_EXPIRATION,
      HONEY_POT_EXPIRATION, KITTIE_REDEMPTION_FEE.toString(), WINNING_KITTIE, TOP_BETTOR, SECOND_RUNNER_UP,
      OTHER_BETTORS, ENDOWNMENT, FINALIZE_REWARDS.toString()];


    await proxy.execute('GameVarAndFee', setMessage(gameVarAndFee, 'setMultipleValues', [bytesNames, values]), {
      from: accounts[0]
    }).should.be.fulfilled;

    let getVar = await gameVarAndFee.getRequiredNumberMatches();
    getVar.toNumber().should.be.equal(REQ_NUM_MATCHES);

    getVar = await gameVarAndFee.getListingFee();
    getVar.toString().should.be.equal(LISTING_FEE.toString());
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

  it('listed kitties array emptied', async () => {
    let listed = await scheduler.getListedKitties();
    console.log('\n==== LISTED KITTIES: ', listed.length);
    listed.length.should.be.equal(0);
  })

  it('get scheduled events for cronjob in setterDB', async () => {
    
    let cronJobs = await gameCreation.getPastEvents('Scheduled', {
      fromBlock: 0,
      toBlock: "latest"
    });

    console.log('\n==== SCHEDULED JOBS EVENTS:', cronJobs.length);
    cronJobs.map(e => {
      console.log('\n  Job:', e.returnValues.job);
      console.log('  Game Id:', e.returnValues.gameId);
      console.log('  Job Id:', e.returnValues.jobId);
      console.log('  Scheduled for:', formatDate(e.returnValues.jobTime));
    })

    jobIdGame2 = cronJobs[1].returnValues.jobId;

    // let firstJob = await cronJob.getFirstJobId();
    // console.log('\n  First Job in Cron: ', firstJob.toString());

    // let parsedJob = await cronJob.parseJobID(firstJob);
    // console.log('  Shceduled for:', formatDate(parsedJob['0'].toString()));
  })

  it('bettors can participate in a created game', async () => {

    let { gameId, playerRed, playerBlack } = gameDetails;

    console.log(`\n==== PLAYING GAME ${gameId} ===`);

    let currentState = await getterDB.getGameState(gameId)
    console.log('\n==== NEW GAME STATE: ', gameStates[currentState.toNumber()])

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

  it('player cant start a game before reaching PRE_GAME', async () => {
    let { gameId, playerRed } = gameDetails;
    await proxy.execute('GameManager', setMessage(gameManager, 'startGame',
      [gameId, 99]), { from: playerRed }).should.be.rejected;
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

    // let firstJob = await cronJob.getFirstJobId();
    // console.log('\n  First Job in Cron: ', firstJob.toString());

    // let parsedJob = await cronJob.parseJobID(firstJob);
    // console.log('  Shceduled for:', formatDate(parsedJob['0'].toString()));

  })

  it('get scheduled events for cronjob in setterDB', async () => {
    let { gameId } = gameDetails;

    let cronJobs = await gameCreation.getPastEvents('Scheduled', {
      fromBlock: 0,
      toBlock: "latest"
    });

    console.log('\n==== SCHEDULED JOBS EVENTS:', cronJobs.length);
    cronJobs.map(e => {
      console.log('\n  Job:', e.returnValues.job);
      console.log('  Game Id:', e.returnValues.gameId);
      console.log('  Job Id:', e.returnValues.jobId);
      console.log('  Scheduled for:', formatDate(e.returnValues.jobTime));      
    })
  })

  it('should move gameState to MAIN_GAME', async () => {

    let { gameId, playerRed, playerBlack } = gameDetails

    let block = await dateTime.getBlockTimeStamp();
    console.log('\nblocktime: ', formatDate(block))

    await timeout(1);
    await proxy.execute('GameManager', setMessage(gameManager, 'startGame',
      [gameId, 2456]), { from: playerRed }).should.be.fulfilled;
    console.log(`\n==== PLAYER RED STARTS`);

    await timeout(1);

    await proxy.execute('GameManager', setMessage(gameManager, 'startGame',
      [gameId, 1148]), { from: playerBlack }).should.be.fulfilled;
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

  it('get scheduled events for cronjob in setterDB', async () => {
    let { gameId } = gameDetails;

    let cronJobs = await gameCreation.getPastEvents('Scheduled', {
      fromBlock: 0,
      toBlock: "latest"
    });

    console.log('\n==== SCHEDULED JOBS EVENTS:', cronJobs.length);
    cronJobs.map(e => {
      console.log('\n  Job:', e.returnValues.job);
      console.log('  Game Id:', e.returnValues.gameId);
      console.log('  Job Id:', e.returnValues.jobId);
      console.log('  Scheduled for:', formatDate(e.returnValues.jobTime));
    })
  })

  //Temporal set manual defense level
  it('get defense level for both players', async () => {
    let { gameId, playerRed, playerBlack } = gameDetails;

    await betting.setDefenseLevel(gameId, playerRed, 4).should.be.fulfilled;
    await betting.setDefenseLevel(gameId, playerBlack, 5).should.be.fulfilled;

    let defense = await betting.defenseLevel(gameId, playerBlack);
    console.log(`\n==== DEFENSE BLACK: ${defense}`);

    defense = await betting.defenseLevel(gameId, playerRed);
    console.log(`\n==== DEFENSE RED: ${defense}`);
  })

  it('players should be able to make bets', async () => {
    let { gameId, playerRed, playerBlack } = gameDetails;

    let currentState = await getterDB.getGameState(gameId)
    currentState.toNumber().should.be.equal(GameState.MAIN_GAME)

    let betDetails;

    let opponentRed = await getterDB.getOpponent(gameId, playerRed);
    console.log('\n==== OPPONENT RED: ', opponentRed);
    let opponentBlack = await getterDB.getOpponent(gameId, playerBlack);
    console.log('\n==== OPPONENT BLACK: ', opponentBlack);

    let betsBlack = [];
    let betsRed = [];

    for (let i = 6; i < 18; i++) {

      let betAmount = randomValue()
      let bettor = accounts[i]
      let supporterInfo = await getterDB.getSupporterInfo(gameId, accounts[i])
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
      await timeout(1);
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

  it('check game 2 cancelled state ', async () => {
    
    let newState = await getterDB.getGameState(2)
    console.log('\n==== GAME 2 STATE: ', gameStates[newState.toNumber()])
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

    let gameTimes = await getterDB.getGameTimes(2);
    while (block.toNumber() < gameTimes.preStartTime.toNumber()) {
      block = await dateTime.getBlockTimeStamp();
      await timeout(3);
    }

    //This proxy call should end game 1
    await proxy.execute('Register', setMessage(register, 'register', []), {
      from: accounts[20]
    })

    let gamePlayers = await getterDB.getGamePlayers(2);
    await proxy.execute('GameManager', setMessage(gameManager, 'participate',
      [2, gamePlayers.playerBlack]), { from: accounts[15] }).should.not.be.fulfilled;

    let newState = await getterDB.getGameState(2)
    console.log('\n==== GAME STATE 2: ', gameStates[newState.toNumber()])

    let currentState = await getterDB.getGameState(gameId)
    currentState.toNumber().should.be.equal(3);

    console.log('\n==== NEW GAME STATE: ', gameStates[currentState.toNumber()])

    block = await dateTime.getBlockTimeStamp();
    console.log('\nblocktime: ', formatDate(block))

    await timeout(1);


  })

  it('can call finalize game', async () => {

    let { gameId, playerRed, playerBlack } = gameDetails;

    await proxy.execute('GameManager', setMessage(gameManager, 'finalize',
      [gameId, randomValue()]), { from: accounts[10] }).should.be.fulfilled;

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

  it('check executed and failed cronjobs in game', async () => {

    // let firstJob = await cronJob.getFirstJobId();
    // console.log('\n  First Job in Cron: ', firstJob.toString());

    // let parsedJob = await cronJob.parseJobID(firstJob);
    // console.log('  Shceduled for:', formatDate(parsedJob['0'].toString()));

    // await cronJob.executeNextJobIfAvailable().should.be.fulfilled;
    //DOES NOT WORK
    // await proxy.executeScheduledJobs().should.be.fulfilled;
    //WORKS, IT EXECUTES A JOB
    //await proxy.executeJob(jobIdGame2).should.be.fulfilled;

    let allJobs = await cronJob.getAllJobs.call();

    console.log('\nAll Jobs in cronjob linked list: ');
    allJobs.map(e => {
      console.log('Job: ', e.toString());
    })
    
    let added = await cronJob.getPastEvents('JobAdded', {
      fromBlock: 0,
      toBlock: "latest"
    });

    console.log('\n==== ADDED JOBS:', added.length);
    added.map(e => {
      console.log('\n  Job Id:', e.returnValues.jobId);
    })

    let executed = await cronJob.getPastEvents('JobExecuted', {
      fromBlock: 0,
      toBlock: "latest"
    });    

    console.log('\n==== EXECUTED JOBS:', executed.length);
    executed.map(e => {
      console.log('\n  Job Id:', e.returnValues.jobId);
    })   

    let failed = await cronJob.getPastEvents('JobFailed', {
      fromBlock: 0,
      toBlock: "latest"
    });

    console.log('\n==== FAILED JOBS:', failed.length);
    failed.map(e => {
      console.log('\n  Job Id:', e.returnValues.jobId);
    })

    let deleted = await cronJob.getPastEvents('JobDeleted', {
      fromBlock: 0,
      toBlock: "latest"
    });

    console.log('\n==== DELETED JOBS:', deleted.length);
    deleted.map(e => {
      console.log('\n  Job Id:', e.returnValues.jobId);
    })

    let execFailed = await proxy.getPastEvents('CronJobExecutionFailed',{
      fromBlock: 0,
      toBlock: "latest"
    });

    console.log('\n==== EXEC FAILED JOBS:', execFailed.length);

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

    //Game cancelled, no more participants added
    // await proxy.execute('GameManager', setMessage(gameManager, 'participate',
    //   [2, gamePlayers.playerBlack]), { from: accounts[17] }).should.not.be.fulfilled;

  })

})

