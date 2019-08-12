const KFProxy = artifacts.require('KFProxy')
const Register = artifacts.require('Register')

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

//truffle exec scripts/FE/registerUser.js <#users>

module.exports = async (callback) => {
  try{
    let proxy = await KFProxy.deployed();
    let register = await Register.deployed()
  
    accounts = await web3.eth.getAccounts();
  
    let amount = accounts[process.argv[4]];

    for(let i = 1; i <= amount; i++){
      await proxy.execute('Register', setMessage(register, 'register', []), {
        from: accounts[i]
      })

      let isRegistered = await register.isRegistered(accounts[i])

      if(isRegistered) console.log('Registered User ', accounts[i]);
    } 

    callback()
  }
  catch(e){callback(e)}
}

