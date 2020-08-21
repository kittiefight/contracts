const EndowmentFund = artifacts.require('EndowmentFund');
const HoneypotAllocationAlgo = artifacts.require('HoneypotAllocationAlgo');
const KFProxy = artifacts.require('KFProxy');
const editJsonFile = require("edit-json-file");

module.exports = async (callback) => {
	try {
		console.log("Starting....");
	    let proxy = await KFProxy.deployed();
	    let endowmentFund = await EndowmentFund.deployed();

	    let honeypotAllocationAlgo = await HoneypotAllocationAlgo.new();
	    console.log(honeypotAllocationAlgo.address);

	    let file = editJsonFile('build/contracts/HoneypotAllocationAlgo.json');

	    file.set("networks.999.address", honeypotAllocationAlgo.address);
	    file.save();

	  	console.log("SetProxy...");
	  	await honeypotAllocationAlgo.setProxy(proxy.address);
	  	await proxy.updateContract('HoneypotAllocationAlgo', honeypotAllocationAlgo.address);

	  	console.log("HoneypotAllocationAlgo deployed...");

	  	console.log("Initialize...");
	  	await endowmentFund.initialize();
	  	callback();
    }
    catch(e){callback(e)}
}
