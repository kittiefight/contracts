const BigNumber = web3.utils.BN;
require('chai')
  .use(require('chai-shallow-deep-equal'))
  .use(require('chai-bn')(BigNumber))
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
const GAME_PRESTART = 60 // 60 secs for quick test
const GAME_DURATION = 120 // games last  2 min
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

  it.skip('sets super admin address', async () => {
    await register.addSuperAdmin(accounts[0])
  })

  it.skip('initialize escrow upgrade', async () => {
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

/*
  it('returnOriginalSender', async () => {
    let claimerAddress = await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'returnOriginalSender'), { from: accounts[0] });
    console.log('claimerAddress returned by contract:' + claimerAddress);  
  })
return;
*/


  // dummy claim pay check
  it('Call Dummy claim to check if payment work', async () => {

    let claimer_balance_kty_pre = await kittieFightToken.balanceOf(accounts[0]); 
    let claimer_balance_eth_pre = await  web3.eth.getBalance(accounts[0]);

    await endowmentFund.claim_dummy({from: accounts[0]});

    let claimer_balance_kty_post = await kittieFightToken.balanceOf(accounts[0]); 
    let claimer_balance_eth_post = await  web3.eth.getBalance(accounts[0]);

    console.log('\n==== CLAIMER BALANCE (pre):', 
                '\n Kty=', claimer_balance_kty_pre.toString(), 
                '\n Eth=', claimer_balance_eth_pre.toString());

    console.log('\n==== CLAIMER BALANCE (post) : 100 wie kty, 1 wei eth added:', 
                '\n Kty=', claimer_balance_kty_post.toString(), 
                '\n Eth=', claimer_balance_eth_post.toString());

  })

  it('Test: function Claim()', async () => {

      // create a dummy honypot
    let gameId = 50;
    let claimer = accounts[0];
    let ethAllocated = await endowmentFund.generateHoneyPot(gameId);

      // can not claim as state not HoneypotState.claiming
    await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'claim',
      [gameId]), { from: claimer }).should.be.rejected;

      // set state to 'claiming' i.e. 5
    await endowmentFund.setHoneypotState(gameId, 5, 0);

    // can not claim as claim time is zero
    await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'claim',
      [gameId]), { from: claimer }).should.be.rejected;

    // set claim time over
    var date = new Date(); var now_timestamp = date.getTime(); 
    await endowmentFund.setHoneypotState(gameId, 5, now_timestamp + 10);

    // can not clain as claim time is over
    await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'claim',
      [gameId]), { from: claimer }).should.be.rejected;

    // set claimer as already claimed
    await endowmentFund.setTotalDebit(gameId, claimer, 1, 1);
    await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'claim',
      [gameId]), { from: claimer }).should.be.rejected;




  }) 
  
  // updateHoneyPotState

})




