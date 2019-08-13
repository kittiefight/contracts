const GameManager = artifacts.require('GameManager')
const KFProxy = artifacts.require('KFProxy')

function setMessage(contract, funcName, argArray) {
    return web3.eth.abi.encodeFunctionCall(
      contract.abi.find((f) => { return f.name == funcName; }),
      argArray
    );
}

// bet 0.01 in a gameId from address of accounts[index]

module.exports = async (callback) => {
	try{
        proxy = await KFProxy.deployed()
        gameManager = await GameManager.deployed()

        let gameId = process.argv[4];
        let index = process.argv[5];

        accounts = await web3.eth.getAccounts();
        
        await proxy.execute('GameManager', setMessage(gameManager, 'bet',
        [gameId, randomValue()]), { from: accounts[index], value: web3.utils.toWei(String(0.01)) })

		callback()
	}
	catch(e){callback(e)}

}