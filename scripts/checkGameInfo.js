const GMGetterDB = artifacts.require('GMGetterDB')
const GameStore = artifacts.require('GameStore')

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

gameStates = ['WAITING', 'PREGAME', 'MAINGAME', 'GAMEOVER', 'CLAIMING', 'CANCELLED'];

function formatDate(timestamp) {
  let date = new Date(null);
  date.setSeconds(timestamp);
  return date.toTimeString().replace(/.*(\d{2}:\d{2}:\d{2}).*/, "$1");
}

//truffle exec scripts/checkGameInfo.js <gameId> --network rinkeby

module.exports = async (callback) => {
	try{
    let getterDB = await GMGetterDB.deployed();
    let gameStore = await GameStore.deployed()

    let gameId = process.argv[4];

    let info = await getterDB.getGameInfo(gameId);
    let times = await getterDB.getGameTimes(gameId);
    let potInfo = await getterDB.getHoneypotInfo(gameId);
    let winners = await getterDB.getWinners(gameId);
    let storeInfo = await gameStore.gameSettings(gameId);

    console.log(`\n============= GAME ${gameId} INFO ==============`);
    
    console.log('\n Game State:', gameStates[info.state.toNumber()]);
    console.log(' Start Time ', formatDate(times.startTime.toString()))
    console.log(' Prestart Time:', formatDate(times.preStartTime.toString()));
    console.log(' End Time:', formatDate(times.endTime.toString()));
    console.log(' Player Black:', info.players[0]);
    console.log(' Player Red:', info.players[1]);
    console.log(' Kitty Black:', info.kittieIds[0].toString());
    console.log(' Kitty Red:', info.kittieIds[1].toString());
    console.log(' Supporters Black:', info.supporters[0].toString());
    console.log(' Supporters Red:', info.supporters[1].toString());
    console.log(' Black Pressed Start?:', info.pressedStart[0]);
    console.log(' Red Pressed Start?:', info.pressedStart[1]);
    console.log(' Initial ETH:', web3.utils.fromWei(potInfo.initialEth.toString()));
    console.log(' Total ETH:', web3.utils.fromWei(potInfo.ethTotal.toString()));
    console.log(' Total KTY:', web3.utils.fromWei(potInfo.ktyTotal.toString()));
    console.log(' Winner:', winners.winner === ZERO_ADDRESS ? null : winners.winner);
    console.log(' Top Bettor:', winners.topBettor === ZERO_ADDRESS ? null : winners.topBettor);
    console.log(' Second Top Bettor:', winners.secondTopBettor === ZERO_ADDRESS ? null : winners.secondTopBettor);
    console.log(' Min Contributors:', storeInfo.minimumContributors.toNumber());
    console.log(' Honeypot Expiration Delay:', storeInfo.honeypotExpirationTime.toNumber()/3600, "hours")
    console.log(' Kittie Hell Expiration Delay:', storeInfo.kittieHellExpirationTime.toNumber()/3600, "hours")

    console.log('=========================================');

		callback()
	}
	catch(e){callback(e)}

}