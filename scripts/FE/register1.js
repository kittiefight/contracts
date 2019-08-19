const KFProxy = artifacts.require('KFProxy')
const Register = artifacts.require('Register')

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

//truffle exec scripts/FE/register1.js accountnumber

module.exports = async (callback) => {
  try{
    let proxy = await KFProxy.deployed();
    let register = await Register.deployed()
    
    accounts = await web3.eth.getAccounts();

    let account = accounts[process.argv[4]];

    await proxy.execute('Register', setMessage(register, 'register', []), {
      from: account
    });


    callback()
  }
  catch(e){callback(e)}
}