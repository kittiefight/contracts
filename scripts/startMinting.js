const EarningsTracker = artifacts.require('EarningsTracker');
const EthieToken = artifacts.require('EthieToken');

module.exports = async (callback) => {
	try {
	  	let earningsTracker = await EarningsTracker.at("0x03d5f19eD6c697031562c6a4741395Eec4764E23");
	  	let ethieToken = await EthieToken.at("0x906e73F22062f0744aeDcCb05c9Cbdc374B01fbd");
	  	console.log("Minting procedure starting...");
	  	await ethieToken.addMinter(earningsTracker.address);
    	await earningsTracker.setCurrentFundingLimit();
    	console.log("Minting done!");

	  	callback();
    }
    catch(e){callback(e)}
}
