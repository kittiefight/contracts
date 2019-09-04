const BigNumber = web3.utils.BN;

const KFProxy = artifacts.require('KFProxy')
const GameVarAndFee = artifacts.require('GameVarAndFee')

// ================ GAME VARS AND FEES ================ //
const LISTING_FEE = new BigNumber(web3.utils.toWei("1250", "ether"));
const TICKET_FEE = new BigNumber(web3.utils.toWei("37.5", "ether"));
const BETTING_FEE = new BigNumber(web3.utils.toWei("2.5", "ether"));
const MIN_CONTRIBUTORS = 5 //833
const REQ_NUM_MATCHES = 1000000 //10
const GAME_PRESTART = 4 * 60 // 4 min
const GAME_DURATION = 5 * 60 // 5 min
const ETH_PER_GAME = new BigNumber(web3.utils.toWei("10", "ether")); //$50,000 / (@ $236.55 USD/ETH)
const TOKENS_PER_GAME = new BigNumber(web3.utils.toWei("1000", "ether")); // 1,000 KTY
const GAME_TIMES = 10 * 60 //Scheduled games 10 min apart
const KITTIE_HELL_EXPIRATION = 60 * 60 * 24 //1 day
const HONEY_POT_EXPIRATION = 60 * 60 * 23// 23 hours
const KITTIE_REDEMPTION_FEE = new BigNumber(web3.utils.toWei("37500", "ether")); //37,500 KTY
const FINALIZE_REWARDS = new BigNumber(web3.utils.toWei("100", "ether")); //100 KTY
const PERFORMANCE_TIME_CHECK = 20;
const TIME_EXTENSION = 60;
//Distribution Rates
const WINNING_KITTIE = 30
const TOP_BETTOR = 25
const SECOND_RUNNER_UP = 15
const OTHER_BETTORS = 15
const ENDOWNMENT = 15
// =================================================== //

function setMessage(contract, funcName, argArray) {
	return web3.eth.abi.encodeFunctionCall(
		contract.abi.find((f) => { return f.name == funcName; }),
		argArray
	);
}

// truffle exec scripts/setAllGameVars.js --network rinkeby


module.exports = async (callback) => {
	try {
		proxy = await KFProxy.deployed()
		gameVarAndFee = await GameVarAndFee.deployed()

		console.log('\nSetting game vars and fees...');
		let names = ['listingFee', 'ticketFee', 'bettingFee', 'gamePrestart', 'gameDuration',
			'minimumContributors', 'requiredNumberMatches', 'ethPerGame', 'tokensPerGame',
			'gameTimes', 'kittieHellExpiration', 'honeypotExpiration', 'kittieRedemptionFee',
			'winningKittie', 'topBettor', 'secondRunnerUp', 'otherBettors', 'endownment',
			'finalizeRewards', 'performanceTime', 'timeExtension'];

		let bytesNames = [];
		for (i = 0; i < names.length; i++) {
			bytesNames.push(web3.utils.asciiToHex(names[i]));
		}

		let values = [LISTING_FEE.toString(), TICKET_FEE.toString(), BETTING_FEE.toString(), GAME_PRESTART, GAME_DURATION, MIN_CONTRIBUTORS,
			REQ_NUM_MATCHES, ETH_PER_GAME.toString(), TOKENS_PER_GAME.toString(), GAME_TIMES, KITTIE_HELL_EXPIRATION,
			HONEY_POT_EXPIRATION, KITTIE_REDEMPTION_FEE.toString(), WINNING_KITTIE, TOP_BETTOR, SECOND_RUNNER_UP,
			OTHER_BETTORS, ENDOWNMENT, FINALIZE_REWARDS.toString(), PERFORMANCE_TIME_CHECK, TIME_EXTENSION];

		await proxy.execute('GameVarAndFee', setMessage(gameVarAndFee, 'setMultipleValues',
			[bytesNames, values]))

		console.log('\nDone!');

		callback()
	}
	catch (e) { callback(e) }
}

