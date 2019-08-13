const KFProxy = artifacts.require('KFProxy')
const GMGetterDB = artifacts.require('GMGetterDB')
const GameManager = artifacts.require('GameManager')

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

function randomValue(num) {
  return Math.floor(Math.random() * num) + 1; // (1-num) value
}

function timeout(s) {
  // console.log(`~~~ Timeout for ${s} seconds`);
  return new Promise(resolve => setTimeout(resolve, s * 1000));
}

//truffle exec scripts/FE/pressStart.js gameId(uint)

module.exports = async (callback) => {
  try{
    let proxy = await KFProxy.deployed();
    let gameManager = await GameManager.deployed();
    let getterDB = await GMGetterDB.deployed();

    accounts = await web3.eth.getAccounts();

    let gameId = process.argv[4];

    let {playerBlack, playerRed, kittyBlack, kittyRed} = await getterDB.getGamePlayers(gameId);

    await proxy.execute('GameManager', setMessage(gameManager, 'startGame',
      [gameId, randomValue(99), "512955438081049600613224346938352058409509756310147795204209859701881294"]), { from: playerBlack });

    await timeout(5);

    await proxy.execute('GameManager', setMessage(gameManager, 'startGame',
      [gameId, randomValue(99), "24171491821178068054575826800486891805334952029503890331493652557302916"]), { from: playerRed });

    console.log('\nPlayerBlack: ', playerBlack);
    console.log('\nPlayerRed: ', playerRed);
    
    callback()
  }
  catch(e){callback(e)}

}