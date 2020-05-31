const KittieFightToken = artifacts.require("KittieFightToken");
const Factory = artifacts.require("UniswapV2Factory");
const WETH = artifacts.require("WETH9");
const KtyWethPair = artifacts.require("IUniswapV2Pair");
const KtyWethOracle = artifacts.require("KtyWethOracle");
const KtyUniswap = artifacts.require("KtyUniswap");
const Router = artifacts.require("UniswapV2Router01");

const BigNumber = web3.utils.BN;

const ethAmount = new BigNumber(
  web3.utils.toWei("10", "ether") //10 ethers
);

const ktyAmount = new BigNumber(
  web3.utils.toWei("5000", "ether") //10 ethers * 500 = 5000 kty
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
    let kittieFightToken = await KittieFightToken.deployed();
    console.log("KTY address:", kittieFightToken.address);
    let weth = await WETH.deployed();
    console.log("Wrapped ether address:", weth.address);
    let factory = await Factory.deployed();
    const pairAddress = await factory.getPair(
      weth.address,
      kittieFightToken.address
    );
    console.log("pair address", pairAddress);
    const ktyWethPair = await KtyWethPair.at(pairAddress);
    console.log("ktyWethPair:", ktyWethPair.address);
    let ktyWethOracle = await KtyWethOracle.deployed();
    let ktyUniswap = await KtyUniswap.deployed();
    let router = await Router.deployed();

    accounts = await web3.eth.getAccounts();

    let wrapped_ether_name = await weth.name();
    let wrapped_ether_symbol = await weth.symbol();
    console.log("weth name:", wrapped_ether_name);
    console.log("weth symbol:", wrapped_ether_symbol);

    let router_factory = await router.factory();
    console.log("router_factory:", router_factory);
    let router_WETH = await router.WETH();
    console.log("router WETH:", router_WETH);

    // token0 will be KTY in the pair contract on mainnet, verifed as below
    const wethMainnet = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    const ktyMainnet = "0x7e9f9f3b323582584526d9f83276338c89f8fbe7"
    let tokenOrder = await ktyWethOracle.sortTokens(wethMainnet, ktyMainnet)
    console.log("token order in pair contract on mainnet:", tokenOrder)

    let token0 = await ktyWethPair.token0();
    let token1 = await ktyWethPair.token1();
    console.log("token0:", token0);
    console.log("token1:", token1);

    let pair = await ktyWethOracle.ktyWethPair();
    console.log("pair:", pair);
    let token0_oracle = await ktyWethOracle.token0();
    let token1_oracle = await ktyWethOracle.token1();
    console.log("token0_oracle:", token0_oracle);
    console.log("token1_oracle:", token1_oracle);

    if (kittieFightToken.address == token0) {
      await kittieFightToken.transfer(ktyWethPair.address, ktyAmount);
      await weth.deposit({value: ethAmount});
      await weth.transfer(ktyWethPair.address, ethAmount);
      await ktyWethPair.mint(accounts[0]);

      await timeout(3);

      let res = await ktyWethPair.getReserves();
      console.log("reserveKTY:", weiToEther(res.reserve0));
      console.log("reserveETH:", weiToEther(res.reserve1));
      console.log("blocktimestampLast:", res.blockTimestampLast.toString());

      let ether_kty_ratio = await ktyUniswap.ETH_KTY_ratio()
      let kty_ether_ratio = await ktyUniswap.KTY_ETH_ratio()
      console.log("Ether to KTY ratio:", "1 ether to", weiToEther(ether_kty_ratio), "KTY")
      console.log("KTY to Ether ratio:", "1 KTY to", weiToEther(kty_ether_ratio), "ether")

      let etherNeeded = await ktyUniswap.etherFor(ktyAmount)
      console.log("Ethers needed to swap 5000 KTY:", weiToEther(etherNeeded))

      // swap ethers for KTY
      // const ethValue = new BigNumber(
      //   web3.utils.toWei("0.2", "ether") //0.2 ethers
      // );
      // await ktyUniswap._swapEthForKty(accounts[1], { value: ethValue })

    } else {
      console.log("KTY is not token0");
    }
    callback();
  } catch (e) {
    callback(e);
  }
};
