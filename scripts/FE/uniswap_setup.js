const KFProxy = artifacts.require("KFProxy");
const EndowmentFund = artifacts.require("EndowmentFund");
const Escrow = artifacts.require("Escrow");
const KittieFightToken = artifacts.require("KittieFightToken");
const Factory = artifacts.require("UniswapV2Factory");
const WETH = artifacts.require("WETH9");
const KtyWethPair = artifacts.require("IUniswapV2Pair");
const KtyWethOracle = artifacts.require("KtyWethOracle");
const KtyUniswap = artifacts.require("KtyUniswap");
const Router = artifacts.require("UniswapV2Router01");

const BigNumber = web3.utils.BN;

const ethAmount = new BigNumber(
  web3.utils.toWei("100", "ether") //5 ethers
);

const ktyAmount = new BigNumber(
  web3.utils.toWei("50000", "ether") //100 ethers * 500 = 50,000 kty
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
    let factory = await Factory.deployed();
    console.log("factory address:", factory.address);
    let ktyWethOracle = await KtyWethOracle.deployed();
    let ktyUniswap = await KtyUniswap.deployed();
    let router = await Router.deployed();

    let router_factory = await router.factory();
    console.log("router_factory:", router_factory);
    let router_WETH = await router.WETH();
    console.log("router WETH:", router_WETH);

    // token0 will be KTY in the pair contract on mainnet, verifed as below
    const wethMainnet = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
    const ktyMainnet = "0x7e9f9f3b323582584526d9f83276338c89f8fbe7";
    let tokenOrder = await ktyWethOracle.sortTokens(wethMainnet, ktyMainnet);
    console.log("token order in pair contract on mainnet:", tokenOrder);

    const pairAddress = await factory.getPair(
      weth.address,
      kittieFightToken.address
    );
    console.log("pair address", pairAddress);
    const ktyWethPair = await KtyWethPair.at(pairAddress);
    console.log("ktyWethPair:", ktyWethPair.address);
    await router.setKtyWethPairAddr(ktyWethPair.address);

    await kittieFightToken.transfer(ktyWethPair.address, ktyAmount);
    await weth.deposit({value: ethAmount});
    await weth.transfer(ktyWethPair.address, ethAmount);
    await ktyWethPair.mint(escrow.address);

    await kittieFightToken.approve(router.address, approveAmount);
    await weth.approve(router.address, approveAmount);
    await ktyWethPair.approve(router.address, approveAmount);

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

    let etherNeeded = await ktyUniswap.etherFor(ktyAmount);
    console.log(
      "Ethers needed to swap ",
      weiToEther(ktyAmount),
      "KTY:",
      weiToEther(etherNeeded)
    );

    callback();
  } catch (e) {
    callback(e);
  }
};
