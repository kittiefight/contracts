const BigNumber = web3.utils.BN;

const KFProxy = artifacts.require('KFProxy')
const GameVarAndFee = artifacts.require('GameVarAndFee')

// ================ GAME VARS AND FEES ================ //
const LISTING_FEE = new BigNumber(web3.utils.toWei("1250", "ether"));
const TICKET_FEE = new BigNumber(web3.utils.toWei("37.5", "ether"));
const BETTING_FEE = new BigNumber(web3.utils.toWei("2.5", "ether"));
const MIN_CONTRIBUTORS = 833
const REQ_NUM_MATCHES = 10
const GAME_PRESTART = 120 // 2 min
const GAME_DURATION = 300 // 5 min
const ETH_PER_GAME = new BigNumber(web3.utils.toWei("211.37", "ether")); //$50,000 / (@ $236.55 USD/ETH)
const TOKENS_PER_GAME = new BigNumber(web3.utils.toWei("1000", "ether")); // 1,000 KTY
const GAME_TIMES = 10*60 //Scheduled games 10 min apart
const KITTIE_HELL_EXPIRATION = 60*60*24 //1 day
const HONEY_POT_EXPIRATION = 60*60*23// 23 hours
const KITTIE_REDEMPTION_FEE = new BigNumber(web3.utils.toWei("37500", "ether")); //37,500 KTY
const FINALIZE_REWARDS = new BigNumber(web3.utils.toWei("100", "ether")); //100 KTY
//Distribution Rates
const WINNING_KITTIE = 30
const TOP_BETTOR = 20
const SECOND_RUNNER_UP = 10
const OTHER_BETTORS = 25
const ENDOWNMENT = 15
// =================================================== //

function setMessage(contract, funcName, argArray) {
    return web3.eth.abi.encodeFunctionCall(
      contract.abi.find((f) => { return f.name == funcName; }),
      argArray
    );
}

module.exports = async (callback) => {
	try {
		proxy = await KFProxy.deployed()
		gameVarAndFee = await GameVarAndFee.deployed()

		console.log('\nSetting game vars and fees...');
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

		await proxy.execute('GameVarAndFee', setMessage(gameVarAndFee, 'setMultipleValues', 
			[bytesNames, values]))
	}
	catch(e){callback(e)}
}

