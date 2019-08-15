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

    let state = await getterDB.getGameState(gameId);
    console.log(Number(state));

    callback()
  }
  catch(e){callback(e)}

}