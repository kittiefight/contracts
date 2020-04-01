const BigNumber = web3.utils.BN;
require('chai')
  .use(require('chai-shallow-deep-equal'))
  .use(require('chai-bignumber')(BigNumber))
  .use(require('chai-as-promised'))
  .should();

//ARTIFACTS
const KFProxy = artifacts.require('KFProxy')
const GenericDB = artifacts.require('GenericDB');
const ProfileDB = artifacts.require('ProfileDB')
const RoleDB = artifacts.require('RoleDB')
const HoneypotAllocationAlgo = artifacts.require('HoneypotAllocationAlgo')
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

function randomValue(num) {
  	return Math.floor(Math.random() * num) + 1; // (1-num) value
}

//Contract instances
let proxy, dateTime, genericDB, profileDB, roleDB, superDaoToken,
  	kittieFightToken, cryptoKitties, register, gameVarAndFee, endowmentFund,
  	endowmentDB, forfeiter, scheduler, betting, hitsResolve,
  	rarityCalculator, kittieHell, kittieHellDB, getterDB, setterDB, gameManager,
  	cronJob, escrow, honeypotAllocationAlgo;

contract('GameManager', (accounts) => {
	it('instantiate contracts', async () => {
		// PROXY
		proxy = await KFProxy.deployed();

		// DATABASES
		genericDB = await GenericDB.deployed();
		profileDB = await ProfileDB.deployed();
		roleDB = await RoleDB.deployed();
		endowmentDB = await EndowmentDB.deployed();
		getterDB = await GMGetterDB.deployed();
		setterDB = await GMSetterDB.deployed();
		kittieHellDB = await KittieHellDB.deployed();

		// CRONJOB
		cronJob = await CronJob.deployed();
		freezeInfo = await FreezeInfo.deployed();
		cronJobTarget = await CronJobTarget.deployed();


		// TOKENS
		superDaoToken = await SuperDaoToken.deployed();
		kittieFightToken = await KittieFightToken.deployed();
		cryptoKitties = await CryptoKitties.deployed();

        // MODULES
        honeypotAllocationAlgo = await HoneypotAllocationAlgo.deployed()
		gameManager = await GameManager.deployed();
		gameStore = await GameStore.deployed();
		gameCreation = await GameCreation.deployed();
		register = await Register.deployed();
		dateTime = await DateTime.deployed();
		gameVarAndFee = await GameVarAndFee.deployed();
		forfeiter = await Forfeiter.deployed();
		scheduler = await Scheduler.deployed();
		betting = await Betting.deployed();
		hitsResolve = await HitsResolve.deployed();
		rarityCalculator = await RarityCalculator.deployed();
		endowmentFund = await EndowmentFund.deployed();
		kittieHell = await KittieHELL.deployed();

		//ESCROW
		escrow = await Escrow.deployed();
	})

	it('registers 40 users', async () => {
		let users = 40;

		for(let i = 1; i <= users; i++){
	      	await proxy.execute('Register', setMessage(register, 'register', []), {
	        	from: accounts[i]
	      	}).should.be.fulfilled;

	      	let isRegistered = await register.isRegistered(accounts[i]);
	    } 
	})

	it('sends 30000 KTYs to 40 users', async () => {
		let amountKTY = 30000;
		let users = 40;

		for(let i = 1; i <= users; i++){
	      	await kittieFightToken.transfer(accounts[i], web3.utils.toWei(String(amountKTY)), {
	          	from: accounts[0]}).should.be.fulfilled;

	      	await kittieFightToken.approve(endowmentFund.address, web3.utils.toWei(String(amountKTY)) , { from: accounts[i] }).should.be.fulfilled;

	      	let userBalance = await kittieFightToken.balanceOf(accounts[i]);
	    } 
	})

	it('mints kitties for 2 users', async () => {
		let users = 8;

		let kitties = [324, 1001, 1555108, 1267904, 454545, 333, 6666, 2111];
	    let cividIds = [1, 2, 3, 4, 5, 6, 7, 8];

	  	await cryptoKitties.mint(accounts[1], kitties[0], { from: accounts[0] }).should.be.fulfilled;
	  	await cryptoKitties.approve(kittieHell.address, kitties[0], { from: accounts[1] }).should.be.fulfilled;
	  	await proxy.execute('Register', setMessage(register, 'verifyAccount', [cividIds[0]]), { from: accounts[1]}).should.be.fulfilled;

	  	console.log(`New Player ${accounts[1]} with Kitty ${kitties[0]}`);

	  	await cryptoKitties.mint(accounts[2], kitties[1], { from: accounts[0] }).should.be.fulfilled;
	  	await cryptoKitties.approve(kittieHell.address, kitties[1], { from: accounts[2] }).should.be.fulfilled;
	  	await proxy.execute('Register', setMessage(register, 'verifyAccount', [cividIds[1]]), { from: accounts[2]}).should.be.fulfilled;

	  	console.log(`New Player ${accounts[2]} with Kitty ${kitties[1]}`);
	})

	it('manual matches kitties', async () => {
		let kittyRed = 324;
	    let kittyBlack = 1001;
	    let gameStartTimeGiven = Math.floor(Date.now() / 1000) + 100; //now + 80 secs, so for prestart 30 secs 50 secs to participate

	    //Must take owners of Kitties here
	    let playerBlack = await cryptoKitties.ownerOf(kittyBlack);
	    let playerRed = await cryptoKitties.ownerOf(kittyRed);

	    console.log('PlayerBlack: ', playerBlack);
	    console.log('PlayerRed: ', playerRed);

	    await proxy.execute('GameCreation', setMessage(gameCreation, 'manualMatchKitties',
	      [playerRed, playerBlack, kittyRed, kittyBlack, gameStartTimeGiven]), { from: accounts[0] }).should.be.fulfilled;

	    await timeout(3);

	    let newGameEvents = await gameCreation.getPastEvents("NewGame", {
	      fromBlock: 0,
	      toBlock: "latest"
	    });

	    newGameEvents.map(async (e) => {
	      let gameInfo = await getterDB.getGameTimes(e.returnValues.gameId);

	      console.log('\n==== NEW GAME CREATED ===');
	      console.log('    GameId ', e.returnValues.gameId)
	      console.log('    Red Fighter ', e.returnValues.kittieRed)
	      console.log('    Red Player ', e.returnValues.playerRed)
	      console.log('    Black Fighter ', e.returnValues.kittieBlack)
	      console.log('    Black Player ', e.returnValues.playerBlack)
	      console.log('    Prestart Time:', formatDate(gameInfo.preStartTime));
	      console.log('    Start Time ', formatDate(e.returnValues.gameStartTime))
	      console.log('    End Time:', formatDate(gameInfo.endTime));
	      console.log('========================\n')
	    })
	    //Take both Kitties game to see it is the same
	    let gameId1 = await getterDB.getGameOfKittie(kittyRed);
	    let gameId2 = await getterDB.getGameOfKittie(kittyBlack);

	    if(gameId1 === gameId2) console.log('\nGameId: ', gameId1);

	    //Take gameStartTime from blockchain to see if it is same as the one we gave
	    let {preStartTime, startTime, endTime} = await getterDB.getGameTimes(gameId1);

	    console.log('\nGame PreStart Time: ', formatDate(preStartTime));
	    console.log('\nGame Start Time in UTC: ', formatDate(startTime));
	    console.log('\nGame End Time: ', formatDate(endTime));
	})

	it('participates users for game 1', async () => {
		let gameId = 1;
	    let blackParticipators = 6;
	    let redParticipators = 6; 
	    let timeInterval = 2;

	    let supportersForRed = [];
	    let supportersForBlack = [];
	    let ticketFee = await gameStore.getTicketFee(gameId);

	    console.log(ticketFee);


	    let {playerBlack, playerRed, kittyBlack, kittyRed} = await getterDB.getGamePlayers(gameId);
	    let participator;


	    //accounts 10-29 can be supporters for black

	    let blacks = Number(blackParticipators) + 10;
	    let reds = Number(redParticipators) + 30;

	    for(let i = 10; i < blacks; i++){
	      participator = accounts[i];
	      await proxy.execute('GameManager', setMessage(gameManager, 'participate',
	      [gameId, playerBlack]), { from: participator }).should.be.fulfilled;
	      console.log('\nNew Participator for playerBlack: ', participator);
	      supportersForBlack.push(participator);
	      await timeout(timeInterval);
	    }


	    //accounts 30-49 can be supporters for red
	    for(let j = 30; j < reds; j++){
	      participator = accounts[j]; 
	      if(j == (Number(reds) - 1)){
	        let block = await dateTime.getBlockTimeStamp();
	        console.log('\nblocktime: ', formatDate(block))

	        let {preStartTime} = await getterDB.getGameTimes(gameId);

	        while (block < preStartTime) {
	          block = Math.floor(Date.now() / 1000);
	          await timeout(3);
	        }
	      }
	      await proxy.execute('GameManager', setMessage(gameManager, 'participate',
	      [gameId, playerRed]), { from: participator }).should.be.fulfilled;
	      console.log('\nNew Participator for playerRed: ', participator);
	      supportersForRed.push(participator);
	      await timeout(timeInterval);

	    }

	    let KTYforBlack = blackParticipators * ticketFee;
	    let KTYforRed = redParticipators * ticketFee;

	    console.log('\nSupporters for Black: ', supportersForBlack);
	    console.log('\nSupporters for Red: ', supportersForRed);

	    console.log('\nTotal KTY for Black (only participators): ', KTYforBlack);
	    console.log('\nTotal KTY for Red (only participators): ', KTYforRed);
	})

	it('players press start for game 1', async () => {
		let gameId = 1;

	    let {playerBlack, playerRed, kittyBlack, kittyRed} = await getterDB.getGamePlayers(gameId);

	    await proxy.execute('GameManager', setMessage(gameManager, 'startGame',
	      [gameId, randomValue(99), "512955438081049600613224346938352058409509756310147795204209859701881294"]), { from: playerBlack }).should.be.fulfilled;

	    await timeout(3);

	    await proxy.execute('GameManager', setMessage(gameManager, 'startGame',
	      [gameId, randomValue(99), "24171491821178068054575826800486891805334952029503890331493652557302916"]), { from: playerRed }).should.be.fulfilled;

	    console.log('\nGame Started: ', gameId);
	    console.log('\nPlayerBlack: ', playerBlack);
	    console.log('\nPlayerRed: ', playerRed);
	})

	it('players bet for game 1', async () => {
		let gameId = 1;
	    let noOfBets = 100;
	    let timeInterval = 2;

	    let {playerBlack, playerRed, kittyBlack, kittyRed} = await getterDB.getGamePlayers(gameId);

	    let supportersRed = await getterDB.getSupporters(gameId, playerRed);
	    let supportersBlack = await getterDB.getSupporters(gameId, playerBlack);
	    let totalBetAmount = 0;
	    let betsBlack = [];
	    let betsRed = [];
	    let betAmount;
	    let player;
	    let supportedPlayer;
	    let randomSupporter;

	    let state = await getterDB.getGameState(gameId);
	    console.log(state);

	    for(let i=0; i<noOfBets; i++){
	      let randomPlayer = randomValue(2);


	      if(i == (Number(noOfBets) - 1)){
	        let block = await dateTime.getBlockTimeStamp();
	        console.log('\nWaiting to end as it last bet! \n BlockTime: ', formatDate(block))

	        let {endTime} = await getterDB.getGameTimes(gameId);
	        console.log('\nEnd Time: ', endTime);

	        while (block < endTime) {
	          block = Math.floor(Date.now() / 1000);
	          await timeout(3);
	        }
	      }
	      //PlayerBlack
	      if(randomPlayer == 1){
	        randomSupporter = randomValue((supportersBlack) - 1);
	        betAmount = randomValue(30);
	        player = 'playerBlack';
	        supportedPlayer = accounts[((Number(randomSupporter)) + 10)];

	        await proxy.execute('GameManager', setMessage(gameManager, 'bet',
	        [gameId, randomValue(98)]), { from: supportedPlayer, value: web3.utils.toWei(String(betAmount)) }).should.be.fulfilled;

	        betsBlack.push(betAmount);
	      }
	      //PlayerRed
	      else{
	        randomSupporter = randomValue(Number(supportersRed) - 1);
	        betAmount = randomValue(30);
	        player = 'playerRed';
	        supportedPlayer = accounts[((Number(randomSupporter)) + 30)];

	        await proxy.execute('GameManager', setMessage(gameManager, 'bet',
	        [gameId, randomValue(98)]), { from: supportedPlayer, value: web3.utils.toWei(String(betAmount)) }).should.be.fulfilled;
	        
	        betsRed.push(betAmount);
	      }

	      let betEvents = await betting.getPastEvents('BetPlaced', {
	        filter: { gameId },
	        fromBlock: 0,
	        toBlock: "latest"
	      })

	      let betDetails = betEvents[betEvents.length - 1].returnValues;
	      console.log(`\n==== NEW BET FOR ${player} ====`);
	      console.log(' Amount:', web3.utils.fromWei(betDetails._lastBetAmount), 'ETH');
	      console.log(' Bettor:', betDetails._bettor);
	      console.log(' Attack Hash:', betDetails.attackHash);
	      console.log(' Blocked?:', betDetails.isBlocked);
	      console.log(` Defense ${player}:`, betDetails.defenseLevelSupportedPlayer);
	      console.log(' Defense Opponent:', betDetails.defenseLevelOpponent);

	      let {endTime} = await getterDB.getGameTimes(gameId);

	      if(player === 'playerBlack'){
	        let lastBetTimestamp = await betting.lastBetTimestamp(gameId, playerBlack);
	        console.log(' Timestamp last Bet: ', formatDate(lastBetTimestamp));

	        if (lastBetTimestamp >= endTime) {
	          console.log('\nGame Ended during last bet!')
	          break;
	        }
	      }
	      else{
	        let lastBetTimestamp = await betting.lastBetTimestamp(gameId, playerRed);
	        console.log(' Timestamp last Bet: ', formatDate(lastBetTimestamp));

	        if (lastBetTimestamp >= endTime) {
	          console.log('\nGame Ended during last bet!')
	          break;
	        }
	      }

	      totalBetAmount = totalBetAmount + betAmount;
	      await timeout(timeInterval);

	    }

	    console.log('\nBets Black: ', betsBlack)
	    console.log('\nBets Red: ', betsRed)

	    let honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

	    console.log(`\n==== HONEYPOT INFO ==== `)
	    console.log(`     InitialEtH: ${web3.utils.fromWei(honeyPotInfo.initialEth.toString())}   `);
	    console.log(`     TotalETH: ${web3.utils.fromWei(honeyPotInfo.ethTotal.toString())}   `);
	    console.log(`     TotalKTY: ${web3.utils.fromWei(honeyPotInfo.ktyTotal.toString())}   `);
	    console.log('=======================\n')
	})

	it('game is getting finalized', async () => {
		let gameId = 1;

	   	let {preStartTime, startTime, endTime} = await getterDB.getGameTimes(gameId);

	    let {playerBlack, playerRed, kittyBlack, kittyRed} = await getterDB.getGamePlayers(gameId);
	    
	    let finalizer = accounts[20];

	    console.log('\n==== WAITING FOR GAME OVER: ', formatDate(endTime))

	    await timeout(2);


	    await proxy.execute('GameManager', setMessage(gameManager, 'finalize',
	      [gameId, randomValue(30)]), { from: finalizer }).should.be.fulfilled;

	    let gameEnd = await gameManager.getPastEvents('GameEnded', {
	      filter: { gameId },
	      fromBlock: 0,
	      toBlock: 'latest'
	    })

	    let state = await getterDB.getGameState(gameId);
	    console.log(state);

	    let { pointsBlack, pointsRed, loser } = gameEnd[0].returnValues;

	    let winners = await getterDB.getWinners(gameId);

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

	it('claims for everyone', async () => {
		let gameId = 1;

	    let winners = await getterDB.getWinners(gameId);
	    let winner = winners.winner;
	    let numberOfSupporters;
	    let incrementingNumber;
	    let claimer;

	    let winnerShare = await endowmentFund.getWinnerShare(gameId, winners.winner);
	    console.log('\nWinner withdrawing ', String(web3.utils.fromWei(winnerShare.winningsETH.toString())), 'ETH')
	    console.log('Winner withdrawing ', String(web3.utils.fromWei(winnerShare.winningsKTY.toString())), 'KTY')
	    await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'claim',
	      [gameId]), { from: winners.winner }).should.be.fulfilled;
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
	      [gameId]), { from: winners.topBettor }).should.be.fulfilled;
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
	      [gameId]), { from: winners.secondTopBettor }).should.be.fulfilled;
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
	            [gameId]), { from: claimer }).should.be.fulfilled;
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

	      }

	      let endowmentShare = await endowmentFund.getEndowmentShare(gameId);
	      console.log(`\n==== ENDOWMENT INFO ==== `);
	      console.log('\nEndowmentShare: ', String(web3.utils.fromWei(endowmentShare.winningsETH.toString())), 'ETH');
	      console.log('EndowmentShare: ', String(web3.utils.fromWei(endowmentShare.winningsKTY.toString())), 'KTY');
	      console.log('=======================\n');
	    }
	})

	it('the loser can redeem his/her kitty, dynamic redemption fee is burnt to kittieHELL, replacement kitties become permanent ghosts in kittieHELL', async () => {
        let gameId = 1;
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
	    const kittieRedemptionFee = parseFloat(redemptionFee)
	    console.log("Loser's Kitty redemption fee in KTY: " + kittieRedemptionFee)

	    const sacrificeKitties = [1017555, 413830, 888]

	    for (let i = 0; i < sacrificeKitties.length; i++) {
	        await cryptoKitties.mint(loser, sacrificeKitties[i]);
	    }

	    for (let i = 0; i < sacrificeKitties.length; i++) {
	        await cryptoKitties.approve(kittieHellDB.address, sacrificeKitties[i], { from: loser });
	    }

	    await kittieFightToken.approve(kittieHell.address, resurrectionCost,
	        { from: loser });
	    
	    await proxy.execute('KittieHell', setMessage(kittieHell, 'payForResurrection',
	        [loserKitty, gameId, loser, sacrificeKitties]), { from: loser }).should.be.fulfilled;

	    let owner = await cryptoKitties.ownerOf(loserKitty);

	    if (owner === kittieHellDB.address) {
	        console.log('Loser kitty became ghost in kittieHELL FOREVER :(');
	    }

	    if (owner === loser){
	      console.log('Kitty Redeemed :)');
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
