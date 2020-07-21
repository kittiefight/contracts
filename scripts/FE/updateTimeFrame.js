const TimeFrame = artifacts.require('TimeFrame');
const KFProxy = artifacts.require('KFProxy');
const EarningsTracker = artifacts.require('EarningsTracker');
const WithdrawPool = artifacts.require('WithdrawPool');
const SuperDaoToken = artifacts.require('MockERC20Token');
const MockStaking = artifacts.require('MockStaking');
const EthieToken = artifacts.require('EthieToken');
const GameStore = artifacts.require('GameStore');
const editJsonFile = require("edit-json-file");

module.exports = async (callback) => {
	try {
		console.log("Starting....");
        let proxy = await KFProxy.deployed();
        let earningsTracker = await EarningsTracker.deployed();
	    let withdrawPool = await WithdrawPool.deployed();
	    let superDaoToken = await SuperDaoToken.deployed();
	    let staking = await MockStaking.deployed();
        let ethieToken = await EthieToken.deployed();
        let gameStore = await GameStore.deployed();

	    let timeFrame = await TimeFrame.new();
	    console.log(timeFrame.address);

	    let file = editJsonFile('build/contracts/TimeFrame.json');

	    file.set("networks.999.address", timeFrame.address);
	    file.save();

	  	console.log("SetProxy...");
	  	await timeFrame.setProxy(proxy.address);
	  	await proxy.updateContract('TimeFrame', timeFrame.address);

	  	console.log("TimeFrame deployed...");

        console.log("Initialize...");
        await timeFrame.initialize();
	  	await earningsTracker.initialize(ethieToken.address);
        await withdrawPool.initialize(staking.address, superDaoToken.address);
		await gameStore.initialize();
		
		// only need to do this step in local test
		await timeFrame.setTimes(250, 120, 120);
		
	  	callback();
    }
    catch(e){callback(e)}
}
