const KFProxy = artifacts.require('KFProxy')
const Register = artifacts.require('Register')
const ProfileDB = artifacts.require('ProfileDB')

// =================================================== //

function setMessage(contract, funcName, argArray) {
    return web3.eth.abi.encodeFunctionCall(
      contract.abi.find((f) => { return f.name == funcName; }),
      argArray
    );
}

function generateCivicId() {
    return Math.floor(Math.random() * 1000) + 1; //
  }

// truffle exec scripts/verifyCivic.js <account> --network rinkeby

module.exports = async (callback) => {
	try{
      register = await Register.deployed()
      proxy = await KFProxy.deployed()
      profileDB = await ProfileDB.deployed();

      let account = process.argv[4];
      let cividId = generateCivicId();

		await proxy.execute('Register', setMessage(register, 'verifyAccount', 
      [cividId]), {from: account})
            
    let id  = await profileDB.getCivicId(account);

		if (id > 0) console.log(`\nVerified account ${account} with civic id ${id}!`);
		else console.log(`\nError verifying account`);

		callback();
	}
	catch(e){callback(e)}

}