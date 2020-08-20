const BigNumber = web3.utils.BN;
require("chai")
  .use(require("chai-shallow-deep-equal"))
  .use(require("chai-bignumber")(BigNumber))
  .use(require("chai-as-promised"))
  .should();

const evm = require("./utils/evm.js");

//ARTIFACTS
const YieldFarming = artifacts.require("YieldFarming");
const SuperDaoToken = artifacts.require("MockERC20Token");
const KittieFightToken = artifacts.require("KittieFightToken");
const Factory = artifacts.require("UniswapV2Factory");
const WETH = artifacts.require("WETH9");
const KtyWethPair = artifacts.require("IUniswapV2Pair");
const KtyWethOracle = artifacts.require("KtyWethOracle");

const editJsonFile = require("edit-json-file");
let file;

const ktyAmount = new BigNumber(
  web3.utils.toWei("50000", "ether") //100 ethers * 500 = 50,000 kty
);

function timeout(s) {
  // console.log(`~~~ Timeout for ${s} seconds`);
  return new Promise(resolve => setTimeout(resolve, s * 1000));
}

function formatDate(timestamp) {
  let date = new Date(null);
  date.setSeconds(timestamp);
  return date.toTimeString().replace(/.*(\d{2}:\d{2}:\d{2}).*/, "$1");
}

function randomValue(num) {
  return Math.floor(Math.random() * num) + 1; // (1-num) value
}

function weiToEther(w) {
  // let eth = web3.utils.fromWei(w.toString(), "ether");
  // return Math.round(parseFloat(eth));
  return web3.utils.fromWei(w.toString(), "ether");
}

//Contract instances
let yieldFarming,
  superDaoToken,
  kittieFightToken,
  factory,
  weth,
  ktyWethPair,
  ktyWethOracle;

contract("YieldFarming", accounts => {
  it("instantiate contracts", async () => {
    // YieldFarming
    yieldFarming = await YieldFarming.deployed();
    // TOKENS
    superDaoToken = await SuperDaoToken.deployed();
    kittieFightToken = await KittieFightToken.deployed();
  });

  it("set up uniswap environment", async () => {
    weth = await WETH.deployed();
    console.log("Wrapped ether address:", weth.address);

    factory = await Factory.deployed();
    console.log("factory address:", factory.address);
    ktyWethOracle = await KtyWethOracle.deployed();
    const pairAddress = await factory.getPair(
      weth.address,
      kittieFightToken.address
    );
    console.log("pair address", pairAddress);
    ktyWethPair = await KtyWethPair.at(pairAddress);
    console.log("ktyWethPair:", ktyWethPair.address);

    // let ktyReserve = await ktyUniswap.getReserveKTY();
    // let ethReserve = await ktyUniswap.getReserveETH();
    // console.log("reserveKTY:", weiToEther(ktyReserve));
    // console.log("reserveETH:", weiToEther(ethReserve));

    // let ether_kty_ratio = await ktyUniswap.ETH_KTY_ratio();
    // let kty_ether_ratio = await ktyUniswap.KTY_ETH_ratio();
    // console.log(
    //   "Ether to KTY ratio:",
    //   "1 ether to",
    //   weiToEther(ether_kty_ratio),
    //   "KTY"
    // );
    // console.log(
    //   "KTY to Ether ratio:",
    //   "1 KTY to",
    //   weiToEther(kty_ether_ratio),
    //   "ether"
    // );

    // let ether_kty_price = await ktyUniswap.ETH_KTY_price();
    // let kty_ether_price = await ktyUniswap.KTY_ETH_price();
    // console.log(
    //   "Ether to KTY price:",
    //   "1 ether to",
    //   weiToEther(ether_kty_price),
    //   "KTY"
    // );
    // console.log(
    //   "KTY to Ether price:",
    //   "1 KTY to",
    //   weiToEther(kty_ether_price),
    //   "ether"
    // );

    // let etherNeeded = await ktyUniswap.etherFor(ktyAmount);
    // console.log(
    //   "Ethers needed to swap ",
    //   weiToEther(ktyAmount),
    //   "KTY:",
    //   weiToEther(etherNeeded)
    // );

    // check balance of pair contract
    let ktyBalance = await kittieFightToken.balanceOf(ktyWethPair.address);
    console.log(
      "KTY balance of KTY-WETH pair contract:",
      ktyBalance.toString()
    );
    let wethBalancce = await weth.balanceOf(ktyWethPair.address);
    console.log(
      "WETH balance of KTY-WETH pair contract:",
      wethBalancce.toString()
    );
  });

  it("sets Rewards Unlock Rate for KittieFightToken and SuperDaoToken", async () => {
    let unlockRates = await yieldFarming.getRewardUnlockRate();
    let KTYunlockRates = unlockRates[0]
    let SDAOunlockRates = unlockRates[1]
    console.log(`\n======== KTY Rewards Unlock Rate ======== `);
    for (let i = 0; i < 6; i++) {
        console.log("KTY rewards unlock rate in", "Month", i, ":", KTYunlockRates[i].toString())
    }

    console.log(`\n======== SDAO Rewards Unlock Rate ======== `);
    for (let j = 0; j < 6; j++) {
        console.log("SDAO rewards unlock rate in", "Month", j, ":", SDAOunlockRates[j].toString())
    }

    console.log("===============================\n");

    let unlockRatesByMonth0 = await yieldFarming.getRewardUnlockRateByMonth(0);
    let unlockRatesByMonth1 = await yieldFarming.getRewardUnlockRateByMonth(1);
    console.log(unlockRatesByMonth0[0].toString());
    console.log(unlockRatesByMonth0[1].toString());
    console.log(unlockRatesByMonth1[0].toString());
    console.log(unlockRatesByMonth1[1].toString());
  });

  it("sets total KittieFightToken and SuperDaoToken rewards for the entire program duration", async () => {
      let totalRewards = await yieldFarming.getTotalRewards()
      console.log("Total KittieFightToken rewards:", weiToEther(totalRewards[0]))
      console.log("Total SuperDaoToken rewards:", weiToEther(totalRewards[1]))
  })
});
