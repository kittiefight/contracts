const Escrow = artifacts.require('Escrow')

// truffle exec scripts/checkEscrow.js --network rinkeby

module.exports = async (callback) => {
	try{
		escrow = await Escrow.deployed();
        let balanceKTY = await escrow.getBalanceKTY();

        let balanceETH = await escrow.getBalanceETH();

        console.log('\nChecking Escrow balances...');
        console.log('\n================');
        console.log(`  ${web3.utils.fromWei(balanceETH)} ETH`);
        console.log(`  ${web3.utils.fromWei(balanceKTY)} KTY`);
        console.log('================');
		

		callback()
	}
	catch(e){callback(e)}
}


