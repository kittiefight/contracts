const EndowmentDB = artifacts.require('EndowmentDB');
const GenericDB = artifacts.require('GenericDB');
const GMGetterDB = artifacts.require('GMGetterDB');
const EndowmentFund = artifacts.require('EndowmentFund');
const WithdrawPool = artifacts.require('WithdrawPool');
const KFProxy = artifacts.require('KFProxy');

module.exports = async (callback) => {
	try {
		console.log("Starting....");
	    let proxy = await KFProxy.deployed();
	    console.log(proxy.address);
	    let genericDB = await GenericDB.deployed();
	  	let endowmentDB = await EndowmentDB.new(genericDB.address);
	  	let withdrawPool = await WithdrawPool.deployed();
	  	console.log("EndowmentDB deployed...");

	  	console.log(endowmentDB.address);

	  	await proxy.updateContract('EndowmentDB', endowmentDB.address);

	  	console.log("SetProxy...");
	  	await endowmentDB.setProxy(proxy.address);

	  	console.log("Initialize...");
	  	let gmGetterDB = await GMGetterDB.deployed();
	  	let endowmentFund = await EndowmentFund.deployed();

	  	await gmGetterDB.initialize();
	  	await endowmentFund.initialize();
	  	// await withdrawPool.initialize();
	  	callback();
    }
    catch(e){callback(e)}
}
