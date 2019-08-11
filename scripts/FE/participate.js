const KFProxy = artifacts.require('KFProxy')
const GMGetterDB = artifacts.require('GMGetterDB')
const GameManager = artifacts.require('GameManager')

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

//truffle exec scripts/FE/participate.js 19 2 0x9dE872401f95D669C6914f6D1cC41A5Ed1791d6D

module.exports = async (callback) => {
  try{
    let proxy = await KFProxy.deployed();
    let gameManager = await GameManager.deployed();
    let getterDB = await GMGetterDB.deployed();

    accounts = await web3.eth.getAccounts();

    let user = accounts[process.argv[4]];
    let gameId = process.argv[5];
    let playerToSupport = process.argv[6];

    await proxy.execute('GameManager', setMessage(gameManager, 'participate',
      [gameId, playerToSupport]), { from: user });

    let supporterInfo = await getterDB.getSupporterInfo(user)

    if(supporterInfo.supportedPlayer === playerToSupport ) console.log('Added Supporter to game', gameId);
    
    callback()
  }
  catch(e){callback(e)}

}

