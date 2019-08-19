
const Escrow = artifacts.require('Escrow')
const EndowmentFund = artifacts.require('EndowmentFund')


// truffle exec scripts/withdrawFunds.js --network rinkeby

module.exports = async (callback) => {
	try{
		escrow = await Escrow.deployed();
		endowmentFund = await EndowmentFund.deployed()

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

		console.log('Done!\n');

		callback()
	}
	catch(e){callback(e)}
}


