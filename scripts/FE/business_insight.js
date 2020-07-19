const KFProxy = artifacts.require("KFProxy");
const EndowmentFund = artifacts.require("EndowmentFund");
const Escrow = artifacts.require("Escrow");
const KittieFightToken = artifacts.require("KittieFightToken");
const Factory = artifacts.require("UniswapV2Factory");
const WETH = artifacts.require("WETH9");
const KtyWethPair = artifacts.require("UniswapV2Pair");
const KtyWethOracle = artifacts.require("KtyWethOracle");
const KtyUniswap = artifacts.require("KtyUniswap");
const Router = artifacts.require("UniswapV2Router01");
const Dai = artifacts.require("Dai");
const DaiWethPair = artifacts.require("IDaiWethPair");
const DaiWethOracle = artifacts.require("DaiWethOracle");
const GameVarAndFee = artifacts.require("GameVarAndFee");
const WithdrawPool = artifacts.require("WithdrawPool");
const EarningsTracker = artifacts.require("EarningsTracker");
const GMGetterDB = artifacts.require('GMGetterDB');
const KittieHellDB = artifacts.require('KittieHellDB');
const KittieHell = artifacts.require('KittieHell');

const BigNumber = web3.utils.BN;

require("chai")
  .use(require("chai-shallow-deep-equal"))
  .use(require("chai-bignumber")(BigNumber))
  .use(require("chai-as-promised"))
  .should();

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find(f => {
      return f.name == funcName;
    }),
    argArray
  );
}

function timeout(s) {
  // console.log(`~~~ Timeout for ${s} seconds`);
  return new Promise(resolve => setTimeout(resolve, s * 1000));
}

function weiToEther(w) {
  //let eth = web3.utils.fromWei(w.toString(), "ether");
  //return Math.round(parseFloat(eth));
  return web3.utils.fromWei(w.toString(), "ether");
}

//truffle exec scripts/FE/uniswap_setup.js

module.exports = async callback => {
  try {
    accounts = await web3.eth.getAccounts();

    let proxy = await KFProxy.deployed();
    let endowmentFund = await EndowmentFund.deployed();
    let escrow = await Escrow.deployed();
    let kittieFightToken = await KittieFightToken.deployed();
    let weth = await WETH.deployed();
    let dai = await Dai.deployed();
    let factory = await Factory.deployed();
    let ktyWethOracle = await KtyWethOracle.deployed();
    let daiWethOracle = await DaiWethOracle.deployed();
    let ktyUniswap = await KtyUniswap.deployed();
    let router = await Router.deployed();
    let gameVarAndFee = await GameVarAndFee.deployed();
    let withdrawPool = await WithdrawPool.deployed();
    let earningsTracker = await EarningsTracker.deployed();
    let gmGetterDB = await GMGetterDB.deployed();
    let kittieHell = await KittieHell.deployed();
    let kittieHellDB = await KittieHellDB.deployed();

    let router_factory = await router.factory();
    let router_WETH = await router.WETH();
    let pairAddress = await factory.getPair(
      weth.address,
      kittieFightToken.address
    );
    let ktyWethPair = await KtyWethPair.at(pairAddress);
    await router.setKtyWethPairAddr(ktyWethPair.address);
    let daiPairAddress = await factory.getPair(weth.address, dai.address);
    let daiWethPair = await DaiWethPair.at(daiPairAddress);

    console.log("\n====== Total KTY supply ======") 
    let totalKtySupply = await kittieFightToken.totalSupply();
    console.log(weiToEther(totalKtySupply))
    console.log("==============================")

    console.log("\n====== Current KTY price ======") 
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
    console.log("==============================")

    console.log("\n====== Weekly DAO Payouts (in ether) ======") 
    let weekly_dao_payouts_0 = await withdrawPool.getInitialETH(0)
    console.log("pool 0:", weiToEther(weekly_dao_payouts_0))
    let weekly_dao_payouts_1 = await withdrawPool.getInitialETH(1)
    console.log("pool 1:", weiToEther(weekly_dao_payouts_1))
    console.log("==============================")

    console.log("\n====== Total DAO Payouts (in ether) ======") 
    let total_dao_payouts = await withdrawPool.getEthPaidOut()
    console.log(weiToEther(total_dao_payouts))
    console.log("==============================")

    console.log("\n====== Last Weekly Lender Payouts (in ether) ======") 
    let current_epoch = await earningsTracker.getCurrentEpoch()
    console.log("current_epoch", current_epoch.toString())
    let last_weekly_lender_payouts = await earningsTracker.getLastWeeklyLenderPayOut()
    console.log(weiToEther(last_weekly_lender_payouts))
    console.log("==============================")

    console.log("\n====== Total Lender Payouts (in ether) ======") 
    let total_lender_payouts = await earningsTracker.viewTotalInterests()
    console.log(weiToEther(total_lender_payouts))
    console.log("==============================")

    console.log("\n====== Total Games ======") 
    let total_games = await gmGetterDB.getTotalGames()
    console.log(total_games.toString())
    console.log("==============================")

    console.log("\n====== KTY Locked in Treasury ======") 
    let kty_in_treasury = await kittieFightToken.balanceOf(escrow.address)
    console.log(weiToEther(kty_in_treasury))
    console.log("==============================")

    console.log("\n====== Total KTY Burned ======") 
    let total_kty_burned = await kittieHellDB.getTotalKTYsLockedInKittieHell()
    console.log(weiToEther(total_kty_burned))
    console.log("==============================")

    console.log("\n====== Initial KTY Committed to Game ======") 
    let initial_kty_game = await gmGetterDB.getInitialHoneypot(1)
    console.log(weiToEther(initial_kty_game[1]))
    console.log("==============================")

    console.log("\n====== Initial KTY Committed to Game (in Ether value)======") 
    let initial_kty_game_eth = await gmGetterDB.getInitialHoneypotKTYInEther(1)
    console.log(weiToEther(initial_kty_game_eth))
    console.log("==============================")

    callback();
  } catch (e) {
    callback(e);
  }
};
