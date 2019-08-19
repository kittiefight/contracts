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
    let participator = accounts[process.argv[5]];


    let {playerBlack, playerRed, kittyBlack, kittyRed} = await getterDB.getGamePlayers(gameId);
    
    await proxy.execute('GameManager', setMessage(gameManager, 'participate',
    [gameId, playerRed]), { from: participator });
    

    callback()
  }
  catch(e){callback(e)}

}

