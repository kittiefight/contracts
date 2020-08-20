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
const KtyUniswapOracle = artifacts.require("KtyUniswapOracle");

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
  ktyUniswapOracle;

contract("YieldFarming", accounts => {
  it("instantiate contracts", async () => {
    // YieldFarming
    yieldFarming = await YieldFarming.deployed();
    // TOKENS
    superDaoToken = await SuperDaoToken.deployed();
    kittieFightToken = await KittieFightToken.deployed();
    ktyUniswapOracle = await KtyUniswapOracle.deployed();
    weth = await WETH.deployed();
    factory = await Factory.deployed();
  });

  it("set up uniswap environment", async () => {
    const pairAddress = await factory.getPair(
      weth.address,
      kittieFightToken.address
    );
    console.log("pair address", pairAddress);
    ktyWethPair = await KtyWethPair.at(pairAddress);
    console.log("ktyWethPair:", ktyWethPair.address);

    let ktyReserve = await ktyUniswapOracle.getReserveKTY();
    let ethReserve = await ktyUniswapOracle.getReserveETH();
    console.log("reserveKTY:", weiToEther(ktyReserve));
    console.log("reserveETH:", weiToEther(ethReserve));

    let ether_kty_price = await ktyUniswapOracle.ETH_KTY_price();
    let kty_ether_price = await ktyUniswapOracle.KTY_ETH_price();
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

    // daiWethPair info
    let daiReserve = await ktyUniswapOracle.getReserveDAI();
    let ethReserveFromDai = await ktyUniswapOracle.getReserveETHfromDAI();
    console.log("reserveDAI:", weiToEther(daiReserve));
    console.log("reserveETH:", weiToEther(ethReserveFromDai));

    let ether_dai_price = await ktyUniswapOracle.ETH_DAI_price();
    let dai_ether_price = await ktyUniswapOracle.DAI_ETH_price();
    console.log(
      "Ether to DAI price:",
      "1 ether to",
      weiToEther(ether_dai_price),
      "DAI"
    );
    console.log(
      "DAI to Ether ratio:",
      "1 DAI to",
      weiToEther(dai_ether_price),
      "ether"
    );

    let kty_dai_price = await ktyUniswapOracle.KTY_DAI_price();
    let dai_kty_price = await ktyUniswapOracle.DAI_KTY_price();
    console.log(
      "KTY to DAI price:",
      "1 KTY to",
      weiToEther(kty_dai_price),
      "DAI"
    );
    console.log(
      "DAI to KTY price:",
      "1 DAI to",
      weiToEther(dai_kty_price),
      "KTY"
    );

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
