const KFProxy = artifacts.require('KFProxy')
const GMGetterDB = artifacts.require('GMGetterDB')
const KittieHell = artifacts.require('KittieHell')
const KittieHellDB = artifacts.require("KittieHellDB");
const KittieHellDungeon = artifacts.require("KittieHellDungeon");
const EndowmentFund = artifacts.require('EndowmentFund')
const KittieFightToken = artifacts.require('KittieFightToken')
const CryptoKitties = artifacts.require('MockERC721Token');
const KtyUniswap = artifacts.require("KtyUniswap");
const Escrow = artifacts.require("Escrow");
const GameStore = artifacts.require('GameStore')
const GameManagerHelper = artifacts.require('GameManagerHelper')
const AccountingDB = artifacts.require('AccountingDB')
const RedeemKittie = artifacts.require('RedeemKittie')

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
    let kittieHellDungeon = await KittieHellDungeon.deployed();
    let endowmentFund = await EndowmentFund.deployed();
    let kittieFightToken = await KittieFightToken.deployed();
    let cryptoKitties = await CryptoKitties.deployed();
    let ktyUniswap = await KtyUniswap.deployed();
    let escrow = await Escrow.deployed()
    let gameStore = await GameStore.deployed()
    let gameManagerHelper = await GameManagerHelper.deployed()
    let accountingDB = await AccountingDB.deployed()
    let redeemKittie = await RedeemKittie.deployed()

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

    let resurrectionFee = await accountingDB.getKittieRedemptionFee(gameId);
    let resurrectionCost = resurrectionFee[1]
  
    const sacrificeKitties = [1017555, 413830, 888];

    for (let i = 0; i < sacrificeKitties.length; i++) {
      await cryptoKitties.mint(loser, sacrificeKitties[i]);
    }

    for (let i = 0; i < sacrificeKitties.length; i++) {
      await cryptoKitties.approve(kittieHellDungeon.address, sacrificeKitties[i], {
        from: loser
      });
    }

    // await kittieFightToken.approve(kittieHell.address, resurrectionCost, {
    //   from: loser
    // });

    let ether_resurrection_cost = resurrectionFee[0]
    console.log("KTY resurrection cost:", weiToEther(resurrectionCost))
    console.log("ether needed for swap KTY resurrection:", weiToEther(ether_resurrection_cost))

    await proxy.execute(
      "RedeemKittie",
      setMessage(redeemKittie, "payForResurrection", [
        loserKitty,
        gameId,
        loser,
        sacrificeKitties
      ]),
      {from: loser, value: ether_resurrection_cost}
    );

    let owner = await cryptoKitties.ownerOf(loserKitty);

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

    // -- swap info--
    console.log('\n==== UNISWAP RESERVE RATIO ===');
    ktyReserve = await ktyUniswap.getReserveKTY();
    ethReserve = await ktyUniswap.getReserveETH();
    console.log("reserveKTY:", weiToEther(ktyReserve));
    console.log("reserveETH:", weiToEther(ethReserve));

    ether_kty_ratio = await ktyUniswap.ETH_KTY_ratio();
    kty_ether_ratio = await ktyUniswap.KTY_ETH_ratio();
    console.log(
      "Ether to KTY ratio:",
      "1 ether to",
      weiToEther(ether_kty_ratio),
      "KTY"
    );
    console.log(
      "KTY to Ether ratio:",
      "1 KTY to",
      weiToEther(kty_ether_ratio),
      "ether"
    );

    let ether_kty_price = await ktyUniswap.ETH_KTY_price();
    let kty_ether_price = await ktyUniswap.KTY_ETH_price();
    console.log(
      "Ether to KTY price:",
      "1 ether to",
      weiToEther(ether_kty_price),
      "KTY"
    );
    console.log(
      "KTY to Ether price:",
      "1 KTY to",
      weiToEther(kty_ether_price),
      "ether"
    );
    
    callback()
  }
  catch(e){callback(e)}
}