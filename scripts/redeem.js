const KFProxy = artifacts.require('KFProxy')
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

//truffle exec scripts/redeem.js <gameId> <kittieId> <accountIndex> --network rinkeby                                       

module.exports = async (callback) => {
  try{
    let proxy = await KFProxy.deployed();
    let kittieHell = await KittieHell.deployed();
    let endowmentFund = await EndowmentFund.deployed();
    let kittieFightToken = await KittieFightToken.deployed();
    let cryptoKitties = await CryptoKitties.deployed();

    let gameId = process.argv[4];
    let kittieId = process.argv[5];
    let accountIndex = process.argv[6];
    
    allAccounts = await web3.eth.getAccounts();

    let account = allAccounts[accountIndex];

    let resurrectionCost = await kittieHell.getResurrectionCost(kittieId, gameId);

    console.log(`Approving ${web3.utils.fromWei(resurrectionCost.toString())} KTY to endowment ...`);
    await kittieFightToken.approve(endowmentFund.address, resurrectionCost,
      { from: account });
    
    console.log(`Redeeming kitty ${kittieId} ...`);
    await proxy.execute('KittieHell', setMessage(kittieHell, 'payForResurrection',
      [kittieId, gameId]), { from: account });

    let owner = await cryptoKitties.ownerOf(kittieId);

    if (owner === account){
      console.log('Kitty Redeemed!\n');
    }

    callback()
  }
  catch(e){callback(e)}
}