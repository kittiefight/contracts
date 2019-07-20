const BigNumber = require('bignumber.js');
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
const KittieHELL = artifacts.require('KittieHELL')
const SuperDaoToken = artifacts.require('MockERC20Token');
const KittieFightToken = artifacts.require('MockERC20Token');
const CryptoKitties = artifacts.require('MockERC721Token');
const CronJob = artifacts.require('CronJob');
const ERC20_TOKEN_SUPPLY = new BigNumber(1000000);

//Contract instances
let proxy, dateTime, genericDB, profileDB, roleDB, superDaoToken,
  kittieFightToken, cryptoKitties, register, gameVarAndFee, endowmentFund,
  endowmentDB, distribution, forfeiter, scheduler, betting, hitsResolve,
  rarityCalculator, kittieHELL, getterDB, setterDB, gameManager, cronJob


const kittie1 = 1234
const kittie2 = 32452
const kittie3 = 23134
const kittie4 = 44444
const kittie5 = 55555
const kittie6 = 6666

const cividId1 = 1;
const cividId2 = 2;
const cividId3 = 3;
const cividId4 = 4;

// GAME VARS
const LISTING_FEE = 1000
const TICKET_FEE = 100
const BETTING_FEE = 100
const MIN_CONTRIBUTORS = 2
const REQ_NUM_MATCHES = 2
const GAME_PRESTART = 120 // 2 min
const GAME_DURATION = 300 // games last 5 min



function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

contract('GameManager', ([creator, user1, user2, user3, user4, bettor1, bettor2, bettor3, bettor4, randomAddress]) => {

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

    // CRONJOB
    cronJob = await CronJob.new(genericDB.address)

    // TOKENS
    superDaoToken = await SuperDaoToken.new(ERC20_TOKEN_SUPPLY);
    kittieFightToken = await KittieFightToken.new(ERC20_TOKEN_SUPPLY);
    cryptoKitties = await CryptoKitties.new();

    // MODULES
    gameManager = await GameManager.new()
    register = await Register.new()
    dateTime = await DateTime.new()
    gameVarAndFee = await GameVarAndFee.new(genericDB.address, randomAddress)
    distribution = await Distribution.new()
    forfeiter = await Forfeiter.new()
    scheduler = await Scheduler.new()
    betting = await Betting.new()
    hitsResolve = await HitsResolve.new()
    rarityCalculator = await RarityCalculator.new()
    endowmentFund = await EndowmentFund.new()
    // kittieHELL = await KittieHELL.new(contractManager.address)

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
    await proxy.addContract('CronJob', cronJob.address)
    // await proxy.addContract('KittieHELL', kittieHELL.address)
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
    await cronJob.setProxy(proxy.address)
    // await kittieHELL.setProxy(proxy.address)
  })

  it('initializes contract variables', async () => {
    await gameVarAndFee.initialize()
    await forfeiter.initialize()
    await scheduler.initialize()
    await register.initialize()
    await gameManager.initialize()
    await getterDB.initialize()
    await endowmentFund.initialize() //7
    await endowmentFund.initEscrow()
  })

  // Mint some kitties for the test addresses
  it('mint some kitties for the test addresses', async () => {
    await cryptoKitties.mint(user1, kittie1).should.be.fulfilled;
    await cryptoKitties.mint(user2, kittie2).should.be.fulfilled;
    await cryptoKitties.mint(user3, kittie3).should.be.fulfilled;
    await cryptoKitties.mint(user4, kittie4).should.be.fulfilled;
    await cryptoKitties.mint(user1, kittie5).should.be.fulfilled;
    await cryptoKitties.mint(user2, kittie6).should.be.fulfilled;
  })


  // Approve transfer operation for the system
  // Register no longer holds kittie
  // await cryptoKitties.approve(register.address, kittie1, { from: user1 }).should.be.fulfilled;
  // await cryptoKitties.approve(register.address, kittie2, { from: user2 }).should.be.fulfilled;
  // await cryptoKitties.approve(register.address, kittie3, { from: user3 }).should.be.fulfilled;
  // await cryptoKitties.approve(register.address, kittie4, { from: user4 }).should.be.fulfilled;
  // await cryptoKitties.approve(register.address, kittie5, { from: user5 }).should.be.fulfilled;
  // await cryptoKitties.approve(register.address, kittie6, { from: user2 }).should.be.fulfilled;


  it('transfer some KTY for the test addresses', async () => {
    await kittieFightToken.transfer(user1, 100000).should.be.fulfilled;
    await kittieFightToken.transfer(user2, 100000).should.be.fulfilled;
    await kittieFightToken.transfer(user3, 100000).should.be.fulfilled;
    await kittieFightToken.transfer(user4, 100000).should.be.fulfilled;
    await kittieFightToken.transfer(bettor1, 100000).should.be.fulfilled;
    await kittieFightToken.transfer(bettor2, 100000).should.be.fulfilled;
    await kittieFightToken.transfer(bettor3, 100000).should.be.fulfilled;
    await kittieFightToken.transfer(bettor4, 100000).should.be.fulfilled;
  })


  it('approves erc20 token transfer operation by endowment contract', async () => {
    await kittieFightToken.approve(endowmentFund.address, 100000, { from: user1 }).should.be.fulfilled;
    await kittieFightToken.approve(endowmentFund.address, 100000, { from: user2 }).should.be.fulfilled;
    await kittieFightToken.approve(endowmentFund.address, 100000, { from: user3 }).should.be.fulfilled;
    await kittieFightToken.approve(endowmentFund.address, 100000, { from: user4 }).should.be.fulfilled;
    await kittieFightToken.approve(endowmentFund.address, 100000, { from: bettor1 }).should.be.fulfilled;
    await kittieFightToken.approve(endowmentFund.address, 100000, { from: bettor2 }).should.be.fulfilled;
    await kittieFightToken.approve(endowmentFund.address, 100000, { from: bettor3 }).should.be.fulfilled;
    await kittieFightToken.approve(endowmentFund.address, 100000, { from: bettor4 }).should.be.fulfilled;
  })

  //Set var and fees
  it('Set game vars and fees correctly', async () => {
    let names = ['listingFee', 'ticketFee', 'gamePrestart', 'gameDuration', 'minimumContributors', 'requiredNumberMatches'];
    let values = [LISTING_FEE, TICKET_FEE, GAME_PRESTART, GAME_DURATION, MIN_CONTRIBUTORS, REQ_NUM_MATCHES];

    await proxy.execute('GameVarAndFee', setMessage(gameVarAndFee, 'setMultipleValues', [names, values]), {
      from: creator
    }).should.be.fulfilled;

    let getVar = await gameVarAndFee.getRequiredNumberMatches();

    getVar.toNumber().should.be.equal(2);


    // await proxy.execute('GameVarAndFee', setMessage(gameVarAndFee, 'setVarAndFee', ['listingFee', 1000]), {
    //   from: creator
    // }).should.be.fulfilled;
    // await proxy.execute('GameVarAndFee', setMessage(gameVarAndFee, 'setVarAndFee', ['ticketFee', 100]), {
    //   from: creator
    // }).should.be.fulfilled;
    // await proxy.execute('GameVarAndFee', setMessage(gameVarAndFee, 'setVarAndFee', ['gamePrestart', 120]), {
    //   from: creator
    // }).should.be.fulfilled;
    // await proxy.execute('GameVarAndFee', setMessage(gameVarAndFee, 'setVarAndFee', ['gameDuration', 300]), {
    //   from: creator
    // }).should.be.fulfilled;
    // await proxy.execute('GameVarAndFee', setMessage(gameVarAndFee, 'setVarAndFee', ['minimumContributors', 2]), {
    //   from: creator
    // }).should.be.fulfilled;
    // await proxy.execute('GameVarAndFee', setMessage(gameVarAndFee, 'setVarAndFee', ['requiredNumberMatches', 2]), {
    //   from: creator
    // }).should.be.fulfilled;
  })

  it('registers user to the system', async () => {
    await proxy.execute('Register', setMessage(register, 'register', [user1]), {
      from: user1
    }).should.be.fulfilled;
    await proxy.execute('Register', setMessage(register, 'register', [user2]), {
      from: user2
    }).should.be.fulfilled;
    await proxy.execute('Register', setMessage(register, 'register', [user3]), {
      from: user3
    }).should.be.fulfilled;
    await proxy.execute('Register', setMessage(register, 'register', [user4]), {
      from: user4
    }).should.be.fulfilled;
    await proxy.execute('Register', setMessage(register, 'register', [bettor1]), {
      from: bettor1
    }).should.be.fulfilled;
    await proxy.execute('Register', setMessage(register, 'register', [bettor2]), {
      from: bettor2
    }).should.be.fulfilled;
    await proxy.execute('Register', setMessage(register, 'register', [bettor3]), {
      from: bettor3
    }).should.be.fulfilled;
    await proxy.execute('Register', setMessage(register, 'register', [bettor4]), {
      from: bettor4
    }).should.be.fulfilled;
  })


  it('verify users civid Id', async () => {
    await proxy.execute('Register', setMessage(register, 'verifyAccount', [user1, cividId1]), {
      from: user1
    }).should.be.fulfilled;
    await proxy.execute('Register', setMessage(register, 'verifyAccount', [user2, cividId2]), {
      from: user2
    }).should.be.fulfilled;
    await proxy.execute('Register', setMessage(register, 'verifyAccount', [user3, cividId3]), {
      from: user3
    }).should.be.fulfilled;
    await proxy.execute('Register', setMessage(register, 'verifyAccount', [user4, cividId4]), {
      from: user4
    }).should.be.fulfilled;
  })

  it('verified users have player role', async () => {
    let hasRole = await roleDB.hasRole('player', user1);
    hasRole.should.be.true;

    hasRole = await roleDB.hasRole('player', user2);
    hasRole.should.be.true;
  })

  it('unverified users cannot list kitties', async () => {
    await proxy.execute('GameManager', setMessage(gameManager, 'listKittie',
      [156]), { from: bettor1 }).should.be.rejected;
  })

  it('is not able to list kittie without kitty ownership', async () => {
    //user2 not owner of kittie1
    await proxy.execute('GameManager', setMessage(gameManager, 'listKittie',
      [kittie2]), { from: user1 }).should.be.rejected;
  })

  it('cannot list kitties without proxy', async () => {
    await gameManager.listKittie(kittie1, { from: user1 }).should.be.rejected;
    await gameManager.listKittie(kittie2, { from: user2 }).should.be.rejected;
  })

  it('list 4 kitties to the system', async () => {
    await proxy.execute('GameManager', setMessage(gameManager, 'listKittie',
      [kittie1]), { from: user1 }).should.be.fulfilled;

    await proxy.execute('GameManager', setMessage(gameManager, 'listKittie',
      [kittie2]), { from: user2 }).should.be.fulfilled;

    await proxy.execute('GameManager', setMessage(gameManager, 'listKittie',
      [kittie3]), { from: user3 }).should.be.fulfilled;

    await proxy.execute('GameManager', setMessage(gameManager, 'listKittie',
      [kittie4]), { from: user4 }).should.be.fulfilled;
  })

  it('correctly creates 2 games', async () => {
    let events = await setterDB.getPastEvents("NewGame", { fromBlock: 0, toBlock: "latest" });
    assert.equal(events.length, 2);

    console.log('\nGames Created: \n');
    events.map(e => {
      console.log('-GameId ', e.returnValues.gameId)
      console.log('KittiRed ', e.returnValues.kittieRed)
      console.log('KittiBlack ', e.returnValues.kittieBlack)
      console.log('---')
    })
  })



  //--- PARTICIPATING -----
  it('user can participate in a created game', async () => {

    let events = await setterDB.getPastEvents("NewGame", { fromBlock: 0, toBlock: "latest" });

    //Check games that user1 is not in
    let gameNotIn = events
      .filter(e => ((e.returnValues.playerRed !== user1) || (e.returnValues.playerBlack !== user1)))

    let { gameId, playerRed, playerBlack } = gameNotIn[0].returnValues;

    await proxy.execute('GameManager', setMessage(gameManager, 'participate',
      [gameId, playerRed]), { from: user1 }).should.be.fulfilled;

    //New Supporter added
    events = await setterDB.getPastEvents("NewSupporter", { fromBlock: 0, toBlock: "latest" });
    assert.equal(events.length, 1);

    //Cannot support the opponent too
    await proxy.execute('GameManager', setMessage(gameManager, 'participate',
      [gameId, playerBlack]), { from: user1 }).should.be.rejected;

  })

  return;


})


