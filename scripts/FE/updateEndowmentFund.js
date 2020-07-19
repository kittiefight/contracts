const EndowmentFund = artifacts.require('EndowmentFund');
const GameCreation = artifacts.require('GameCreation');
const GameManager = artifacts.require('GameManager');
const WithdrawPool = artifacts.require('WithdrawPool');
const KittieHell = artifacts.require("KittieHell");
const EarningsTracker = artifacts.require("EarningsTracker");
const KFProxy = artifacts.require('KFProxy');
const SuperDaoToken = artifacts.require('MockERC20Token');
const MockStaking = artifacts.require('MockStaking');
const EthieToken = artifacts.require('EthieToken');
const Escrow = artifacts.require('Escrow');
const editJsonFile = require("edit-json-file");

module.exports = async (callback) => {
	try {
		console.log("Starting....");
	    let proxy = await KFProxy.deployed();

	    let oldEndowment = await EndowmentFund.deployed();
	    let newEndowment = await EndowmentFund.new();
	    let escrow = await Escrow.deployed();
	    console.log(newEndowment.address);

	    let file = editJsonFile('build/contracts/EndowmentFund.json');

	    file.set("networks.999.address", newEndowment.address);
	    file.save();

	  	console.log("SetProxy...");
	  	await newEndowment.setProxy(proxy.address);
	  	await proxy.updateContract('EndowmentFund', newEndowment.address);

	  	await newEndowment.initialize();
	    await oldEndowment.transferEscrowOwnership(newEndowment.address);
	    await newEndowment.initUpgradeEscrow(escrow.address);

	  	let withdrawPool = await WithdrawPool.deployed();
	  	let staking = await MockStaking.deployed();
	  	let superDaoToken = await SuperDaoToken.deployed();
	  	let kittieHell = await KittieHell.deployed();
	  	let gameManager = await GameManager.deployed();
	  	let gameCreation = await GameCreation.deployed();
	  	let earningsTracker = await EarningsTracker.deployed();
	  	let ethieToken = await EthieToken.deployed();

	  	console.log("EndowmentFund deployed...");

	  	console.log("Initialize...");
	  	await gameManager.initialize();
	  	await gameCreation.initialize();
	  	await kittieHell.initialize();
	  	await earningsTracker.initialize(ethieToken.address);
	  	await withdrawPool.initialize(staking.address, superDaoToken.address);
	  	callback();
    }
    catch(e){callback(e)}
}
