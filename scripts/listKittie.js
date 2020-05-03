const CryptoKitties = artifacts.require('MockERC721Token');
const KFProxy = artifacts.require('KFProxy')
const GameCreation = artifacts.require('GameCreation')
const Scheduler = artifacts.require('Scheduler')

// =================================================== //

function setMessage(contract, funcName, argArray) {
    return web3.eth.abi.encodeFunctionCall(
      contract.abi.find((f) => { return f.name == funcName; }),
      argArray
    );
}

// truffle exec scripts/listKittie.js <kittieId> --network rinkeby
// account owner of kittie should be unlocked

module.exports = async (callback) => {
	try{
        cryptoKitties = await CryptoKitties.deployed();
        proxy = await KFProxy.deployed()
        gameCreation = await GameCreation.deployed();
        scheduler = await Scheduler.deployed()

        let kittieId = process.argv[4];
        owner = await cryptoKitties.ownerOf(kittieId);

		await proxy.execute('GameCreation', setMessage(gameCreation, 'listKittie', 
            [kittieId]), {from: owner})
            
        let isListed = await scheduler.isKittyListedForMatching(kittieId);

		if (isListed) console.log(`\nListed kittie ${kittieId}!`);
		else console.log(`\nError listing kittie`);

		callback();
	}
	catch(e){callback(e)}

}
