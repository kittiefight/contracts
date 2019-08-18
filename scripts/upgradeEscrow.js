const BigNumber = web3.utils.BN;

const Escrow = artifacts.require('Escrow')
const EndowmentFund = artifacts.require('EndowmentFund')
const KittieFightToken = artifacts.require('ERC20Standard')

const KTY_ADDRESS = '0x8d05f69bd9e804eb467c7e1f2902ecd5e41a72da';

const INITIAL_KTY_ENDOWMENT = new BigNumber(
    web3.utils.toWei("50000", "ether") //50.000 KTY
);

const INITIAL_ETH_ENDOWMENT = new BigNumber(
    web3.utils.toWei("700", "ether") //700 ETH
);

// truffle exec scripts/upgradeEscrow.js --network rinkeby

module.exports = async (callback) => {
	try{
		escrow = await Escrow.deployed();
		endowmentFund = await EndowmentFund.deployed()
		kittieFightToken = await KittieFightToken.at(KTY_ADDRESS);

		allAccounts = await web3.eth.getAccounts();

		let superAdmin = allAccounts[0];

		console.log('Transfering ownership to SuperAdmin...')
		await endowmentFund.transferEscrowOwnership(superAdmin)

		let balanceKTY = await escrow.getBalanceKTY();
        let balanceETH = await escrow.getBalanceETH();

		console.log('Checking Escrow balances...');
        console.log('\n================');
        console.log(`  ${web3.utils.fromWei(balanceETH)} ETH`);
        console.log(`  ${web3.utils.fromWei(balanceKTY)} KTY`);
        console.log('================');
		
		console.log('\nTransfering Balances to super admin...');
		await escrow.transferKTY(superAdmin, balanceKTY);
		await escrow.transferETH(superAdmin, balanceETH);

		console.log('Upgrading Escrow...');
		await endowmentFund.initUpgradeEscrow(escrow.address)
		//Transfer KTY
		await kittieFightToken.transfer(endowmentFund.address, INITIAL_KTY_ENDOWMENT)
		await endowmentFund.sendKTYtoEscrow(INITIAL_KTY_ENDOWMENT);
		//Transfer ETH
		await endowmentFund.sendETHtoEscrow({value:INITIAL_ETH_ENDOWMENT});

		console.log('Done!\n');

		callback()
	}
	catch(e){callback(e)}
}


