const KFProxy = artifacts.require('KFProxy')
const GMGetterDB = artifacts.require('GMGetterDB')
const GameManager = artifacts.require('GameManager')

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

//truffle exec scripts/participate.js <gameId> <RED or BLACK> <account>

module.exports = async (callback) => {
  try{
    let proxy = await KFProxy.deployed();
    let gameManager = await GameManager.deployed();
    let getterDB = await GMGetterDB.deployed();

    let gameId = process.argv[4];
    let playerToSupport = process.argv[5];
    let account = process.argv[6]; 

    let supported;
    
    let {playerBlack, playerRed} = await getterDB.getGamePlayers(gameId);
    
    if (playerToSupport === "RED") supported = playerRed;
    else if (playerToSupport === "BLACK") supported = playerBlack;
    else callback(new Error("You need to choose 'RED' or 'BLACK'"))

    await proxy.execute('GameManager', setMessage(gameManager, 'participate',
    [gameId, supported]), { from: account })
    
    let info = await getterDB.getSupporterInfo(gameId, account);

    if (info.supportedPlayer === supported) console.log(`\nAdded participator for player ${playerToSupport}`);
    
    callback()
  }
  catch(e){callback(e)}

}

