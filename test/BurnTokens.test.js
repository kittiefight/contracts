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
    rarityCalculator, kittieHell, kittieHellDB, getterDB, setterDB, gameManager,
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
const GAME_PRESTART = 30 // 30 secs for quick test
const GAME_DURATION = 60 // games last  1 min
const ETH_PER_GAME = new BigNumber(web3.utils.toWei("10", "ether"));
const TOKENS_PER_GAME = new BigNumber(web3.utils.toWei("10000", "ether"));
const GAME_TIMES = 60 //Scheduled games 2 min apart
const KITTIE_HELL_EXPIRATION = 300
const HONEY_POT_EXPIRATION = 180
//const KITTIE_REDEMPTION_FEE = new BigNumber(web3.utils.toWei("500", "ether"));
const FINALIZE_REWARDS = new BigNumber(web3.utils.toWei("500", "ether")); //500 KTY
//Distribution Rates
const WINNING_KITTIE = 35
const TOP_BETTOR = 25
const SECOND_RUNNER_UP = 10
const OTHER_BETTORS = 15
const ENDOWNMENT = 15
const PERCENTAGEFORKITTIEREDEMPTIONFEE = 10
const USDKTYPRICE = new BigNumber(web3.utils.toWei('0.4', 'ether')) // 0.4 USD to 1 KTY
const REQUIRED_KITTIE_SACRIFICE_NUM = 3
// =================================================== //

//If you change endowment initial tokens, need to change deployment file too

// ======== INITIAL AMOUNTS ================ //
const TOKENS_FOR_USERS = new BigNumber(
    web3.utils.toWei("10000", "ether") //5.000 KTY 
);

const INITIAL_KTY_ENDOWMENT = new BigNumber(
    web3.utils.toWei("100000", "ether") //50.000 KTY
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
        kittieHell = await KittieHELL.deployed()

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
            await cryptoKitties.approve(kittieHell.address, kitties[i], { from: accounts[i] }).should.be.fulfilled;
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
            'gameTimes', 'kittieHellExpiration', 'honeypotExpiration', 'winningKittie', 'topBettor', 'secondRunnerUp', 'otherBettors', 'endownment',
            'finalizeRewards', 'percentageForKittieRedemptionFee', 'usdKTYPrice', 'requiredKittieSacrificeNum'];

        let bytesNames = [];
        for (i = 0; i < names.length; i++) {
            bytesNames.push(web3.utils.asciiToHex(names[i]));
        }

        let values = [LISTING_FEE.toString(), TICKET_FEE.toString(), BETTING_FEE.toString(), GAME_PRESTART, GAME_DURATION, MIN_CONTRIBUTORS,
            REQ_NUM_MATCHES, ETH_PER_GAME.toString(), TOKENS_PER_GAME.toString(), GAME_TIMES, KITTIE_HELL_EXPIRATION,
            HONEY_POT_EXPIRATION, WINNING_KITTIE, TOP_BETTOR, SECOND_RUNNER_UP,
            OTHER_BETTORS, ENDOWNMENT, FINALIZE_REWARDS.toString(), PERCENTAGEFORKITTIEREDEMPTIONFEE, USDKTYPRICE.toString(), REQUIRED_KITTIE_SACRIFICE_NUM];

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

        // Supporters for playerRed now are accounts[5] till accounts[10], so 6
        for (let i = 6; i < 11; i++) {
            let index = Math.floor(Math.random() * 2)
            await proxy.execute('GameManager', setMessage(gameManager, 'participate',
                [gameId, playerRed]), { from: accounts[i] }).should.be.fulfilled;
        }

        // Supporters for playerBlack now are accounts[11] till accounts[15], so 5
        for (let i = 11; i < 16; i++) {
            let index = Math.floor(Math.random() * 2)
            await proxy.execute('GameManager', setMessage(gameManager, 'participate',
                [gameId, playerBlack]), { from: accounts[i] }).should.be.fulfilled;
        }

        // // adds more supporters for player red
        // for (let i = 12; i < 18; i++) {
        //   await proxy.execute('GameManager', setMessage(gameManager, 'participate',
        //     [gameId, playerBlack]), { from: accounts[i] }).should.be.fulfilled;
        // }

        //Check NewSupporter events
        events = await gameManager.getPastEvents("NewSupporter", { fromBlock: 0, toBlock: "latest" });
        assert.equal(events.length, 11);
    })


    it('moves gameState to PRE_GAME', async () => {
        let { gameId, playerRed, playerBlack, preStartTime } = gameDetails;

        console.log('\n==== WAITING FOR PREGAME TIME: ', formatDate(preStartTime))

        let block = await dateTime.getBlockTimeStamp();
        console.log('\nblocktime: ', formatDate(block))

        if (block < preStartTime) {
            block = await dateTime.getBlockTimeStamp();
            await timeout(preStartTime-block);
        }

        let currentState = await getterDB.getGameState(gameId)
        currentState.toNumber().should.be.equal(GameState.WAITING)

        //IDEA: Player can hit button to change state, and have benefits in kittie redemption

        //Should be able to participate in prestart state+++Bettor for black, so now participators 6 for each side
        await proxy.execute('GameManager', setMessage(gameManager, 'participate',
            [gameId, playerBlack]), { from: accounts[16] }).should.be.fulfilled;

        //Show supporters
        let redSupporters = await getterDB.getSupporters(gameId, playerRed);
        console.log(`\n==== SUPPORTERS FOR RED CORNER: ${redSupporters.toNumber()}`);

        let blackSupporters = await getterDB.getSupporters(gameId, playerBlack);
        console.log(`\n==== SUPPORTERS FOR BLACK CORNER: ${blackSupporters.toNumber()}`);


        let newState = await getterDB.getGameState(gameId)
        console.log('\n==== NEW STATE: ', gameStates[newState.toNumber()])
        newState.toNumber().should.be.equal(GameState.PRE_GAME)

        events = await gameManager.getPastEvents("NewSupporter", { fromBlock: 0, toBlock: "latest" });
        assert.equal(events.length, 12);


    })

    it('moves gameState to MAIN_GAME', async () => {

        let { gameId, playerRed, playerBlack } = gameDetails

        let block = await dateTime.getBlockTimeStamp();
        console.log('\nblocktime: ', formatDate(block))

        await timeout(1);
        await proxy.execute('GameManager', setMessage(gameManager, 'startGame',
            [gameId, 2456, "24171491821178068054575826800486891805334952029503890331493652557302916"]), { from: playerRed }).should.be.fulfilled;
        console.log(`\n==== PLAYER RED STARTS`);

        await timeout(1);

        await proxy.execute('GameManager', setMessage(gameManager, 'startGame',
            [gameId, 1148, "512955438081049600613224346938352058409509756310147795204209859701881294"]), { from: playerBlack }).should.be.fulfilled;
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

    it('kittie hell contracts is now owner of fighting kitties', async () => {
        let { kittieRed, kittieBlack } = gameDetails;

        //Red Kitty
        let owner = await cryptoKitties.ownerOf(kittieRed);
        owner.should.be.equal(kittieHell.address)
        //Black kitty
        owner = await cryptoKitties.ownerOf(kittieBlack);
        owner.should.be.equal(kittieHell.address)
    })

    it('betting algo creates a fight map', async () => {
        let { gameId } = gameDetails;

        let attack = [];
        let fightMap = {};
        console.log('\n==== FIGHT MAP CREATED')
        for (let i = 0; i < 7; i++) {
            attack[i] = await betting.fightMap(gameId, i)
            console.log(`Name: ${attack[i].attack}`);
            console.log(`Hash: ${attack[i].hash}\n`);
            fightMap[attack[i].hash] = attack[i].attack;
        }
        console.log('=================\n')
        gameDetails.fightMap = fightMap;
    })

    it('players make bets', async () => {
        let { gameId, playerRed, playerBlack } = gameDetails;

        let currentState = await getterDB.getGameState(gameId)
        currentState.toNumber().should.be.equal(GameState.MAIN_GAME)

        let betDetails;

        let opponentRed = playerBlack;//await getterDB.getOpponent(gameId, playerRed);
        console.log('\n==== OPPONENT RED: ', opponentRed);
        let opponentBlack = playerRed; //await getterDB.getOpponent(gameId, playerBlack);
        console.log('\n==== OPPONENT BLACK: ', opponentBlack);

        let betsBlack = [];
        let betsRed = [];


        //This one is to make 4 conscutive bets (1ETH till 4ETH), so as to see if defense level is changing
        //One other bet is from fillBets with betting 0, so that's why they are 4 and not 5
        for (let i = 5; i < 10; i++) {

            //betAmount is bigger each time to check for consecutive bets
            let betAmount = i - 4
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
                //This line make bets in black be incremental
                //betAmount = 1 + i
                betsBlack.push(betAmount);
                (blackBetStore.has(bettor)) ?
                    blackBetStore.set(bettor, blackBetStore.get(bettor) + betAmount) :
                    blackBetStore.set(bettor, betAmount)
            }

            if (i == 9) console.log(`\n==== SHOULD LOWER BLACKS DEFENSE ====`);
            await proxy.execute('GameManager', setMessage(gameManager, 'bet',
                [gameId, betAmount]), { from: bettor, value: web3.utils.toWei(String(betAmount)) }).should.be.fulfilled;

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

            //Till now we have 1 + 2 +...+ 6 = 21 Eth bet and starting honeypot was 100 Eth
            totalBetAmount = totalBetAmount + betAmount;
            await timeout(2);
        }

        for (let i = 11; i < 15; i++) {

            let betAmount = 0
            let bettor = accounts[i]
            let supporterInfo = await getterDB.getSupporterInfo(gameId, accounts[i])
            let supportedPlayer = supporterInfo.supportedPlayer;
            let player



            if (i == 11) {
                //We do one bet from accounts[11] (Supporter of black), while last hit for Red corner was 2 seconds ago, so must be blocked
                //Also, now we have 31 Eth bet
                betAmount = 10
                console.log(`\n==== SHOULD BE BLOCKED ====`);
                await proxy.execute('GameManager', setMessage(gameManager, 'bet',
                    [gameId, 10]), { from: accounts[i], value: web3.utils.toWei(String(10)) }).should.be.fulfilled;
            }
            else if (i == 12) {
                //We make a higher hit, to check that is high attack
                //Also, now we have 42 Eth bet
                betAmount = 11
                console.log(`\n==== SHOULD BE HIGH ATTACK ====`);
                await proxy.execute('GameManager', setMessage(gameManager, 'bet',
                    [gameId, 11]), { from: accounts[12], value: web3.utils.toWei(String(11)) }).should.be.fulfilled;
            }
            else if (i == 13) {
                //We make a lower hit, to check that is low attack
                //Also, now we have 44 Eth bet
                betAmount = 2
                console.log(`\n==== SHOULD BE LOW ATTACK ====`);
                await proxy.execute('GameManager', setMessage(gameManager, 'bet',
                    [gameId, 2]), { from: accounts[13], value: web3.utils.toWei(String(2)) }).should.be.fulfilled;
            }
            else if (i == 14) {
                //We make an equal hit, to check that is low attack
                //Also, now we have 46 Eth bet
                betAmount = 2
                console.log(`\n==== SHOULD BE LOW ATTACK ====`);
                await proxy.execute('GameManager', setMessage(gameManager, 'bet',
                    [gameId, 2]), { from: accounts[14], value: web3.utils.toWei(String(2)) }).should.be.fulfilled;
            }

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
            console.log(' Attack Name in Fight Map:', gameDetails.fightMap[betDetails.attackHash]);
            console.log(' Blocked?:', betDetails.isBlocked);
            console.log(` Defense ${player}:`, betDetails.defenseLevelSupportedPlayer);
            console.log(' Defense Opponent:', betDetails.defenseLevelOpponent);

            let lastBetTimestamp = await betting.lastBetTimestamp(gameId, supportedPlayer);
            console.log(' Timestamp last Bet: ', formatDate(lastBetTimestamp));

            totalBetAmount = totalBetAmount + betAmount;
            await timeout(2);
        }

        console.log('\nBets Black: ', betsBlack)
        console.log('Bets Red: ', betsRed)
    })

    it('get final defense level for both players', async () => {
        let { gameId, playerRed, playerBlack } = gameDetails;

        let defense = await betting.defenseLevel(gameId, playerBlack);
        console.log(`\n==== FINAL DEFENSE BLACK: ${defense}`);

        defense = await betting.defenseLevel(gameId, playerRed);
        console.log(`\n==== FINAL DEFENSE RED: ${defense}`);
    })

    it('display honeypot info', async () => {

        let { gameId } = gameDetails;

        let honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

        console.log(`\n==== HONEPOT INFO ==== `)
        console.log(`     InitialEtH: ${web3.utils.fromWei(honeyPotInfo.initialEth.toString())}   `);
        console.log(`     TotalETH: ${web3.utils.fromWei(honeyPotInfo.ethTotal.toString())}   `);
        console.log(`     TotalKTY: ${web3.utils.fromWei(honeyPotInfo.ktyTotal.toString())}   `);
        console.log('=======================\n')

        await timeout(1);
    })

    it('game ends', async () => {

        let { gameId, endTime } = gameDetails;

        console.log('\n==== WAITING FOR PREVIOUS GAME OVER TIME: ', formatDate(endTime))

        let block = await dateTime.getBlockTimeStamp();
        console.log('\nblocktime: ', formatDate(block))

        if (block < endTime) {
            block = await dateTime.getBlockTimeStamp();
            await timeout(endTime-block);
        }

        await proxy.execute('GameManager', setMessage(gameManager, 'bet',
            [gameId, randomValue()]), { from: accounts[7], value: web3.utils.toWei('50') }).should.be.fulfilled;

            let honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

            console.log(`\n==== HONEPOT INFO ==== `)
            console.log(`     InitialEtH: ${web3.utils.fromWei(honeyPotInfo.initialEth.toString())}   `);
            console.log(`     TotalETH: ${web3.utils.fromWei(honeyPotInfo.ethTotal.toString())}   `);
            console.log(`     TotalKTY: ${web3.utils.fromWei(honeyPotInfo.ktyTotal.toString())}   `);
            console.log('=======================\n')
    

        let currentState = await getterDB.getGameState(gameId)
        currentState.toNumber().should.be.equal(3);
        /*block = await dateTime.getBlockTimeStamp();
        console.log('\n==== SAME GAME STATE: ', gameStates[currentState.toNumber()])

        let times = await getterDB.getGameTimes(gameId);
        console.log('\n==== GAME EXTENDED TO: ', formatDate(times.endTime.toNumber()));

        let gameExtendedEvents = await gameManager.getPastEvents('GameExtended', {
            filter: { gameId },
            fromBlock: 0,
            toBlock: "latest"
        })

        gameExtendedEvents.length.should.be.equal(1);

        await timeout(1);*/

    })

    it('finalizes a game', async () => {
        let { gameId } = gameDetails;
        let {playerBlack, playerRed, kittyBlack, kittyRed} = await getterDB.getGamePlayers(gameId);
        let finalizer = accounts[10];
        await proxy.execute('GameManager', setMessage(gameManager, 'finalize',
      [gameId, 301]), { from: finalizer });

      let gameEnd = await gameManager.getPastEvents('GameEnded', {
        filter: { gameId },
        fromBlock: 0,
        toBlock: 'latest'
      })
  
      let state = await getterDB.getGameState(gameId);
      console.log(state);
  
      let { pointsBlack, pointsRed, loser } = gameEnd[0].returnValues;
  
      let winners = await getterDB.getWinners(gameId);

      console.log(winners)
  
      let corner = (winners.winner === playerBlack) ? "Black Corner" : "Red Corner";
  
      console.log(`\n==== WINNER: ${corner} ==== `)
      console.log(`   Winner: ${winners.winner}   `);
      console.log(`   TopBettor: ${winners.topBettor}   `)
      console.log(`   SecondTopBettor: ${winners.secondTopBettor}   `)
      console.log('')
      console.log(`   Points Black: ${pointsBlack}   `);
      console.log(`   Point Red: ${pointsRed}   `);
      console.log('=======================\n')

      await timeout(3);

    let honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `)
    console.log(`     InitialEtH: ${web3.utils.fromWei(honeyPotInfo.initialEth.toString())}   `);
    console.log(`     TotalETH: ${web3.utils.fromWei(honeyPotInfo.ethTotal.toString())}   `);
    console.log(`     TotalKTY: ${web3.utils.fromWei(honeyPotInfo.ktyTotal.toString())}   `);
    console.log('=======================\n')
    
    let finalHoneypot = await getterDB.getFinalHoneypot(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `)
    console.log(`     TotalETH: ${web3.utils.fromWei(finalHoneypot.totalEth.toString())}   `);
    console.log(`     TotalKTY: ${web3.utils.fromWei(finalHoneypot.totalKty.toString())}   `);
    console.log('=======================\n')
    })

    it('winners claim winnings', async () => {
        let { gameId } = gameDetails;

    let winners = await getterDB.getWinners(gameId);
    let winner = winners.winner;
    let numberOfSupporters;
    let incrementingNumber;
    let claimer;

    let winnerShare = await endowmentFund.getWinnerShare(gameId, winners.winner);
    console.log('\nWinner withdrawing ', String(web3.utils.fromWei(winnerShare.winningsETH.toString())), 'ETH')
    console.log('Winner withdrawing ', String(web3.utils.fromWei(winnerShare.winningsKTY.toString())), 'KTY')
    await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'claim',
      [gameId]), { from: winners.winner });
    let withdrawalState = await endowmentFund.getWithdrawalState(gameId, winners.winner);
    console.log('Withdrew funds from Winner? ', withdrawalState);

    let honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `)
    console.log(`     InitialEtH: ${web3.utils.fromWei(honeyPotInfo.initialEth.toString())}   `);
    console.log(`     TotalETH: ${web3.utils.fromWei(honeyPotInfo.ethTotal.toString())}   `);
    console.log(`     TotalKTY: ${web3.utils.fromWei(honeyPotInfo.ktyTotal.toString())}   `);
    console.log('=======================\n')

    await timeout(1);

    let topBettorsShare = await endowmentFund.getWinnerShare(gameId, winners.topBettor);
    console.log('\nTop Bettor withdrawing ', String(web3.utils.fromWei(topBettorsShare.winningsETH.toString())), 'ETH')
    console.log('Top Bettor withdrawing ', String(web3.utils.fromWei(topBettorsShare.winningsKTY.toString())), 'KTY')
    await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'claim',
      [gameId]), { from: winners.topBettor });
    withdrawalState = await endowmentFund.getWithdrawalState(gameId, winners.topBettor);
    console.log('Withdrew funds from Top Bettor? ', withdrawalState);

    honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `)
    console.log(`     InitialEtH: ${web3.utils.fromWei(honeyPotInfo.initialEth.toString())}   `);
    console.log(`     TotalETH: ${web3.utils.fromWei(honeyPotInfo.ethTotal.toString())}   `);
    console.log(`     TotalKTY: ${web3.utils.fromWei(honeyPotInfo.ktyTotal.toString())}   `);
    console.log('=======================\n')

    await timeout(1);

    let secondTopBettorsShare = await endowmentFund.getWinnerShare(gameId, winners.secondTopBettor);
    console.log('\nSecond Top Bettor withdrawing ', String(web3.utils.fromWei(secondTopBettorsShare.winningsETH.toString())), 'ETH')
    console.log('Second Top Bettor withdrawing ', String(web3.utils.fromWei(secondTopBettorsShare.winningsKTY.toString())), 'KTY')
    await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'claim',
      [gameId]), { from: winners.secondTopBettor });
    withdrawalState = await endowmentFund.getWithdrawalState(gameId, winners.secondTopBettor);
    console.log('Withdrew funds from Second Top Bettor? ', withdrawalState);

    honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `)
    console.log(`     InitialEtH: ${web3.utils.fromWei(honeyPotInfo.initialEth.toString())}   `);
    console.log(`     TotalETH: ${web3.utils.fromWei(honeyPotInfo.ethTotal.toString())}   `);
    console.log(`     TotalKTY: ${web3.utils.fromWei(honeyPotInfo.ktyTotal.toString())}   `);
    console.log('=======================\n')

    await timeout(1);


    let {playerBlack, playerRed, kittyBlack, kittyRed} = await getterDB.getGamePlayers(gameId);

    if(winner === playerBlack){
      numberOfSupporters = await getterDB.getSupporters(gameId, playerBlack);
      incrementingNumber = 10;
    }
    else{
      numberOfSupporters = await getterDB.getSupporters(gameId, playerRed);
      incrementingNumber = 30; 
    }

    for(let i=0; i<numberOfSupporters; i++){
      claimer = accounts[i+incrementingNumber];
      if(claimer === winners.topBettor) continue;
      else if(claimer === winners.secondTopBettor) continue;
      else{

        share = await endowmentFund.getWinnerShare(gameId, claimer);
        console.log('\nClaimer withdrawing ', String(web3.utils.fromWei(share.winningsETH.toString())), 'ETH')
        console.log('Claimer withdrawing ', String(web3.utils.fromWei(share.winningsKTY.toString())), 'KTY')
        if(Number(String(web3.utils.fromWei(share.winningsETH.toString()))) != 0){
          await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'claim',
            [gameId]), { from: claimer });
          withdrawalState = await endowmentFund.getWithdrawalState(gameId, claimer);
          console.log('Withdrew funds from Claimer? ', withdrawalState);
        }

        honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

        console.log(`\n==== HONEYPOT INFO ==== `)
        console.log(`     InitialEtH: ${web3.utils.fromWei(honeyPotInfo.initialEth.toString())}   `);
        console.log(`     TotalETH: ${web3.utils.fromWei(honeyPotInfo.ethTotal.toString())}   `);
        console.log(`     TotalKTY: ${web3.utils.fromWei(honeyPotInfo.ktyTotal.toString())}   `);
        console.log('=======================\n')

        await timeout(1);
    }}
    })

    it('the loser can redeem his/her kitty, dynamic redemption fee is burnt to kittieHELL, replacement kitties become permanent ghosts in kittieHELL', async () => {
        let { gameId } = gameDetails;
        let winners = await getterDB.getWinners(gameId);

    let {playerBlack, playerRed, kittyBlack, kittyRed} = await getterDB.getGamePlayers(gameId);

    let loserKitty;
    let loser;

    if(winners.winner === playerRed){
      loser = playerBlack;
      loserKitty = Number(kittyBlack);
    }
    else{
      loser = playerRed;
      loserKitty = Number(kittyRed);
    }

    console.log("Loser's Kitty: " + loserKitty)

    let resurrectionCost = await kittieHell.getResurrectionCost(loserKitty, gameId);

    const redemptionFee = web3.utils.fromWei(resurrectionCost.toString(), 'ether')
    const kittieRedemptionFee = Math.round(parseFloat(redemptionFee))
    console.log("Loser's Kitty redemption fee in KTY: " + kittieRedemptionFee)

    const sacrificeKitties = [1017555, 413830, 888]

    for (let i = 0; i < sacrificeKitties.length; i++) {
        await cryptoKitties.mint(loser, sacrificeKitties[i]);
    }

    for (let i = 0; i < sacrificeKitties.length; i++) {
        await cryptoKitties.approve(kittieHellDB.address, sacrificeKitties[i], { from: loser });
    }

    //for (let i = 0; i < sacrificeKitties.length; i++) {
      //  await proxy.execute('KittieHellDB', setMessage(kittieHellDB, 'sacrificeKittieToHell',
        //[loserKitty, loser, sacrificeKitties[i]]), { from: loser });
    //}

    await kittieFightToken.approve(kittieHell.address, resurrectionCost,
        { from: loser });
    
    await proxy.execute('KittieHell', setMessage(kittieHell, 'payForResurrection',
        [loserKitty, gameId, loser, sacrificeKitties]), { from: loser });

    let owner = await cryptoKitties.ownerOf(loserKitty);

    if (owner === loser){
      console.log('Kitty Redeemed');
    }

    let numberOfSacrificeKitties = await kittieHellDB.getNumberOfSacrificeKitties(loserKitty)
    console.log("Number of sacrificing kitties in kittieHELL for "+loserKitty+": "+numberOfSacrificeKitties.toNumber())

    let KTYsLockedInKittieHell = await kittieHellDB.getTotalKTYsLockedInKittieHell()
    const ktys = web3.utils.fromWei(KTYsLockedInKittieHell.toString(), 'ether')
    const ktysLocked = Math.round(parseFloat(ktys))
    console.log("KTYs locked in kittieHELL: "+ktysLocked)

    const isLoserKittyInHell = await kittieHellDB.isKittieGhost(loserKitty)
    console.log("Is Loser's kitty in Hell? "+isLoserKittyInHell)

    const isSacrificeKittyOneInHell = await kittieHellDB.isKittieGhost(sacrificeKitties[0])
    console.log("Is sacrificing kitty 1 in Hell? "+isSacrificeKittyOneInHell)

    const isSacrificeKittyTwoInHell = await kittieHellDB.isKittieGhost(sacrificeKitties[1])
    console.log("Is sacrificing kitty 2 in Hell? "+isSacrificeKittyTwoInHell)

    const isSacrificeKittyThreeInHell = await kittieHellDB.isKittieGhost(sacrificeKitties[2])
    console.log("Is sacrificing kitty 3 in Hell? "+isSacrificeKittyThreeInHell)

    })

})
