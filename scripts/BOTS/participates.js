const KFProxy = artifacts.require('KFProxy')
const GMGetterDB = artifacts.require('GMGetterDB')
const GameManager = artifacts.require('GameManager')

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

//truffle exec scripts/BOTS/participates.js <gameId> <playerToSupport> <fromAccount> <toAccount> --network rinkeby

module.exports = async (callback) => {
  try{
    let proxy = await KFProxy.deployed();
    let gameManager = await GameManager.deployed();
    let getterDB = await GMGetterDB.deployed();

    let gameId = process.argv[4];
    let playerToSupport = process.argv[5]; //RED or BLACK as string
    let fromAccount = process.argv[6];
    let toAccount = process.argv[7];
    
    allAccounts = await web3.eth.getAccounts();

    let {playerBlack, playerRed} = await getterDB.getGamePlayers(gameId);

    let supported;

    if (playerToSupport === "RED") supported = playerRed;
    else if (playerToSupport === "BLACK") supported = playerBlack;

    for(i = fromAccount ; i <= toAccount; i++){

        let account = allAccounts[i]; 
        console.log(`Supporting Player ${playerToSupport}...`)
        proxy.execute('GameManager', setMessage(gameManager, 'participate',
            [gameId, supported]), { from: account })

    }
    callback()
  }
  catch(e){callback(e)}

}

