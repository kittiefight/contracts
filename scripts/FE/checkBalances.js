const EndowmentDB = artifacts.require('EndowmentDB');
const GMGetterDB = artifacts.require('GMGetterDB');

module.exports = async (callback) => {
	try {
	  	let endowmentDB = await EndowmentDB.deployed();
	  	let getterDB = await GMGetterDB.deployed();

	  	let endowmentBalances = await endowmentDB.getEndowmentBalance();
	  	console.log("EndowmentBalanceKTY: ", web3.utils.fromWei(endowmentBalances[0].toString()));
	  	console.log("EndowmentBalanceEther: ", web3.utils.fromWei(endowmentBalances[1].toString()));

	  	let honeypotBalances = await endowmentDB.getHoneyPotBalance(1);
	  	console.log("HoneyPotBalanceKTY: ", web3.utils.fromWei(honeypotBalances[0].toString()));
	  	console.log("HoneyPotBalanceEther: ", web3.utils.fromWei(honeypotBalances[1].toString()));

	  	let ethInPool = await endowmentDB.getETHinPool(1);
	  	console.log("EthInPool: ", web3.utils.fromWei(ethInPool.toString()));

	  	let investment = await endowmentDB.getInvestment(1);
	  	console.log("Investment: ", web3.utils.fromWei(investment.toString()));

	  	let gameState = await getterDB.getGameState(1);
	  	console.log("GameState: ", gameState.toString());
	  	
	  	callback();
    }
    catch(e){callback(e)}
}
