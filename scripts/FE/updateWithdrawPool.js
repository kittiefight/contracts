const KFProxy = artifacts.require("KFProxy");
const WithdrawPool = artifacts.require('WithdrawPool')
const GameCreation = artifacts.require("GameCreation");
const TimeLockManager = artifacts.require('TimeLockManager');
const SuperDaoToken = artifacts.require('MockERC20Token');

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
    let timeLockManager = await TimeLockManager.deployed();
    let superDaoToken = await SuperDaoToken.deployed();
   
    let withdrawPool = await WithdrawPool.new();
    console.log("New WithdrawPool address:", withdrawPool.address);

    let file = editJsonFile("build/contracts/WithdrawPool.json");

    file.set("networks.999.address", withdrawPool.address);
    file.save();

    console.log("SetProxy...");
    await withdrawPool.setProxy(proxy.address);
    await proxy.updateContract("WithdrawPool", withdrawPool.address);

    console.log("New withdrawPool deployed...");

    console.log("Initialize...");
    await withdrawPool.initialize(timeLockManager.address, superDaoToken.address);
    await gameCreation.initialize();

    callback();
  } catch (e) {
    callback(e);
  }
};
