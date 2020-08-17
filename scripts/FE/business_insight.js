const KFProxy = artifacts.require("KFProxy");
const Escrow = artifacts.require("Escrow");
const KittieFightToken = artifacts.require("KittieFightToken");
const WithdrawPoolGetters = artifacts.require("WithdrawPoolGetters");
const KittieHell = artifacts.require('KittieHell');
const BusinessInsight = artifacts.require('BusinessInsight');
const RedeemKittie = artifacts.require('RedeemKittie');
const GenericDB = artifacts.require('GenericDB');

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
    let businessInsight = await BusinessInsight.deployed();
    let escrow = await Escrow.deployed();
    let kittieFightToken = await KittieFightToken.deployed();
    let withdrawPoolGetters = await WithdrawPoolGetters.deployed();
    let kittieHell = await KittieHell.deployed();
    let redeemKittie = await RedeemKittie.deployed();
    let genericDB = await GenericDB.deployed();
  
    console.log("\n====== Total KTY supply ======") 
    let totalKtySupply = await kittieFightToken.totalSupply();
    console.log(weiToEther(totalKtySupply))
    console.log("==============================")

    console.log("\n====== Current KTY price ======") 
    let ether_kty_price = await businessInsight.ETH_KTY_price();
    let kty_ether_price = await businessInsight.KTY_ETH_price();
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
    let weekly_dao_payouts_0 = await businessInsight.getInitialETH(0)
    console.log("pool 0:", weiToEther(weekly_dao_payouts_0))
    let weekly_dao_payouts_1 = await businessInsight.getInitialETH(1)
    console.log("pool 1:", weiToEther(weekly_dao_payouts_1))
    console.log("==============================")

    console.log("\n====== Total DAO Payouts (in ether) ======") 
    let total_dao_payouts = await businessInsight.viewTotalEthAllocatedToPools()
    console.log(weiToEther(total_dao_payouts))
    console.log("==============================")

    console.log("\n====== Total DAO Actually Claimed (in ether) ======") 
    let total_dao_claimed = await businessInsight.getEthPaidOut()
    console.log(weiToEther(total_dao_claimed))
    console.log("==============================")

    console.log("\n====== Last Weekly Lender Payouts (in ether) ======") 
    let current_epoch = await businessInsight.getCurrentEpoch()
    console.log("current_epoch", current_epoch.toString())
    let last_weekly_lender_payouts = await businessInsight.getLastWeeklyLenderPayOut()
    console.log(weiToEther(last_weekly_lender_payouts))
    console.log("==============================")

    console.log("\n====== Total Lender Payouts (in ether) ======") 
    let total_lender_payouts = await businessInsight.viewTotalInterests()
    console.log(weiToEther(total_lender_payouts))
    console.log("==============================")

    console.log("\n====== Total Games ======") 
    let total_games = await businessInsight.getTotalGames()
    console.log(total_games.toString())
    console.log("==============================")

    console.log("\n====== KTY Locked in Treasury ======") 
    let kty_in_treasury = await kittieFightToken.balanceOf(escrow.address)
    console.log(weiToEther(kty_in_treasury))
    console.log("==============================")

    console.log("\n====== Total KTY Burned ======") 
    let total_kty_burned = await kittieFightToken.balanceOf(redeemKittie.address)
    console.log(weiToEther(total_kty_burned))
    console.log("==============================")

    console.log("\n====== Initial KTY Committed to Game ======") 
    let initial_kty_game = await businessInsight.getInitialHoneypot(1)
    console.log(weiToEther(initial_kty_game[1]))
    console.log("==============================")

    console.log("\n====== Initial KTY Committed to Game (in current Ether value)======") 
    let initial_kty_game_eth = await businessInsight.getInitialHoneypotKTYInEther(1)
    console.log(weiToEther(initial_kty_game_eth))
    console.log("==============================")

    console.log("\n====== Total cumulative 'ether' spent by all users in a game ======") 
    let total_spent_in_game = await businessInsight.getTotalSpentInGame(1)
    console.log(weiToEther(total_spent_in_game))
    console.log("==============================")

    console.log("\n====== Total KTY swapped on uniswap during game lifetime ======") 
    let total_swapped_kty_in_game = await businessInsight.getTotalSwappedKtyInGame(1)
    console.log(weiToEther(total_swapped_kty_in_game))
    console.log("==============================")

    console.log("\n====== Pooled Ether ======") 
    let pooled_ether = await businessInsight.getPooledEther(0)
    console.log(weiToEther(pooled_ether))
    console.log("==============================")

    console.log("\n====== Interest of pooled ether ======") 
    let interest_pooled_ether = await businessInsight.viewWeeklyInterests(0)
    console.log(weiToEther(interest_pooled_ether))
    console.log("==============================")

    // ethie token
    console.log("\n====== Get Info for an Ethie (ethieTokenID: 1) ======") 
    let res_ethie = await businessInsight.getEthieInfo(1)
    console.log("etherValue:", weiToEther(res_ethie.etherValue))
    console.log("startingEpoch:", res_ethie.startingEpoch.toString())
    console.log("generation:", res_ethie.generation.toString())
    console.log("lockedAt:", res_ethie.lockedAt.toString())
    console.log("lockTime:", res_ethie.lockTime.toString())
    console.log("is burnt?", res_ethie.isBurnt)
    console.log("==============================")
    
    console.log("\n====== Get Info for an Ethie (ethieTokenID: 3) ======") 
    res_ethie = await businessInsight.getEthieInfo(3)
    console.log("etherValue:", weiToEther(res_ethie.etherValue))
    console.log("startingEpoch:", res_ethie.startingEpoch.toString())
    console.log("generation:", res_ethie.generation.toString())
    console.log("lockedAt:", res_ethie.lockedAt.toString())
    console.log("lockTime:", res_ethie.lockTime.toString())
    console.log("is burnt?", res_ethie.isBurnt)
    console.log("==============================")

    // alternative method for getting any info from genericDB directly
    // let eth_value_generic = await genericDB.getUintStorage("EarningsTracker", web3.utils.soliditySha3(3, "ethValue"))
    // console.log(weiToEther(eth_value_generic))
    // let is_burnt_generic = await genericDB.getBoolStorage("EarningsTracker", web3.utils.soliditySha3(3, "tokenBurnt"))
    // console.log(is_burnt_generic)

    console.log("\n====== Get Static Values In One Getter ======") 
    let res_static = await businessInsight.getGameStaticInfo(1)
    // console.log(res_static)
    let shares = res_static.shares
    console.log("bettingFeeEtherSwap:", weiToEther(res_static.bettingFeeEtherSwap))
    console.log("bettingFeeKTY:", weiToEther(res_static.bettingFeeKTY))
    console.log("ticketFeeEtherSwap:", weiToEther(res_static.ticketFeeEtherSwap))
    console.log("ticketFeeKTY:", weiToEther(res_static.ticketFeeKTY))
    console.log("redemptionFeeEtherSwap:", weiToEther(res_static.redemptionFeeEtherSwap))
    console.log("redemptionFeeKTY:", weiToEther(res_static.redemptionFeeKTY))
    console.log("kittieHellExpirationTime:", res_static.kittieHellExpirationTime.toString())
    console.log("honeypotExpirationTime:", res_static.honeypotExpirationTime.toString())
    console.log("minimumContributors:", res_static.minimumContributors.toString())
    console.log("shareWinner:", shares[0].toString())
    console.log("shareTopSupporter:", shares[1].toString())
    console.log("shareSecondSupporter:", shares[2].toString())
    console.log("shareRemainingSupporter:", shares[3].toString())
    console.log("shareEndowmentFund:", shares[4].toString())
    console.log("==============================")

    console.log("\n====== Get Dynaicm Values In One Getter ======") 
    let res_dynamic = await businessInsight.getGameDynamicInfo(1)
    // console.log(res_dynamic)
    let gameTimes = res_dynamic.gameTimes
    let honeypotInfo = res_dynamic.honeypotInfo
    let ethByCorner = res_dynamic.ethByCorner
    let finalHoneypot = res_dynamic.finalHoneypot
    let winners = res_dynamic.winners

    console.log("startTime:", gameTimes[0].toString())
    console.log("preStartTime:", gameTimes[1].toString())
    console.log("endTime:", gameTimes[2].toString())
    console.log("honeypotID:", honeypotInfo[0].toString())
    console.log("status:", honeypotInfo[1].toString())
    console.log("initialEth:", weiToEther(honeypotInfo[2]))
    console.log("ethTotal:", weiToEther(honeypotInfo[3]))
    console.log("ktyTotal:", weiToEther(honeypotInfo[4]))
    console.log("expTime:", honeypotInfo[5].toString())
    console.log("ethByCorner[0]:", weiToEther(ethByCorner[0]))
    console.log("ethByCorner[1]:", weiToEther(ethByCorner[1]))
    console.log("finalEthTotal:", weiToEther(finalHoneypot[0]))
    console.log("finalKtyTotal:", weiToEther(finalHoneypot[1]))
    console.log("winner:", winners[0])
    console.log("topBettor:", winners[1])
    console.log("secondTopBettor:", winners[2])
    console.log("==============================")

    callback();
  } catch (e) {
    callback(e);
  }
};
