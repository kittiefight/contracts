const KFProxy = artifacts.require('KFProxy')
const GMGetterDB = artifacts.require('GMGetterDB')
const GameCreation = artifacts.require('GameCreation')
const CryptoKitties = artifacts.require('MockERC721Token')

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

function formatDate(timestamp) {
  let date = new Date(null);
  date.setSeconds(timestamp);
  return date.toTimeString().replace(/.*(\d{2}:\d{2}:\d{2}).*/, "$1");
}

//let gameStartTime = Math.floor(Date.now() / 1000) + 100 + 250;

//truffle exec scripts/manualMatch.js <kittyRed> <kittyBlack> <gameStartTimeStamp>
//Only SuperAdmin can call this function. Owners of Kittys must be those players.
//Example: truffle exec scripts/manualMatch.js 1001 324 1565714534

module.exports = async (callback) => {
  try{
    let proxy = await KFProxy.deployed();
    let getterDB = await GMGetterDB.deployed();
    let gameCreation = await GameCreation.deployed();
    let cryptoKitties = await CryptoKitties.deployed();

    let kittyRed = process.argv[4];
    let kittyBlack = process.argv[5];
    let gameStartTime = Math.floor(Date.now() / 1000) + 100 + 250 //process.argv[6];

    accounts = await web3.eth.getAccounts();

    //Must take owners of Kitties here
    let playerBlack = await cryptoKitties.ownerOf(kittyBlack);
    let playerRed = await cryptoKitties.ownerOf(kittyRed);

    console.log('PlayerBlack: ', playerBlack);
    console.log('PlayerRed: ', playerRed);

    await proxy.execute('GameCreation', setMessage(gameCreation, 'manualMatchKitties',
      [playerRed, playerBlack, kittyRed, kittyBlack, gameStartTime]), { from: accounts[0] });

    let newGameEvents = await gameCreation.getPastEvents("NewGame", {
      fromBlock: 0,
      toBlock: "latest"
    });

    newGameEvents.map(async (e) => {
      let gameInfo = await getterDB.getGameTimes(e.returnValues.gameId);

      console.log('\n==== NEW GAME CREATED ===');
      console.log('    GameId ', e.returnValues.gameId)
      console.log('    Red Fighter ', e.returnValues.kittieRed)
      console.log('    Red Player ', e.returnValues.playerRed)
      console.log('    Black Fighter ', e.returnValues.kittieBlack)
      console.log('    Black Player ', e.returnValues.playerBlack)
      console.log('    Start Time ', formatDate(e.returnValues.gameStartTime))
      console.log('    Prestart Time:', formatDate(gameInfo.preStartTime));
      console.log('    End Time:', formatDate(gameInfo.endTime));
      console.log('========================\n')
    })
    //Take both Kitties game to see it is the same
    let gameId1 = await getterDB.getGameOfKittie(kittyRed);
    let gameId2 = await getterDB.getGameOfKittie(kittyBlack);

    if(gameId1 == gameId2) console.log(`\nGame ${gameId1} created successfully!`);
    
    callback()
  }
  catch(e){callback(e)}

}