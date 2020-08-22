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
const Dai = artifacts.require("Dai");
const DaiWethPair = artifacts.require("IDaiWethPair");

const editJsonFile = require("edit-json-file");
const {assert} = require("chai");
let file;

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
  ktyUniswapOracle,
  dai,
  daiWethPair;

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
    dai = await Dai.deployed();

    const ktyPairAddress = await factory.getPair(
      weth.address,
      kittieFightToken.address
    );
    ktyWethPair = await KtyWethPair.at(ktyPairAddress);

    const daiPairAddress = await factory.getPair(weth.address, dai.address);
    const daiWethPair = await DaiWethPair.at(daiPairAddress);
    console.log("daiWethPair:", daiWethPair.address);
  });

  it("sets Rewards Unlock Rate for KittieFightToken and SuperDaoToken", async () => {
    let unlockRates = await yieldFarming.getRewardUnlockRate();
    let KTYunlockRates = unlockRates[0];
    let SDAOunlockRates = unlockRates[1];
    console.log(`\n======== KTY Rewards Unlock Rate ======== `);
    for (let i = 0; i < 6; i++) {
      console.log(
        "KTY rewards unlock rate in",
        "Month",
        i,
        ":",
        KTYunlockRates[i].toString()
      );
    }

    console.log(`\n======== SDAO Rewards Unlock Rate ======== `);
    for (let j = 0; j < 6; j++) {
      console.log(
        "SDAO rewards unlock rate in",
        "Month",
        j,
        ":",
        SDAOunlockRates[j].toString()
      );
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
    let totalRewards = await yieldFarming.getTotalRewards();
    console.log("Total KittieFightToken rewards:", weiToEther(totalRewards[0]));
    console.log("Total SuperDaoToken rewards:", weiToEther(totalRewards[1]));
  });

  it("users provides liquidity to Uniswap KTY-Weth pool", async () => {
    const weth_amount = new BigNumber(
      web3.utils.toWei("100", "ether") //100 ethers
    );

    const kty_amount = new BigNumber(
      web3.utils.toWei("50000", "ether") //100 ethers * 500 = 50,000 kty
    );

    let balanceLP;

    for (let i = 1; i < 19; i++) {
      await kittieFightToken.transfer(accounts[i], kty_amount);
      await kittieFightToken.transfer(ktyWethPair.address, kty_amount, {
        from: accounts[i]
      });
      await weth.deposit({from: accounts[i], value: weth_amount});
      await weth.transfer(ktyWethPair.address, weth_amount, {
        from: accounts[i]
      });
      await ktyWethPair.mint(accounts[i], {from: accounts[i]});

      balanceLP = await ktyWethPair.balanceOf(accounts[i]);

      console.log(
        "User",
        i,
        ": Balance of Uniswap Liquidity tokens:",
        weiToEther(balanceLP)
      );
    }

    let totalSupplyLP = await ktyWethPair.totalSupply();
    console.log(
      "Total Supply of Uniswap Liquidity tokens:",
      weiToEther(totalSupplyLP)
    );

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

  // ==============================  FIRST MONTH: MONTH 0  ==============================

  it("users deposit Uinswap Liquidity tokens in Yield Farming contract", async () => {
    // temporarily set month as 60 sec and day as 2 sec for testing purpose
    let MONTH = 30 * 2;
    let DAY = 2;
    await yieldFarming.setMonthAndDay(MONTH, DAY);
    let seconds = new Date().getTime() / 1000;
    let startTime = Math.floor(seconds);
    await yieldFarming.setProgramDuration(6, startTime);

    console.log(
      "\n====================== FIRST MONTH: MONTH 0 ======================\n"
    );
    // make first deposit
    let deposit_LP_amount = new BigNumber(
      web3.utils.toWei("30", "ether") //30 Uniswap Liquidity tokens
    );
    let LP_locked;
    for (let i = 1; i < 19; i++) {
      await ktyWethPair.approve(yieldFarming.address, deposit_LP_amount, {
        from: accounts[i]
      }).should.be.fulfilled;
      await yieldFarming.deposit(deposit_LP_amount, {from: accounts[i]}).should
        .be.fulfilled;
      LP_locked = await yieldFarming.getLiquidityTokenLocked(accounts[i]);
      console.log(
        "Uniswap Liquidity tokens locked by user",
        i,
        ":",
        weiToEther(LP_locked)
      );
      assert.equal(weiToEther(LP_locked), 30);
    }

    let total_LP_locked = await yieldFarming.getTotalLiquidityTokenLocked();
    console.log(
      "Total Uniswap Liquidity tokens locked in Yield Farming:",
      weiToEther(total_LP_locked)
    );
    assert.equal(weiToEther(total_LP_locked), 540);

    let totalLiquidityTokenLockedInDAI = await yieldFarming.getTotalLiquidityTokenLockedInDAI();
    console.log(
      "Total Uniswap Liquidity tokens locked in Dai value:",
      weiToEther(totalLiquidityTokenLockedInDAI)
    );
  });

  it("show batches of deposit of a staker", async () => {
    // make 2nd deposit
    let deposit_LP_amount = new BigNumber(
      web3.utils.toWei("40", "ether") //40 Uniswap Liquidity tokens
    );

    for (let i = 1; i < 9; i++) {
      await ktyWethPair.approve(yieldFarming.address, deposit_LP_amount, {
        from: accounts[i]
      }).should.be.fulfilled;
      await yieldFarming.deposit(deposit_LP_amount, {from: accounts[i]}).should
        .be.fulfilled;
    }

    // make 3rd deposit
    deposit_LP_amount = new BigNumber(
      web3.utils.toWei("50", "ether") //50 Uniswap Liquidity tokens
    );

    for (let i = 1; i < 19; i++) {
      await ktyWethPair.approve(yieldFarming.address, deposit_LP_amount, {
        from: accounts[i]
      }).should.be.fulfilled;
      await yieldFarming.deposit(deposit_LP_amount, {from: accounts[i]}).should
        .be.fulfilled;
    }

    // get info on all batches of each staker
    console.log(`\n======== Batches Info ======== `);
    let allBatches;
    let lastBatchNumber;
    for (let i = 1; i < 19; i++) {
      console.log("User", i);
      allBatches = await yieldFarming.getAllBatches(accounts[i]);
      lastBatchNumber = await yieldFarming.getLastBatchNumber(accounts[i]);
      for (let j = 0; j < allBatches.length; j++) {
        console.log("Batch Number:", j);
        console.log("Liquidity Locked:", weiToEther(allBatches[j]));
      }
      console.log("Last number of batches:", lastBatchNumber.toString());
      console.log("Total number of batches:", allBatches.length);
      console.log("****************************\n");
    }
    console.log("===============================\n");
  });

  it("gets program duration", async () => {
    let programDuration = await yieldFarming.getProgramDuration();
    // console.log(programDuration)
    let entireProgramDuration = programDuration.entireProgramDuration;
    let monthDuration = programDuration.monthDuration;
    let startMonth = programDuration.startMonth;
    let endMonth = programDuration.endMonth;
    let activeMonth = programDuration.activeMonth;
    let elapsedMonths = programDuration.elapsedMonths;
    let allMonthsStartTime = programDuration.allMonthsStartTime;
    console.log(`\n======== Program Duration and Months ======== `);
    console.log("Entire program duration:", entireProgramDuration.toString());
    console.log("Month duration:", monthDuration.toString());
    console.log("Start Month:", startMonth.toString());
    console.log("End Month:", endMonth.toString());
    console.log("Active Month:", activeMonth.toString());
    console.log("Elapsed Months:", elapsedMonths.toString());
    for (let i = 0; i < 6; i++) {
      console.log("Month", i, "Start Time:", allMonthsStartTime[i].toString());
    }
    console.log("===============================================\n");
  });

  it("gets current month", async () => {
    let currentMonth = await yieldFarming.getCurrentMonth();
    console.log("Current Month:", currentMonth.toString());
  });

  it("calculates rewards by batch number", async () => {
    let rewards = await yieldFarming.calculateRewardsByBatchNumber(
      accounts[1],
      1
    );
    //console.log(rewards);
    let rewardKTY = rewards[0];
    let rewardSDAO = rewards[1];
    console.log(
      "KittieFightToken reward for user 1's batch 1:",
      weiToEther(rewardKTY)
    );
    console.log(
      "SuperDaoToken reward for user 1's batch 1:",
      weiToEther(rewardSDAO)
    );
  });

  it("unlocks KittieFightToken and SuperDaoToken rewards for the first month", async () => {
    let rewards_month_0 = await yieldFarming.getTotalRewardsByMonth(0);
    let KTYrewards_month_0 = rewards_month_0.rewardKTYbyMonth;
    let SDAOrewards_month_0 = rewards_month_0.rewardSDAObyMonth;

    console.log("KTY Rewards for Month 0:", weiToEther(KTYrewards_month_0));
    console.log("SDAO Rewards for Month 0:", weiToEther(SDAOrewards_month_0));

    kittieFightToken.transfer(yieldFarming.address, KTYrewards_month_0);
    superDaoToken.transfer(yieldFarming.address, SDAOrewards_month_0);
  });

  it("user withdraws Uniswap Liquidity tokens by Batch Number and get rewards in KittieFighToken and SuperDaoTokne", async () => {
    // Info before withdraw
    let user = 1;
    console.log("User", user);

    console.log(`\n======== User: Batches Info Before Withdraw ======== `);
    let allBatches;
    let lastBatchNumber;
    let isBatchValid;

    allBatches = await yieldFarming.getAllBatches(accounts[user]);
    lastBatchNumber = await yieldFarming.getLastBatchNumber(accounts[user]);
    for (let j = 0; j < allBatches.length; j++) {
      console.log("Batch Number:", j);
      console.log("Liquidity Locked:", weiToEther(allBatches[j]));
      isBatchValid = await yieldFarming.isBatchValid(accounts[user], j);
      console.log("Is Batch Valid?", isBatchValid);
    }
    console.log("Last number of batches:", lastBatchNumber.toString());
    console.log("Total number of batches:", allBatches.length);
    console.log("===============================\n");
    let LP_balance_user_1_before = await ktyWethPair.balanceOf(accounts[user]);
    let KTY_balance_user_1_before = await kittieFightToken.balanceOf(
      accounts[1]
    );
    let SDAO_balance_user_1_before = await superDaoToken.balanceOf(
      accounts[user]
    );

    // withdraw by Batch NUmber
    await yieldFarming.withdrawByBatchNumber(1, {from: accounts[user]}).should
      .be.fulfilled;

    // Info after withdraw
    console.log(`\n======== User 1:  Batches Info After Withdraw ======== `);
    allBatches;
    lastBatchNumber;
    isBatchValid;

    allBatches = await yieldFarming.getAllBatches(accounts[user]);
    lastBatchNumber = await yieldFarming.getLastBatchNumber(accounts[user]);
    for (let j = 0; j < allBatches.length; j++) {
      console.log("Batch Number:", j);
      console.log("Liquidity Locked:", weiToEther(allBatches[j]));
      isBatchValid = await yieldFarming.isBatchValid(accounts[user], j);
      console.log("Is Batch Valid?", isBatchValid);
    }
    console.log("Last number of batches:", lastBatchNumber.toString());
    console.log("Total number of batches:", allBatches.length);
    console.log("===============================\n");

    let LP_balance_user_1_after = await ktyWethPair.balanceOf(accounts[user]);
    let KTY_balance_user_1_after = await kittieFightToken.balanceOf(
      accounts[user]
    );
    let SDAO_balance_user_1_after = await superDaoToken.balanceOf(
      accounts[user]
    );
    console.log(
      "User 1 Liquidity Token balance before withdraw:",
      weiToEther(LP_balance_user_1_before)
    );
    console.log(
      "User 1 Liquidity Token balance after withdraw:",
      weiToEther(LP_balance_user_1_after)
    );
    console.log(
      "User 1 KittieFightToken balance before withdraw:",
      weiToEther(KTY_balance_user_1_before)
    );
    console.log(
      "User 1 KittieFightToke Token balance after withdraw:",
      weiToEther(KTY_balance_user_1_after)
    );
    console.log(
      "User 1 SuperDaoToken balance before withdraw:",
      weiToEther(SDAO_balance_user_1_before)
    );
    console.log(
      "User 1 SuperDaoToken balance after withdraw:",
      weiToEther(SDAO_balance_user_1_after)
    );

    let rewardsClaimedByUser = await yieldFarming.getTotalRewardsClaimedByStaker(
      accounts[user]
    );
    console.log(
      "Total KittieFightToken rewards claimed by user 1:",
      weiToEther(rewardsClaimedByUser[0])
    );
    console.log(
      "Total SuperDaoToken rewards claimed by user 1:",
      weiToEther(rewardsClaimedByUser[1])
    );

    let total_LP_locked = await yieldFarming.getTotalLiquidityTokenLocked();
    console.log(
      "Total Uniswap Liquidity tokens locked in Yield Farming:",
      weiToEther(total_LP_locked)
    );

    let totalLiquidityTokenLockedInDAI = await yieldFarming.getTotalLiquidityTokenLockedInDAI();
    console.log(
      "Total Uniswap Liquidity tokens locked in Dai value:",
      weiToEther(totalLiquidityTokenLockedInDAI)
    );

    let totalRewardsClaimed = await yieldFarming.getTotalRewardsClaimed();
    console.log(
      "Total KittieFightToken rewards claimed:",
      weiToEther(totalRewardsClaimed[0])
    );
    console.log(
      "Total SuperDaoToken rewards claimed:",
      weiToEther(totalRewardsClaimed[1])
    );
  });

  it("allocates an amount of Uniswap Liquidity tokens to batches per FIFO", async () => {
    let LP_amount = new BigNumber(
      web3.utils.toWei("60", "ether") //60 Uniswap Liquidity tokens
    );
    let user = 7;
    console.log("User", user);
    let allocation_LP = await yieldFarming.allocateLP(
      accounts[user],
      LP_amount
    );
    let startBatchNumber = allocation_LP[0];
    let endBatchNumber = allocation_LP[1];
    let hasResidual = allocation_LP[2];
    console.log("Starting Batch Number:", startBatchNumber.toString());
    console.log("End Batch Number:", endBatchNumber.toString());
    console.log("has residual?", hasResidual);
  });

  it("calculates the KittieFightToken and SuperDaoToken rewards per the Liquidity token amount given for a staker", async () => {
    let LP_amount = new BigNumber(
      web3.utils.toWei("60", "ether") //60 Uniswap Liquidity tokens
    );
    let user = 7;
    console.log("User", user);
    let rewards = await yieldFarming.calculateRewardsByAmount(
      accounts[user],
      LP_amount
    );
    let rewardKTY = rewards.rewardKTY;
    let rewardSDAO = rewards.rewardSDAO;
    let startBatchNumber = rewards.startBatchNumber;
    let endBatchNumber = rewards.endBatchNumber;
    console.log("KittieFightToken rewards calculated:", weiToEther(rewardKTY));
    console.log("SuperDaoToken rewards calculated:", weiToEther(rewardSDAO));
    console.log("starting batch number:", startBatchNumber.toString());
    console.log("end batch number:", endBatchNumber.toString());
  });

  it("user withdraws Uniswap Liquidity tokens by Amount and get rewards in KittieFighToken and SuperDaoTokne", async () => {
    let withdraw_LP_amount = new BigNumber(
      web3.utils.toWei("60", "ether") //60 Uniswap Liquidity tokens
    );
    // Info before withdraw
    console.log(`\n======== User: Batches Info Before Withdraw ======== `);
    let allBatches;
    let lastBatchNumber;
    let isBatchValid;
    let user = 7;

    console.log("User", user);

    allBatches = await yieldFarming.getAllBatches(accounts[user]);
    lastBatchNumber = await yieldFarming.getLastBatchNumber(accounts[user]);
    for (let j = 0; j < allBatches.length; j++) {
      console.log("Batch Number:", j);
      console.log("Liquidity Locked:", weiToEther(allBatches[j]));
      isBatchValid = await yieldFarming.isBatchValid(accounts[user], j);
      console.log("Is Batch Valid?", isBatchValid);
    }
    console.log("Last number of batches:", lastBatchNumber.toString());
    console.log("Total number of batches:", allBatches.length);
    console.log("===============================\n");
    let LP_balance_user_before = await ktyWethPair.balanceOf(accounts[user]);
    let KTY_balance_user_before = await kittieFightToken.balanceOf(
      accounts[user]
    );
    let SDAO_balance_user_before = await superDaoToken.balanceOf(
      accounts[user]
    );

    // withdraw by Batch NUmber
    await yieldFarming.withdrawByAmount(withdraw_LP_amount, {
      from: accounts[user]
    }).should.be.fulfilled;

    // Info after withdraw
    console.log(`\n======== User:  Batches Info After Withdraw ======== `);
    allBatches;
    lastBatchNumber;
    isBatchValid;

    allBatches = await yieldFarming.getAllBatches(accounts[user]);
    lastBatchNumber = await yieldFarming.getLastBatchNumber(accounts[user]);
    for (let j = 0; j < allBatches.length; j++) {
      console.log("Batch Number:", j);
      console.log("Liquidity Locked:", weiToEther(allBatches[j]));
      isBatchValid = await yieldFarming.isBatchValid(accounts[user], j);
      console.log("Is Batch Valid?", isBatchValid);
    }
    console.log("Last number of batches:", lastBatchNumber.toString());
    console.log("Total number of batches:", allBatches.length);
    console.log("===============================\n");

    let LP_balance_user_after = await ktyWethPair.balanceOf(accounts[user]);
    let KTY_balance_user_after = await kittieFightToken.balanceOf(
      accounts[user]
    );
    let SDAO_balance_user_after = await superDaoToken.balanceOf(accounts[user]);
    console.log(
      "User Liquidity Token balance before withdraw:",
      weiToEther(LP_balance_user_before)
    );
    console.log(
      "User Liquidity Token balance after withdraw:",
      weiToEther(LP_balance_user_after)
    );
    console.log(
      "User KittieFightToken balance before withdraw:",
      weiToEther(KTY_balance_user_before)
    );
    console.log(
      "User KittieFightToke Token balance after withdraw:",
      weiToEther(KTY_balance_user_after)
    );
    console.log(
      "User SuperDaoToken balance before withdraw:",
      weiToEther(SDAO_balance_user_before)
    );
    console.log(
      "User SuperDaoToken balance after withdraw:",
      weiToEther(SDAO_balance_user_after)
    );

    let rewardsClaimedByUser = await yieldFarming.getTotalRewardsClaimedByStaker(
      accounts[user]
    );
    console.log(
      "Total KittieFightToken rewards claimed by user:",
      weiToEther(rewardsClaimedByUser[0])
    );
    console.log(
      "Total SuperDaoToken rewards claimed by user:",
      weiToEther(rewardsClaimedByUser[1])
    );

    let total_LP_locked = await yieldFarming.getTotalLiquidityTokenLocked();
    console.log(
      "Total Uniswap Liquidity tokens locked in Yield Farming:",
      weiToEther(total_LP_locked)
    );

    let totalLiquidityTokenLockedInDAI = await yieldFarming.getTotalLiquidityTokenLockedInDAI();
    console.log(
      "Total Uniswap Liquidity tokens locked in Dai value:",
      weiToEther(totalLiquidityTokenLockedInDAI)
    );

    let totalRewardsClaimed = await yieldFarming.getTotalRewardsClaimed();
    console.log(
      "Total KittieFightToken rewards claimed:",
      weiToEther(totalRewardsClaimed[0])
    );
    console.log(
      "Total SuperDaoToken rewards claimed:",
      weiToEther(totalRewardsClaimed[1])
    );
  });

  it("allocates an amount of Uniswap Liquidity tokens to batches per FIFO, with an empty batch among valid batches", async () => {
    let LP_amount = new BigNumber(
      web3.utils.toWei("60", "ether") //60 Uniswap Liquidity tokens
    );
    let user = 1;
    console.log("User", user);
    let allocation_LP = await yieldFarming.allocateLP(
      accounts[user],
      LP_amount
    );
    let startBatchNumber = allocation_LP[0];
    let endBatchNumber = allocation_LP[1];
    let hasResidual = allocation_LP[2];
    console.log("Starting Batch Number:", startBatchNumber.toString());
    console.log("End Batch Number:", endBatchNumber.toString());
    console.log("has residual?", hasResidual);
  });

  it("calculates the KittieFightToken and SuperDaoToken rewards per the Liquidity token amount given for a staker, with an empty batch among valid batches", async () => {
    let LP_amount = new BigNumber(
      web3.utils.toWei("60", "ether") //60 Uniswap Liquidity tokens
    );
    let user = 1;
    console.log("User", user);
    let rewards = await yieldFarming.calculateRewardsByAmount(
      accounts[user],
      LP_amount
    );
    let rewardKTY = rewards.rewardKTY;
    let rewardSDAO = rewards.rewardSDAO;
    let startBatchNumber = rewards.startBatchNumber;
    let endBatchNumber = rewards.endBatchNumber;
    console.log("KittieFightToken rewards calculated:", weiToEther(rewardKTY));
    console.log("SuperDaoToken rewards calculated:", weiToEther(rewardSDAO));
    console.log("starting batch number:", startBatchNumber.toString());
    console.log("end batch number:", endBatchNumber.toString());
  });

  it("user withdraws Uniswap Liquidity tokens by Amount and get rewards in KittieFighToken and SuperDaoTokne, with an empty batch among valid batches", async () => {
    let withdraw_LP_amount = new BigNumber(
      web3.utils.toWei("60", "ether") //60 Uniswap Liquidity tokens
    );
    // Info before withdraw
    console.log(`\n======== User: Batches Info Before Withdraw ======== `);
    let allBatches;
    let lastBatchNumber;
    let isBatchValid;
    let user = 1;

    console.log("User", user);

    allBatches = await yieldFarming.getAllBatches(accounts[user]);
    lastBatchNumber = await yieldFarming.getLastBatchNumber(accounts[user]);
    for (let j = 0; j < allBatches.length; j++) {
      console.log("Batch Number:", j);
      console.log("Liquidity Locked:", weiToEther(allBatches[j]));
      isBatchValid = await yieldFarming.isBatchValid(accounts[user], j);
      console.log("Is Batch Valid?", isBatchValid);
    }
    console.log("Last number of batches:", lastBatchNumber.toString());
    console.log("Total number of batches:", allBatches.length);
    console.log("===============================\n");
    let LP_balance_user_before = await ktyWethPair.balanceOf(accounts[user]);
    let KTY_balance_user_before = await kittieFightToken.balanceOf(
      accounts[user]
    );
    let SDAO_balance_user_before = await superDaoToken.balanceOf(
      accounts[user]
    );

    // withdraw by Batch NUmber
    await yieldFarming.withdrawByAmount(withdraw_LP_amount, {
      from: accounts[user]
    }).should.be.fulfilled;

    // Info after withdraw
    console.log(`\n======== User:  Batches Info After Withdraw ======== `);
    allBatches;
    lastBatchNumber;
    isBatchValid;

    allBatches = await yieldFarming.getAllBatches(accounts[user]);
    lastBatchNumber = await yieldFarming.getLastBatchNumber(accounts[user]);
    for (let j = 0; j < allBatches.length; j++) {
      console.log("Batch Number:", j);
      console.log("Liquidity Locked:", weiToEther(allBatches[j]));
      isBatchValid = await yieldFarming.isBatchValid(accounts[user], j);
      console.log("Is Batch Valid?", isBatchValid);
    }
    console.log("Last number of batches:", lastBatchNumber.toString());
    console.log("Total number of batches:", allBatches.length);
    console.log("===============================\n");

    let LP_balance_user_after = await ktyWethPair.balanceOf(accounts[user]);
    let KTY_balance_user_after = await kittieFightToken.balanceOf(
      accounts[user]
    );
    let SDAO_balance_user_after = await superDaoToken.balanceOf(accounts[user]);
    console.log(
      "User Liquidity Token balance before withdraw:",
      weiToEther(LP_balance_user_before)
    );
    console.log(
      "User Liquidity Token balance after withdraw:",
      weiToEther(LP_balance_user_after)
    );
    console.log(
      "User KittieFightToken balance before withdraw:",
      weiToEther(KTY_balance_user_before)
    );
    console.log(
      "User KittieFightToke Token balance after withdraw:",
      weiToEther(KTY_balance_user_after)
    );
    console.log(
      "User SuperDaoToken balance before withdraw:",
      weiToEther(SDAO_balance_user_before)
    );
    console.log(
      "User SuperDaoToken balance after withdraw:",
      weiToEther(SDAO_balance_user_after)
    );

    let rewardsClaimedByUser = await yieldFarming.getTotalRewardsClaimedByStaker(
      accounts[user]
    );
    console.log(
      "Total KittieFightToken rewards claimed by user:",
      weiToEther(rewardsClaimedByUser[0])
    );
    console.log(
      "Total SuperDaoToken rewards claimed by user:",
      weiToEther(rewardsClaimedByUser[1])
    );

    let total_LP_locked = await yieldFarming.getTotalLiquidityTokenLocked();
    console.log(
      "Total Uniswap Liquidity tokens locked in Yield Farming:",
      weiToEther(total_LP_locked)
    );

    let totalLiquidityTokenLockedInDAI = await yieldFarming.getTotalLiquidityTokenLockedInDAI();
    console.log(
      "Total Uniswap Liquidity tokens locked in Dai value:",
      weiToEther(totalLiquidityTokenLockedInDAI)
    );

    let totalRewardsClaimed = await yieldFarming.getTotalRewardsClaimed();
    console.log(
      "Total KittieFightToken rewards claimed:",
      weiToEther(totalRewardsClaimed[0])
    );
    console.log(
      "Total SuperDaoToken rewards claimed:",
      weiToEther(totalRewardsClaimed[1])
    );
  });

  it("Approching the second month: Month 1", async () => {
    let currentMonth = await yieldFarming.getCurrentMonth();
    let currentDay = await yieldFarming.getCurrentDay();
    let daysElapsedInMonth = await yieldFarming.getElapsedDaysInMonth(
      currentDay,
      currentMonth
    );
    let timeUntilCurrentMonthEnd = await yieldFarming.timeUntilCurrentMonthEnd();
    console.log("Current Month:", currentMonth.toString());
    console.log("Current Day:", currentDay.toString());
    console.log(
      "Time (in seconds) until current month ends:",
      timeUntilCurrentMonthEnd.toString()
    );
    console.log(
      "Days elapsed in current month:",
      daysElapsedInMonth.toString()
    );
    console.log("Life goes on...");
    await timeout(timeUntilCurrentMonthEnd.toNumber());
    console.log("The second Month starts: Month 1...");
  });

  // ==============================  SECOND MONTH: MONTH 1  ==============================
  it("unlocks KittieFightToken and SuperDaoToken rewards for the first month (Month 0)", async () => {
    let rewards_month_0 = await yieldFarming.getTotalRewardsByMonth(0);
    let KTYrewards_month_0 = rewards_month_0.rewardKTYbyMonth;
    let SDAOrewards_month_0 = rewards_month_0.rewardSDAObyMonth;

    console.log("KTY Rewards for Month 0:", weiToEther(KTYrewards_month_0));
    console.log("SDAO Rewards for Month 0:", weiToEther(SDAOrewards_month_0));

    kittieFightToken.transfer(yieldFarming.address, KTYrewards_month_0);
    superDaoToken.transfer(yieldFarming.address, SDAOrewards_month_0);
  });

  it("users deposit Uinswap Liquidity tokens in Yield Farming contract", async () => {
    console.log(
      "\n====================== SECOND MONTH: MONTH 1 ======================\n"
    );
    let deposit_LP_amount = new BigNumber(
      web3.utils.toWei("10", "ether") //30 Uniswap Liquidity tokens
    );
    let LP_locked;
    for (let i = 1; i < 19; i++) {
      await ktyWethPair.approve(yieldFarming.address, deposit_LP_amount, {
        from: accounts[i]
      }).should.be.fulfilled;
      await yieldFarming.deposit(deposit_LP_amount, {from: accounts[i]}).should
        .be.fulfilled;
      LP_locked = await yieldFarming.getLiquidityTokenLocked(accounts[i]);
      console.log(
        "Uniswap Liquidity tokens locked by user",
        i,
        ":",
        weiToEther(LP_locked)
      );
    }

    let total_LP_locked = await yieldFarming.getTotalLiquidityTokenLocked();
    console.log(
      "Total Uniswap Liquidity tokens locked in Yield Farming:",
      weiToEther(total_LP_locked)
    );

    let totalLiquidityTokenLockedInDAI = await yieldFarming.getTotalLiquidityTokenLockedInDAI();
    console.log(
      "Total Uniswap Liquidity tokens locked in Dai value:",
      weiToEther(totalLiquidityTokenLockedInDAI)
    );

    // get info on all batches of each staker
    console.log(`\n======== Batches Info ======== `);
    let allBatches;
    let lastBatchNumber;
    for (let i = 1; i < 19; i++) {
      console.log("User", i);
      allBatches = await yieldFarming.getAllBatches(accounts[i]);
      lastBatchNumber = await yieldFarming.getLastBatchNumber(accounts[i]);
      for (let j = 0; j < allBatches.length; j++) {
        console.log("Batch Number:", j);
        console.log("Liquidity Locked:", weiToEther(allBatches[j]));
      }
      console.log("Last number of batches:", lastBatchNumber.toString());
      console.log("Total number of batches:", allBatches.length);
      console.log("****************************\n");
    }
    console.log("===============================\n");
  });

  it("calculates rewards by batch number", async () => {
    let user = 3;
    console.log("User", user);

    let rewards = await yieldFarming.calculateRewardsByBatchNumber(
      accounts[user],
      0
    );
    //console.log(rewards);
    let rewardKTY = rewards[0];
    let rewardSDAO = rewards[1];
    console.log(
      "KittieFightToken reward for user 1's batch 1:",
      weiToEther(rewardKTY)
    );
    console.log(
      "SuperDaoToken reward for user 1's batch 1:",
      weiToEther(rewardSDAO)
    );
  });

  it("user withdraws Uniswap Liquidity tokens by Batch Number and get rewards in KittieFighToken and SuperDaoTokne", async () => {
    // Info before withdraw
    let user = 3;
    console.log("User", user);

    console.log(`\n======== User: Batches Info Before Withdraw ======== `);
    let allBatches;
    let lastBatchNumber;
    let isBatchValid;

    allBatches = await yieldFarming.getAllBatches(accounts[user]);
    lastBatchNumber = await yieldFarming.getLastBatchNumber(accounts[user]);
    for (let j = 0; j < allBatches.length; j++) {
      console.log("Batch Number:", j);
      console.log("Liquidity Locked:", weiToEther(allBatches[j]));
      isBatchValid = await yieldFarming.isBatchValid(accounts[user], j);
      console.log("Is Batch Valid?", isBatchValid);
    }
    console.log("Last number of batches:", lastBatchNumber.toString());
    console.log("Total number of batches:", allBatches.length);
    console.log("===============================\n");
    let LP_balance_user_1_before = await ktyWethPair.balanceOf(accounts[user]);
    let KTY_balance_user_1_before = await kittieFightToken.balanceOf(
      accounts[1]
    );
    let SDAO_balance_user_1_before = await superDaoToken.balanceOf(
      accounts[user]
    );

    // withdraw by Batch NUmber
    await yieldFarming.withdrawByBatchNumber(1, {from: accounts[user]}).should
      .be.fulfilled;

    // Info after withdraw
    console.log(`\n======== User 1:  Batches Info After Withdraw ======== `);
    allBatches;
    lastBatchNumber;
    isBatchValid;

    allBatches = await yieldFarming.getAllBatches(accounts[user]);
    lastBatchNumber = await yieldFarming.getLastBatchNumber(accounts[user]);
    for (let j = 0; j < allBatches.length; j++) {
      console.log("Batch Number:", j);
      console.log("Liquidity Locked:", weiToEther(allBatches[j]));
      isBatchValid = await yieldFarming.isBatchValid(accounts[user], j);
      console.log("Is Batch Valid?", isBatchValid);
    }
    console.log("Last number of batches:", lastBatchNumber.toString());
    console.log("Total number of batches:", allBatches.length);
    console.log("===============================\n");

    let LP_balance_user_1_after = await ktyWethPair.balanceOf(accounts[user]);
    let KTY_balance_user_1_after = await kittieFightToken.balanceOf(
      accounts[user]
    );
    let SDAO_balance_user_1_after = await superDaoToken.balanceOf(
      accounts[user]
    );
    console.log(
      "User 1 Liquidity Token balance before withdraw:",
      weiToEther(LP_balance_user_1_before)
    );
    console.log(
      "User 1 Liquidity Token balance after withdraw:",
      weiToEther(LP_balance_user_1_after)
    );
    console.log(
      "User 1 KittieFightToken balance before withdraw:",
      weiToEther(KTY_balance_user_1_before)
    );
    console.log(
      "User 1 KittieFightToke Token balance after withdraw:",
      weiToEther(KTY_balance_user_1_after)
    );
    console.log(
      "User 1 SuperDaoToken balance before withdraw:",
      weiToEther(SDAO_balance_user_1_before)
    );
    console.log(
      "User 1 SuperDaoToken balance after withdraw:",
      weiToEther(SDAO_balance_user_1_after)
    );

    let rewardsClaimedByUser = await yieldFarming.getTotalRewardsClaimedByStaker(
      accounts[user]
    );
    console.log(
      "Total KittieFightToken rewards claimed by user 1:",
      weiToEther(rewardsClaimedByUser[0])
    );
    console.log(
      "Total SuperDaoToken rewards claimed by user 1:",
      weiToEther(rewardsClaimedByUser[1])
    );

    let total_LP_locked = await yieldFarming.getTotalLiquidityTokenLocked();
    console.log(
      "Total Uniswap Liquidity tokens locked in Yield Farming:",
      weiToEther(total_LP_locked)
    );

    let totalLiquidityTokenLockedInDAI = await yieldFarming.getTotalLiquidityTokenLockedInDAI();
    console.log(
      "Total Uniswap Liquidity tokens locked in Dai value:",
      weiToEther(totalLiquidityTokenLockedInDAI)
    );

    let totalRewardsClaimed = await yieldFarming.getTotalRewardsClaimed();
    console.log(
      "Total KittieFightToken rewards claimed:",
      weiToEther(totalRewardsClaimed[0])
    );
    console.log(
      "Total SuperDaoToken rewards claimed:",
      weiToEther(totalRewardsClaimed[1])
    );
  });

  it("allocates an amount of Uniswap Liquidity tokens to batches per FIFO", async () => {
    let LP_amount = new BigNumber(
      web3.utils.toWei("60", "ether") //60 Uniswap Liquidity tokens
    );
    let user = 6;
    console.log("User", user);
    let allocation_LP = await yieldFarming.allocateLP(
      accounts[user],
      LP_amount
    );
    let startBatchNumber = allocation_LP[0];
    let endBatchNumber = allocation_LP[1];
    let hasResidual = allocation_LP[2];
    console.log("Starting Batch Number:", startBatchNumber.toString());
    console.log("End Batch Number:", endBatchNumber.toString());
    console.log("has residual?", hasResidual);
  });

  it("calculates the KittieFightToken and SuperDaoToken rewards per the Liquidity token amount given for a staker", async () => {
    let LP_amount = new BigNumber(
      web3.utils.toWei("60", "ether") //60 Uniswap Liquidity tokens
    );
    let user = 6;
    console.log("User", user);
    let rewards = await yieldFarming.calculateRewardsByAmount(
      accounts[user],
      LP_amount
    );
    let rewardKTY = rewards.rewardKTY;
    let rewardSDAO = rewards.rewardSDAO;
    let startBatchNumber = rewards.startBatchNumber;
    let endBatchNumber = rewards.endBatchNumber;
    console.log("KittieFightToken rewards calculated:", weiToEther(rewardKTY));
    console.log("SuperDaoToken rewards calculated:", weiToEther(rewardSDAO));
    console.log("starting batch number:", startBatchNumber.toString());
    console.log("end batch number:", endBatchNumber.toString());
  });

  it("user withdraws Uniswap Liquidity tokens by Amount and get rewards in KittieFighToken and SuperDaoTokne", async () => {
    let withdraw_LP_amount = new BigNumber(
      web3.utils.toWei("60", "ether") //60 Uniswap Liquidity tokens
    );
    // Info before withdraw
    console.log(`\n======== User: Batches Info Before Withdraw ======== `);
    let allBatches;
    let lastBatchNumber;
    let isBatchValid;
    let user = 6;

    console.log("User", user);

    allBatches = await yieldFarming.getAllBatches(accounts[user]);
    lastBatchNumber = await yieldFarming.getLastBatchNumber(accounts[user]);
    for (let j = 0; j < allBatches.length; j++) {
      console.log("Batch Number:", j);
      console.log("Liquidity Locked:", weiToEther(allBatches[j]));
      isBatchValid = await yieldFarming.isBatchValid(accounts[user], j);
      console.log("Is Batch Valid?", isBatchValid);
    }
    console.log("Last number of batches:", lastBatchNumber.toString());
    console.log("Total number of batches:", allBatches.length);
    console.log("===============================\n");
    let LP_balance_user_before = await ktyWethPair.balanceOf(accounts[user]);
    let KTY_balance_user_before = await kittieFightToken.balanceOf(
      accounts[user]
    );
    let SDAO_balance_user_before = await superDaoToken.balanceOf(
      accounts[user]
    );

    // withdraw by Batch NUmber
    await yieldFarming.withdrawByAmount(withdraw_LP_amount, {
      from: accounts[user]
    }).should.be.fulfilled;

    // Info after withdraw
    console.log(`\n======== User:  Batches Info After Withdraw ======== `);
    allBatches;
    lastBatchNumber;
    isBatchValid;

    allBatches = await yieldFarming.getAllBatches(accounts[user]);
    lastBatchNumber = await yieldFarming.getLastBatchNumber(accounts[user]);
    for (let j = 0; j < allBatches.length; j++) {
      console.log("Batch Number:", j);
      console.log("Liquidity Locked:", weiToEther(allBatches[j]));
      isBatchValid = await yieldFarming.isBatchValid(accounts[user], j);
      console.log("Is Batch Valid?", isBatchValid);
    }
    console.log("Last number of batches:", lastBatchNumber.toString());
    console.log("Total number of batches:", allBatches.length);
    console.log("===============================\n");

    let LP_balance_user_after = await ktyWethPair.balanceOf(accounts[user]);
    let KTY_balance_user_after = await kittieFightToken.balanceOf(
      accounts[user]
    );
    let SDAO_balance_user_after = await superDaoToken.balanceOf(accounts[user]);
    console.log(
      "User Liquidity Token balance before withdraw:",
      weiToEther(LP_balance_user_before)
    );
    console.log(
      "User Liquidity Token balance after withdraw:",
      weiToEther(LP_balance_user_after)
    );
    console.log(
      "User KittieFightToken balance before withdraw:",
      weiToEther(KTY_balance_user_before)
    );
    console.log(
      "User KittieFightToke Token balance after withdraw:",
      weiToEther(KTY_balance_user_after)
    );
    console.log(
      "User SuperDaoToken balance before withdraw:",
      weiToEther(SDAO_balance_user_before)
    );
    console.log(
      "User SuperDaoToken balance after withdraw:",
      weiToEther(SDAO_balance_user_after)
    );

    let rewardsClaimedByUser = await yieldFarming.getTotalRewardsClaimedByStaker(
      accounts[user]
    );
    console.log(
      "Total KittieFightToken rewards claimed by user:",
      weiToEther(rewardsClaimedByUser[0])
    );
    console.log(
      "Total SuperDaoToken rewards claimed by user:",
      weiToEther(rewardsClaimedByUser[1])
    );

    let total_LP_locked = await yieldFarming.getTotalLiquidityTokenLocked();
    console.log(
      "Total Uniswap Liquidity tokens locked in Yield Farming:",
      weiToEther(total_LP_locked)
    );

    let totalLiquidityTokenLockedInDAI = await yieldFarming.getTotalLiquidityTokenLockedInDAI();
    console.log(
      "Total Uniswap Liquidity tokens locked in Dai value:",
      weiToEther(totalLiquidityTokenLockedInDAI)
    );

    let totalRewardsClaimed = await yieldFarming.getTotalRewardsClaimed();
    console.log(
      "Total KittieFightToken rewards claimed:",
      weiToEther(totalRewardsClaimed[0])
    );
    console.log(
      "Total SuperDaoToken rewards claimed:",
      weiToEther(totalRewardsClaimed[1])
    );
  });

  it("allocates an amount of Uniswap Liquidity tokens to batches per FIFO, with an empty batch among valid batches", async () => {
    let LP_amount = new BigNumber(
      web3.utils.toWei("60", "ether") //60 Uniswap Liquidity tokens
    );
    let user = 3;
    console.log("User", user);
    let allocation_LP = await yieldFarming.allocateLP(
      accounts[user],
      LP_amount
    );
    let startBatchNumber = allocation_LP[0];
    let endBatchNumber = allocation_LP[1];
    let hasResidual = allocation_LP[2];
    console.log("Starting Batch Number:", startBatchNumber.toString());
    console.log("End Batch Number:", endBatchNumber.toString());
    console.log("has residual?", hasResidual);
  });

  it("calculates the KittieFightToken and SuperDaoToken rewards per the Liquidity token amount given for a staker, with an empty batch among valid batches", async () => {
    let LP_amount = new BigNumber(
      web3.utils.toWei("60", "ether") //60 Uniswap Liquidity tokens
    );
    let user = 3;
    console.log("User", user);
    let rewards = await yieldFarming.calculateRewardsByAmount(
      accounts[user],
      LP_amount
    );
    let rewardKTY = rewards.rewardKTY;
    let rewardSDAO = rewards.rewardSDAO;
    let startBatchNumber = rewards.startBatchNumber;
    let endBatchNumber = rewards.endBatchNumber;
    console.log("KittieFightToken rewards calculated:", weiToEther(rewardKTY));
    console.log("SuperDaoToken rewards calculated:", weiToEther(rewardSDAO));
    console.log("starting batch number:", startBatchNumber.toString());
    console.log("end batch number:", endBatchNumber.toString());
  });

  it("user withdraws Uniswap Liquidity tokens by Amount and get rewards in KittieFighToken and SuperDaoTokne, with an empty batch among valid batches", async () => {
    let withdraw_LP_amount = new BigNumber(
      web3.utils.toWei("60", "ether") //60 Uniswap Liquidity tokens
    );
    // Info before withdraw
    console.log(`\n======== User: Batches Info Before Withdraw ======== `);
    let allBatches;
    let lastBatchNumber;
    let isBatchValid;
    let user = 3;

    console.log("User", user);

    allBatches = await yieldFarming.getAllBatches(accounts[user]);
    lastBatchNumber = await yieldFarming.getLastBatchNumber(accounts[user]);
    for (let j = 0; j < allBatches.length; j++) {
      console.log("Batch Number:", j);
      console.log("Liquidity Locked:", weiToEther(allBatches[j]));
      isBatchValid = await yieldFarming.isBatchValid(accounts[user], j);
      console.log("Is Batch Valid?", isBatchValid);
    }
    console.log("Last number of batches:", lastBatchNumber.toString());
    console.log("Total number of batches:", allBatches.length);
    console.log("===============================\n");
    let LP_balance_user_before = await ktyWethPair.balanceOf(accounts[user]);
    let KTY_balance_user_before = await kittieFightToken.balanceOf(
      accounts[user]
    );
    let SDAO_balance_user_before = await superDaoToken.balanceOf(
      accounts[user]
    );

    // withdraw by Batch NUmber
    await yieldFarming.withdrawByAmount(withdraw_LP_amount, {
      from: accounts[user]
    }).should.be.fulfilled;

    // Info after withdraw
    console.log(`\n======== User:  Batches Info After Withdraw ======== `);
    allBatches;
    lastBatchNumber;
    isBatchValid;

    allBatches = await yieldFarming.getAllBatches(accounts[user]);
    lastBatchNumber = await yieldFarming.getLastBatchNumber(accounts[user]);
    for (let j = 0; j < allBatches.length; j++) {
      console.log("Batch Number:", j);
      console.log("Liquidity Locked:", weiToEther(allBatches[j]));
      isBatchValid = await yieldFarming.isBatchValid(accounts[user], j);
      console.log("Is Batch Valid?", isBatchValid);
    }
    console.log("Last number of batches:", lastBatchNumber.toString());
    console.log("Total number of batches:", allBatches.length);
    console.log("===============================\n");

    let LP_balance_user_after = await ktyWethPair.balanceOf(accounts[user]);
    let KTY_balance_user_after = await kittieFightToken.balanceOf(
      accounts[user]
    );
    let SDAO_balance_user_after = await superDaoToken.balanceOf(accounts[user]);
    console.log(
      "User Liquidity Token balance before withdraw:",
      weiToEther(LP_balance_user_before)
    );
    console.log(
      "User Liquidity Token balance after withdraw:",
      weiToEther(LP_balance_user_after)
    );
    console.log(
      "User KittieFightToken balance before withdraw:",
      weiToEther(KTY_balance_user_before)
    );
    console.log(
      "User KittieFightToke Token balance after withdraw:",
      weiToEther(KTY_balance_user_after)
    );
    console.log(
      "User SuperDaoToken balance before withdraw:",
      weiToEther(SDAO_balance_user_before)
    );
    console.log(
      "User SuperDaoToken balance after withdraw:",
      weiToEther(SDAO_balance_user_after)
    );

    let rewardsClaimedByUser = await yieldFarming.getTotalRewardsClaimedByStaker(
      accounts[user]
    );
    console.log(
      "Total KittieFightToken rewards claimed by user:",
      weiToEther(rewardsClaimedByUser[0])
    );
    console.log(
      "Total SuperDaoToken rewards claimed by user:",
      weiToEther(rewardsClaimedByUser[1])
    );

    let total_LP_locked = await yieldFarming.getTotalLiquidityTokenLocked();
    console.log(
      "Total Uniswap Liquidity tokens locked in Yield Farming:",
      weiToEther(total_LP_locked)
    );

    let totalLiquidityTokenLockedInDAI = await yieldFarming.getTotalLiquidityTokenLockedInDAI();
    console.log(
      "Total Uniswap Liquidity tokens locked in Dai value:",
      weiToEther(totalLiquidityTokenLockedInDAI)
    );

    let totalRewardsClaimed = await yieldFarming.getTotalRewardsClaimed();
    console.log(
      "Total KittieFightToken rewards claimed:",
      weiToEther(totalRewardsClaimed[0])
    );
    console.log(
      "Total SuperDaoToken rewards claimed:",
      weiToEther(totalRewardsClaimed[1])
    );
  });

  it("Approching the third month: Month 2", async () => {
    let currentMonth = await yieldFarming.getCurrentMonth();
    let currentDay = await yieldFarming.getCurrentDay();
    let daysElapsedInMonth = await yieldFarming.getElapsedDaysInMonth(
      currentDay,
      currentMonth
    );
    let timeUntilCurrentMonthEnd = await yieldFarming.timeUntilCurrentMonthEnd();
    console.log("Current Month:", currentMonth.toString());
    console.log("Current Day:", currentDay.toString());
    console.log(
      "Time (in seconds) until current month ends:",
      timeUntilCurrentMonthEnd.toString()
    );
    console.log(
      "Days elapsed in current month:",
      daysElapsedInMonth.toString()
    );
    console.log("Life goes on...");
    await timeout(timeUntilCurrentMonthEnd.toNumber());
    console.log("The second Month starts: Month 1...");
  });
});
