const EndowmentFund = artifacts.require('EndowmentFund');
const Escrow = artifacts.require('Escrow');
const editJsonFile = require("edit-json-file");

module.exports = async (callback) => {
	try {
		console.log("Starting....");
	    let endowmentFund = await EndowmentFund.deployed();

	    let escrow = await Escrow.new();
	    console.log(escrow.address);

	    let file = editJsonFile('build/contracts/Escrow.json');

	    file.set("networks.999.address", escrow.address);
	    file.save();

	  	console.log("Escrow deployed...");

	  	console.log("Initialize...");
	  	await escrow.transferOwnership(endowmentFund.address);
	  	await endowmentFund.initUpgradeEscrow(escrow.address);
	  	callback();
    }
    catch(e){callback(e)}
}
