const KittieHell = artifacts.require("KittieHell");
const KittieHellDB = artifacts.require("KittieHellDB");
const KFProxy = artifacts.require("KFProxy");
const Forfeiter = artifacts.require("Forfeiter.sol");
const Scheduler = artifacts.require("Scheduler");
const GameCreation = artifacts.require("GameCreation");
const KittieFightToken = artifacts.require('KittieFightToken')
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
    let kittieHellDB = await KittieHellDB.deployed();
    let forfeiter = await Forfeiter.deployed();
    let gameCreation = await GameCreation.deployed();
    let scheduler = await Scheduler.deployed();
    let kittieFightToken = await KittieFightToken.deployed();
    let oldKittieHell = await KittieHell.deployed();
    console.log("Old KittieHell address:", oldKittieHell.address)

    let kittieHell = await KittieHell.new();
    console.log("New KittieHell address:", kittieHell.address);

    // transfer all the locked KTYs to the new kittieHell address before upgrading kittieHell
    await oldKittieHell.transferKTYsLockedInHell(kittieHell.address);
    let balBefore = await kittieFightToken.balanceOf(oldKittieHell.address);
    let balAfter = await kittieFightToken.balanceOf(kittieHell.address);

    console.log("KTYs owned by old KittieHell:", weiToEther(balBefore));
    console.log("KTYs owned by new KittieHell:", weiToEther(balAfter));

    let file = editJsonFile("build/contracts/KittieHell.json");

    file.set("networks.999.address", kittieHell.address);
    file.save();

    console.log("SetProxy...");
    await kittieHell.setProxy(proxy.address);
    await proxy.updateContract("KittieHell", kittieHell.address);

    console.log("KittieHell deployed...");

    console.log("Initialize...");
    await kittieHell.initialize();
    await kittieHellDB.initialize();
    await forfeiter.initialize();
    await scheduler.initialize();
    await gameCreation.initialize();

    callback();
  } catch (e) {
    callback(e);
  }
};
