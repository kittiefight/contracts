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

const BigNumber = web3.utils.BN;

const ethAmount = new BigNumber(
  web3.utils.toWei("100", "ether") //100 ethers
);

const ktyAmount = new BigNumber(
  web3.utils.toWei("50000", "ether") //100 ethers * 500 = 50,000 kty
);

const daiAmount = new BigNumber(
  web3.utils.toWei("24191.54", "ether") //100 ethers * 241.9154 dai/ether = 24191.54 kty
);

const swapAmount = new BigNumber(
  web3.utils.toWei("500", "ether") // to swap for 500 kty
);

const MaxUint256 = new BigNumber(
  web3.utils.toWei("1000000000000000000", "ether")
);

const approveAmount = new BigNumber(
  web3.utils.toWei("1000000000000000000", "ether")
);

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
    console.log("accounts[0]:", accounts[0]);

    let proxy = await KFProxy.deployed();
    let endowmentFund = await EndowmentFund.deployed();
    let escrow = await Escrow.deployed();
    let kittieFightToken = await KittieFightToken.deployed();
    console.log("KTY address:", kittieFightToken.address);
    let weth = await WETH.deployed();
    console.log("Wrapped ether address:", weth.address);
    let dai = await Dai.deployed();
    let factory = await Factory.deployed();
    console.log("factory address:", factory.address);
    let ktyWethOracle = await KtyWethOracle.deployed();
    let daiWethOracle = await DaiWethOracle.deployed()
    let ktyUniswap = await KtyUniswap.deployed();
    let router = await Router.deployed();

    let router_factory = await router.factory();
    console.log("router_factory:", router_factory);
    let router_WETH = await router.WETH();
    console.log("router WETH:", router_WETH);

    const pairAddress = await factory.getPair(
      weth.address,
      kittieFightToken.address
    );
    console.log("pair address", pairAddress);
    const ktyWethPair = await KtyWethPair.at(pairAddress);
    console.log("ktyWethPair:", ktyWethPair.address);
    await router.setKtyWethPairAddr(ktyWethPair.address);

    const daiPairAddress = await factory.getPair(
      weth.address,
      dai.address
    );
    console.log("dai-weth pair address", daiPairAddress);
    const daiWethPair = await DaiWethPair.at(daiPairAddress);
    console.log("daiWethPair:", daiWethPair.address);

    await dai.mint(accounts[0], daiAmount)

    await dai.transfer(daiWethPair.address, daiAmount);
    await weth.deposit({value: ethAmount});
    await weth.transfer(daiWethPair.address, ethAmount);
    await daiWethPair.mint(accounts[10]);

    await kittieFightToken.transfer(ktyWethPair.address, ktyAmount);
    await weth.deposit({value: ethAmount});
    await weth.transfer(ktyWethPair.address, ethAmount);
    await ktyWethPair.mint(escrow.address);

    let ktyReserve = await ktyUniswap.getReserveKTY();
    let ethReserve = await ktyUniswap.getReserveETH();
    console.log("reserveKTY:", weiToEther(ktyReserve));
    console.log("reserveETH:", weiToEther(ethReserve));

    let ether_kty_ratio = await ktyUniswap.ETH_KTY_ratio();
    let kty_ether_ratio = await ktyUniswap.KTY_ETH_ratio();
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

    let etherNeeded = await ktyUniswap.etherFor(ktyAmount);
    console.log(
      "Ethers needed to swap ",
      weiToEther(ktyAmount),
      "KTY:",
      weiToEther(etherNeeded)
    );

    // daiWethPair info
    let daiReserve = await ktyUniswap.getReserveDAI();
    let ethReserveFromDai = await ktyUniswap.getReserveETHfromDAI();
    console.log("reserveDAI:", weiToEther(daiReserve));
    console.log("reserveETH:", weiToEther(ethReserveFromDai));

    let ether_dai_ratio = await ktyUniswap.ETH_DAI_ratio();
    let dai_ether_ratio = await ktyUniswap.DAI_ETH_ratio();
    console.log(
      "Ether to DAI ratio:",
      "1 ether to",
      weiToEther(ether_dai_ratio),
      "DAI"
    );
    console.log(
      "DAI to Ether ratio:",
      "1 DAI to",
      weiToEther(dai_ether_ratio),
      "ether"
    );

    let kty_dai_ratio = await ktyUniswap.KTY_DAI_ratio();
    let dai_kty_ratio = await ktyUniswap.DAI_KTY_ratio();
    console.log(
      "KTY to DAI ratio:",
      "1 KTY to",
      weiToEther(kty_dai_ratio),
      "DAI"
    );
    console.log(
      "DAI to KTY ratio:",
      "1 DAI to",
      weiToEther(dai_kty_ratio),
      "KTY"
    );

    

    callback();
  } catch (e) {
    callback(e);
  }
};
