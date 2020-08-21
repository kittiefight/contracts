const KFProxy = artifacts.require("KFProxy");
const GameStore = artifacts.require("GameStore");
const GMSetterDB = artifacts.require("GMSetterDB");
const GMGetterDB = artifacts.require("GMGetterDB");
const GameManager = artifacts.require("GameManager");
const GameCreation = artifacts.require("GameCreation");
const Forfeiter = artifacts.require("Forfeiter");
const EndowmentFund = artifacts.require("EndowmentFund");
const Scheduler = artifacts.require("Scheduler");
const KittieHELL = artifacts.require("KittieHell");

const editJsonFile = require("edit-json-file");

function weiToEther(w) {
  //let eth = web3.utils.fromWei(w.toString(), "ether");
  //return Math.round(parseFloat(eth));
  return web3.utils.fromWei(w.toString(), "ether");
}

module.exports = async callback => {
  try {
    console.log("Starting....");
    let proxy = await KFProxy.deployed();
    let gameCreation = await GameCreation.deployed();
    let gmSetterDB = await GMSetterDB.deployed();
    let gmGetterDB = await GMGetterDB.deployed();
    let gameManager = await GameManager.deployed();
    let forfeiter = await Forfeiter.deployed();
    let endowmentFund = await EndowmentFund.deployed();
    let scheduler = await Scheduler.deployed();
    let kittieHell = await KittieHELL.deployed();

    let gameStore = await GameStore.new();
    console.log("New GameStore address:", gameStore.address);

    let file = editJsonFile("build/contracts/GameStore.json");

    file.set("networks.999.address", gameStore.address);
    file.save();

    console.log("SetProxy...");
    await gameStore.setProxy(proxy.address);
    await proxy.updateContract("GameStore", gameStore.address);

    console.log("New GameStore deployed...");

    console.log("Initialize...");
    await gameStore.initialize();
    await gameCreation.initialize();
    await gmSetterDB.initialize();
    await gmGetterDB.initialize();
    await gameManager.initialize();
    await forfeiter.initialize();
    await endowmentFund.initialize();
    await scheduler.initialize();
    await kittieHell.initialize();

    callback();
  } catch (e) {
    callback(e);
  }
};
