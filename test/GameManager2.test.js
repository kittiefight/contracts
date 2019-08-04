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
  endowmentDB, distribution, forfeiter, scheduler, betting, hitsResolve,
  rarityCalculator, kittieHELL, kittieHellDB, getterDB, setterDB, gameManager,
  cronJob, escrow

//Kitty Ids
const kitties = [0, 1001, 1555108, 1267904, 454545, 333, 6666];

//Civic Ids
const cividIds = [0, 1, 2, 3, 4, 5, 6];

gameStates = ['WAITING', 'PREGAME', 'MAINGAME', 'GAMEOVER', 'CLAIMING'];
potStates = ['CREATED', 'ASSIGNED', 'SCHEDULED', 'STARTED', 'FORFEITED', 'CLAIMING', 'DISSOLVED']
const GameState = {
  WAITING: 0,
  PRE_GAME: 1,
  MAIN_GAME: 2,
  GAME_OVER: 3,
  CLAIMING: 4,
  KITTIE_HELL: 5,
  CANCELLED: 6
}

// ======== GAME VARS AND FEES ================ //
const LISTING_FEE = new BigNumber(web3.utils.toWei("1000", "ether"));
const TICKET_FEE = new BigNumber(web3.utils.toWei("100", "ether"));
const BETTING_FEE = new BigNumber(web3.utils.toWei("100", "ether"));
const MIN_CONTRIBUTORS = 2
const REQ_NUM_MATCHES = 2
const GAME_PRESTART = 45 // 45 secs for quick test
const GAME_DURATION = 60 // games last 1 min
const ETH_PER_GAME = new BigNumber(web3.utils.toWei("10", "ether"));
const TOKENS_PER_GAME = new BigNumber(web3.utils.toWei("10000", "ether"));
const GAME_TIMES = 120 //Scheduled games 2 min apart
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
// ============================================== //

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

function formatDate(timestamp)
{
    let date = new Date(null);
    date.setSeconds(timestamp);
    return date.toTimeString().replace(/.*(\d{2}:\d{2}:\d{2}).*/, "$1");
}

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
    cronJobTarget= await CronJobTarget.deployed();


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

  it.skip('adds contract addresses to contract manager', async () => {
    await proxy.addContract('TimeContract', dateTime.address)
    await proxy.addContract('GenericDB', genericDB.address)
    await proxy.addContract('CryptoKitties', cryptoKitties.address);
    await proxy.addContract('SuperDAOToken', superDaoToken.address);
    await proxy.addContract('KittieFightToken', kittieFightToken.address);
    await proxy.addContract('ProfileDB', profileDB.address);
    await proxy.addContract('RoleDB', roleDB.address);
    await proxy.addContract('Register', register.address)
    await proxy.addContract('GameVarAndFee', gameVarAndFee.address)
    await proxy.addContract('EndowmentFund', endowmentFund.address)
    await proxy.addContract('EndowmentDB', endowmentDB.address)
    await proxy.addContract('Forfeiter', forfeiter.address)
    await proxy.addContract('Scheduler', scheduler.address)
    await proxy.addContract('Betting', betting.address)
    await proxy.addContract('HitsResolve', hitsResolve.address)
    await proxy.addContract('RarityCalculator', rarityCalculator.address)
    await proxy.addContract('GMSetterDB', setterDB.address)
    await proxy.addContract('GMGetterDB', getterDB.address)
    await proxy.addContract('GameManager', gameManager.address)
    await proxy.addContract('GameStore', gameStore.address)
    await proxy.addContract('GameCreation', gameCreation.address)
    await proxy.addContract('CronJob', cronJob.address)
    await proxy.addContract('FreezeInfo', freezeInfo.address);
    await proxy.addContract('CronJobTarget', cronJobTarget.address);
    await proxy.addContract('KittieHell', kittieHELL.address)
    await proxy.addContract('KittieHellDB', kittieHellDB.address)
    

  })

  it.skip('sets proxy in contracts', async () => {
    await genericDB.setProxy(proxy.address)
    await profileDB.setProxy(proxy.address);
    await roleDB.setProxy(proxy.address);
    await setterDB.setProxy(proxy.address)
    await getterDB.setProxy(proxy.address)
    await endowmentFund.setProxy(proxy.address)
    await endowmentDB.setProxy(proxy.address)
    await gameVarAndFee.setProxy(proxy.address)
    await forfeiter.setProxy(proxy.address)
    await scheduler.setProxy(proxy.address)
    await betting.setProxy(proxy.address)
    await hitsResolve.setProxy(proxy.address)
    await rarityCalculator.setProxy(proxy.address)
    await register.setProxy(proxy.address)
    await gameManager.setProxy(proxy.address)
    await gameStore.setProxy(proxy.address)
    await gameCreation.setProxy(proxy.address)
    await cronJob.setProxy(proxy.address)
    await kittieHELL.setProxy(proxy.address)
    await kittieHellDB.setProxy(proxy.address)
    await cronJobTarget.setProxy(proxy.address);
    await freezeInfo.setProxy(proxy.address);

  })

  it.skip('initializes contract variables', async () => {
    await gameStore.initialize()
    await gameCreation.initialize()
    await forfeiter.initialize()
    await scheduler.initialize()
    await register.initialize()
    await gameManager.initialize()
    await getterDB.initialize()
    await setterDB.initialize()
    await endowmentFund.initialize()
    await kittieHellDB.setKittieHELL()
    await kittieHELL.initialize()
    await hitsResolve.initialize()
  })

  it.skip('sets super admin address', async() => {
    await register.addSuperAdmin(accounts[0])
  })

  it.skip('initialize escrow upgrade', async() => {
    await endowmentFund.initUpgradeEscrow(escrow.address)
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
    console.log('\n==== LISTED KITTIES: ',listed.length);
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
      console.log('    Black Fighter ', e.returnValues.kittieBlack)
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
    console.log('\n==== LISTED KITTIES: ',listed.length);
    listed.length.should.be.equal(0);
  })

  it('bettors can participate in a created game', async () => {

    let { gameId, playerRed, playerBlack } = gameDetails;

    console.log(`\n==== PLAYING GAME ${gameId} ===`);    

    let currentState = await getterDB.getGameState(gameId)
    console.log('\n==== NEW STATE: ', gameStates[currentState.toNumber()])

    console.log('\n==== ADDING SUPPORTERS TO THE GAME ');

    await proxy.execute('GameManager', setMessage(gameManager, 'participate',
      [gameId, playerRed]), { from: accounts[5] }).should.be.fulfilled;

    //New Supporter added
    let events = await gameManager.getPastEvents("NewSupporter", { fromBlock: 0, toBlock: "latest" });
    assert.equal(events.length, 1);


    //Cannot support the opponent too
    await proxy.execute('GameManager', setMessage(gameManager, 'participate',
      [gameId, playerBlack]), { from: accounts[5] }).should.be.rejected;

    // adds more supporters for player red
    for (let i = 6; i < 12; i++) {
      await proxy.execute('GameManager', setMessage(gameManager, 'participate',
        [gameId, playerRed]), { from: accounts[i] }).should.be.fulfilled;
    }

    // adds more supporters for player red
    for (let i = 12; i < 18; i++) {
      await proxy.execute('GameManager', setMessage(gameManager, 'participate',
        [gameId, playerBlack]), { from: accounts[i] }).should.be.fulfilled;
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
    console.log('\n==== WAITING FOR PREGAME TIME')

    let block = await dateTime.getBlockTimeStamp();
    console.log('\nblocktime: ', formatDate(block))
      
    while(block < gameDetails.preStartTime){
      block = await dateTime.getBlockTimeStamp();
      await timeout(3);
    }

    let { gameId, playerRed, playerBlack } = gameDetails;

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
    console.log('\n==== NEW STATE: ', gameStates[gameInfo.state.toNumber()])

    //Check players start button
    gameInfo.pressedStart[0].should.be.true
    gameInfo.pressedStart[1].should.be.true

    //Game starts
    gameInfo.state.toNumber().should.be.equal(GameState.MAIN_GAME)
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
    // 50.000 + 4*1000 + 14*100
    let expected = new BigNumber(web3.utils.toWei("55400", "ether"));
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

  it('initializing last 5 bets (temporal)', async () => { 
    
    let { gameId, playerRed, playerBlack } = gameDetails;

    for (let i = 0; i < 5; i++) {
      await betting.fillBets(gameId, playerRed, 0)
      await betting.fillBets(gameId, playerBlack, 0)
    }
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

    for (let i = 6; i < 18; i++) {
      // let supportedPlayer = i < 10 ? playerRed : playerBlack;
      let betAmount = randomValue()
      let bettor = accounts[i]
      let supporterInfo = await getterDB.getSupporterInfo(gameId, accounts[i])
      let supportedPlayer = supporterInfo.supportedPlayer;
      let player;

      if (supportedPlayer == playerRed) {
        player = 'RED';
        (redBetStore.has(bettor)) ?
          redBetStore.set(bettor, redBetStore.get(bettor) + betAmount) :
          redBetStore.set(bettor, betAmount)
          
      } else {
        player = 'BLACK';
        (blackBetStore.has(bettor)) ?
          blackBetStore.set(bettor, blackBetStore.get(bettor) + betAmount) :
          blackBetStore.set(bettor, betAmount)
      }     
      

      await proxy.execute('GameManager', setMessage(gameManager, 'bet',
        [gameId, randomValue()]), { from: bettor, value: web3.utils.toWei(String(betAmount)) }).should.be.fulfilled;

      let betEvents = await betting.getPastEvents('BetPlaced', {
        filter: {gameId},
        fromBlock: 0, 
        toBlock: "latest" 
      })
      

      betDetails = betEvents[betEvents.length -1].returnValues;
      console.log(`\n==== NEW BET FOR ${player} ====`);
      console.log('Amount:', web3.utils.fromWei(betDetails._lastBetAmount), 'ETH');
      console.log('Bettor:', betDetails._bettor);
      console.log('Attack Hash:', betDetails.attackHash);
      console.log('Blocked?:', betDetails.isBlocked);
      console.log(`Defense ${player}:`, betDetails.defenseLevelSupportedPlayer);
      console.log('Defense Opponent:', betDetails.defenseLevelOpponent);

      let lastBetTimestamp = await betting.lastBetTimestamp(gameId,supportedPlayer);
      console.log('Timestamp last Bet: ',lastBetTimestamp.toString());

      

      totalBetAmount  = totalBetAmount + betAmount;
      await timeout(1);
    }
  }) 

  it('correctly adds all bets for each corner', async () => {
    let block = await dateTime.getBlockTimeStamp();
      console.log('\nblocktime: ', formatDate(block))

    let { gameId, playerRed, playerBlack } = gameDetails;

    let redTotal = await getterDB.getTotalBet(gameId, playerRed)
    let blackTotal = await getterDB.getTotalBet(gameId, playerBlack)
    let actualTotalBet = redTotal.add(blackTotal)

    console.log(`\n==== TOTAL BETS: ${totalBetAmount} ETH `)

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
    
    console.log('\n==== WAITING FOR GAME OVER')

    let block = await dateTime.getBlockTimeStamp();
      
    while(block < gameDetails.endTime){
      block = await dateTime.getBlockTimeStamp();
      await timeout(2);
    } 

    let { gameId } = gameDetails;  

    await proxy.execute('GameManager', setMessage(gameManager, 'bet',
      [gameId, randomValue()]), { from: accounts[7], value: web3.utils.toWei('1') }).should.be.fulfilled;
    
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
      filter: {gameId},
      fromBlock: 0,
      toBlock: 'latest'
    })
    
    let {pointsBlack, pointsRed, loser} = gameEnd[0].returnValues;

    let winners = await getterDB.getWinners(gameId);

    gameDetails.winners = winners;
    gameDetails.loser = loser;

    let corner = (winners.winner === playerBlack) ? "Black Corner":"Red Corner"

    console.log(`\n==== WINNER: ${corner} ==== `)
    console.log(`   Winner: ${winners.winner}   `);
    console.log(`   TopBettor: ${winners.topBettor}   `)
    console.log(`   SecondTopBettor: ${winners.secondTopBettor}   `)
    console.log('')
    console.log(`   Points Black: ${pointsBlack/100}   `);
    console.log(`   Point Red: ${pointsRed/100}   `);
    console.log('=======================\n')

    await timeout(1);
    
  })
  
  it('correct honeypot info', async () => {

    let { gameId } = gameDetails;

    let honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

    console.log(`\n==== HONEPOT INFO ==== `)
    console.log(`     InitialEtH: ${web3.utils.fromWei(honeyPotInfo.initialEth.toString())}   `);
    console.log(`     TotalETH: ${web3.utils.fromWei(honeyPotInfo.ethTotal.toString())}   `);
    console.log(`     TotalKTY: ${web3.utils.fromWei(honeyPotInfo.ktyTotal.toString())}   `);
    console.log('=======================\n')

    //1 ether from the last bet that ended game
    honeyPotInfo.ethTotal.toString().should.be.equal(
      String(ETH_PER_GAME.add(new BigNumber(web3.utils.toWei(String(totalBetAmount+1)))))
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
    console.log('    ETH: ',  web3.utils.fromWei(endowmentShare.winningsETH.toString()));
    console.log('    KTY: ',  web3.utils.fromWei(endowmentShare.winningsKTY.toString()));
    
    let bettors = await gameManager.getPastEvents("NewSupporter", { 
      filter: {gameId}, 
      fromBlock: 0, 
      toBlock: "latest" 
    });

    

    //Get list of other bettors
    supporters = bettors
      .map(e => e.returnValues) 
      .filter(e => e.playerSupported === winners.winner)
      .filter(e => e.supporter !== winners.topBettor)
      .filter(e => e.supporter !== winners.secondTopBettor)
      .map( e => e.supporter) 
    
    gameDetails.supporters = supporters;

    console.log(`\n  OTHER BETTORS SHARE: ${rates[3].toString()} %`);
    console.log('   List: ', supporters) 
    for(let i=0; i<supporters.length; i++){
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
    let { gameId, supporters } = gameDetails;    

    let block = await dateTime.getBlockTimeStamp();
    console.log('\nblocktime: ', formatDate(block))

    let potState = await endowmentDB.getHoneypotState(gameId);
    console.log('\n==== HONEYPOT DISSOLUTION TIME: ',formatDate(potState.claimTime.toNumber()))

    let winners = await getterDB.getWinners(gameId);
    let winnerShare = await endowmentFund.getWinnerShare(gameId, winners.winner);     

    let balance = await kittieFightToken.balanceOf(winners.winner)
    balance = Number(web3.utils.fromWei(balance.toString()));   
  
    // WINNER CLAIMING
    await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'claim',
    [gameId]), { from: winners.winner }).should.be.fulfilled;
    let withdrawalState = await endowmentFund.getWithdrawalState(gameId,  winners.winner);
    console.log('\nWinner withdrew funds? ', withdrawalState)

    let claims = await endowmentFund.getPastEvents('WinnerClaimed', { 
      filter: {gameId}, 
      fromBlock: 0, 
      toBlock: "latest" 
    });
    claims.length.should.be.equal(1);

    let newBalance = await kittieFightToken.balanceOf(winners.winner)
    // balance.should.be.equal(newBalance.add(winnerShare.winningsKTY))
    newBalance = Number(web3.utils.fromWei(newBalance.toString()));
    let winningsKTY = Number(web3.utils.fromWei(winnerShare.winningsKTY.toString()));

    newBalance.should.be.equal(balance + winningsKTY);

    // TOP BETTOR CLAIMING
    await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'claim',
    [gameId]), { from: winners.topBettor }).should.be.fulfilled;
    withdrawalState = await endowmentFund.getWithdrawalState(gameId,  winners.topBettor);
    console.log('Top Bettor withdrew funds? ', withdrawalState)


    // SECOND TOP BETTOR CLAIMING
    await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'claim',
    [gameId]), { from: winners.secondTopBettor }).should.be.fulfilled;
    withdrawalState = await endowmentFund.getWithdrawalState(gameId,  winners.secondTopBettor);
    console.log('Second Top Bettor withdrew funds? ', withdrawalState)

    // OTHER BETTOR CLAIMING
    await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'claim',
    [gameId]), { from: supporters[1]}).should.be.fulfilled;
    withdrawalState = await endowmentFund.getWithdrawalState(gameId,  supporters[1]);
    console.log('Other Bettor withdrew funds? ', withdrawalState)

    claims = await endowmentFund.getPastEvents('WinnerClaimed', { 
      filter: {gameId}, 
      fromBlock: 0, 
      toBlock: "latest" 
    });

    claims.length.should.be.equal(4);


  })

  it('check game kitties dead status', async () => {
    
    let { playerBlack, kittieBlack, kittieRed, winners } = gameDetails; 

    if( gameDetails.loser === playerBlack) {
      loserKitty = kittieBlack;
      winnerKitty = kittieRed;
    }
    else{
      loserKitty = kittieRed;
      winnerKitty = kittieBlack
    }

    gameDetails.loserKitty = loserKitty;

    //Loser Kittie Dead
    let isKittyDead = await kittieHELL.isKittyDead(loserKitty);
    isKittyDead.should.be.true;

    winnerOwner = await cryptoKitties.ownerOf(winnerKitty);
    winnerOwner.should.be.equal( winners.winner);

  })

  it('pay for resurrection', async () => {

    console.log('\n==== KITTIE HELL: ')
    
    let { loserKitty, loser } = gameDetails; 
    
    let resurrectionCost = await kittieHELL.getResurrectionCost(loserKitty);

    console.log('Resurrection Cost: ',String(web3.utils.fromWei(resurrectionCost.toString())), 'KTY')

    await kittieFightToken.approve(endowmentFund.address, resurrectionCost, 
      { from: loser }).should.be.fulfilled;  

    await proxy.execute('KittieHell', setMessage(kittieHELL, 'payForResurrection',
      [loserKitty]), { from: loser }).should.be.fulfilled;

    let owner = await cryptoKitties.ownerOf(loserKitty)
    //Ownership back to address, not kittieHell
    owner.should.be.equal(loser);

  })

})

// original data based on 
// https://api.cryptokitties.co/cattributes
// RarityCalculationsDBs are built based on these original data.
const cattributesData = [
  { description: "totesbasic", type: "pattern", gene: 15, total: "357328" },
  { description: "thicccbrowz", type: "eyes", gene: 7, total: "261737" },
  { description: "pouty", type: "mouth", gene: 9, total: "239894" },
  {
    description: "granitegrey",
    type: "colortertiary",
    gene: 4,
    total: "231062",
  },
  {
    description: "kittencream",
    type: "colortertiary",
    gene: 6,
    total: "228748",
  },
  { description: "happygokitty", type: "mouth", gene: 14, total: "217675" },
  {
    description: "royalpurple",
    type: "colorsecondary",
    gene: 6,
    total: "208081",
  },
  {
    description: "swampgreen",
    type: "colorsecondary",
    gene: 8,
    total: "207611",
  },
  {
    description: "lemonade",
    type: "colorsecondary",
    gene: 13,
    total: "198827",
  },
  {
    description: "greymatter",
    type: "colorprimary",
    gene: 10,
    total: "197753",
  },
  { description: "coffee", type: "colorsecondary", gene: 12, total: "187877" },
  { description: "soserious", type: "mouth", gene: 15, total: "181556" },
  { description: "ragdoll", type: "body", gene: 15, total: "178290" },
  { description: "crazy", type: "eyes", gene: 6, total: "175398" },
  { description: "luckystripe", type: "pattern", gene: 9, total: "173368" },
  {
    description: "cottoncandy",
    type: "colorprimary",
    gene: 4,
    total: "170075",
  },
  { description: "strawberry", type: "coloreyes", gene: 7, total: "158208" },
  { description: "mintgreen", type: "coloreyes", gene: 3, total: "152137" },
  { description: "amur", type: "pattern", gene: 10, total: "151854" },
  { description: "mauveover", type: "colorprimary", gene: 5, total: "151251" },
  { description: "munchkin", type: "body", gene: 12, total: "145716" },
  { description: "selkirk", type: "body", gene: 1, total: "143269" },
  { description: "sizzurp", type: "coloreyes", gene: 5, total: "139728" },
  { description: "shadowgrey", type: "colorprimary", gene: 0, total: "134554" },
  { description: "sphynx", type: "body", gene: 13, total: "132919" },
  {
    description: "bananacream",
    type: "colorprimary",
    gene: 15,
    total: "126658",
  },
  { description: "saycheese", type: "mouth", gene: 10, total: "124120" },
  { description: "simple", type: "eyes", gene: 5, total: "122615" },
  { description: "wiley", type: "eyes", gene: 14, total: "121061" },
  { description: "topaz", type: "coloreyes", gene: 2, total: "119943" },
  { description: "spock", type: "pattern", gene: 12, total: "119683" },
  { description: "icy", type: "colortertiary", gene: 3, total: "117836" },
  {
    description: "chocolate",
    type: "colorsecondary",
    gene: 14,
    total: "113092",
  },
  {
    description: "egyptiankohl",
    type: "colorsecondary",
    gene: 2,
    total: "112992",
  },
  { description: "tiger", type: "pattern", gene: 1, total: "112653" },
  {
    description: "purplehaze",
    type: "colortertiary",
    gene: 10,
    total: "110145",
  },
  {
    description: "sandalwood",
    type: "colortertiary",
    gene: 1,
    total: "106106",
  },
  { description: "sapphire", type: "coloreyes", gene: 8, total: "105881" },
  { description: "himalayan", type: "body", gene: 11, total: "105273" },
  { description: "slyboots", type: "eyes", gene: 13, total: "104984" },
  { description: "thundergrey", type: "coloreyes", gene: 0, total: "104672" },
  { description: "rascal", type: "pattern", gene: 2, total: "103387" },
  { description: "chronic", type: "eyes", gene: 12, total: "103102" },
  { description: "birman", type: "body", gene: 3, total: "102891" },
  { description: "cyan", type: "coloreyes", gene: 15, total: "102604" },
  { description: "wonky", type: "eyes", gene: 1, total: "100311" },
  { description: "aquamarine", type: "colorprimary", gene: 6, total: "100184" },
  { description: "frosting", type: "colortertiary", gene: 15, total: "99477" },
  { description: "ragamuffin", type: "body", gene: 14, total: "97745" },
  { description: "chestnut", type: "coloreyes", gene: 6, total: "97512" },
  { description: "gold", type: "coloreyes", gene: 1, total: "96770" },
  { description: "orangesoda", type: "colorprimary", gene: 3, total: "96512" },
  { description: "wuvme", type: "mouth", gene: 2, total: "96487" },
  { description: "raisedbrow", type: "eyes", gene: 19, total: "96319" },
  { description: "grim", type: "mouth", gene: 11, total: "95561" },
  { description: "cymric", type: "body", gene: 9, total: "94958" },
  { description: "googly", type: "eyes", gene: 3, total: "93886" },
  {
    description: "emeraldgreen",
    type: "colortertiary",
    gene: 7,
    total: "93291",
  },
  { description: "cinderella", type: "colorprimary", gene: 9, total: "92005" },
  { description: "koladiviya", type: "body", gene: 4, total: "91854" },
  { description: "salmon", type: "colorprimary", gene: 1, total: "90701" },
  {
    description: "barkbrown",
    type: "colorsecondary",
    gene: 11,
    total: "83274",
  },
  { description: "whixtensions", type: "mouth", gene: 0, total: "80845" },
  { description: "coralsunrise", type: "coloreyes", gene: 11, total: "78633" },
  {
    description: "azaleablush",
    type: "colortertiary",
    gene: 12,
    total: "77153",
  },
  { description: "bobtail", type: "body", gene: 5, total: "77039" },
  { description: "scarlet", type: "colorsecondary", gene: 10, total: "75289" },
  { description: "dahlia", type: "coloreyes", gene: 10, total: "68885" },
  { description: "beard", type: "mouth", gene: 8, total: "67190" },
  { description: "rorschach", type: "pattern", gene: 6, total: "66836" },
  { description: "belleblue", type: "colortertiary", gene: 0, total: "66308" },
  { description: "cashewmilk", type: "colortertiary", gene: 5, total: "64540" },
  { description: "tongue", type: "mouth", gene: 23, total: "64236" },
  { description: "spangled", type: "pattern", gene: 7, total: "62049" },
  { description: "cloudwhite", type: "colorprimary", gene: 16, total: "61823" },
  { description: "gerbil", type: "mouth", gene: 3, total: "61148" },
  { description: "calicool", type: "pattern", gene: 8, total: "61079" },
  { description: "brownies", type: "colorprimary", gene: 12, total: "60039" },
  { description: "skyblue", type: "colorsecondary", gene: 22, total: "53131" },
  { description: "savannah", type: "body", gene: 0, total: "50522" },
  { description: "olive", type: "coloreyes", gene: 12, total: "50428" },
  { description: "pixiebob", type: "body", gene: 7, total: "50346" },
  { description: "leopard", type: "pattern", gene: 4, total: "49552" },
  {
    description: "morningglory",
    type: "colortertiary",
    gene: 14,
    total: "49516",
  },
  { description: "ganado", type: "pattern", gene: 3, total: "47030" },
  { description: "laperm", type: "body", gene: 22, total: "46224" },
  { description: "bloodred", type: "colortertiary", gene: 19, total: "43398" },
  { description: "kalahari", type: "colortertiary", gene: 8, total: "42713" },
  { description: "confuzzled", type: "mouth", gene: 4, total: "42440" },
  {
    description: "doridnudibranch",
    type: "coloreyes",
    gene: 13,
    total: "42250",
  },
  { description: "asif", type: "eyes", gene: 11, total: "41891" },
  { description: "oldlace", type: "colorprimary", gene: 18, total: "41208" },
  { description: "parakeet", type: "coloreyes", gene: 14, total: "41064" },
  { description: "limegreen", type: "coloreyes", gene: 17, total: "38424" },
  { description: "peach", type: "colortertiary", gene: 2, total: "37550" },
  { description: "rollercoaster", type: "mouth", gene: 7, total: "37170" },
  { description: "lilac", type: "colorsecondary", gene: 4, total: "35515" },
  { description: "swarley", type: "eyes", gene: 0, total: "35461" },
  { description: "jaguar", type: "pattern", gene: 11, total: "33928" },
  { description: "shale", type: "colortertiary", gene: 9, total: "32405" },
  { description: "otaku", type: "eyes", gene: 4, total: "32399" },
  { description: "fangtastic", type: "mouth", gene: 12, total: "31869" },
  { description: "apricot", type: "colorsecondary", gene: 5, total: "31322" },
  { description: "stunned", type: "eyes", gene: 15, total: "30699" },
  { description: "nachocheez", type: "colorprimary", gene: 7, total: "30052" },
  {
    description: "poisonberry",
    type: "colorsecondary",
    gene: 3,
    total: "28719",
  },
  { description: "tigerpunk", type: "pattern", gene: 20, total: "27526" },
  { description: "serpent", type: "eyes", gene: 2, total: "27220" },
  { description: "sass", type: "eyes", gene: 22, total: "26666" },
  { description: "dali", type: "mouth", gene: 20, total: "25472" },
  { description: "henna", type: "pattern", gene: 21, total: "25407" },
  { description: "impish", type: "mouth", gene: 5, total: "25067" },
  { description: "norwegianforest", type: "body", gene: 16, total: "24860" },
  {
    description: "springcrocus",
    type: "colorsecondary",
    gene: 1,
    total: "24317",
  },
  { description: "chartreux", type: "body", gene: 10, total: "23641" },
  { description: "onyx", type: "colorprimary", gene: 25, total: "23223" },
  { description: "forgetmenot", type: "coloreyes", gene: 9, total: "23046" },
  { description: "bubblegum", type: "coloreyes", gene: 19, total: "22469" },
  { description: "moue", type: "mouth", gene: 13, total: "21851" },
  { description: "siberian", type: "body", gene: 8, total: "21823" },
  { description: "chantilly", type: "body", gene: 2, total: "20909" },
  { description: "camo", type: "pattern", gene: 5, total: "20427" },
  { description: "fabulous", type: "eyes", gene: 18, total: "19858" },
  {
    description: "missmuffett",
    type: "colortertiary",
    gene: 13,
    total: "19413",
  },
  { description: "baddate", type: "eyes", gene: 10, total: "19360" },
  { description: "violet", type: "colorsecondary", gene: 9, total: "18679" },
  { description: "elk", type: "wild", gene: 17, total: "17707" },
  { description: "salty", type: "environment", gene: 16, total: "17489" },
  { description: "caffeine", type: "eyes", gene: 8, total: "16555" },
  {
    description: "padparadscha",
    type: "colorsecondary",
    gene: 7,
    total: "16226",
  },
  { description: "wolfgrey", type: "colorsecondary", gene: 20, total: "15757" },
  { description: "persian", type: "body", gene: 23, total: "14624" },
  { description: "eclipse", type: "coloreyes", gene: 23, total: "14536" },
  { description: "martian", type: "colorprimary", gene: 27, total: "14436" },
  { description: "tundra", type: "colorprimary", gene: 11, total: "14348" },
  { description: "mittens", type: "pattern", gene: 13, total: "14292" },
  { description: "manul", type: "body", gene: 6, total: "14032" },
  { description: "daffodil", type: "colortertiary", gene: 16, total: "13619" },
  { description: "cerulian", type: "colorsecondary", gene: 21, total: "13586" },
  {
    description: "butterscotch",
    type: "colorsecondary",
    gene: 15,
    total: "13361",
  },
  { description: "hintomint", type: "colorprimary", gene: 14, total: "13248" },
  { description: "wasntme", type: "mouth", gene: 1, total: "13053" },
  { description: "highlander", type: "body", gene: 18, total: "12969" },
  { description: "neckbeard", type: "mouth", gene: 26, total: "12636" },
  { description: "verdigris", type: "colorprimary", gene: 23, total: "12274" },
  { description: "belch", type: "mouth", gene: 6, total: "12168" },
  { description: "dippedcone", type: "pattern", gene: 18, total: "11874" },
  { description: "alien", type: "eyes", gene: 17, total: "11654" },
  { description: "dragonwings", type: "wild", gene: 28, total: "11591" },
  { description: "koala", type: "colorprimary", gene: 19, total: "11574" },
  { description: "dragontail", type: "wild", gene: 24, total: "11366" },
  { description: "harbourfog", type: "colorprimary", gene: 8, total: "11103" },
  { description: "wingtips", type: "eyes", gene: 25, total: "10855" },
  { description: "flapflap", type: "wild", gene: 22, total: "10740" },
  {
    description: "patrickstarfish",
    type: "colortertiary",
    gene: 23,
    total: "10688",
  },
  {
    description: "dragonfruit",
    type: "colorprimary",
    gene: 13,
    total: "10569",
  },
  { description: "thunderstruck", type: "pattern", gene: 17, total: "10122" },
  {
    description: "safetyvest",
    type: "colorsecondary",
    gene: 17,
    total: "10102",
  },
  { description: "toyger", type: "body", gene: 26, total: "9949" },
  { description: "arcreactor", type: "pattern", gene: 22, total: "9660" },
  { description: "ducky", type: "wild", gene: 18, total: "9581" },
  { description: "sweetmeloncakes", type: "eyes", gene: 23, total: "9279" },
  { description: "sully", type: "colortertiary", gene: 28, total: "9253" },
  {
    description: "peppermint",
    type: "colorsecondary",
    gene: 24,
    total: "9249",
  },
  { description: "roadtogold", type: "environment", gene: 26, total: "9198" },
  { description: "wowza", type: "eyes", gene: 9, total: "9071" },
  { description: "cheeky", type: "mouth", gene: 16, total: "8966" },
  { description: "lynx", type: "body", gene: 20, total: "8832" },
  { description: "pumpkin", type: "coloreyes", gene: 16, total: "8597" },
  { description: "atlantis", type: "colortertiary", gene: 20, total: "8502" },
  { description: "shamrock", type: "colorprimary", gene: 29, total: "8351" },
  { description: "periwinkle", type: "colortertiary", gene: 22, total: "7998" },
  { description: "buzzed", type: "eyes", gene: 27, total: "7992" },
  { description: "manx", type: "body", gene: 27, total: "7932" },
  { description: "littlefoot", type: "wild", gene: 16, total: "7768" },
  { description: "starstruck", type: "mouth", gene: 17, total: "7700" },
  { description: "unicorn", type: "wild", gene: 27, total: "7639" },
  { description: "grimace", type: "mouth", gene: 21, total: "7596" },
  { description: "daemonhorns", type: "wild", gene: 23, total: "7568" },
  { description: "hotrod", type: "pattern", gene: 26, total: "7487" },
  { description: "hanauma", type: "colortertiary", gene: 11, total: "7295" },
  { description: "highsociety", type: "pattern", gene: 19, total: "7120" },
  { description: "royalblue", type: "colorsecondary", gene: 26, total: "6995" },
  { description: "redvelvet", type: "colorprimary", gene: 22, total: "6984" },
  { description: "mainecoon", type: "body", gene: 21, total: "6973" },
  {
    description: "finalfrontier",
    type: "environment",
    gene: 21,
    total: "6775",
  },
  { description: "pearl", type: "colorsecondary", gene: 29, total: "6743" },
  { description: "palejade", type: "coloreyes", gene: 21, total: "6396" },
  { description: "kaleidoscope", type: "coloreyes", gene: 30, total: "6126" },
  { description: "razzledazzle", type: "pattern", gene: 25, total: "6072" },
  { description: "allyouneed", type: "pattern", gene: 27, total: "6035" },
  { description: "universe", type: "colorsecondary", gene: 25, total: "5962" },
  {
    description: "turtleback",
    type: "colorsecondary",
    gene: 18,
    total: "5608",
  },
  { description: "satiated", type: "mouth", gene: 27, total: "5522" },
  { description: "pinefresh", type: "coloreyes", gene: 22, total: "5508" },
  {
    description: "inflatablepool",
    type: "colorsecondary",
    gene: 28,
    total: "5420",
  },
  { description: "firedup", type: "eyes", gene: 26, total: "5410" },
  { description: "mekong", type: "body", gene: 17, total: "5270" },
  { description: "meowgarine", type: "colorprimary", gene: 2, total: "5248" },
  { description: "chameleon", type: "eyes", gene: 16, total: "5222" },
  { description: "hyacinth", type: "colorprimary", gene: 26, total: "4885" },
  { description: "daemonwings", type: "wild", gene: 20, total: "4751" },
  { description: "buttercup", type: "colortertiary", gene: 18, total: "4744" },
  { description: "fox", type: "body", gene: 24, total: "4697" },
  { description: "yokel", type: "mouth", gene: 24, total: "4565" },
  {
    description: "twilightsparkle",
    type: "coloreyes",
    gene: 20,
    total: "4534",
  },
  { description: "splat", type: "pattern", gene: 16, total: "4530" },
  { description: "flamingo", type: "colortertiary", gene: 17, total: "4485" },
  { description: "seafoam", type: "colortertiary", gene: 24, total: "4384" },
  {
    description: "rosequartz",
    type: "colorsecondary",
    gene: 19,
    total: "4380",
  },
  { description: "vigilante", type: "pattern", gene: 0, total: "4318" },
  { description: "juju", type: "environment", gene: 18, total: "4210" },
  { description: "cobalt", type: "colortertiary", gene: 25, total: "4173" },
  { description: "dioscuri", type: "coloreyes", gene: 29, total: "4090" },
  { description: "topoftheworld", type: "mouth", gene: 25, total: "4087" },
  { description: "tinybox", type: "environment", gene: 19, total: "3738" },
  { description: "avatar", type: "pattern", gene: 28, total: "3644" },
  { description: "glacier", type: "colorprimary", gene: 21, total: "3592" },
  { description: "samwise", type: "mouth", gene: 18, total: "3560" },
  { description: "trioculus", type: "wild", gene: 19, total: "3552" },
  {
    description: "mintmacaron",
    type: "colortertiary",
    gene: 27,
    total: "3477",
  },
  { description: "garnet", type: "colorsecondary", gene: 23, total: "3356" },
  { description: "bornwithit", type: "eyes", gene: 28, total: "3328" },
  { description: "cyborg", type: "colorsecondary", gene: 0, total: "2757" },
  { description: "hotcocoa", type: "colorprimary", gene: 28, total: "2695" },
  { description: "wyrm", type: "wild", gene: 30, total: "2677" },
  { description: "drift", type: "environment", gene: 23, total: "2623" },
  { description: "alicorn", type: "wild", gene: 29, total: "2619" },
  { description: "walrus", type: "mouth", gene: 28, total: "2517" },
  { description: "lavender", type: "colorprimary", gene: 20, total: "2504" },
  { description: "majestic", type: "mouth", gene: 22, total: "2495" },
  { description: "oohshiny", type: "prestige", gene: null, total: "2484" },
  { description: "lykoi", type: "body", gene: 28, total: "2320" },
  { description: "drama", type: "eyes", gene: 30, total: "2319" },
  { description: "kurilian", type: "body", gene: 25, total: "2309" },
  { description: "aflutter", type: "wild", gene: 25, total: "2268" },
  { description: "delite", type: "mouth", gene: 30, total: "2170" },
  { description: "frozen", type: "environment", gene: 25, total: "2077" },
  { description: "babypuke", type: "coloreyes", gene: 24, total: "2043" },
  { description: "balinese", type: "body", gene: 19, total: "1930" },
  { description: "oceanid", type: "eyes", gene: 24, total: "1927" },
  {
    description: "prairierose",
    type: "colorsecondary",
    gene: 30,
    total: "1919",
  },
  { description: "tendertears", type: "eyes", gene: 20, total: "1875" },
  { description: "candyshoppe", type: "eyes", gene: 29, total: "1864" },
  { description: "autumnmoon", type: "coloreyes", gene: 26, total: "1855" },
  { description: "hacker", type: "eyes", gene: 21, total: "1845" },
  { description: "myparade", type: "environment", gene: 20, total: "1786" },
  { description: "moonrise", type: "pattern", gene: 30, total: "1754" },
  { description: "gyre", type: "pattern", gene: 29, total: "1686" },
  { description: "isotope", type: "coloreyes", gene: 4, total: "1653" },
  { description: "prism", type: "environment", gene: 29, total: "1600" },
  { description: "ruhroh", type: "mouth", gene: 19, total: "1582" },
  { description: "icicle", type: "colorprimary", gene: 24, total: "1537" },
  { description: "featherbrain", type: "wild", gene: 21, total: "1533" },
  { description: "junglebook", type: "environment", gene: 30, total: "1515" },
  { description: "foghornpawhorn", type: "wild", gene: 26, total: "1467" },
  { description: "scorpius", type: "pattern", gene: 24, total: "1454" },
  { description: "jacked", type: "environment", gene: 27, total: "1432" },
  { description: "cornflower", type: "colorprimary", gene: 17, total: "1398" },
  { description: "firstblush", type: "colorprimary", gene: 30, total: "1381" },
  { description: "purrbados", type: "prestige", gene: null, total: "1344" },
  { description: "floorislava", type: "environment", gene: 28, total: "1286" },
  { description: "hooked", type: "prestige", gene: null, total: "1277" },
  { description: "oasis", type: "coloreyes", gene: 27, total: "1275" },
  { description: "duckduckcat", type: "prestige", gene: null, total: "1249" },
  { description: "dreamcloud", type: "prestige", gene: null, total: "1246" },
  { description: "alpacacino", type: "prestige", gene: null, total: "1220" },
  { description: "gemini", type: "coloreyes", gene: 28, total: "1220" },
  { description: "secretgarden", type: "environment", gene: 24, total: "1186" },
  { description: "mertail", type: "colorsecondary", gene: 27, total: "1185" },
  {
    description: "summerbonnet",
    type: "colortertiary",
    gene: 21,
    total: "1158",
  },
  { description: "liger", type: "body", gene: 30, total: "1149" },
  { description: "dune", type: "environment", gene: 17, total: "1144" },
  { description: "dreamboat", type: "colortertiary", gene: 30, total: "1141" },
  { description: "inaband", type: "prestige", gene: null, total: "1048" },
  { description: "lit", type: "prestige", gene: null, total: "1006" },
  { description: "furball", type: "prestige", gene: null, total: "998" },
  { description: "struck", type: "mouth", gene: 29, total: "961" },
  { description: "wrecked", type: "prestige", gene: null, total: "959" },
  { description: "downbythebay", type: "coloreyes", gene: 25, total: "934" },
  { description: "alpunka", type: "prestige", gene: null, total: "926" },
  { description: "prune", type: "prestige", gene: null, total: "921" },
  { description: "cindylou", type: "prestige", gene: null, total: "905" },
  { description: "burmilla", type: "body", gene: 29, total: "904" },
  { description: "uplink", type: "prestige", gene: null, total: "870" },
  { description: "metime", type: "environment", gene: 22, total: "863" },
  { description: "reindeer", type: "prestige", gene: null, total: "854" },
  { description: "huacool", type: "prestige", gene: null, total: "837" },
  { description: "ooze", type: "colorsecondary", gene: 16, total: "832" },
  {
    description: "mallowflower",
    type: "colortertiary",
    gene: 26,
    total: "809",
  },
  { description: "beatlesque", type: "prestige", gene: null, total: "783" },
  { description: "gauntlet", type: "prestige", gene: null, total: "781" },
  { description: "scratchingpost", type: "prestige", gene: null, total: "772" },
  { description: "holidaycheer", type: "prestige", gene: null, total: "759" },
  { description: "fallspice", type: "colortertiary", gene: 29, total: "758" },
  { description: "bridesmaid", type: "coloreyes", gene: 18, total: "740" },
  { description: "landlubber", type: "prestige", gene: null, total: "711" },
  { description: "squelch", type: "prestige", gene: null, total: "652" },
  { description: "maraud", type: "prestige", gene: null, total: "620" },
  { description: "thatsawrap", type: "prestige", gene: null, total: "615" },
  { description: "fileshare", type: "prestige", gene: null, total: "515" },
  { description: "timbers", type: "prestige", gene: null, total: "472" },
  { description: "catterypack", type: "prestige", gene: null, total: "340" },
  { description: "pawsfree", type: "prestige", gene: null, total: "264" },
  { description: "bionic", type: "prestige", gene: null, total: "195" },
]


// original data based on 
// https://github.com/openblockchains/programming-cryptocollectibles/blob/master/02_genereader.md

const kaiToCattributesData = [
    {
      body: {
        genes: "0-3",
        name: "Fur",
        code: "FU",
        kai: {
          "1": "savannah",
          "2": "selkirk",
          "3": "chantilly",
          "4": "birman",
          "5": "koladiviya",
          "6": "bobtail",
          "7": "manul",
          "8": "pixiebob",
          "9": "siberian",
          a: "cymric",
          b: "chartreux",
          c: "himalayan",
          d: "munchkin",
          e: "sphynx",
          f: "ragamuffin",
          g: "ragdoll",
          h: "norwegianforest",
          i: "mekong",
          j: "highlander",
          k: "balinese",
          m: "lynx",
          n: "mainecoon",
          o: "laperm",
          p: "persian",
          q: "fox",
          r: "kurilian",
          s: "toyger",
          t: "manx",
          u: "lykoi",
          v: "burmilla",
          w: "liger",
          x: "",
        },
      },
    },
    {
      pattern: {
        genes: "4-7",
        name: "Pattern",
        code: "PA",
        kai: {
          "1": "vigilante",
          "2": "tiger",
          "3": "rascal",
          "4": "ganado",
          "5": "leopard",
          "6": "camo",
          "7": "rorschach",
          "8": "spangled",
          "9": "calicool",
          a: "luckystripe",
          b: "amur",
          c: "jaguar",
          d: "spock",
          e: "mittens",
          f: "totesbasic",
          g: "totesbasic",
          h: "splat",
          i: "thunderstruck",
          j: "dippedcone",
          k: "highsociety",
          m: "tigerpunk",
          n: "henna",
          o: "arcreactor",
          p: "totesbasic",
          q: "scorpius",
          r: "razzledazzle",
          s: "hotrod",
          t: "allyouneed",
          u: "avatar",
          v: "gyre",
          w: "moonrise",
          x: "",
        },
      },
    },
    {
      coloreyes: {
        genes: "8-11",
        name: "Eye Color",
        code: "EC",
        kai: {
          "1": "thundergrey",
          "2": "gold",
          "3": "topaz",
          "4": "mintgreen",
          "5": "isotope",
          "6": "sizzurp",
          "7": "chestnut",
          "8": "strawberry",
          "9": "sapphire",
          a: "forgetmenot",
          b: "dahlia",
          c: "coralsunrise",
          d: "olive",
          e: "doridnudibranch",
          f: "parakeet",
          g: "cyan",
          h: "pumpkin",
          i: "limegreen",
          j: "bridesmaid",
          k: "bubblegum",
          m: "twilightsparkle",
          n: "palejade",
          o: "pinefresh",
          p: "eclipse",
          q: "babypuke",
          r: "downbythebay",
          s: "autumnmoon",
          t: "oasis",
          u: "gemini",
          v: "dioscuri",
          w: "kaleidoscope",
          x: "",
        },
      },
    },
    {
      eyes: {
        genes: "12-15",
        name: "Eye Shape",
        code: "ES",
        kai: {
          "1": "swarley",
          "2": "wonky",
          "3": "serpent",
          "4": "googly",
          "5": "otaku",
          "6": "simple",
          "7": "crazy",
          "8": "thicccbrowz",
          "9": "caffeine",
          a: "wowza",
          b: "baddate",
          c: "asif",
          d: "chronic",
          e: "slyboots",
          f: "wiley",
          g: "stunned",
          h: "chameleon",
          i: "alien",
          j: "fabulous",
          k: "raisedbrow",
          m: "tendertears",
          n: "hacker",
          o: "sass",
          p: "sweetmeloncakes",
          q: "oceanid",
          r: "wingtips",
          s: "firedup",
          t: "buzzed",
          u: "bornwithit",
          v: "candyshoppe",
          w: "drama",
          x: "",
        },
      },
    },
    {
      color1: {
        genes: "16-19",
        name: "Base Color",
        code: "BC",
        kai: {
          "1": "shadowgrey",
          "2": "salmon",
          "3": "meowgarine",
          "4": "orangesoda",
          "5": "cottoncandy",
          "6": "mauveover",
          "7": "aquamarine",
          "8": "nachocheez",
          "9": "harbourfog",
          a: "cinderella",
          b: "greymatter",
          c: "tundra",
          d: "brownies",
          e: "dragonfruit",
          f: "hintomint",
          g: "bananacream",
          h: "cloudwhite",
          i: "cornflower",
          j: "oldlace",
          k: "koala",
          m: "lavender",
          n: "glacier",
          o: "redvelvet",
          p: "verdigris",
          q: "icicle",
          r: "onyx",
          s: "hyacinth",
          t: "martian",
          u: "hotcocoa",
          v: "shamrock",
          w: "firstblush",
          x: "",
        },
      },
    },
    {
      color2: {
        genes: "20-23",
        name: "Highlight Color",
        code: "HC",
        kai: {
          "1": "cyborg",
          "2": "springcrocus",
          "3": "egyptiankohl",
          "4": "poisonberry",
          "5": "lilac",
          "6": "apricot",
          "7": "royalpurple",
          "8": "padparadscha",
          "9": "swampgreen",
          a: "violet",
          b: "scarlet",
          c: "barkbrown",
          d: "coffee",
          e: "lemonade",
          f: "chocolate",
          g: "butterscotch",
          h: "ooze",
          i: "safetyvest",
          j: "turtleback",
          k: "rosequartz",
          m: "wolfgrey",
          n: "cerulian",
          o: "skyblue",
          p: "garnet",
          q: "peppermint",
          r: "universe",
          s: "royalblue",
          t: "mertail",
          u: "inflatablepool",
          v: "pearl",
          w: "prairierose",
          x: "",
        },
      },
    },
    {
      color3: {
        genes: "24-27",
        name: "Accent Color",
        code: "AC",
        kai: {
          "1": "belleblue",
          "2": "sandalwood",
          "3": "peach",
          "4": "icy",
          "5": "granitegrey",
          "6": "cashewmilk",
          "7": "kittencream",
          "8": "emeraldgreen",
          "9": "kalahari",
          a: "shale",
          b: "purplehaze",
          c: "hanauma",
          d: "azaleablush",
          e: "missmuffett",
          f: "morningglory",
          g: "frosting",
          h: "daffodil",
          i: "flamingo",
          j: "buttercup",
          k: "bloodred",
          m: "atlantis",
          n: "summerbonnet",
          o: "periwinkle",
          p: "patrickstarfish",
          q: "seafoam",
          r: "cobalt",
          s: "mallowflower",
          t: "mintmacaron",
          u: "sully",
          v: "fallspice",
          w: "dreamboat",
          x: "",
        },
      },
    },
    {
      wild: {
        genes: "28-31",
        name: "Wild",
        code: "WE",
        kai: {
          "1": "",
          "2": "",
          "3": "",
          "4": "",
          "5": "",
          "6": "",
          "7": "",
          "8": "",
          "9": "",
          a: "",
          b: "",
          c: "",
          d: "",
          e: "",
          f: "",
          g: "",
          h: "littlefoot",
          i: "elk",
          j: "ducky",
          k: "trioculus",
          m: "daemonwings",
          n: "featherbrain",
          o: "flapflap",
          p: "daemonhorns",
          q: "dragontail",
          r: "aflutter",
          s: "foghornpawhorn",
          t: "unicorn",
          u: "dragonwings",
          v: "alicorn",
          w: "wyrm",
          x: "",
        },
      },
    },
    {
      mouth: {
        genes: "32-35",
        name: "Mouth",
        code: "MO",
        kai: {
          "1": "whixtensions",
          "2": "wasntme",
          "3": "wuvme",
          "4": "gerbil",
          "5": "confuzzled",
          "6": "impish",
          "7": "belch",
          "8": "rollercoaster",
          "9": "beard",
          a: "pouty",
          b: "saycheese",
          c: "grim",
          d: "fangtastic",
          e: "moue",
          f: "happygokitty",
          g: "soserious",
          h: "cheeky",
          i: "starstruck",
          j: "samwise",
          k: "ruhroh",
          m: "dali",
          n: "grimace",
          o: "majestic",
          p: "tongue",
          q: "yokel",
          r: "topoftheworld",
          s: "neckbeard",
          t: "satiated",
          u: "walrus",
          v: "struck",
          w: "delite",
          x: "",
        },
      },
    },
    {
      environment: {
        genes: "36-39",
        name: "Environment",
        code: "EN",
        kai: {
          "1": "",
          "2": "",
          "3": "",
          "4": "",
          "5": "",
          "6": "",
          "7": "",
          "8": "",
          "9": "",
          a: "",
          b: "",
          c: "",
          d: "",
          e: "",
          f: "",
          g: "",
          h: "salty",
          i: "dune",
          j: "juju",
          k: "tinybox",
          m: "myparade",
          n: "finalfrontier",
          o: "metime",
          p: "drift",
          q: "secretgarden",
          r: "frozen",
          s: "roadtogold",
          t: "jacked",
          u: "floorislava",
          v: "prism",
          w: "junglebook",
          x: "",
        },
      },
    },
    {
      secret: {
        genes: "40-43",
        name: "Secret Y Gene",
        code: "SE",
        kai: {},
      },
    },
    {
      prestige: { genes: "44-47", name: "Purrstige", code: "PU", kai: {} },
    },
  ]

// Samples of original data for fill in the db FancyKitties
// based on https://www.cryptokitties.co/catalogue/fancy-cats
// Fancy kitties are selected based on the rank of generation (low to high).
// Generally speaking, fancy kitties priced lower than $100 are not considered as valualbe fancy kitties.
const FancyKitties = [
        
  ['Catamari', 1642629, 1642657, 1641933, 1642019, 
            1646755, 1639921, 1643320, 1646438, 
            1649667, 1645264, 1643775, 1644114,
            1640134, 1647228, 1643862, 1647294, 
            1641007, 1646945, 1646255, 1642591, 
            1644179, 1643528, 1647854, 1649527,
            1646945, 1643862, 1640134, 1641704, 
            1649527, 1641007, 1643252, 1644544,
            1647485, 1649133, 1649632, 1640061],


  ['Magmeow', 1631726, 1634450, 1632058, 1631206,
            1631875, 1629596, 1635110, 1633445,
            1634369, 1632890, 1631778, 1634504,
            1635234, 1634504, 1631965, 1632890,
            1635110, 1634369, 1632233, 1635107,
            1632190, 1630243, 1634301, 1633445,
            1632841, 1631778, 1632233, 1633445,
            1635107, 1635234, 1635028, 1633281,
            1635449, 1633501, 1633378, 1633885],

  ['Kitijira', 1616077, 1626771, 1624378, 1621802,
            1620498, 1620920, 1620827, 1622099,
            1620131, 1625850, 1627335, 1621018,
            1621802, 1619371, 1622012, 1628854,
            1621378, 1619639, 1621078, 1618937,
            1622779, 1623096, 1621843, 1622632,
            1620432, 1619639, 1622012, 1621078,
            1619371, 1616707, 1628854, 1621843,
            1621907, 1623096, 1623973, 1618937,
            1621078, 1620578, 1621508, 1624223,
            1621330, 1622707, 1619208, 1628279,
            1625513, 1627029, 1620855, 1621197],

  ['Whisper', 1600063, 1598628, 1595078, 1598372,
           1596604, 1610037, 1602063, 1597556,
           1597306, 1605931, 1606998, 1607247,
           1606998, 1607247, 1598164, 1600894,
           1597556, 1597306, 1610037, 1601338,
           1599641, 1598638, 1600664, 1599655,
           1597774, 1601113, 1600664, 1604885,
           1598748, 1599655, 1600074, 1600727,
           1599641, 1598638, 1602861, 1605716],

  ['Krakitten', 1549620, 1551317, 1549815, 1566316,
             1551090, 1549243, 1551803, 1552014,
             1554967, 1549707, 1550485, 1550517,
             1550517, 1560149, 1550554, 1549707,
             1555405, 1560460, 1549243, 1566316,
             1551090, 1554967, 1563186, 1549402,
             1555405, 1560376, 1555375, 1555108,
             1554116, 1551753, 1551012, 1555717,
             1553405, 1560593, 1555566, 1566504,
             1560696, 1560593, 1560945, 1550568,
             1554116, 1566504, 1551753, 1553323,
             1555108, 1560376, 1555375, 1550523,
             1555108, 1563428, 1564177, 1551401,
             1555657, 1560945, 1560376, 1554116,
             1555717, 1553405, 1550523, 1550507]
]



