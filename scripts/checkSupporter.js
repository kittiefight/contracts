const GMGetterDB = artifacts.require('GMGetterDB')
const GameManager = artifacts.require('GameManager')

//truffle exec scripts/checkSupporter.js <gameId> <supporter> --network rinkeby

module.exports = async (callback) => {
    try{
      let getterDB = await GMGetterDB.deployed();
  
      let gameId = process.argv[4];
      let supporter = process.argv[5];      
    
      let supporterInfo = await getterDB.getSupporterInfo(gameId, supporter);     
      
      console.log('\n============= SUPPORTER INFO ================');
      console.log('\n Address:', supporter);
      console.log(' Bet Amount:', web3.utils.fromWei(supporterInfo.betAmount.toString()), 'ETH');
      console.log(' Supported Player:', supporterInfo.supportedPlayer);
      console.log(' Payed Ticket Fee?:', supporterInfo.ticketFeePaid);
      console.log(' Claimed earnings?:', supporterInfo.hasClaimed);
      
      callback()
    }
    catch(e){callback(e)}
  
  }
  