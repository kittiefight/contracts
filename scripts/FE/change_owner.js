const KFProxy = artifacts.require('KFProxy')
const GMGetterDB = artifacts.require('GMGetterDB')
const KittieHell = artifacts.require('KittieHell')
const EndowmentFund = artifacts.require('EndowmentFund')
const KittieFightToken = artifacts.require('KittieFightToken')
const CryptoKitties = artifacts.require('MockERC721Token');

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

//truffle exec scripts/FE/change_owner.js kittieID(uint) (number for accounts[number]) 
//Script for changing owner of kitty                                      

module.exports = async (callback) => {
  try{
    let proxy = await KFProxy.deployed();
    let getterDB = await GMGetterDB.deployed();
    let kittieHell = await KittieHell.deployed();
    let endowmentFund = await EndowmentFund.deployed();
    let kittieFightToken = await KittieFightToken.deployed();
    let cryptoKitties = await CryptoKitties.deployed();

    accounts = await web3.eth.getAccounts();

    let kittyId = process.argv[4];
    let newOwner = accounts[process.argv[5]];

    let player = await cryptoKitties.ownerOf(kittyId);
    console.log('Old Owner: ', player);

    await cryptoKitties.transfer(newOwner, kittyId, {from: player});

    let owner = await cryptoKitties.ownerOf(kittyId);

    if(owner === newOwner){
      console.log('Owner changed: ', newOwner);
    }


    


    callback()
  }
  catch(e){callback(e)}
}