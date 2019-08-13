const KFProxy = artifacts.require('KFProxy')
const Register = artifacts.require('Register')

// =================================================== //

function setMessage(contract, funcName, argArray) {
    return web3.eth.abi.encodeFunctionCall(
      contract.abi.find((f) => { return f.name == funcName; }),
      argArray
    );
}

// truffle exec scripts/register.js <account> --network rinkeby

module.exports = async (callback) => {
	try{
        register = await Register.deployed()
        proxy = await KFProxy.deployed()

		let account = process.argv[4];

		await proxy.execute('Register', setMessage(register, 'register', 
            []), {from: account})
            
        let isRegistered = await register.isRegistered(account);

		if (isRegistered) console.log(`\nRegistered account ${account}!`);
		else console.log(`\nError registering account`);

		callback();
	}
	catch(e){callback(e)}

}