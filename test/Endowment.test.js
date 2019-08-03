
const BigNumber = require('bn.js');
require('chai')
  .use(require('chai-shallow-deep-equal'))
  .use(require('chai-bn')(BigNumber))
  .use(require('chai-as-promised'))
  .should();



const KFProxy = artifacts.require('KFProxy')
//const Guard = artifacts.require('Guard')
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

//Contract instances
let proxy, guard, dateTime, genericDB, profileDB, roleDB, superDaoToken,
  kittieFightToken, cryptoKitties, register, gameVarAndFee, endowmentFund,
  endowmentDB, distribution, forfeiter, scheduler, betting, hitsResolve,
  rarityCalculator, kittieHELL, kittieHellDB, getterDB, setterDB, gameManager,
  cronJob, escrow


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

// GAME VARS AND FEES
const LISTING_FEE = new BigNumber(web3.utils.toWei("5", "ether"));
const TICKET_FEE = new BigNumber(web3.utils.toWei("2", "ether"));
const BETTING_FEE = new BigNumber(web3.utils.toWei("1", "ether"));
const MIN_CONTRIBUTORS = 2
const REQ_NUM_MATCHES = 2
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

const kovanMedianizer = '0xA944bd4b25C9F186A846fd5668941AA3d3B8425F'
const kitties = [0, 1001, 1555108, 1267904, 454545, 333, 6666];

gameStates = ['WAITING', 'PREGAME', 'MAINGAME', 'GAMEOVER', 'CLAIMING'];

potStates = ['CREATED', 'ASSIGNED', 'SCHEDULED', 'STARTED', 'FORFEITED', 'CLAIMING', 'DISSOLVED']

const cividIds = [0, 1, 2, 3, 4, 5, 6];

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
  return Math.floor(Math.random() * 30) + 1; // 0-100ETH
}

function timeout(s) {
   console.log(`~~~ Timeout for ${s} seconds`);
  return new Promise(resolve => setTimeout(resolve, s * 1000));
}

function formatDate(timestamp)
{
    let date = new Date(null);
    date.setSeconds(timestamp);
    return date.toTimeString().replace(/.*(\d{2}:\d{2}:\d{2}).*/, "$1");
}

contract('Endowment', (accounts) => {

  it('deploys contracts', async () => {
    // PROXY
    proxy = await KFProxy.new()
    //guard = await Guard.new()

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
    //await proxy.addContract('Guard', guard.address)
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
    //await guard.setProxy(proxy.address);
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
  
  it('add KTY to endowment', async () => {    
    await kittieFightToken.transfer(endowmentFund.address, INITIAL_KTY_ENDOWMENT).should.be.fulfilled;
    let endowmentFund_kty = await kittieFightToken.balanceOf(endowmentFund.address); 
    //console.log('balanceOf(endowmentFund.address) = ' + endowmentFund_kty);
  })

  it('send KTY to escrow from endowment', async () => {    
    await endowmentFund.sendKTYtoEscrow(INITIAL_KTY_ENDOWMENT);
    let balanceKTY = await escrow.getBalanceKTY();
    //console.log(' escrow.getBalanceKTY() = ' + balanceKTY);
    balanceKTY.toString().should.be.equal(INITIAL_KTY_ENDOWMENT.toString());
  })


  it('send ETH to escrow from accounts[0]', async () => {    
      await endowmentFund.sendETHtoEscrow({from: accounts[0], value:INITIAL_ETH_ENDOWMENT});

      let balanceETH = await escrow.getBalanceETH();
      //console.log(' escrow.getBalanceETH() = ' + balanceETH);
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
    
    //console.log('\n==== GAME FEE: \n', 'getListingFee=', getVar.toString(), '\nLISTING_FEE=', LISTING_FEE.toString());
    LISTING_FEE.should.be.a.bignumber.that.equals(await gameVarAndFee.getListingFee());

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

  var preListing_ed_kty = 0;
  var preListing_ed_eth = 0;
  var preListing_es_kty = 0;
  var preListing_es_eth = 0;
  it('endowment fund and ecsrow funds before kitty listing', async () => {  
    
    let endowmentBalance = await endowmentDB.getEndowmentBalance();
    preListing_ed_kty = endowmentBalance.endowmentBalanceKTY;
    preListing_ed_eth = endowmentBalance.endowmentBalanceETH;

    preListing_es_kty = await escrow.getBalanceKTY(); 
    preListing_es_eth = await escrow.getBalanceETH(); 

  })

  it('list 3 kitties to the system', async () => {
    for (let i = 1; i < 4; i++) {
      await proxy.execute('GameCreation', setMessage(gameCreation, 'listKittie',
        [kitties[i]]), { from: accounts[i] }).should.be.fulfilled;
    }
  })

  it('check if listing fee added to endowment fund and ecsrow funds', async () => {  

    // endowment
    console.log('\n==== FUNDS IN ENDOWMENT (pre listing):', 
                '\n Kty=', preListing_ed_eth.toString(), 
                '\n Eth=', preListing_ed_eth.toString());
    
    let endowmentBalance = await endowmentDB.getEndowmentBalance();
    let endowmentBalanceKTY = endowmentBalance.endowmentBalanceKTY;
    let endowmentBalanceETH = endowmentBalance.endowmentBalanceETH;
    console.log('\n==== FUNDS IN ENDOWMENT (post listing):', 
                '\n Kty=', endowmentBalanceKTY.toString(), 
                '\n Eth=', endowmentBalanceETH.toString());

    let ed_added_kty = endowmentBalanceKTY.sub(preListing_ed_eth);

    // since 3 listed ed_added_kty = 3 * listing fee
    let listingFee_3 = LISTING_FEE.mul(new BigNumber(3)); 
    listingFee_3.should.be.a.bignumber.that.equals(ed_added_kty);

    // escrow
    console.log('\n==== FUNDS IN ESCROW (pre listing):', 
                '\n Kty=', preListing_es_kty.toString(), 
                '\n Eth=', preListing_es_eth.toString());
    
    let postListing_es_kty = await escrow.getBalanceKTY(); 
    let postListing_es_eth = await escrow.getBalanceETH(); 
    console.log('\n==== FUNDS IN ESCROW (post listing):', 
                '\n Kty=', postListing_es_eth.toString(), 
                '\n Eth=', postListing_es_eth.toString());

    // since kty is transafed to escrow
    let es_added_kty = postListing_es_kty.sub(preListing_es_kty);
    listingFee_3.should.be.a.bignumber.that.equals(es_added_kty);

  })

  it('check if endowment fund has required funds to start game', async () => {  
    
    let reqKtyPerGame = await gameVarAndFee.getTokensPerGame();  
    let reqEthPerGame = await gameVarAndFee.getEthPerGame();
    console.log('\n==== TokensPerGame - EthPerGame:', 
                '\n Kty=', reqKtyPerGame.toString(), 
                '\n Eth=', reqEthPerGame.toString());

    let endowmentBalance = await endowmentDB.getEndowmentBalance();
    let endowmentBalanceKTY = endowmentBalance.endowmentBalanceKTY;
    let endowmentBalanceETH = endowmentBalance.endowmentBalanceETH;
    console.log('\n==== FUNDS IN ENDOWMENT:', 
                '\n Kty=', endowmentBalanceKTY.toString(), 
                '\n Eth=', endowmentBalanceETH.toString());

    endowmentBalanceKTY.should.be.a.bignumber.that.gte(reqKtyPerGame);
    endowmentBalanceETH.should.be.a.bignumber.that.gte(reqEthPerGame);

  })

  it('list 1 more kittie to the system', async () => {

    await proxy.execute('GameCreation', setMessage(gameCreation, 'listKittie',
      [kitties[4]]), { from: accounts[4] }).should.be.fulfilled;
  })

  var pre_ed_kty = 0;
  var pre_ed_eth = 0;
  var pre_es_kty = 0;
  var pre_es_eth = 0;

  it('Status of endowment, escrow BEFORE game creation', async () => {


    let endowmentBalance = await endowmentDB.getEndowmentBalance();
    pre_ed_kty = endowmentBalance.endowmentBalanceKTY;
    pre_ed_eth = endowmentBalance.endowmentBalanceETH;
    console.log('\n==== FUNDS IN ENDOWMENT before creating game :', 
                '\n Kty=', pre_ed_kty.toString(), 
                '\n Eth=', pre_ed_eth.toString());

    pre_es_kty = await escrow.getBalanceKTY(); 
    pre_es_eth = await escrow.getBalanceETH(); 
    console.log('\n==== FUNDS IN ESCROW before creating game :', 
                '\n Kty=', pre_es_kty.toString(), 
                '\n Eth=', pre_es_eth.toString());
  })

  var hp_total_kty = 0;
  var hp_total_eth = 0;
  var counter = 0;
  it('Create Game', async () => {

    // to create honeypot
    let kty_required_forNewGame = await gameVarAndFee.getTokensPerGame();
    let eth_required_forNewGame = await gameVarAndFee.getEthPerGame();

    let newGameEvents = await gameCreation.getPastEvents("NewGame", { 
      fromBlock: 0, 
      toBlock: "latest" 
    });

    newGameEvents.map(async (e) => {
      let gameInfo = await getterDB.getGameTimes(e.returnValues.gameId);
      counter++;
      console.log('\n==== NEW GAME CREATED ===');
      console.log('    GameId ', e.returnValues.gameId)

      // honeypot fund
      honeyPotBalance = await endowmentDB.getHoneyPotBalance(e.returnValues.gameId);
      honeyPotBalanceKTY = honeyPotBalance.honeyPotBalanceKTY;
      honeyPotBalanceETH = honeyPotBalance.honeyPotBalanceETH;
      console.log('\n==== FUNDS IN HONEYPOT of GameId='+e.returnValues.gameId,
                 '\n Kty=', honeyPotBalanceKTY.toString(), 
                 '\n Eth=', honeyPotBalanceETH.toString()
                 );

      honeyPotBalanceKTY.should.be.a.bignumber.that.eq(kty_required_forNewGame);
      honeyPotBalanceETH.should.be.a.bignumber.that.eq(eth_required_forNewGame);

      hp_total_kty = new BigNumber(hp_total_kty).add(honeyPotBalanceKTY);
      hp_total_eth = new BigNumber(hp_total_eth).add(honeyPotBalanceETH);

    })

    //Assign variable to game that is going to be played in the test
    // gameDetails = newGameEvents[newGameEvents.length -1].returnValues
    gameDetails = newGameEvents[0].returnValues

    let gameTimes = await getterDB.getGameTimes(gameDetails.gameId);
    gameDetails.endTime = gameTimes.endTime.toNumber();
    gameDetails.preStartTime = gameTimes.preStartTime.toNumber();
  })

  // Post game creation //
  it('Status of endowment, escrow before POST game creation', async () => {

      //  endowment
      endowmentBalance = await endowmentDB.getEndowmentBalance();
      let post_ed_kty = endowmentBalance.endowmentBalanceKTY;
      let post_ed_eth = endowmentBalance.endowmentBalanceETH;
      let ed_kty_diff = post_ed_kty.sub(pre_ed_kty);      
      let ed_eth_diff = post_ed_eth.sub(pre_ed_eth);
      
      let kty_used_in_game = kty_required_forNewGame.mul(new BigNumber(counter));
      let eth_used_in_game = eth_required_forNewGame.mul(new BigNumber(counter));
  
      console.log('\n==== FUNDS IN ENDOWMENT post creation of Game', 
                  '\n Kty=', post_ed_kty.toString(),
                  '\n Eth=', post_ed_eth.toString(),
                  '\n Kty used from Endowment=', ed_kty_diff.toString(),
                  '\n Kty Game needed=', kty_used_in_game.toString(),
                  '\n Eth used from Endowment=', ed_kty_diff.toString(),
                  '\n Eth Game needed=', eth_used_in_game.toString(),
                  );

      // honeypot amount is deducted from endowment fund
      ed_kty_diff.should.be.a.bignumber.that.eq(kty_used_in_game);
      ed_eth_diff.should.be.a.bignumber.that.eq(eth_used_in_game);

      // escrow status: 
      post_es_kty = await escrow.getBalanceKTY(); 
      post_es_eth = await escrow.getBalanceETH(); 
      console.log('\n==== FUNDS IN ESCROW post creation of GameId='+e.returnValues.gameId, 
                  '\n Kty=', post_es_kty.toString(), 
                  '\n Eth=', post_es_eth.toString());
      
      es_eth_diff = post_es_eth.sub(pre_es_eth); 
      es_eth_diff.should.be.a.bignumber.that.eq(0); // as escrow is not used

  })

  // claim check
  it('Call Dummy claim to check if payment work', async () => {

    let sender_balance_kty = await kittieFightToken.balanceOf(accounts[0]); 
    let sender_balance_eth = await  web3.eth.getBalance(accounts[0]);

    await endowmentFund.claim_dummy({from: accounts[0]});

    let sender_balance_kty_post = await kittieFightToken.balanceOf(accounts[0]); 
    let sender_balance_eth_post = await  web3.eth.getBalance(accounts[0]);

    console.log('\n==== CLAIMER BALANCE (pre):', '\n Kty=', sender_balance_kty.toString(), '\n Eth=', sender_balance_eth.toString());
    console.log('\n==== CLAIMER BALANCE (post):', '\n Kty=', sender_balance_kty_post.toString(), '\n Eth=', sender_balance_eth_post.toString());

  })

  return;

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

      
    while(block < gameDetails.preStartTime){
      block = await dateTime.getBlockTimeStamp();
      await(3);
    }

    let { gameId, playerRed, playerBlack } = gameDetails;

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


  })  

  //This works but not inside contract
  it.skip('set defense level for both players', async () => { 

    let { gameId, playerRed, playerBlack, kittieBlack, kittieRed } = gameDetails;

    const gene1 = '512955438081049600613224346938352058409509756310147795204209859701881294'

    const gene2 = '24171491821178068054575826800486891805334952029503890331493652557302916'

    //This works, with previous test uncommented
    let defense = await rarityCalculator.getDefenseLevel.call(kittieBlack, gene1);
    await betting.setDefenseLevel(gameId, playerBlack, defense);
    console.log(`\n==== DEFENSE BLACK: ${defense}`);

    defense = await rarityCalculator.getDefenseLevel.call(kittieRed, gene2);
    await betting.setDefenseLevel(gameId, playerRed, defense);
    console.log(`\n==== DEFENSE RED: ${defense}`);
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

  it('get defense level for both players', async () => { 
    let { gameId, playerRed, playerBlack } = gameDetails;

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
      await timeout(1);
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

  it('should be able to make bet', async () => {
    let { gameId, playerRed, playerBlack } = gameDetails;

    let currentState = await getterDB.getGameState(gameId)
    currentState.toNumber().should.be.equal(GameState.MAIN_GAME)

    for (let i = 6; i < 18; i++) {
      // let supportedPlayer = i < 10 ? playerRed : playerBlack;
      let betAmount = randomValue()
      let bettor = accounts[i]
      let supporterInfo = await getterDB.getSupporterInfo(gameId, accounts[i])
      let supportedPlayer = supporterInfo.supportedPlayer;

      if (supportedPlayer == playerRed) {
        (redBetStore.has(bettor)) ?
          redBetStore.set(bettor, redBetStore.get(bettor) + betAmount) :
          redBetStore.set(bettor, betAmount)
          console.log('\n==== NEW BET FOR RED', 'Amount:', betAmount, 'ETH, bettor:', bettor);
      } else {
        (blackBetStore.has(bettor)) ?
          blackBetStore.set(bettor, blackBetStore.get(bettor) + betAmount) :
          blackBetStore.set(bettor, betAmount)
          console.log('\n==== NEW BET FOR BLACK', 'Amount:', betAmount, 'ETH, bettor:', bettor);
      }     
      

      await proxy.execute('GameManager', setMessage(gameManager, 'bet',
        [gameId, randomValue()]), { from: bettor, value: web3.utils.toWei(String(betAmount)) }).should.be.fulfilled;

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

  it('game ends', async () => {
    
    console.log('\n==== WAITING FOR GAME OVER')

    let block = await dateTime.getBlockTimeStamp();
      
    while(block < gameDetails.endTime){
      block = await dateTime.getBlockTimeStamp();
      await(1);
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
    withdrawalState = await endowmentFund.getWithdrawalState(gameId,  winners.topBettor);
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

    console.log('Resurrection Cost: ',resurrectionCost.toString(), 'KTY')

    await kittieFightToken.approve(kittieHELL.address, resurrectionCost, 
      { from: loser }).should.be.fulfilled;

    await proxy.execute('KittieHell', setMessage(kittieHELL, 'payForResurrection',
      [loserKitty]), { from: loser }).should.be.fulfilled;

    let owner = await cryptoKitties.ownerOf(loserKitty)
    //Ownership back to address, not kittieHell
    owner.should.be.equal(loser);

  })

})




