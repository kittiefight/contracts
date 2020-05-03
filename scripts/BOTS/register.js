const KFProxy = artifacts.require('KFProxy')
const Register = artifacts.require('Register')

// =================================================== //

function setMessage(contract, funcName, argArray) {
    return web3.eth.abi.encodeFunctionCall(
      contract.abi.find((f) => { return f.name == funcName; }),
      argArray
    );
}

// truffle exec scripts/BOTS/register.js <fromAccount> <toAccount> --network rinkeby

module.exports = async (callback) => {
	try{
        register = await Register.deployed()
        proxy = await KFProxy.deployed()

        let allAccounts = await web3.eth.getAccounts();

		let fromAccount = process.argv[4];
        let toAccount = process.argv[5];

        for(i = fromAccount ; i <= toAccount; i++){
            let account = allAccounts[i]; 

            let isRegistered = await register.isRegistered(account);

            if(!isRegistered){
                await proxy.execute('Register', setMessage(register, 'register', 
                    []), {from: account})
                
                let isRegistered = await register.isRegistered(account);

                if (isRegistered) console.log(`\nRegistered account ${account}!`);
                else console.log(`\nError registering account`);
            }
        }
		callback();
	}
	catch(e){callback(e)}

}