const BigNumber = web3.utils.BN;

const KFProxy = artifacts.require('KFProxy')
const GameVarAndFee = artifacts.require('GameVarAndFee')
// =================================================== //

function setMessage(contract, funcName, argArray) {
    return web3.eth.abi.encodeFunctionCall(
      contract.abi.find((f) => { return f.name == funcName; }),
      argArray
    );
}

//truffle exec scripts/FE/setGameVar.js <varName> <value>

//pass value as uint

module.exports = async (callback) => {
	try {
		proxy = await KFProxy.deployed()
        gameVarAndFee = await GameVarAndFee.deployed()
        
        let varName = accounts[process.argv[4]];
        let value = accounts[process.argv[5]];

        console.log(`\nSetting ${varName} to ${value} ...`);       
        
		await proxy.execute('GameVarAndFee', setMessage(gameVarAndFee, 'setVarAndFee', 
			[varName, value]))
	}
	catch(e){callback(e)}
}

