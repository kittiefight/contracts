const KFProxy = artifacts.require('KFProxy')
const GMGetterDB = artifacts.require('GMGetterDB')
const GameCreation = artifacts.require('GameCreation')
const MockERC721Token = artifacts.require('MockERC721Token')

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
function timeout(s) {
  // console.log(`~~~ Timeout for ${s} seconds`);
  return new Promise(resolve => setTimeout(resolve, s * 1000));
}

//truffle exec scripts/FE/newgame.js kittyRed(kittieID) kittyBlack(kittieID) gameStartTimeGiven(FORMATexample (UTC): 2009 02 13 23:31:30)
//Only SuperAdmin can call this function. Owners of Kittys must be those players.
//Example: truffle exec scripts/FE/newGame.js 1001 324 '2019-08-12T19:25:00.906Z';

module.exports = async (callback) => {
  try{
    let proxy = await KFProxy.deployed();
    let getterDB = await GMGetterDB.deployed();
    let gameCreation = await GameCreation.deployed();
    let mockERC721Token = await MockERC721Token.deployed();

    accounts = await web3.eth.getAccounts();

    let kittyRed = process.argv[4];
    let kittyBlack = process.argv[5];
    let gameStartTimeGiven = process.argv[6];

    //Must take owners of Kitties here
    let playerBlack = await mockERC721Token.ownerOf(kittyBlack);
    let playerRed = await mockERC721Token.ownerOf(kittyRed);

    console.log('PlayerBlack: ', playerBlack);
    console.log('PlayerRed: ', playerRed);

    //Format of FORMATexample to timestamp for blockchain
    // Set variable to current date and time
    let gameStartTimeGivenToTimestamp1 = new Date(gameStartTimeGiven).valueOf();

    let gameStartTimeGivenToTimestamp = gameStartTimeGivenToTimestamp1/1000;
    console.log(gameStartTimeGivenToTimestamp);

    await proxy.execute('GameCreation', setMessage(gameCreation, 'manualMatchKitties',
      [playerRed, playerBlack, kittyRed, kittyBlack, gameStartTimeGivenToTimestamp]), { from: accounts[0] });

    await timeout(5);

    let newGameEvents = await gameCreation.getPastEvents("NewGame", {
      fromBlock: 0,
      toBlock: "latest"
    });
    // assert.equal(newGameEvents.length, 2);



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
    console.log(gameId1);
    console.log(gameId2);

    if(gameId1 === gameId2) console.log('\nGameId: ', gameId1);

    //Take gameStartTime from blockchain to see if it is same as the one we gave
    let {preStartTime, startTime, endTime} = await getterDB.getGameTimes(gameId1);

    console.log('\nGame PreStart Time in UTC: ', formatDate(preStartTime));
    if(startTime === gameStartTimeGivenToTimestamp) console.log('\nGame Start Time in UTC: ', formatDate(startTime));
    console.log('\nGame End Time in UTC: ', formatDate(endTime));

    let {realPlayerBlack, realPlayerRed, realKittyBlack, realKittyRed} = await getterDB.getGamePlayers(gameId1);

    if((realPlayerBlack === playerBlack) && (realPlayerRed === playerRed) && (realKittyBlack === kittyBlack) && (realKittyRed === kittyRed)){
      console.log('\nPlayer Black: ', playerBlack);
      console.log('\nKitty Black: ', kittyBlack);
      console.log('\nPlayer Red: ', playerRed);
      console.log('\nKitty Red: ', kittyRed);
    }
    
    callback()
  }
  catch(d){callback(d)}

}