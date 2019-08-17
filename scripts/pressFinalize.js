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

// truffle exec scripts/FE/finalize.js <gameId> --network rinkeby

module.exports = async (callback) => {
  try{
    let proxy = await KFProxy.deployed();
    let gameManager = await GameManager.deployed();
    let getterDB = await GMGetterDB.deployed();

    let gameId = process.argv[4];
    let accountIndex = process.argv[5];

    allAccounts = await web3.eth.getAccounts();

    let finalizer = allAccounts[accountIndex];

    let {playerBlack} = await getterDB.getGamePlayers(gameId);

    console.log('Pressing finalize button...')
    await proxy.execute('GameManager', setMessage(gameManager, 'finalize',
      [gameId, randomValue(99)]), { from: finalizer });

    let gameEnd = await gameManager.getPastEvents('GameEnded', {
      filter: { gameId },
      fromBlock: 0,
      toBlock: 'latest'
    })

    let { pointsBlack, pointsRed } = gameEnd[0].returnValues;

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