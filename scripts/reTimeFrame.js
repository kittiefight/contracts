const TimeFrame = artifacts.require('TimeFrame');
const WithdrawPool = artifacts.require('WithdrawPool');
const GameStore = artifacts.require('GameStore');
const EarningsTracker = artifacts.require('EarningsTracker');
const KFProxy = artifacts.require('KFProxy');
const EthieToken = artifacts.require('EthieToken');
const MockStaking = artifacts.require('MockStaking');

module.exports = async (callback) => {
	try {
		console.log("Starting....");
	    let proxy = await KFProxy.at("0x1b6Eb91a521Ad7C1971F793dccCf20fA55E044AF");
	    console.log(proxy.address);
	  	let timeFrame = await TimeFrame.new();
	  	console.log("TimeFrame deployed...");
	  	let withdrawPool = await WithdrawPool.at("0xCaF5c643686ccc158801DfC052638d18bECFA45c");
	  	let gameStore = await GameStore.at("0x73462eC60e915E6EEfB927fb06FdD7d4e65B1513");
	  	let earningsTracker = await EarningsTracker.at("0x03d5f19eD6c697031562c6a4741395Eec4764E23");
	  	let ethieToken = await EthieToken.at("0x906e73F22062f0744aeDcCb05c9Cbdc374B01fbd");
	  	let mockStaking = await MockStaking.at("0x78f5F7B53b074aD8018F486934DF9530a3fcC319");

	  	console.log(timeFrame.address);

	  	await proxy.updateContract('TimeFrame', timeFrame.address);

	  	console.log("Initializing...");
	  	await timeFrame.setProxy(proxy.address);
	  	await gameStore.initialize();
	  	await withdrawPool.initialize(mockStaking.address, "0xB0251539F2893a10e757EbF32B62ae83105CF0d9");
	  	await earningsTracker.initialize(ethieToken.address);
	  	callback();
    }
    catch(e){callback(e)}
}
