const BigNumber = web3.utils.BN;

const EndowmentFund = artifacts.require('EndowmentFund');
const EndowmentDB = artifacts.require('EndowmentDB');
const KittieFightToken = artifacts.require('ERC20Standard');
const KFProxy = artifacts.require('KFProxy');
const Escrow = artifacts.require('Escrow');
const GenericDB = artifacts.require('GenericDB');

const KTY_ADDRESS = '0x8d05f69bd9e804eb467c7e1f2902ecd5e41a72da';

const INITIAL_KTY_ENDOWMENT = new BigNumber(
	web3.utils.toWei("20000", "ether") //50.000 KTY
);

const INITIAL_ETH_ENDOWMENT = new BigNumber(
	web3.utils.toWei("1000", "ether") //700 ETH
);

// truffle exec scripts/upgradeEndowment.js --network rinkeby

module.exports = async (callback) => {
	try {
		endowmentFund = await EndowmentFund.new();
		kittieFightToken = await KittieFightToken.at(KTY_ADDRESS);
		proxy = await KFProxy.at("0xbBa7D376d227f8854a3fAFE3823CCd58DbC69a90");
		escrow = await Escrow.new();
		endowmentDB = await EndowmentDB.new("0xf9930bdB446812361D5e00A0B45D094C06EeB840");

		let owner = await escrow.owner();

		console.log(owner);

		console.log('Upgrading Endowment...');
		console.log(endowmentFund.address);

		console.log("Updating Endowment on proxy");
		await proxy.updateContract('EndowmentFund', endowmentFund.address);

		console.log("Setting Proxy on Endowment");
		await endowmentFund.setProxy(proxy.address);

		await proxy.updateContract('EndowmentDB', endowmentDB.address);
        await endowmentDB.setProxy(proxy.address);

		console.log('Initialize Endowment');
		await endowmentFund.initialize();

		console.log("Transfer Escrow's OwnerShip");
		await escrow.transferOwnership(endowmentFund.address);

		console.log('Initialize Escrow');
		await endowmentFund.initUpgradeEscrow(escrow.address);

		//Transfer KTY
		console.log("Transfering KTYs to Endowment");
		await kittieFightToken.transfer(endowmentFund.address, INITIAL_KTY_ENDOWMENT);

		console.log("Transfering KTYs to Escrow");
		await endowmentFund.sendKTYtoEscrow(INITIAL_KTY_ENDOWMENT);

		//Transfer ETH
		console.log("Transfering Eth to Escrow");
		await endowmentFund.sendETHtoEscrow({ value: INITIAL_ETH_ENDOWMENT });

		console.log('Done!\n');

		console.log('Escrow Address: ', escrow.address);
		console.log('EndowmentFund Address: ', endowmentFund.address);

		let balanceKTY = await escrow.getBalanceKTY();

		let balanceETH = await escrow.getBalanceETH();

		owner = await escrow.owner();
		console.log('Escrow owner:', owner);

		console.log('\nChecking Escrow balances...');
		console.log('\n================');
		console.log(`  ${web3.utils.fromWei(balanceETH)} ETH`);
		console.log(`  ${web3.utils.fromWei(balanceKTY)} KTY`);
		console.log('================');

		callback()
	}
	catch (e) { callback(e) }
}


