
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
// =================================================== //

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

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
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
  Simulation of 2 games created, 4 kitties listed. Game Forfeits because one player
  does not hit start on time
*/
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

  it('registers user to the system', async () => {
    for (let i = 1; i < 21; i++) {
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

    gameDetails.startTime = gameTimes.startTime.toNumber();

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


  })

  it('show cronjob details', async () => {
    let allJobs = await cronJob.getAllJobs.call();

    console.log('\n  All Jobs in cronjob linked list: ');
    allJobs.map(e => {
      console.log('  Job: ', e.toString());
    })

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
  });

  it('players press start', async () => {

    let { gameId, playerRed, playerBlack, startTime } = gameDetails

    let block = await dateTime.getBlockTimeStamp();
    console.log('\nblocktime: ', formatDate(block))

    const gene1 = "512955438081049600613224346938352058409509756310147795204209859701881294";
    const gene2 = "24171491821178068054575826800486891805334952029503890331493652557302916";

    await timeout(1);
    await proxy.execute('GameManager', setMessage(gameManager, 'startGame',
      [gameId, 2456, gene1]), { from: playerRed }).should.be.fulfilled;
    console.log(`\n==== PLAYER RED STARTS`);

    console.log('\n==== WAITING FOR MAIN GAME TIME OF GAME 1: ', formatDate(startTime))

    block = await dateTime.getBlockTimeStamp();

    while (block < startTime) {
      block = await dateTime.getBlockTimeStamp();
      await timeout(3);
    }

    console.log('\nblocktime: ', formatDate(block))

    // let game2Times = await getterDB.getGameTimes(2);

    // console.log('\n==== WAITING FOR PRE START TIME OF GAME 2: ', formatDate(game2Times.preStartTime))
    // while (block < game2Times.preStartTime) {
    //   block = await dateTime.getBlockTimeStamp();
    //   await timeout(3);
    // }

    // console.log('\nblocktime: ', formatDate(block))

    // //This proxy call cancels the game 
    // await proxy.execute('Register', setMessage(register, 'register', []), {
    //   from: accounts[21]
    // }).should.be.fulfilled;

    await proxy.execute('GameManager', setMessage(gameManager, 'startGame',
      [gameId, 1148, gene2]), { from: playerBlack }).should.be.fulfilled;
    console.log(`\n==== PLAYER BLACK TRIES TO START LATE`);

    let newState = await getterDB.getGameState(gameId)
    console.log('\n==== NEW STATE: ', gameStates[newState.toNumber()])
    newState.toNumber().should.be.equal(GameState.CANCELLED)

    let cancelledEvents = await forfeiter.getPastEvents('GameCancelled', {
      fromBlock: 0,
      toBlock: "latest"
    })
    
    console.log('\n==== CANCELLED GAME EVENTS: ', cancelledEvents.length)
    cancelledEvents.map(e => {      
      console.log('\n GameId: ', e.returnValues.gameId)
      console.log(' Reason: ', e.returnValues.reason)
    })

  })

  it('show cronjob details', async () => {

    let allJobs = await cronJob.getAllJobs.call();

    console.log('\n  All Jobs in cronjob linked list: ');
    allJobs.map(e => {
      console.log('  Job: ', e.toString());
    })

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
  });

  it('kittie hell contracts released kitties', async () => {
    let { kittieRed, kittieBlack } = gameDetails;

    //Red Kitty
    let owner = await cryptoKitties.ownerOf(kittieRed);
    owner.should.not.be.equal(kittieHELL.address)
    //Black kitty
    owner = await cryptoKitties.ownerOf(kittieBlack);
    owner.should.not.be.equal(kittieHELL.address)
  })

})


