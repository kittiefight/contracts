const GameCreation = artifacts.require("GameCreation");
const GMGetterDB = artifacts.require("GMGetterDB");

function formatDate(timestamp) {
  let date = new Date(null);
  date.setSeconds(timestamp);
  return date.toTimeString().replace(/.*(\d{2}:\d{2}:\d{2}).*/, "$1");
}

//truffle exec scripts/FE/getGames.js
module.exports = async callback => {
  try {
    let gameCreation = await GameCreation.deployed();
    let gmGetterDB = await GMGetterDB.deployed();

    let newGameEvents = await gameCreation.getPastEvents("NewGame", {
      fromBlock: 0,
      toBlock: "latest"
    });

    for (let i = 0; i < newGameEvents.length; i++) {
      let gameDetails = newGameEvents[i].returnValues;
      let gameState = await gmGetterDB.getGameState(gameDetails.gameId);
      console.log(`\n==== NEW GAME with id ${gameDetails.gameId} ====`);
      console.log("PlayerBlack: ", gameDetails.playerBlack);
      console.log("  PlayerRed: ", gameDetails.playerRed);
      console.log("KittieBlack: ", gameDetails.kittieBlack);
      console.log("  KittieRed: ", gameDetails.kittieRed);
      console.log("  GameStart: ", formatDate(gameDetails.gameStartTime));
      console.log("  GameState: ", gameState.toString());
    }
    callback();
  } catch (e) {
    callback(e);
  }
};
