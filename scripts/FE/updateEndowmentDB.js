const EndowmentDB = artifacts.require('EndowmentDB');
const GenericDB = artifacts.require('GenericDB');
const GMGetterDB = artifacts.require('GMGetterDB');
const EndowmentFund = artifacts.require('EndowmentFund');
const WithdrawPool = artifacts.require('WithdrawPool');
const KFProxy = artifacts.require('KFProxy');
const SuperDaoToken = artifacts.require('MockERC20Token');
const MockStaking = artifacts.require('MockStaking');
const editJsonFile = require("edit-json-file");

module.exports = async (callback) => {
	try {
		console.log("Starting....");
	    let proxy = await KFProxy.deployed();
	    console.log(proxy.address);
	    let genericDB = await GenericDB.deployed();
	  	let endowmentDB = await EndowmentDB.new(genericDB.address);
	  	let withdrawPool = await WithdrawPool.deployed();
	  	let staking = await MockStaking.deployed();
	  	let superDaoToken = await SuperDaoToken.deployed();
	  	console.log("EndowmentDB deployed...");

	  	console.log(endowmentDB.address);

	    let file = editJsonFile('build/contracts/EndowmentDB.json');

	    file.set("networks.999.address", endowmentDB.address);
	    file.save();

	  	await proxy.updateContract('EndowmentDB', endowmentDB.address);

	  	console.log("SetProxy...");
	  	await endowmentDB.setProxy(proxy.address);

	  	console.log("Initialize...");
	  	let gmGetterDB = await GMGetterDB.deployed();
	  	let endowmentFund = await EndowmentFund.deployed();

	  	await gmGetterDB.initialize();
	  	await endowmentFund.initialize();
	  	await withdrawPool.initialize(staking.address, superDaoToken.address);
	  	callback();
    }
    catch(e){callback(e)}
}
