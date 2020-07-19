const EarningsTracker = artifacts.require('EarningsTracker');
const KFProxy = artifacts.require('KFProxy');
const WithdrawPool = artifacts.require('WithdrawPool');
const SuperDaoToken = artifacts.require('MockERC20Token');
const MockStaking = artifacts.require('MockStaking');
const EthieToken = artifacts.require('EthieToken');
const editJsonFile = require("edit-json-file");

module.exports = async (callback) => {
	try {
		console.log("Starting....");
	    let proxy = await KFProxy.deployed();
	    let withdrawPool = await WithdrawPool.deployed();
	    let superDaoToken = await SuperDaoToken.deployed();
	    let staking = await MockStaking.deployed();
	    let ethieToken = await EthieToken.deployed();

	    let earningsTracker = await EarningsTracker.new();
	    console.log(earningsTracker.address);

	    let file = editJsonFile('build/contracts/EarningsTracker.json');

	    file.set("networks.999.address", earningsTracker.address);
	    file.save();

	  	console.log("SetProxy...");
	  	await earningsTracker.setProxy(proxy.address);
	  	await proxy.updateContract('EarningsTracker', earningsTracker.address);

	  	console.log("EarningsTracker deployed...");

	  	console.log("Initialize...");
	  	await earningsTracker.initialize(ethieToken.address);
	  	await withdrawPool.initialize(staking.address, superDaoToken.address);
	  	callback();
    }
    catch(e){callback(e)}
}
