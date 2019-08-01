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
const KittieHELL = artifacts.require('KittieHELL')
const KittieHellDB = artifacts.require('KittieHellDB')
const SuperDaoToken = artifacts.require('MockERC20Token');
const KittieFightToken = artifacts.require('MockERC20Token');
const CryptoKitties = artifacts.require('MockERC721Token');
const CronJob = artifacts.require('CronJob');
const FreezeInfo = artifacts.require('FreezeInfo');
const CronJobTarget = artifacts.require('CronJobTarget');

// const ERC20_TOKEN_SUPPLY = new BigNumber(1000000);
const ERC20_TOKEN_SUPPLY = new BigNumber(
  web3.utils.toWei("100000000", "ether") //100 Million
);

const TOKENS_FOR_USERS = new BigNumber(
  web3.utils.toWei("5000", "ether") //100 Million
);

const INITIAL_KTY_ENDOWMENT = new BigNumber(
  web3.utils.toWei("50000", "ether") //50.000 KTY
);

const INITIAL_ETH_ENDOWMENT = new BigNumber(
  web3.utils.toWei("1000", "ether") //1.000 ETH
);

//Contract instances
let proxy, dateTime, genericDB, profileDB, roleDB, superDaoToken,
  kittieFightToken, cryptoKitties, register, gameVarAndFee, endowmentFund,
  endowmentDB, distribution, forfeiter, scheduler, betting, hitsResolve,
  rarityCalculator, kittieHELL, kittieHellDB, getterDB, setterDB, gameManager,
  cronJob, escrow

const kovanMedianizer = '0xA944bd4b25C9F186A846fd5668941AA3d3B8425F'
const kitties = []
const cividIds = []

assignIds()

function assignIds(){
    for(let i = 0; i < 17; i++){
        kitties.push(i)
        cividIds.push(i)
    }
}

gameStates = ['WAITING', 'PREGAME', 'MAINGAME', 'GAMEOVER', 'CLAIMING'];

potStates = ['CREATED', 'ASSIGNED', 'SCHEDULED', 'STARTED', 'FORFEITED', 'CLAIMING', 'DISSOLVED']

// GAME VARS AND FEES
const LISTING_FEE = new BigNumber(web3.utils.toWei("1000", "ether"));
const TICKET_FEE = new BigNumber(web3.utils.toWei("100", "ether"));
const BETTING_FEE = new BigNumber(web3.utils.toWei("100", "ether"));
const MIN_CONTRIBUTORS = 2
const REQ_NUM_MATCHES = 8
const GAME_PRESTART = 20 // 20 secs for quick test
const GAME_DURATION = 60 // games last 0.5 min
const ETH_PER_GAME = new BigNumber(web3.utils.toWei("10", "ether"));
const TOKENS_PER_GAME = new BigNumber(web3.utils.toWei("10000", "ether"));
const GAME_TIMES = 120 //Scheduled games 1 min apart
const KITTIE_HELL_EXPIRATION = 300
const HONEY_POT_EXPIRATION = 180
const KITTIE_REDEMPTION_FEE = new BigNumber(web3.utils.toWei("500", "ether"));
//Distribution Rates
const WINNING_KITTIE = 35
const TOP_BETTOR = 25
const SECOND_RUNNER_UP = 10
const OTHER_BETTORS = 15
const ENDOWNMENT = 15
const FINALIZE_REWARDS = new BigNumber(web3.utils.toWei("500", "ether")); //500 KTY

const GameState = {
  WAITING: 0,
  PRE_GAME: 1,
  MAIN_GAME: 2,
  GAME_OVER: 3,
  CLAIMING: 4,
  KITTIE_HELL: 5,
  CANCELLED: 6
}

let gameDetails;


function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

function randomValue() {
  return Math.floor(Math.random() * 30) + 1; // 0-100ETH
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

  it('deploys contracts', async () => {
    // PROXY
    proxy = await KFProxy.new()

    // DATABASES
    genericDB = await GenericDB.new()
    profileDB = await ProfileDB.new(genericDB.address);
    roleDB = await RoleDB.new(genericDB.address);
    endowmentDB = await EndowmentDB.new(genericDB.address)
    getterDB = await GMGetterDB.new(genericDB.address)
    setterDB = await GMSetterDB.new(genericDB.address)
    kittieHellDB = await KittieHellDB.new(genericDB.address)

    // CRONJOB
    cronJob = await CronJob.new(genericDB.address)
    freezeInfo = await FreezeInfo.new();
    cronJobTarget= await CronJobTarget.new();


    // TOKENS
    superDaoToken = await SuperDaoToken.new(ERC20_TOKEN_SUPPLY);
    kittieFightToken = await KittieFightToken.new(ERC20_TOKEN_SUPPLY);
    cryptoKitties = await CryptoKitties.new();

    // MODULES
    gameManager = await GameManager.new()
    gameStore = await GameStore.new()
    gameCreation = await GameCreation.new()
    register = await Register.new()
    dateTime = await DateTime.new()
    gameVarAndFee = await GameVarAndFee.new(genericDB.address, kovanMedianizer)
    forfeiter = await Forfeiter.new()
    scheduler = await Scheduler.new()
    betting = await Betting.new()
    hitsResolve = await HitsResolve.new()
    rarityCalculator = await RarityCalculator.deployed()  //for testnet, as raruty needs some SETUP :)
    // rarityCalculator = await RarityCalculator.new()
    endowmentFund = await EndowmentFund.new()
    kittieHELL = await KittieHELL.new()

    //ESCROW
    escrow = await Escrow.new()
    await escrow.transferOwnership(endowmentFund.address).should.be.fulfilled

  })

  it('adds contract addresses to contract manager', async () => {
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

  it('sets proxy in contracts', async () => {
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

  it('initializes contract variables', async () => {
    await gameVarAndFee.initialize()
    await gameStore.initialize()
    await gameCreation.initialize()
    await forfeiter.initialize()
    await scheduler.initialize()
    await register.initialize()
    await gameManager.initialize()
    await getterDB.initialize()
    await setterDB.initialize()
    await endowmentFund.initialize()
    await endowmentFund.initUpgradeEscrow(escrow.address)
    await kittieHellDB.setKittieHELL()
    await kittieHELL.initialize()
    await hitsResolve.initialize()
  })

  it('mint some kitties for the test addresses', async () => {
    for (let i = 1; i < 17; i++) {
      await cryptoKitties.mint(accounts[i], kitties[i]).should.be.fulfilled;
    }
  })

  it('approve transfer operation', async () => {
    for (let i = 1; i < 17; i++) {
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

  it('initialize endowment/escrow funds', async () => {    
      await kittieFightToken.transfer(endowmentFund.address, INITIAL_KTY_ENDOWMENT).should.be.fulfilled;
      await endowmentFund.sendKTYtoEscrow(INITIAL_KTY_ENDOWMENT);
      await endowmentFund.sendETHtoEscrow({from: accounts[0], value:INITIAL_ETH_ENDOWMENT});

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
    for (let i = 1; i < 17; i++) {
      await proxy.execute('Register', setMessage(register, 'verifyAccount', [cividIds[i]]), {
        from: accounts[i]
      }).should.be.fulfilled;
    }
  })

  let newGameEvents
  it('correctly creates 8 games', async () => {
    for (let i = 1; i < 17; i++) {
        await proxy.execute('GameCreation', setMessage(gameCreation, 'listKittie',
          [kitties[i]]), { from: accounts[i] }).should.be.fulfilled;
    }

    newGameEvents = await gameCreation.getPastEvents("NewGame", { 
      fromBlock: 0, 
      toBlock: "latest" 
    });

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
    // gameDetails = newGameEvents[0].returnValues

    // let gameTimes = await getterDB.getGameTimes(gameDetails.gameId);

    // gameDetails.endTime = gameTimes.endTime.toNumber();

    // gameDetails.preStartTime = gameTimes.preStartTime.toNumber();
  })

  // GAME_STATE = 0
  it('forfeit game if playerRed does not own the listed kitty', async () => {

  })

  it('forfeit game if playerBlack does not own the listed kitty', async () => {

  })

  it('forfeit game if playerRed does not have enough supporters', async () => {

  })

  it('forfeit game if playerBlack does not have enough supporters', async () => {

  })


  // GAME_STATE = 1
  it('move gameState to PRE_GAME', async () => {

  })

  it('forfeit game if playerRed does not own the listed kitty', async () => {

  })

  it('forfeit game if playerBlack does not own the listed kitty', async () => {

  })  

  it('forfeit game if playerRed does not hitStart on time', async () => {

  })

  it('forfeit game if playerBlack does not hitStart on time', async () => {
      
  })

  it('honeyPotState should be forfeited', async () => {

  })

  it('kitties should be removed to the game', async () => {

  })

})