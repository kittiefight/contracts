const GameManager = artifacts.require('GameManager')
const KFProxy = artifacts.require('KFProxy')

function setMessage(contract, funcName, argArray) {
    return web3.eth.abi.encodeFunctionCall(
      contract.abi.find((f) => { return f.name == funcName; }),
      argArray
    );
}

//truffle exec scripts/bet.js <gameId> <index_account> 
// bet in a gameId from address of accounts[index] amountBet(eth)

module.exports = async (callback) => {
	try{
        proxy = await KFProxy.deployed()
        gameManager = await GameManager.deployed()

        let gameId = process.argv[4];
        let index = process.argv[5];
        let amountBet = process.argv[6];

        accounts = await web3.eth.getAccounts();
        
        await proxy.execute('GameManager', setMessage(gameManager, 'bet',
        [gameId, randomValue()]), { from: accounts[index], value: web3.utils.toWei(String(amountBet)) })

		callback()
	}
	catch(e){callback(e)}

}