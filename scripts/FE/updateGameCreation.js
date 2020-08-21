const KFProxy = artifacts.require("KFProxy");
const GMSetterDB = artifacts.require("GMSetterDB");
const GameManager = artifacts.require("GameManager");
const GameCreation = artifacts.require("GameCreation");
const Scheduler = artifacts.require("Scheduler");

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
    let gmSetterDB = await GMSetterDB.deployed();
    let gameManager = await GameManager.deployed();
    let scheduler = await Scheduler.deployed();

    let gameCreation = await GameCreation.new();
    console.log("New GameCreation address:", gameCreation.address);

    let file = editJsonFile("build/contracts/GameCreation.json");

    file.set("networks.999.address", gameCreation.address);
    file.save();

    console.log("SetProxy...");
    await gameCreation.setProxy(proxy.address);
    await proxy.updateContract("GameCreation", gameCreation.address);

    console.log("New GameCreation deployed...");

    console.log("Initialize...");
    await gameCreation.initialize();
    await gmSetterDB.initialize();
    await gameManager.initialize();
    await scheduler.initialize();

    callback();
  } catch (e) {
    callback(e);
  }
};
