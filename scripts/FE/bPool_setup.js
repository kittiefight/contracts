const KittieFightToken = artifacts.require("KittieFightToken");
const WETH = artifacts.require("WETH9");
const BFactory = artifacts.require("BFactory");
const BPool = artifacts.require("BPool");

const BigNumber = web3.utils.BN;

const ktyAmount = new BigNumber(
  web3.utils.toWei("500000", "ether") // 500,000 kty = 50,000 * $0.4 = $200,000
);

const wethAmount = new BigNumber(
  web3.utils.toWei("1000", "ether") // 1,000 weth = 1,000 * $200 = $200,000
);

const weight = new BigNumber(
  web3.utils.toWei("25", "ether") // 50% weight
);

const swapFee = new BigNumber(
  web3.utils.toWei("0.1", "ether") // 10%
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

    let kittieFightToken = await KittieFightToken.deployed();
    console.log("KTY address:", kittieFightToken.address);
    let bFactory = await BFactory.deployed();
    console.log("bFactory address:", bFactory.address);
    let weth = await WETH.deployed();
    console.log("WETH address:", weth.address);

    // create a new pool
    let bPool = await bFactory.newBPool();

    let poolAddress;

    let newPoolEvents = await bFactory.getPastEvents("LOG_NEW_POOL", {
      fromBlock: 0,
      toBlock: "latest"
    });

    newPoolEvents.map(async e => {
      console.log("\n==== POOL CREATED ===");
      console.log("Caller ", e.returnValues.caller);
      console.log("Pool Address ", e.returnValues.pool);
      console.log("========================\n");
      poolAddress = e.returnValues.pool;
    });

    let isBPool = await bFactory.isBPool(poolAddress);
    console.log("is pool?", isBPool);

    bPool = await BPool.at(poolAddress);

    // get controller
    let controller = await bPool.getController();
    console.log("controller:", controller);

    // bind token to pool
    await kittieFightToken.approve(poolAddress, ktyAmount);
    await weth.deposit({value: wethAmount});
    await weth.approve(poolAddress, wethAmount);

    await bPool.bind(kittieFightToken.address, ktyAmount, weight);
    await bPool.bind(weth.address, wethAmount, weight);

    let currentTokens = await bPool.getCurrentTokens();

    console.log("current tokens:", currentTokens);

    let numTokens = await bPool.getNumTokens();
    console.log("Number of tokens", numTokens.toNumber());

    // set swap fee
    await bPool.setSwapFee(swapFee);

    let swapFee1 = await bPool.getSwapFee();
    console.log("Swap Fee:", swapFee1.toString());

    await bPool.setPublicSwap(true);

    const isPublicSwap = await bPool.isPublicSwap();
    console.log("Is public swap?", isPublicSwap);

    const weightKTY = await bPool.getDenormalizedWeight(
      kittieFightToken.address
    );
    console.log("KTY denomalized weight in bpool:", weightKTY.toString());

    const weightWETH = await bPool.getDenormalizedWeight(weth.address);
    console.log("WETH denomalized weight in bpool:", weightWETH.toString());

    const totalWeight = await bPool.getTotalDenormalizedWeight();
    console.log("Total denormalized weigth:", totalWeight.toString());

    const normalizedWeightKTY = await bPool.getNormalizedWeight(
      kittieFightToken.address
    );
    console.log(
      "KTY normalized weight in bpool:",
      normalizedWeightKTY.toString()
    );

    const normalizedWeightWETH = await bPool.getNormalizedWeight(weth.address);
    console.log(
      "WETH normalized weight in bpool:",
      normalizedWeightWETH.toString()
    );

    const balanceKTY = await bPool.getBalance(kittieFightToken.address);
    console.log("KTY balance in bpool:", balanceKTY.toString());

    const balanceWETH = await bPool.getBalance(weth.address);
    console.log("WETH balance in bpool:", balanceWETH.toString());

    const spotPriceKTY = await bPool.getSpotPrice(
      kittieFightToken.address,
      weth.address
    );
    console.log("KTY Spot Price:", spotPriceKTY.toString());

    const spotPriceWETH = await bPool.getSpotPrice(
      weth.address,
      kittieFightToken.address
    );
    console.log("WETH Spot Price:", spotPriceWETH.toString());

    const spotPriceKTYsansFee = await bPool.getSpotPriceSansFee(
      kittieFightToken.address,
      weth.address
    );
    console.log("KTY Spot Price Sans Fee:", spotPriceKTYsansFee.toString());

    const spotPriceWETHsansFee = await bPool.getSpotPriceSansFee(
      weth.address,
      kittieFightToken.address
    );
    console.log("WETH Spot Price Sans Fee:", spotPriceWETHsansFee.toString());

    // swap exact WETH amount with KTY
    const ethAmountMax = new BigNumber(
      web3.utils.toWei("2", "ether") //1 ether = $200 = $200/$0.4 = 500 KTY
    );

    const ktyAmountOut = new BigNumber(
      web3.utils.toWei("500", "ether") // 500 kty
    );

    const maxPrice = new BigNumber(
      web3.utils.toWei("1", "ether") 
    );

    // const spotPriceBefore = await bPool.calcSpotPrice(
    //   balanceWETH,
    //   weightWETH,
    //   balanceKTY,
    //   weightKTY,
    //   swapFee1
    // )

    // console.log("spotPriceBefore:", spotPriceBefore.toString())

    // const tokenAmountIn = await bPool.calcInGivenOut(
    //   balanceWETH,
    //   weightWETH,
    //   balanceKTY,
    //   weightKTY,
    //   ktyAmountOut,
    //   swapFee1
    // );

    // console.log("tokenAmountIn:", tokenAmountIn.toString())

    await weth.deposit({value: wethAmount, from: accounts[1]});
    await weth.approve(poolAddress, wethAmount, { from: accounts[1] });

    const txr = await bPool.swapExactAmountOut(
      weth.address,
      ethAmountMax,
      kittieFightToken.address,
      ktyAmountOut,
      maxPrice,
      {
        from: accounts[1]
      },
    );

    const log = txr.logs[0];
    console.log(log.event);

    let newSwapEvents = await bPool.getPastEvents("LOG_SWAP", {
      fromBlock: 0,
      toBlock: "latest"
    });

    newSwapEvents.map(async e => {
      console.log("\n==== WETH swapped for KTY ===");
      console.log("Caller ", e.returnValues.caller);
      console.log("Token in", e.returnValues.tokenIn);
      console.log("Token out", e.returnValues.tokenOut);
      console.log("WETH amount in", e.returnValues.tokenAmountIn);
      console.log("KTY amount out", e.returnValues.tokenAmountOut);

      console.log("========================\n");
      poolAddress = e.returnValues.pool;
    });

    callback();
  } catch (e) {
    callback(e);
  }
};
