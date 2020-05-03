const GameManager = artifacts.require('GameManager')
const GMGetterDB = artifacts.require('GMGetterDB')

// truffle exec scripts/getFinalDetails.js <gameId>  --network rinkeby

module.exports = async (callback) => {
    try{
        let gameManager = await GameManager.deployed();
        let getterDB = await GMGetterDB.deployed();

        let gameId = process.argv[4];

        let info = await getterDB.getGameInfo(gameId);

        let gameEnd = await gameManager.getPastEvents('GameEnded', {
            filter: { gameId },
            fromBlock: 0,
            toBlock: 'latest'
        })
            
        let { pointsBlack, pointsRed } = gameEnd[0].returnValues;
        
        let winners = await getterDB.getWinners(gameId);        
        
        
        let corner = (winners.winner === info.players[0]) ? "Black Corner" : "Red Corner"
        
        console.log(`\n==== WINNER: ${corner} ==== `)
        console.log(`   Winner: ${winners.winner}   `);
        console.log(`   TopBettor: ${winners.topBettor}   `)
        console.log(`   SecondTopBettor: ${winners.secondTopBettor}   `)
        console.log('')
        console.log(`   Points Black: ${pointsBlack / 100}   `);
        console.log(`   Point Red: ${pointsRed / 100}   `);
        console.log('=======================\n')
      
      
        callback()
    }
    catch(e){callback(e)}
  
  }
