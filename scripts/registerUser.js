const KFProxy = artifacts.require('KFProxy')
const Register = artifacts.require('Register')

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

//truffle exec scripts/registerUser.js 7

module.exports = async (callback) => {
  let proxy = await KFProxy.deployed();
  let register = await Register.deployed()

  accounts = await web3.eth.getAccounts();

  let user = accounts[process.argv[4]];

  await proxy.execute('Register', setMessage(register, 'register', []), {
    from: user
  })

  let isRegistered = await register.isRegistered(user)

  if(isRegistered) console.log('Registered User ', user);
  
  callback()
}

