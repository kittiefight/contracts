const KFProxy = artifacts.require('KFProxy')
const GMGetterDB = artifacts.require('GMGetterDB')
const KittieHell = artifacts.require('KittieHell')
const EndowmentFund = artifacts.require('EndowmentFund')
const KittieFightToken = artifacts.require('KittieFightToken')

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

//truffle exec scripts/FE/redeem.js gameId(uint)
//                                        

module.exports = async (callback) => {
  try{
    let proxy = await KFProxy.deployed();
    let getterDB = await GMGetterDB.deployed();
    let kittieHell = await KittieHell.deployed();
    let endowmentFund = await EndowmentFund.deployed();
    let kittieFightToken = await KittieFightToken.deployed();

    accounts = await web3.eth.getAccounts();

    let gameId = process.argv[4];

    let winners = await getterDB.getWinners(gameId);

    let {playerBlack, playerRed, kittyBlack, kittyRed} = await getterDB.getGamePlayers(gameId);

    let loserKitty;
    let loser;

    if(winners.winner === playerRed){
      loser = playerBlack;
      loserKitty = Number(kittyBlack);
    }
    else{
      loser = playerRed;
      loserKitty = Number(kittyRed);
    }
    console.log(loserKitty);
    console.log(loser);

    let values = await kittieHell.getKittyStatus(loserKitty);
    console.log(values);

    let resurrectionCost = await kittieHell.getResurrectionCost(loserKitty, gameId);

    await kittieFightToken.approve(endowmentFund.address, resurrectionCost,
      { from: loser });

    await proxy.execute('KittieHell', setMessage(kittieHell, 'payForResurrection',
      [loserKitty, gameId]), { from: loser });

    let owner = await cryptoKitties.ownerOf(loserKitty);

    if (owner === loser){
      console.log('Kitty Redeemed');
    }


    callback()
  }
  catch(e){callback(e)}
}