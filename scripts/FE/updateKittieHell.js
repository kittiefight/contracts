const KittieHell = artifacts.require("KittieHell");
const KittieHellDB = artifacts.require("KittieHellDB");
const KFProxy = artifacts.require("KFProxy");
const Forfeiter = artifacts.require("Forfeiter.sol");
const Scheduler = artifacts.require("Scheduler");
const GameCreation = artifacts.require("GameCreation");
const editJsonFile = require("edit-json-file");

module.exports = async callback => {
  try {
    console.log("Starting....");
    let proxy = await KFProxy.deployed();
    let kittieHellDB = await KittieHellDB.deployed();
    let forfeiter = await Forfeiter.deployed();
    let gameCreation = await GameCreation.deployed();
    let scheduler = await Scheduler.deployed();

    let kittieHell = await KittieHell.new();
    console.log(kittieHell.address);

    let file = editJsonFile("build/contracts/KittieHell.json");

    file.set("networks.999.address", kittieHell.address);
    file.save();

    console.log("SetProxy...");
    await kittieHell.setProxy(proxy.address);
    await proxy.updateContract("KittieHell", kittieHell.address);

    console.log("KittieHell deployed...");

    console.log("Initialize...");
    await kittieHell.initialize();
    await kittieHellDB.setKittieHELL();
    await forfeiter.initialize();
    await scheduler.initialize();
    await gameCreation.initialize();

    callback();
  } catch (e) {
    callback(e);
  }
};
