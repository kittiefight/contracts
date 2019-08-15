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

		console.log('\nUpgrading Escrow...');
		await endowmentFund.initUpgradeEscrow(escrow.address)
		//Transfer KTY
		await kittieFightToken.transfer(endowmentFund.address, INITIAL_KTY_ENDOWMENT)
		await endowmentFund.sendKTYtoEscrow(INITIAL_KTY_ENDOWMENT);
		//Transfer ETH
		await endowmentFund.sendETHtoEscrow({value:INITIAL_ETH_ENDOWMENT});

		callback()
	}
	catch(e){callback(e)}
}


