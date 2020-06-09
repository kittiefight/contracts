const KFProxy = artifacts.require('KFProxy')
const GMGetterDB = artifacts.require('GMGetterDB')
const KittieHell = artifacts.require('KittieHell')
const KittieHellDB = artifacts.require("KittieHellDB");
const EndowmentFund = artifacts.require('EndowmentFund')
const KittieFightToken = artifacts.require('KittieFightToken')
const CryptoKitties = artifacts.require('MockERC721Token');
const KtyUniswap = artifacts.require("KtyUniswap");

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

function weiToEther(w) {
  //let eth = web3.utils.fromWei(w.toString(), "ether");
  //return Math.round(parseFloat(eth));
  return web3.utils.fromWei(w.toString(), "ether");
}

//truffle exec scripts/FE/redeem.js gameId(uint)
//                                        

module.exports = async (callback) => {
  try{
    let proxy = await KFProxy.deployed();
    let getterDB = await GMGetterDB.deployed();
    let kittieHell = await KittieHell.deployed();
    let kittieHellDB = await KittieHellDB.deployed();
    let endowmentFund = await EndowmentFund.deployed();
    let kittieFightToken = await KittieFightToken.deployed();
    let cryptoKitties = await CryptoKitties.deployed();
    let ktyUniswap = await KtyUniswap.deployed();

    accounts = await web3.eth.getAccounts();

    let gameId = process.argv[4];
  
    let winners = await getterDB.getWinners(gameId);

    let {
      playerBlack,
      playerRed,
      kittyBlack,
      kittyRed
    } = await getterDB.getGamePlayers(gameId);

    let loserKitty;
    let loser;

    if (winners.winner === playerRed) {
      loser = playerBlack;
      loserKitty = Number(kittyBlack);
    } else {
      loser = playerRed;
      loserKitty = Number(kittyRed);
    }

    console.log("Loser's Kitty: " + loserKitty);

    let resurrectionCost = await kittieHell.getResurrectionCost(
      loserKitty,
      gameId
    );

    const sacrificeKitties = [1017555, 413830, 888];

    for (let i = 0; i < sacrificeKitties.length; i++) {
      await cryptoKitties.mint(loser, sacrificeKitties[i]);
    }

    for (let i = 0; i < sacrificeKitties.length; i++) {
      await cryptoKitties.approve(kittieHellDB.address, sacrificeKitties[i], {
        from: loser
      });
    }

    // await kittieFightToken.approve(kittieHell.address, resurrectionCost, {
    //   from: loser
    // });

    ether_resurrection_cost = await ktyUniswap.etherFor(resurrectionCost)
    console.log("KTY resurrection cost:", weiToEther(resurrectionCost))
    console.log("ether needed for swap KTY resurrection:", weiToEther(ether_resurrection_cost))

    await proxy.execute(
      "KittieHell",
      setMessage(kittieHell, "payForResurrection", [
        loserKitty,
        gameId,
        loser,
        sacrificeKitties
      ]),
      {from: loser, value: ether_resurrection_cost}
    );

    let owner = await cryptoKitties.ownerOf(loserKitty);

    if (owner === kittieHellDB.address) {
      console.log("Loser kitty became ghost in kittieHELL FOREVER :(");
    }

    if (owner === loser) {
      console.log("Kitty Redeemed :)");
    }

    let numberOfSacrificeKitties = await kittieHellDB.getNumberOfSacrificeKitties(
      loserKitty
    );
    console.log(
      "Number of sacrificing kitties in kittieHELL for " +
        loserKitty +
        ": " +
        numberOfSacrificeKitties.toNumber()
    );

    let KTYsLockedInKittieHell = await kittieHellDB.getTotalKTYsLockedInKittieHell();
    const ktys = web3.utils.fromWei(KTYsLockedInKittieHell.toString(), "ether");
    const ktysLocked = Math.round(parseFloat(ktys));
    console.log("KTYs locked in kittieHELL: " + ktysLocked);

    const isLoserKittyInHell = await kittieHellDB.isKittieGhost(loserKitty);
    console.log("Is Loser's kitty in Hell? " + isLoserKittyInHell);

    const isSacrificeKittyOneInHell = await kittieHellDB.isKittieGhost(
      sacrificeKitties[0]
    );
    console.log("Is sacrificing kitty 1 in Hell? " + isSacrificeKittyOneInHell);

    const isSacrificeKittyTwoInHell = await kittieHellDB.isKittieGhost(
      sacrificeKitties[1]
    );
    console.log("Is sacrificing kitty 2 in Hell? " + isSacrificeKittyTwoInHell);

    const isSacrificeKittyThreeInHell = await kittieHellDB.isKittieGhost(
      sacrificeKitties[2]
    );
    console.log(
      "Is sacrificing kitty 3 in Hell? " + isSacrificeKittyThreeInHell
    );
    
    callback()
  }
  catch(e){callback(e)}
}