const KFProxy = artifacts.require('KFProxy')
const GMGetterDB = artifacts.require('GMGetterDB')
const GameStore = artifacts.require('GameStore')
const GameManager = artifacts.require('GameManager')
const Register = artifacts.require('Register')
const DateTime = artifacts.require('DateTime')

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

function timeout(s) {
  // console.log(`~~~ Timeout for ${s} seconds`);
  return new Promise(resolve => setTimeout(resolve, s * 1000));
}

function formatDate(timestamp) {
  let date = new Date(null);
  date.setSeconds(timestamp);
  return date.toTimeString().replace(/.*(\d{2}:\d{2}:\d{2}).*/, "$1");
}

function randomValue(num) {
  return Math.floor(Math.random() * num) + 1; // (1-num) value
}

//truffle exec scripts/FE/finalize.js gameId(uint)

module.exports = async (callback) => {
  try{
    let proxy = await KFProxy.deployed();
    let gameManager = await GameManager.deployed();
    let getterDB = await GMGetterDB.deployed();
    let gameStore = await GameStore.deployed();
    let register = await Register.deployed();
    let dateTime = await DateTime.deployed();

    accounts = await web3.eth.getAccounts();

    let gameId = process.argv[4];

    let {preStartTime, startTime, endTime} = await getterDB.getGameTimes(gameId);

    let {playerBlack, playerRed, kittyBlack, kittyRed} = await getterDB.getGamePlayers(gameId);
    
    let finalizer = accounts[20];

    console.log('\n==== WAITING FOR GAME OVER: ', formatDate(endTime))

    await timeout(2);


    await proxy.execute('GameManager', setMessage(gameManager, 'finalize',
      [gameId, randomValue(30)]), { from: finalizer });

    let gameEnd = await gameManager.getPastEvents('GameEnded', {
      filter: { gameId },
      fromBlock: 0,
      toBlock: 'latest'
    })

    let state = await getterDB.getGameState(gameId);
    console.log(state);

    let { pointsBlack, pointsRed, loser } = gameEnd[0].returnValues;

    let winners = await getterDB.getWinners(gameId);

    let corner = (winners.winner === playerBlack) ? "Black Corner" : "Red Corner";

    console.log(`\n==== WINNER: ${corner} ==== `)
    console.log(`   Winner: ${winners.winner}   `);
    console.log(`   TopBettor: ${winners.topBettor}   `)
    console.log(`   SecondTopBettor: ${winners.secondTopBettor}   `)
    console.log('')
    console.log(`   Points Black: ${pointsBlack}   `);
    console.log(`   Point Red: ${pointsRed}   `);
    console.log('=======================\n')

    await timeout(3);

    let honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `)
    console.log(`     InitialEtH: ${web3.utils.fromWei(honeyPotInfo.initialEth.toString())}   `);
    console.log(`     TotalETH: ${web3.utils.fromWei(honeyPotInfo.ethTotal.toString())}   `);
    console.log(`     TotalKTY: ${web3.utils.fromWei(honeyPotInfo.ktyTotal.toString())}   `);
    console.log('=======================\n')
    
    let finalHoneypot = await getterDB.getFinalHoneypot(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `)
    console.log(`     TotalETH: ${web3.utils.fromWei(finalHoneypot.totalEth.toString())}   `);
    console.log(`     TotalKTY: ${web3.utils.fromWei(finalHoneypot.totalKty.toString())}   `);
    console.log('=======================\n')

    callback()
  }
  catch(e){callback(e)}

}
