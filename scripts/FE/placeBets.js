const KFProxy = artifacts.require('KFProxy')
const GMGetterDB = artifacts.require('GMGetterDB')
const GameManager = artifacts.require('GameManager')
const Betting = artifacts.require('Betting')
const DateTime = artifacts.require('DateTime')

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

function randomValue(num) {
  return Math.floor(Math.random() * num) + 1; // (1-num) value
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

//truffle exec scripts/FE/placeBets.js gameId(uint) noOfBets(uint) timeBetweenBets[uint(seconds)] maxAmountToBet

module.exports = async (callback) => {
  try{
    let proxy = await KFProxy.deployed();
    let gameManager = await GameManager.deployed();
    let getterDB = await GMGetterDB.deployed();
    let betting = await Betting.deployed();
    let dateTime = await DateTime.deployed();

    accounts = await web3.eth.getAccounts();

    let gameId = process.argv[4];
    let noOfBets = process.argv[5];
    let timeInterval = process.argv[6];
    let maxLimit = process.argv[7];

    let {playerBlack, playerRed, kittyBlack, kittyRed} = await getterDB.getGamePlayers(gameId);

    let supportersRed = await getterDB.getSupporters(gameId, playerRed);
    let supportersBlack = await getterDB.getSupporters(gameId, playerBlack);
    let totalBetAmount = 0;
    let betsBlack = [];
    let betsRed = [];
    let betAmount;
    let player;
    let supportedPlayer;
    let randomSupporter;

    let state = await getterDB.getGameState(gameId);
    console.log(state);

    for(let i=0; i<noOfBets; i++){
      let randomPlayer = randomValue(2);


      if(i == (Number(noOfBets) - 1)){
        let block = await dateTime.getBlockTimeStamp();
        console.log('\nWaiting to end as it last bet! \n BlockTime: ', formatDate(block))

        let {endTime} = await getterDB.getGameTimes(gameId);
        console.log('\nEnd Time: ', endTime);

        while (block < endTime) {
          block = Math.floor(Date.now() / 1000);
          await timeout(3);
        }
      }
      //PlayerBlack
      if(randomPlayer == 1){
        randomSupporter = randomValue((supportersBlack) - 1);
        betAmount = randomValue(maxLimit);
        player = 'playerBlack';
        supportedPlayer = accounts[((Number(randomSupporter)) + 10)];

        await proxy.execute('GameManager', setMessage(gameManager, 'bet',
        [gameId, randomValue(98)]), { from: supportedPlayer, value: web3.utils.toWei(String(betAmount)) });

        betsBlack.push(betAmount);
      }
      //PlayerRed
      else{
        randomSupporter = randomValue(Number(supportersRed) - 1);
        betAmount = randomValue(maxLimit);
        player = 'playerRed';
        supportedPlayer = accounts[((Number(randomSupporter)) + 30)];

        await proxy.execute('GameManager', setMessage(gameManager, 'bet',
        [gameId, randomValue(98)]), { from: supportedPlayer, value: web3.utils.toWei(String(betAmount)) });
        
        betsRed.push(betAmount);
      }

      let betEvents = await betting.getPastEvents('BetPlaced', {
        filter: { gameId },
        fromBlock: 0,
        toBlock: "latest"
      })

      let betDetails = betEvents[betEvents.length - 1].returnValues;
      console.log(`\n==== NEW BET FOR ${player} ====`);
      console.log(' Amount:', web3.utils.fromWei(betDetails._lastBetAmount), 'ETH');
      console.log(' Bettor:', betDetails._bettor);
      console.log(' Attack Hash:', betDetails.attackHash);
      console.log(' Blocked?:', betDetails.isBlocked);
      console.log(` Defense ${player}:`, betDetails.defenseLevelSupportedPlayer);
      console.log(' Defense Opponent:', betDetails.defenseLevelOpponent);

      let {endTime} = await getterDB.getGameTimes(gameId);

      if(player === 'playerBlack'){
        let lastBetTimestamp = await betting.lastBetTimestamp(gameId, playerBlack);
        console.log(' Timestamp last Bet: ', formatDate(lastBetTimestamp));

        if (lastBetTimestamp > endTime) {
          console.log('\nGame Ended during last bet!')
          break;
        }
      }
      else{
        let lastBetTimestamp = await betting.lastBetTimestamp(gameId, playerRed);
        console.log(' Timestamp last Bet: ', formatDate(lastBetTimestamp));

        if (lastBetTimestamp >= endTime) {
          console.log('\nGame Ended during last bet!')
          break;
        }
      }

      totalBetAmount = totalBetAmount + betAmount;
      await timeout(timeInterval);

    }

    console.log('\nBets Black: ', betsBlack)
    console.log('\nBets Red: ', betsRed)

    let honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `)
    console.log(`     InitialEtH: ${web3.utils.fromWei(honeyPotInfo.initialEth.toString())}   `);
    console.log(`     TotalETH: ${web3.utils.fromWei(honeyPotInfo.ethTotal.toString())}   `);
    console.log(`     TotalKTY: ${web3.utils.fromWei(honeyPotInfo.ktyTotal.toString())}   `);
    console.log('=======================\n')    
    

    callback()
  }
  catch(e){callback(e)}

}
