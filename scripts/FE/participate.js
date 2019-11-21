const KFProxy = artifacts.require('KFProxy')
const GMGetterDB = artifacts.require('GMGetterDB')
const GameStore = artifacts.require('GameStore')
const GameManager = artifacts.require('GameManager')
const DateTime = artifacts.require('DateTime')
const RoleDB = artifacts.require('RoleDB')
const Escrow = artifacts.require('Escrow')
const EndowmentFund = artifacts.require('EndowmentFund')

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

//truffle exec scripts/FE/participate.js gameId(uint) noOfParticipatorsForBlack(uint) noOfParticipatorsForRed(uint) 
//                                       timeBetweenParticipates[uint(seconds)] 

module.exports = async (callback) => {
  try{
    let proxy = await KFProxy.deployed();
    let gameManager = await GameManager.deployed();
    let getterDB = await GMGetterDB.deployed();
    let gameStore = await GameStore.deployed();
    let dateTime = await DateTime.deployed();
    let roleDB = await RoleDB.deployed();
    let escrow = await Escrow.deployed();
    let endowmentFund = await EndowmentFund.deployed();

    accounts = await web3.eth.getAccounts();


    let gameId = process.argv[4];
    let blackParticipators = process.argv[5];
    let redParticipators = process.argv[6]; 
    let timeInterval = process.argv[7];
    let supportersForRed = [];
    let supportersForBlack = [];
    let ticketFee = await gameStore.getTicketFee(gameId);


    let {playerBlack, playerRed, kittyBlack, kittyRed} = await getterDB.getGamePlayers(gameId);
    let participator;


    //accounts 10-29 can be supporters for black

    let blacks = Number(blackParticipators) + 10;
    let reds = Number(redParticipators) + 30;

    for(let i = 10; i < blacks; i++){
      participator = accounts[i];
      await proxy.execute('GameManager', setMessage(gameManager, 'participate',
      [gameId, playerBlack]), { from: participator })
      console.log('\nNew Participator for playerBlack: ', participator);
      supportersForBlack.push(participator);
      await timeout(timeInterval);
    }


    //accounts 30-49 can be supporters for red
    for(let j = 30; j < reds; j++){
      participator = accounts[j]; 
      if(j == (Number(reds) - 1)){
        let block = await dateTime.getBlockTimeStamp();
        console.log('\nblocktime: ', formatDate(block))

        let {preStartTime} = await getterDB.getGameTimes(gameId);

        while (block < preStartTime) {
          block = Math.floor(Date.now() / 1000);
          await timeout(3);
        }
      }
      await proxy.execute('GameManager', setMessage(gameManager, 'participate',
      [gameId, playerRed]), { from: participator });
      console.log('\nNew Participator for playerRed: ', participator);
      supportersForRed.push(participator);
      await timeout(timeInterval);

    }

    let KTYforBlack = blackParticipators * ticketFee;
    let KTYforRed = redParticipators * ticketFee;

    console.log('\nSupporters for Black: ', supportersForBlack);
    console.log('\nSupporters for Red: ', supportersForRed);

    console.log('\nTotal KTY for Black (only participators): ', KTYforBlack);
    console.log('\nTotal KTY for Red (only participators): ', KTYforRed);
    

    callback()
  }
  catch(e){callback(e)}

}

