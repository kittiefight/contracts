const GameManager = artifacts.require('GameManager');
const Forfeiter = artifacts.require('Forfeiter');
const KFProxy = artifacts.require('KFProxy');
const MockStaking = artifacts.require('MockStaking');

module.exports = async (callback) => {
	try {
		console.log("Starting....");
	    let proxy = await KFProxy.at("0x1b6Eb91a521Ad7C1971F793dccCf20fA55E044AF");
	  	let gameManager = await GameManager.new();
	  	console.log("GameManager deployed...");
	  	let forfeiter = await Forfeiter.at("0x73CC3A29705493d54F9aa76D1e91f5B5F917b535");

	  	console.log(gameManager.address);

	  	await proxy.updateContract('GameManager', gameManager.address);

	  	console.log("Initializing...");
	  	await gameManager.setProxy(proxy.address);
	  	await gameManager.initialize();
	  	await forfeiter.initialize();

	  	// let staking = await MockStaking.at("0x78f5F7B53b074aD8018F486934DF9530a3fcC319");
	  	// await staking.initialize("0xB0251539F2893a10e757EbF32B62ae83105CF0d9");
	  	callback();
    }
    catch(e){callback(e)}
}
