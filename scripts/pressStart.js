
const KFProxy = artifacts.require('KFProxy')
const GameManager = artifacts.require('GameManager')
const KittieHELL = artifacts.require('KittieHell')
const CryptoKitties = artifacts.require('MockERC721Token');

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

//truffle exec scripts/pressStart.js <gameId> <accountIndex> --network rinkeby

module.exports = async (callback) => {
  try{
    let proxy = await KFProxy.deployed();
    let gameManager = await GameManager.deployed();
    let kittieHELL = await KittieHELL.deployed()
    let cryptoKitties = await CryptoKitties.deployed();

    let gameId = process.argv[4];
    let accountIndex = process.argv[5];

    // let gamePlayers = await getterDB.getGamePlatyers(gameId);
    
    allAccounts = await web3.eth.getAccounts();

    const genes = "24171491821178068054575826800486891805334952029503890331493652557302916";

    let account = allAccounts[accountIndex];
    
    console.log('Pressing start button...')
    await proxy.execute('GameManager', setMessage(gameManager, 'startGame',
      [gameId, 2456, genes]), { from: account });
    
    console.log(`Player ${account} pressed start in game ${gameId}`)
    
    callback()
  }
  catch(e){callback(e)}

}
