const BigNumber = web3.utils.BN;
require('chai')
  .use(require('chai-shallow-deep-equal'))
  .use(require('chai-bignumber')(BigNumber))
  .use(require('chai-as-promised'))
  .should();

  const evm = require('./utils/evm.js');

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
const TimeFrame = artifacts.require('TimeFrame')
const EthieToken = artifacts.require('EthieToken')
const EarningsTracker = artifacts.require('EarningsTracker')

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

function weiToEther(w) {
	let eth = web3.utils.fromWei(w.toString(), 'ether')
    return Math.round(parseFloat(eth))
}

//Contract instances
let proxy, dateTime, genericDB, profileDB, roleDB, superDaoToken,
  	kittieFightToken, cryptoKitties, register, gameVarAndFee, endowmentFund,
  	endowmentDB, forfeiter, scheduler, betting, hitsResolve,
  	rarityCalculator, kittieHell, kittieHellDB, getterDB, setterDB, gameManager,
  	cronJob, escrow, honeypotAllocationAlgo, timeFrame, ethieToken, earningsTracker;

contract('EarningsTracker', (accounts) => {
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
        ethieToken = await EthieToken.deployed();

		// TIMEFRAME
		timeFrame = await TimeFrame.deployed();

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
        earningsTracker = await EarningsTracker.deployed()

		//ESCROW
        escrow = await Escrow.deployed();
	})

	it('sets Epoch 0', async () => {
		// start epoch 0 6 days + 21 hours ago, so that timeFrame.setNewEpoch() can be
		// called by GameManager when the test game finalizes
		const startTime = Math.floor(Date.now() / 1000) - 6 * 24 * 60 * 60 + 5 * 60
		await timeFrame.setEpoch_0(startTime)
		const epoch_0_start_unix = await timeFrame._epochStartTime(0)
		console.log("epoch 0 start time in unix time:", epoch_0_start_unix.toNumber())
		const epoch_0_start_human_readable = await timeFrame.epochStartTime(0)
		const epoch_0_end_human_readable = await timeFrame.epochEndTime(0)
		console.log("\n******************* Epoch 0 Start Time *****************")
		console.log(
			'Date:',
			epoch_0_start_human_readable[0].toNumber()+'-'+
			epoch_0_start_human_readable[1].toNumber()+'-'+
			epoch_0_start_human_readable[2].toNumber(), ' ',
			'Time:',
			epoch_0_start_human_readable[3].toNumber()+':'+
			epoch_0_start_human_readable[4].toNumber()+':'+
			epoch_0_start_human_readable[5].toNumber()
			
		)
		console.log("\n******************* Epoch 0 End Time *******************")
		console.log(
			'Date:',
			epoch_0_end_human_readable[0].toNumber()+'-'+
			epoch_0_end_human_readable[1].toNumber()+'-'+
			epoch_0_end_human_readable[2].toNumber(), ' ',
			'Time:',
			epoch_0_end_human_readable[3].toNumber()+':'+
			epoch_0_end_human_readable[4].toNumber()+':'+
			epoch_0_end_human_readable[5].toNumber()
			
		)
		console.log('********************************************************\n')
		
	})

	it('sends 30000 KTYs to 40 users', async () => {
		let amountKTY = 30000;
		let users = 3;

		for(let i = 1; i <= users; i++){
	      	await kittieFightToken.transfer(accounts[i], web3.utils.toWei(String(amountKTY)), {
	          	from: accounts[0]}).should.be.fulfilled;

	      	await kittieFightToken.approve(endowmentFund.address, web3.utils.toWei(String(amountKTY)) , { from: accounts[i] }).should.be.fulfilled;

              let userBalance = await kittieFightToken.balanceOf(accounts[i]);
              console.log("KTY owned by "+accounts[i]+" : "+userBalance.toString())
	    } 
    })
    
    it('preset funding limit for each generation in initialization', async() => {
        let presetFundingLimit0 = await earningsTracker.getFundingLimit(0)
        presetFundingLimit0 = weiToEther(presetFundingLimit0)
        assert.equal(presetFundingLimit0, 500)
    })

    it('sets current funding limit', async () => {
        await earningsTracker.setCurrentFundingLimit()
        let currentFundingLimit = await earningsTracker.currentFundingLimit()
        currentFundingLimit = weiToEther(currentFundingLimit)
        assert.equal(currentFundingLimit, 500)
    })

    it('gets current generation based on current funding limit', async () => {
        let currentGeneration = await earningsTracker.getCurrentGeneration()
        currentGeneration = currentGeneration.toNumber()
        assert.equal(currentGeneration, 0)
    })

    it('adds minter role to EarningsTracker', async () => {
        await ethieToken.addMinter(earningsTracker.address)
        let isEarningsTrackerMinter = await ethieToken.isMinter(earningsTracker.address)
        assert.isTrue(isEarningsTrackerMinter)
    })

    it('an investor can deposit and lock ether, and receive an EthieToken NFT', async () => {
       let message = web3.eth.abi.encodeFunctionCall(
        EarningsTracker.abi.find(f => {
          return f.name == 'lockETH'
        }),
        []
      )
      let ethAmount = web3.utils.toWei(String(10), 'ether');
	  await proxy.execute('EarningsTracker', message, {'value': ethAmount})
	  let ethieToken_account0 = await ethieToken.balanceOf(accounts[0])
	  assert.equal(ethieToken_account0.toNumber(), 1)
    })
		 
})
