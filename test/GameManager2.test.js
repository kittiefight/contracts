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
const GameVarAndFee = artifacts.require('GameVarAndFee')
const Distribution = artifacts.require('Distribution')
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
// const ERC20_TOKEN_SUPPLY = new BigNumber(1000000);
const ERC20_TOKEN_SUPPLY = new BigNumber(
  web3.utils.toWei("100000000", "ether") //100 Million
);

//Contract instances
let proxy, dateTime, genericDB, profileDB, roleDB, superDaoToken,
  kittieFightToken, cryptoKitties, register, gameVarAndFee, endowmentFund,
  endowmentDB, distribution, forfeiter, scheduler, betting, hitsResolve,
  rarityCalculator, kittieHELL, kittieHellDB, getterDB, setterDB, gameManager,
  cronJob, escrow

const kovanMedianizer = '0xA944bd4b25C9F186A846fd5668941AA3d3B8425F'
const kitties = [0, 1234, 32452, 23134, 44444, 55555, 6666];

gameStates = ['WAITING', 'PREGAME', 'STARTED', 'FINISHED'];

const cividIds = [0, 1, 2, 3, 4, 5, 6];

// GAME VARS AND FEES
const LISTING_FEE = 1000
const TICKET_FEE = 100
const BETTING_FEE = 100
const MIN_CONTRIBUTORS = 2
const REQ_NUM_MATCHES = 2
const GAME_PRESTART = 30 // 30 secs for quick test
const GAME_DURATION = 120 // games last 2 min
const ETH_PER_GAME = 0 //How does endowment start funds?
const TOKENS_PER_GAME = 0;
const GAME_TIMES = 60 //Scheduled games 1 min apart

const GameState = {
  WAITING: 0,
  PRE_GAME: 1,
  MAIN_GAME: 2,
  KITTIE_HELL: 3,
  WITHDREW_EARNINGS: 4,
  CANCELLED: 5
}

let gameDetails;

function timeout(s) {
  // console.log(`~~~ Timeout for ${s} seconds`);
  return new Promise(resolve => setTimeout(resolve, s * 1000));
}


function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
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

    // TOKENS
    superDaoToken = await SuperDaoToken.new(ERC20_TOKEN_SUPPLY);
    kittieFightToken = await KittieFightToken.new(ERC20_TOKEN_SUPPLY);
    cryptoKitties = await CryptoKitties.new();

    // MODULES
    gameManager = await GameManager.new()
    gameStore = await GameStore.new()
    register = await Register.new()
    dateTime = await DateTime.new()
    gameVarAndFee = await GameVarAndFee.new(genericDB.address, kovanMedianizer)
    distribution = await Distribution.new()
    forfeiter = await Forfeiter.new()
    scheduler = await Scheduler.new()
    betting = await Betting.new()
    hitsResolve = await HitsResolve.new()
    rarityCalculator = await RarityCalculator.new()
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
    await proxy.addContract('Distribution', distribution.address)
    await proxy.addContract('Forfeiter', forfeiter.address)
    await proxy.addContract('Scheduler', scheduler.address)
    await proxy.addContract('Betting', betting.address)
    await proxy.addContract('HitsResolve', hitsResolve.address)
    await proxy.addContract('RarityCalculator', rarityCalculator.address)
    await proxy.addContract('GMSetterDB', setterDB.address)
    await proxy.addContract('GMGetterDB', getterDB.address)
    await proxy.addContract('GameManager', gameManager.address)
    await proxy.addContract('GameStore', gameStore.address)
    await proxy.addContract('CronJob', cronJob.address)
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
    await distribution.setProxy(proxy.address)
    await forfeiter.setProxy(proxy.address)
    await scheduler.setProxy(proxy.address)
    await betting.setProxy(proxy.address)
    await hitsResolve.setProxy(proxy.address)
    await rarityCalculator.setProxy(proxy.address)
    await register.setProxy(proxy.address)
    await gameManager.setProxy(proxy.address)
    await gameStore.setProxy(proxy.address)
    await cronJob.setProxy(proxy.address)
    await kittieHELL.setProxy(proxy.address)
    await kittieHellDB.setProxy(proxy.address)
  })

  it('initializes contract variables', async () => {
    await gameVarAndFee.initialize()
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
      await kittieFightToken.transfer(accounts[i], 100000).should.be.fulfilled;
    }
  })

  it('approves erc20 token transfer operation by endowment contract', async () => {
    for (let i = 1; i < 20; i++) {
      await kittieFightToken.approve(endowmentFund.address, 100000, { from: accounts[i] }).should.be.fulfilled;
    }
  })

  it('Set game vars and fees correctly', async () => {
    let names = ['listingFee', 'ticketFee', 'bettingFee', 'gamePrestart', 'gameDuration',
      'minimumContributors', 'requiredNumberMatches', 'ethPerGame', 'tokensPerGame',
      'gameTimes'];

    let bytesNames = [];
    for (i = 0; i < names.length; i++) {
      bytesNames.push(web3.utils.asciiToHex(names[i]));
    }

    let values = [LISTING_FEE, TICKET_FEE, BETTING_FEE, GAME_PRESTART, GAME_DURATION, MIN_CONTRIBUTORS,
      REQ_NUM_MATCHES, ETH_PER_GAME, TOKENS_PER_GAME, GAME_TIMES];

    await proxy.execute('GameVarAndFee', setMessage(gameVarAndFee, 'setMultipleValues', [bytesNames, values]), {
      from: accounts[0]
    }).should.be.fulfilled;

    let getVar = await gameVarAndFee.getRequiredNumberMatches();
    getVar.toNumber().should.be.equal(REQ_NUM_MATCHES);

    getVar = await gameVarAndFee.getListingFee();
    getVar.toNumber().should.be.equal(LISTING_FEE);
  })

  it('registers user to the system', async () => {
    for (let i = 1; i < 20; i++) {
      await proxy.execute('Register', setMessage(register, 'register', [accounts[i]]), {
        from: accounts[i]
      }).should.be.fulfilled;
    }
  })

  it('verify users civid Id', async () => {
    for (let i = 1; i < 5; i++) {
      await proxy.execute('Register', setMessage(register, 'verifyAccount', [accounts[i], cividIds[i]]), {
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
    await proxy.execute('GameManager', setMessage(gameManager, 'listKittie',
      [156]), { from: accounts[5] }).should.be.rejected;
  })

  it('is not able to list kittie without kitty ownership', async () => {
    //account 3 not owner of kittie1
    await proxy.execute('GameManager', setMessage(gameManager, 'listKittie',
      [kitties[1]]), { from: accounts[3] }).should.be.rejected;
  })

  it('cannot list kitties without proxy', async () => {
    await gameManager.listKittie(kitties[1], { from: accounts[1] }).should.be.rejected;
  })

  it('list 4 kitties to the system', async () => {
    for (let i = 1; i < 5; i++) {
      await proxy.execute('GameManager', setMessage(gameManager, 'listKittie',
        [kitties[i]]), { from: accounts[i] }).should.be.fulfilled;
    }
  })

  it('correctly creates 2 games', async () => {
    let newGameEvents = await gameManager.getPastEvents("NewGame", { fromBlock: 0, toBlock: "latest" });
    assert.equal(newGameEvents.length, 2);

    newGameEvents.map(e => {
      console.log('\n==== NEW GAME CREATED ===');
      console.log('    GameId ', e.returnValues.gameId)
      console.log('    KittieRed ', e.returnValues.kittieRed)
      console.log('    KittieBlack ', e.returnValues.kittieBlack)
      console.log('    StartTime ', e.returnValues.gameStartTime)
      console.log('========================\n')
    })

    gameDetails = newGameEvents[0].returnValues
  })

  it('bettors can participate in a created game', async () => {

    console.log('\n==== PLAING GAME 1 ===\n');

    let { gameId, playerRed, playerBlack } = gameDetails;

    await proxy.execute('GameManager', setMessage(gameManager, 'participate',
      [gameId, playerRed]), { from: accounts[5] }).should.be.fulfilled;

    //New Supporter added
    let events = await gameManager.getPastEvents("NewSupporter", { fromBlock: 0, toBlock: "latest" });
    assert.equal(events.length, 1);


    //Cannot support the opponent too
    await proxy.execute('GameManager', setMessage(gameManager, 'participate',
      [gameId, playerBlack]), { from: accounts[5] }).should.be.rejected;

    // adds more supporters for player red
    for (let i = 6; i < 10; i++) {
      await proxy.execute('GameManager', setMessage(gameManager, 'participate',
        [gameId, playerRed]), { from: accounts[i] }).should.be.fulfilled;
    }

    // adds more supporters for player red
    for (let i = 10; i < 15; i++) {
      await proxy.execute('GameManager', setMessage(gameManager, 'participate',
        [gameId, playerBlack]), { from: accounts[i] }).should.be.fulfilled;
    }

    //Check NewSupporter events
    events = await gameManager.getPastEvents("NewSupporter", { fromBlock: 0, toBlock: "latest" });
    assert.equal(events.length, 10);

    let currentState = await getterDB.getGameState(gameId)
    console.log('\n==== NEW STATE: ', gameStates[currentState.toNumber()])
  })

  it('player cant start a game before reaching PRE_GAME', async () => {
    let { gameId, playerRed } = gameDetails;
    await proxy.execute('GameManager', setMessage(gameManager, 'startGame',
      [gameId, 99]), { from: playerRed }).should.be.rejected;
  })

  it('should move gameState to PRE_GAME', function (done) {
    console.log('\n==== WAITING FOR PREGAME TIME')
    this.timeout(180000)
    setTimeout(async function () {

      let { gameId, playerRed, playerBlack } = gameDetails;

      let currentState = await getterDB.getGameState(gameId)
      currentState.toNumber().should.be.equal(GameState.WAITING)

      //Should be able to participate in prestart state
      await proxy.execute('GameManager', setMessage(gameManager, 'participate',
        [gameId, playerBlack]), { from: accounts[15] }).should.be.fulfilled;

      await proxy.execute('GameManager', setMessage(gameManager, 'participate',
        [gameId, playerRed]), { from: accounts[16] }).should.be.fulfilled;

      let redSupporters = await getterDB.getSupporters(gameId, playerRed);
      console.log(`\n==== SUPPORTERS FOR RED CORNER: ${redSupporters.toNumber()}`);

      let blackSupporters = await getterDB.getSupporters(gameId, playerBlack);
      console.log(`\n==== SUPPORTERS FOR BLACK CORNER: ${blackSupporters.toNumber()}`);


      let newState = await getterDB.getGameState(gameId)
      console.log('\n==== NEW STATE: ', gameStates[newState.toNumber()])
      newState.toNumber().should.be.equal(GameState.PRE_GAME)

      events = await gameManager.getPastEvents("NewSupporter", { fromBlock: 0, toBlock: "latest" });
      assert.equal(events.length, 12);

      done()
    }, 31000);

  })

  it('should move gameState to MAIN_GAME', async () => {

    let { gameId, playerRed, playerBlack } = gameDetails

    await timeout(1);
    await proxy.execute('GameManager', setMessage(gameManager, 'startGame',
      [gameId, 99]), { from: playerRed }).should.be.fulfilled;
    console.log(`\n==== PLAYER RED STARTS`);

    await timeout(1);
    await proxy.execute('GameManager', setMessage(gameManager, 'startGame',
      [gameId, 100]), { from: playerBlack }).should.be.fulfilled;
    console.log(`\n==== PLAYER BLACK STARTS`);

    let gameInfo = await getterDB.getGameInfo(gameId)
    console.log('\n==== NEW STATE: ', gameStates[gameInfo.state.toNumber()])

    //Check players start button
    gameInfo.pressedStart[0].should.be.true
    gameInfo.pressedStart[1].should.be.true

    //Game starts
    gameInfo.state.toNumber().should.be.equal(GameState.MAIN_GAME)
  })

  // it('defense level', async () => { })

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

    // 4 Listed kitties, and 12 supporters
    balanceKTY.toNumber().should.be.equal(LISTING_FEE * 4 + TICKET_FEE * 12)
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

  return;

  it('supporter can successfully make a bet', async () => { })

})


