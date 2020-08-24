const CryptoKitties = artifacts.require("MockERC721Token");
const KFProxy = artifacts.require("KFProxy");
const Scheduler = artifacts.require("Scheduler");
const ListKitties = artifacts.require("ListKitties");
const GameVarAndFee = artifacts.require("GameVarAndFee");

// =================================================== //

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find(f => {
      return f.name == funcName;
    }),
    argArray
  );
}

// truffle exec scripts/listKitties.js kittieId1 kittieId2
// account owner of kittie should be unlocked

module.exports = async callback => {
  try {
    cryptoKitties = await CryptoKitties.deployed();
    proxy = await KFProxy.deployed();
    scheduler = await Scheduler.deployed();
    listKitties = await ListKitties.deployed();
    gameVarAndFee = await GameVarAndFee.deployed();

    let kittieId1 = process.argv[4];
    let kittieId2 = process.argv[5];
    let owner1 = await cryptoKitties.ownerOf(kittieId1);
    let owner2 = await cryptoKitties.ownerOf(kittieId2);

    console.log(owner1);
    console.log(owner2);

    const value = await gameVarAndFee.getListingFee();
    console.log(value[0].toString());

    await proxy.execute(
      "ListKitties",
      setMessage(listKitties, "listKittie", [kittieId1]),
      {from: owner1, value: value[0].toString()}
    );

    await proxy.execute(
      "ListKitties",
      setMessage(listKitties, "listKittie", [kittieId2]),
      {from: owner2, value: value[0].toString()}
    );

    let isListed = await scheduler.isKittyListedForMatching(kittieId1);

    let noOfKitties = await scheduler.getNoOfKittiesListed();
    console.log("NoOfKittiesListed: ", noOfKitties.toString());

    if (isListed) console.log(`\nListed kittie ${kittieId1}!`);
    else console.log(`\nError listing kittie`);

    isListed = await scheduler.isKittyListedForMatching(kittieId2);

    if (isListed) console.log(`\nListed kittie ${kittieId2}!`);
    else console.log(`\nError listing kittie`);

    callback();
  } catch (e) {
    callback(e);
  }
};
