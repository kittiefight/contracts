const BigNumber = web3.utils.BN;
require("chai")
  .use(require("chai-shallow-deep-equal"))
  .use(require("chai-bignumber")(BigNumber))
  .use(require("chai-as-promised"))
  .should();

const evm = require("./utils/evm.js");

//ARTIFACTS
const KFProxy = artifacts.require("KFProxy");
const GenericDB = artifacts.require("GenericDB");
const ProfileDB = artifacts.require("ProfileDB");
const RoleDB = artifacts.require("RoleDB");
const HoneypotAllocationAlgo = artifacts.require("HoneypotAllocationAlgo");
const GMSetterDB = artifacts.require("GMSetterDB");
const GMGetterDB = artifacts.require("GMGetterDB");
const GameManager = artifacts.require("GameManager");
const GameStore = artifacts.require("GameStore");
const GameCreation = artifacts.require("GameCreation");
const GameVarAndFee = artifacts.require("GameVarAndFee");
const Forfeiter = artifacts.require("Forfeiter");
const DateTime = artifacts.require("DateTime");
const Scheduler = artifacts.require("Scheduler");
const Betting = artifacts.require("Betting");
const HitsResolve = artifacts.require("HitsResolve");
const RarityCalculator = artifacts.require("RarityCalculator");
const Register = artifacts.require("Register");
const EndowmentFund = artifacts.require("EndowmentFund");
const EndowmentDB = artifacts.require("EndowmentDB");
const Escrow = artifacts.require("Escrow");
const KittieHELL = artifacts.require("KittieHell");
const KittieHellDB = artifacts.require("KittieHellDB");
const SuperDaoToken = artifacts.require("MockERC20Token");
const KittieFightToken = artifacts.require("KittieFightToken");
const CryptoKitties = artifacts.require("MockERC721Token");
const CronJob = artifacts.require("CronJob");
const FreezeInfo = artifacts.require("FreezeInfo");
const CronJobTarget = artifacts.require("CronJobTarget");
const TimeFrame = artifacts.require("TimeFrame");
const WithdrawPool = artifacts.require("WithdrawPool");
const MockStaking = artifacts.require("MockStaking");
const EthieToken = artifacts.require("EthieToken");
const EarningsTracker = artifacts.require("EarningsTracker");
const EarningsTrackerDB = artifacts.require("EarningsTrackerDB");
const Factory = artifacts.require("UniswapV2Factory");
const WETH = artifacts.require("WETH9");
const KtyWethPair = artifacts.require("IUniswapV2Pair");
const KtyWethOracle = artifacts.require("KtyWethOracle");
const KtyUniswap = artifacts.require("KtyUniswap");
const Router = artifacts.require("UniswapV2Router01");
const Dai = artifacts.require("Dai");
const DaiWethPair = artifacts.require("IDaiWethPair");
const DaiWethOracle = artifacts.require("DaiWethOracle");

const editJsonFile = require("edit-json-file");
let file;

const ktyAmount = new BigNumber(
  web3.utils.toWei("50000", "ether") //100 ethers * 500 = 50,000 kty
);

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
let proxy,
  dateTime,
  genericDB,
  profileDB,
  roleDB,
  superDaoToken,
  kittieFightToken,
  cryptoKitties,
  register,
  gameVarAndFee,
  endowmentFund,
  endowmentDB,
  forfeiter,
  scheduler,
  betting,
  hitsResolve,
  rarityCalculator,
  kittieHell,
  kittieHellDB,
  getterDB,
  setterDB,
  gameManager,
  cronJob,
  escrow,
  honeypotAllocationAlgo,
  timeFrame,
  withdrawPool,
  staking,
  earningsTracker,
  earningsTrackerDB,
  ethieToken,
  factory,
  weth,
  ktyWethPair,
  ktyWethOracle,
  ktyUniswap,
  router,
  dai,
  daiWethPair,
  daiWethOracle;

let initial_epoch_0_end_time,
  initial_pool_0_available_time,
  initial_pool_0_dissolve_time,
  initial_epoch_1_end_time,
  initial_pool_1_available_time,
  initial_pool_1_dissolve_time,
  initial_epoch_2_end_time,
  initial_pool_2_available_time,
  initial_pool_2_dissolve_time;

contract("GameManager", accounts => {
  it("instantiate contracts", async () => {
    // PROXY
    proxy = await KFProxy.deployed();

    // DATABASES
    genericDB = await GenericDB.deployed();
    profileDB = await ProfileDB.deployed();
    roleDB = await RoleDB.deployed();
    endowmentDB = await EndowmentDB.deployed();
    getterDB = await GMGetterDB.deployed();
    setterDB = await GMSetterDB.deployed();
    kittieHellDB = await KittieHellDB.deployed();
    earningsTrackerDB = await EarningsTrackerDB.deployed();

    // CRONJOB
    cronJob = await CronJob.deployed();
    freezeInfo = await FreezeInfo.deployed();
    cronJobTarget = await CronJobTarget.deployed();

    // TOKENS
    superDaoToken = await SuperDaoToken.deployed();
    kittieFightToken = await KittieFightToken.deployed();
    cryptoKitties = await CryptoKitties.deployed();
    ethieToken = await EthieToken.deployed();

    // TIMEFRAME
    timeFrame = await TimeFrame.deployed();

    // MODULES
    honeypotAllocationAlgo = await HoneypotAllocationAlgo.deployed();
    gameManager = await GameManager.deployed();
    gameStore = await GameStore.deployed();
    gameCreation = await GameCreation.deployed();
    register = await Register.deployed();
    dateTime = await DateTime.deployed();
    gameVarAndFee = await GameVarAndFee.deployed();
    forfeiter = await Forfeiter.deployed();
    scheduler = await Scheduler.deployed();
    betting = await Betting.deployed();
    hitsResolve = await HitsResolve.deployed();
    rarityCalculator = await RarityCalculator.deployed();
    endowmentFund = await EndowmentFund.deployed();
    kittieHell = await KittieHELL.deployed();
    earningsTracker = await EarningsTracker.deployed();

    //ESCROW
    escrow = await Escrow.deployed();

    // WithdrawPool - Pool for SuperDao token stakers
    withdrawPool = await WithdrawPool.deployed();

    // staking - a mock contract of Aragon's staking contract
    staking = await MockStaking.deployed();
  });

  it("set up uniswap environment", async () => {
    weth = await WETH.deployed();
    console.log("Wrapped ether address:", weth.address);
    dai = await Dai.deployed();
    factory = await Factory.deployed();
    console.log("factory address:", factory.address);
    ktyWethOracle = await KtyWethOracle.deployed();
    daiWethOracle = await DaiWethOracle.deployed();
    ktyUniswap = await KtyUniswap.deployed();
    router = await Router.deployed();

    let router_factory = await router.factory();
    console.log("router_factory:", router_factory);
    let router_WETH = await router.WETH();
    console.log("router WETH:", router_WETH);

    const pairAddress = await factory.getPair(
      weth.address,
      kittieFightToken.address
    );
    console.log("pair address", pairAddress);
    ktyWethPair = await KtyWethPair.at(pairAddress);
    console.log("ktyWethPair:", ktyWethPair.address);
    await router.setKtyWethPairAddr(ktyWethPair.address);

    const daiPairAddress = await factory.getPair(weth.address, dai.address);
    console.log("dai-weth pair address", daiPairAddress);
    daiWethPair = await DaiWethPair.at(daiPairAddress);
    console.log("daiWethPair:", daiWethPair.address);

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

    // verify game var and fee platform fees are in dai and kty set during deployment
    let listingFee = await gameVarAndFee.getListingFee();
    console.log(
      "Ether needed for swapping listing fee kty",
      weiToEther(listingFee[0])
    );
    console.log("Listing fee in kty:", weiToEther(listingFee[1]));

    let finalRewards = await gameVarAndFee.getFinalizeRewards();
    console.log("Final rewards in kty:", weiToEther(finalRewards));

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

  it("registers 40 users", async () => {
    let users = 40;

    for (let i = 1; i <= users; i++) {
      await proxy.execute("Register", setMessage(register, "register", []), {
        from: accounts[i]
      }).should.be.fulfilled;
    }
  });

  it("mints kitties for 2 users", async () => {
    let users = 8;

    let kitties = [324, 1001, 1555108, 1267904, 454545, 333, 6666, 2111];
    let cividIds = [1, 2, 3, 4, 5, 6, 7, 8];

    await cryptoKitties.mint(accounts[1], kitties[0], {from: accounts[0]})
      .should.be.fulfilled;
    await cryptoKitties.approve(kittieHell.address, kitties[0], {
      from: accounts[1]
    }).should.be.fulfilled;
    await proxy.execute(
      "Register",
      setMessage(register, "verifyAccount", [cividIds[0]]),
      {from: accounts[1]}
    ).should.be.fulfilled;

    console.log(`New Player ${accounts[1]} with Kitty ${kitties[0]}`);

    await cryptoKitties.mint(accounts[2], kitties[1], {from: accounts[0]})
      .should.be.fulfilled;
    await cryptoKitties.approve(kittieHell.address, kitties[1], {
      from: accounts[2]
    }).should.be.fulfilled;
    await proxy.execute(
      "Register",
      setMessage(register, "verifyAccount", [cividIds[1]]),
      {from: accounts[2]}
    ).should.be.fulfilled;

    console.log(`New Player ${accounts[2]} with Kitty ${kitties[1]}`);
  });

  it("superDaoToken holders stake superDaoToken, and investors invest via EthieToken NFTs", async () => {
    const stakedTokens = new BigNumber(
      web3.utils.toWei("10000", "ether") //
    );

    for (let i = 1; i < 4; i++) {
      await superDaoToken.transfer(accounts[i], stakedTokens, {
        from: accounts[0]
      });
      let balBefore = await superDaoToken.balanceOf(accounts[i]);
      console.log(
        `Balance of staker ${i} before staking:`,
        weiToEther(balBefore)
      );

      await superDaoToken.approve(staking.address, stakedTokens, {
        from: accounts[i]
      });

      await staking.stake(stakedTokens, {from: accounts[i]});

      let balStaking = await superDaoToken.balanceOf(staking.address);
      console.log(
        "Balance of staking contract after staking:",
        weiToEther(balStaking)
      );

      let balAfter = await superDaoToken.balanceOf(accounts[i]);
      console.log(
        `Balance of staker ${i} after staking:`,
        weiToEther(balAfter)
      );
    }

    await ethieToken.addMinter(earningsTracker.address);
    await earningsTrackerDB.setCurrentFundingLimit();

    for (let i = 0; i < 6; i++) {
      let ethAmount = web3.utils.toWei(String(10 + i), "ether");
      console.log(ethAmount.toString());
      console.log(accounts[i]);
      await proxy.execute(
        "EarningsTracker",
        setMessage(earningsTracker, "lockETH", []),
        {
          gas: 900000,
          from: accounts[i],
          value: ethAmount.toString()
        }
      );
      let number_ethieToken = await ethieToken.balanceOf(accounts[i]);
      let ethieTokenID = await ethieToken.tokenOfOwnerByIndex(accounts[i], 0);
      ethieTokenID = ethieTokenID.toNumber();
      let tokenProperties = await ethieToken.properties(ethieTokenID);
      let ethAmountToken = weiToEther(tokenProperties.ethAmount);
      let generationToken = tokenProperties.generation.toNumber();
      let lockTime = tokenProperties.lockPeriod.toString();
      console.log(`\n************** Investor: accounts${i} **************`);
      console.log("EthieToken ID:", ethieTokenID);
      console.log("Oringinal ether amount held in this token:", ethAmountToken);
      console.log("This token's generation:", generationToken);
      console.log("This token's lock time(in seconds):", lockTime);
      console.log("****************************************************\n");
    }
  });

  it("sets Epoch 0, Pool 0, and sets investment for Epoch 0", async () => {
    await timeFrame.setTimes(250, 120, 120);

    await withdrawPool.setPool_0();

    const epoch_0_start_unix = await timeFrame._epochStartTime(0);
    const epoch_0_end_unix = await timeFrame._epochEndTime(0);
    initial_epoch_0_end_time = epoch_0_end_unix.toNumber();

    console.log("\n******************* Epoch 0 *****************");
    console.log(
      "epoch 0 start time in unix time:",
      epoch_0_start_unix.toNumber()
    );
    console.log("epoch 0 end time in unix time:", epoch_0_end_unix.toNumber());
    console.log("********************************************************\n");

    const numberOfPools = await withdrawPool.getTotalNumberOfPools();
    console.log("Number of pools:", numberOfPools.toNumber());
    console.log("\n******************* Pool 0 Created*******************");
    const pool_0_details = await withdrawPool.weeklyPools(0);
    console.log(
      "epoch ID associated with this pool",
      pool_0_details.epochID.toString()
    );
    console.log(
      "block number when this pool was created",
      pool_0_details.blockNumber.toString()
    );
    console.log(
      "initial ether available in this pool:",
      pool_0_details.initialETHAvailable.toString()
    );
    console.log(
      "ether available in this pool:",
      pool_0_details.ETHAvailable.toString()
    );
    console.log(
      "date available for claiming from this pool:",
      formatDate(pool_0_details.dateAvailable)
    );
    console.log(
      "whether initial ether has been distributed to this pool:",
      pool_0_details.initialETHadded
    );
    console.log(
      "time when this pool is dissolved:",
      formatDate(pool_0_details.dateDissolved)
    );
    console.log(
      "stakers who have claimed from this pool:",
      pool_0_details.stakersClaimed[0]
    );
    console.log("********************************************************\n");

    initial_pool_0_available_time = pool_0_details.dateAvailable.toNumber();
    initial_pool_0_dissolve_time = pool_0_details.dateDissolved.toNumber();
  });

  // ============================== EPOCH 0 ==============================

  it("manual matches kitties", async () => {
    console.log("\n============================== EPOCH 0 ==============================")
    console.log(
      "\n$$$$$$$$$$$$$$$$$$$$$$$$$$$$ GAME 1 $$$$$$$$$$$$$$$$$$$$$$$$$$$$"
    );
    let kittyRed = 324;
    let kittyBlack = 1001;
    let gameStartTimeGiven = Math.floor(Date.now() / 1000) + 70; //now + 80 secs, so for prestart 30 secs 50 secs to participate

    //Must take owners of Kitties here
    let playerBlack = await cryptoKitties.ownerOf(kittyBlack);
    let playerRed = await cryptoKitties.ownerOf(kittyRed);

    console.log("PlayerBlack: ", playerBlack);
    console.log("PlayerRed: ", playerRed);

    await proxy.execute(
      "GameCreation",
      setMessage(gameCreation, "manualMatchKitties", [
        playerRed,
        playerBlack,
        kittyRed,
        kittyBlack,
        gameStartTimeGiven
      ]),
      {from: accounts[0]}
    ).should.be.fulfilled;

    await timeout(3);

    let newGameEvents = await gameCreation.getPastEvents("NewGame", {
      fromBlock: 0,
      toBlock: "latest"
    });

    newGameEvents.map(async e => {
      let gameInfo = await getterDB.getGameTimes(e.returnValues.gameId);

      console.log("\n==== NEW GAME CREATED ===");
      console.log("    GameId ", e.returnValues.gameId);
      console.log("    Red Fighter ", e.returnValues.kittieRed);
      console.log("    Red Player ", e.returnValues.playerRed);
      console.log("    Black Fighter ", e.returnValues.kittieBlack);
      console.log("    Black Player ", e.returnValues.playerBlack);
      console.log("    Prestart Time:", formatDate(gameInfo.preStartTime));
      console.log("    Start Time ", formatDate(e.returnValues.gameStartTime));
      console.log("    End Time:", formatDate(gameInfo.endTime));
      console.log("========================\n");
    });
    //Take both Kitties game to see it is the same
    let gameId1 = await getterDB.getGameOfKittie(kittyRed);
    let gameId2 = await getterDB.getGameOfKittie(kittyBlack);

    if (gameId1 === gameId2) console.log("\nGameId: ", gameId1);

    //Take gameStartTime from blockchain to see if it is same as the one we gave
    let {preStartTime, startTime, endTime} = await getterDB.getGameTimes(
      gameId1
    );

    console.log("\nGame PreStart Time: ", formatDate(preStartTime));
    console.log("\nGame Start Time in UTC: ", formatDate(startTime));
    console.log("\nGame End Time: ", formatDate(endTime));
  });

  it("participates users for game 1", async () => {
    let gameId = 1;
    let blackParticipators = 6;
    let redParticipators = 6;
    let timeInterval = 2;

    let supportersForRed = [];
    let supportersForBlack = [];
    let ticketFee = await gameStore.getTicketFee(gameId);

    let KTY_escrow_before_swap = await kittieFightToken.balanceOf(
      escrow.address
    );

    let {
      playerBlack,
      playerRed,
      kittyBlack,
      kittyRed
    } = await getterDB.getGamePlayers(gameId);
    let participator;

    //accounts 10-29 can be supporters for black
    let blacks = Number(blackParticipators) + 10;
    let reds = Number(redParticipators) + 30;

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

    for (let i = 10; i < blacks; i++) {
      let participate_fee = await gameStore.getTicketFee(1);
      let ether_participate = participate_fee[0];
      let kty_participate = participate_fee[1];
      console.log(
        "ether needed for swapping participate_fee in kty:",
        weiToEther(ether_participate)
      );
      console.log("participate_fee in kty:", weiToEther(kty_participate));
      participator = accounts[i];
      await proxy.execute(
        "GameManager",
        setMessage(gameManager, "participate", [gameId, playerBlack]),
        {from: participator, value: ether_participate}
      );
      console.log("\nNew Participator for playerBlack: ", participator);
      supportersForBlack.push(participator);

      await timeout(timeInterval);
    }

    //accounts 30-49 can be supporters for red
    for (let j = 30; j < reds; j++) {
      participator = accounts[j];
      if (j == Number(reds) - 1) {
        let block = await dateTime.getBlockTimeStamp();
        console.log("\nblocktime: ", formatDate(block));

        let {preStartTime} = await getterDB.getGameTimes(gameId);

        while (block < preStartTime) {
          block = Math.floor(Date.now() / 1000);
          await timeout(3);
        }
      }
      let participate_fee = await gameStore.getTicketFee(1);
      let ether_participate = participate_fee[0];
      let kty_participate = participate_fee[1];
      console.log(
        "ether needed for swapping participate_fee in kty:",
        weiToEther(ether_participate)
      );
      console.log("participate_fee in kty:", weiToEther(kty_participate));

      await proxy.execute(
        "GameManager",
        setMessage(gameManager, "participate", [gameId, playerRed]),
        {from: participator, value: ether_participate}
      );
      console.log("\nNew Participator for playerRed: ", participator);
      supportersForRed.push(participator);

      await timeout(timeInterval);
    }

    console.log("\nSupporters for Black: ", supportersForBlack);
    console.log("\nSupporters for Red: ", supportersForRed);

    let newSwapEvents = await endowmentFund.getPastEvents("EthSwappedforKTY", {
      fromBlock: 0,
      toBlock: "latest"
    });

    newSwapEvents.map(async e => {
      console.log("\n==== NEW Swap CREATED ===");
      console.log("    sender ", e.returnValues.sender);
      console.log("    ether for swap ", e.returnValues.ethAmount);
      console.log("    KTY swapped ", e.returnValues.ktyAmount);
      console.log("    ether receiver ", e.returnValues.receiver);
      console.log("========================\n");
    });

    // escrow KTY balance
    let KTY_escrow_after_swap = await kittieFightToken.balanceOf(
      escrow.address
    );
    console.log(
      "escrow KTY balance before swap:",
      weiToEther(KTY_escrow_before_swap)
    );
    console.log(
      "escrow KTY balance after swap:",
      weiToEther(KTY_escrow_after_swap)
    );

    // uniswap reserve ratio

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
  });

  it("players press start for game 1", async () => {
    let gameId = 1;

    let {
      playerBlack,
      playerRed,
      kittyBlack,
      kittyRed
    } = await getterDB.getGamePlayers(gameId);

    await proxy.execute(
      "GameManager",
      setMessage(gameManager, "startGame", [
        gameId,
        randomValue(99),
        "512955438081049600613224346938352058409509756310147795204209859701881294"
      ]),
      {from: playerBlack}
    ).should.be.fulfilled;

    await timeout(3);

    await proxy.execute(
      "GameManager",
      setMessage(gameManager, "startGame", [
        gameId,
        randomValue(99),
        "24171491821178068054575826800486891805334952029503890331493652557302916"
      ]),
      {from: playerRed}
    ).should.be.fulfilled;

    console.log("\nGame Started: ", gameId);
    console.log("\nPlayerBlack: ", playerBlack);
    console.log("\nPlayerRed: ", playerRed);
  });

  it("players bet for game 1", async () => {
    let gameId = 1;
    let noOfBets = 100;
    let timeInterval = 2;

    let {
      playerBlack,
      playerRed,
      kittyBlack,
      kittyRed
    } = await getterDB.getGamePlayers(gameId);

    let supportersRed = await getterDB.getSupporters(gameId, playerRed);
    let supportersBlack = await getterDB.getSupporters(gameId, playerBlack);
    let totalBetAmount = 0;
    let betsBlack = [];
    let betsRed = [];
    let betAmount;
    let player;
    let supportedPlayer;
    let randomSupporter;

    let state = await getterDB.getGameState(gameId);
    console.log(state);

    for (let i = 0; i < noOfBets; i++) {
      let randomPlayer = randomValue(2);

      if (i == Number(noOfBets) - 1) {
        let block = await dateTime.getBlockTimeStamp();
        console.log(
          "\nWaiting to end as it last bet! \n BlockTime: ",
          formatDate(block)
        );

        let {endTime} = await getterDB.getGameTimes(gameId);
        console.log("\nEnd Time: ", endTime);

        while (block < endTime) {
          block = Math.floor(Date.now() / 1000);
          await timeout(3);
        }
      }
      //PlayerBlack
      if (randomPlayer == 1) {
        randomSupporter = randomValue(supportersBlack - 1);
        betAmount = randomValue(30);
        player = "playerBlack";
        supportedPlayer = accounts[Number(randomSupporter) + 10];

        await proxy.execute(
          "GameManager",
          setMessage(gameManager, "bet", [gameId, randomValue(98)]),
          {from: supportedPlayer, value: web3.utils.toWei(String(betAmount))}
        ).should.be.fulfilled;

        betsBlack.push(betAmount);
      }
      //PlayerRed
      else {
        randomSupporter = randomValue(Number(supportersRed) - 1);
        betAmount = randomValue(30);
        player = "playerRed";
        supportedPlayer = accounts[Number(randomSupporter) + 30];

        await proxy.execute(
          "GameManager",
          setMessage(gameManager, "bet", [gameId, randomValue(98)]),
          {from: supportedPlayer, value: web3.utils.toWei(String(betAmount))}
        ).should.be.fulfilled;

        betsRed.push(betAmount);
      }

      let betEvents = await betting.getPastEvents("BetPlaced", {
        filter: {gameId},
        fromBlock: 0,
        toBlock: "latest"
      });

      let betDetails = betEvents[betEvents.length - 1].returnValues;
      console.log(`\n==== NEW BET FOR ${player} ====`);
      console.log(
        " Amount:",
        web3.utils.fromWei(betDetails._lastBetAmount),
        "ETH"
      );
      console.log(" Bettor:", betDetails._bettor);
      console.log(" Attack Hash:", betDetails.attackHash);
      console.log(" Blocked?:", betDetails.isBlocked);
      console.log(
        ` Defense ${player}:`,
        betDetails.defenseLevelSupportedPlayer
      );
      console.log(" Defense Opponent:", betDetails.defenseLevelOpponent);

      let {endTime} = await getterDB.getGameTimes(gameId);

      if (player === "playerBlack") {
        let lastBetTimestamp = await betting.lastBetTimestamp(
          gameId,
          playerBlack
        );
        console.log(" Timestamp last Bet: ", formatDate(lastBetTimestamp));

        if (lastBetTimestamp >= endTime) {
          console.log("\nGame Ended during last bet!");
          break;
        }
      } else {
        let lastBetTimestamp = await betting.lastBetTimestamp(
          gameId,
          playerRed
        );
        console.log(" Timestamp last Bet: ", formatDate(lastBetTimestamp));

        if (lastBetTimestamp >= endTime) {
          console.log("\nGame Ended during last bet!");
          break;
        }
      }

      totalBetAmount = totalBetAmount + betAmount;
      await timeout(timeInterval);
    }

    console.log("\nBets Black: ", betsBlack);
    console.log("\nBets Red: ", betsRed);

    let honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `);
    console.log(
      `     InitialEtH: ${web3.utils.fromWei(
        honeyPotInfo.initialEth.toString()
      )}   `
    );
    console.log(
      `     TotalETH: ${web3.utils.fromWei(
        honeyPotInfo.ethTotal.toString()
      )}   `
    );
    console.log(
      `     TotalKTY: ${web3.utils.fromWei(
        honeyPotInfo.ktyTotal.toString()
      )}   `
    );
    console.log("=======================\n");
  });

  it("game is getting finalized", async () => {
    let gameId = 1;

    let {preStartTime, startTime, endTime} = await getterDB.getGameTimes(
      gameId
    );

    let {
      playerBlack,
      playerRed,
      kittyBlack,
      kittyRed
    } = await getterDB.getGamePlayers(gameId);

    let finalizer = accounts[20];

    console.log("\n==== WAITING FOR GAME OVER: ", formatDate(endTime));

    await timeout(2);

    await proxy.execute(
      "GameManager",
      setMessage(gameManager, "finalize", [gameId, randomValue(30)]),
      {from: finalizer}
    ).should.be.fulfilled;

    let gameEnd = await gameManager.getPastEvents("GameEnded", {
      filter: {gameId},
      fromBlock: 0,
      toBlock: "latest"
    });

    let state = await getterDB.getGameState(gameId);
    console.log(state);

    let {pointsBlack, pointsRed, loser} = gameEnd[0].returnValues;

    let winners = await getterDB.getWinners(gameId);

    let corner = winners.winner === playerBlack ? "Black Corner" : "Red Corner";

    console.log(`\n==== WINNER: ${corner} ==== `);
    console.log(`   Winner: ${winners.winner}   `);
    console.log(`   TopBettor: ${winners.topBettor}   `);
    console.log(`   SecondTopBettor: ${winners.secondTopBettor}   `);
    console.log("");
    console.log(`   Points Black: ${pointsBlack}   `);
    console.log(`   Point Red: ${pointsRed}   `);
    console.log("=======================\n");

    await timeout(3);

    let honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `);
    console.log(
      `     InitialEtH: ${web3.utils.fromWei(
        honeyPotInfo.initialEth.toString()
      )}   `
    );
    console.log(
      `     TotalETH: ${web3.utils.fromWei(
        honeyPotInfo.ethTotal.toString()
      )}   `
    );
    console.log(
      `     TotalKTY: ${web3.utils.fromWei(
        honeyPotInfo.ktyTotal.toString()
      )}   `
    );
    console.log("=======================\n");

    let finalHoneypot = await getterDB.getFinalHoneypot(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `);
    console.log(
      `     TotalETH: ${web3.utils.fromWei(
        finalHoneypot.totalEth.toString()
      )}   `
    );
    console.log(
      `     TotalKTY: ${web3.utils.fromWei(
        finalHoneypot.totalKty.toString()
      )}   `
    );
    console.log("=======================\n");
  });

  it("claims for everyone", async () => {
    let gameId = 1;

    let winners = await getterDB.getWinners(gameId);
    let winner = winners.winner;
    let numberOfSupporters;
    let incrementingNumber;
    let claimer;

    let winnerShare = await endowmentFund.getWinnerShare(
      gameId,
      winners.winner
    );
    console.log(
      "\nWinner withdrawing ",
      String(web3.utils.fromWei(winnerShare.winningsETH.toString())),
      "ETH"
    );
    console.log(
      "Winner withdrawing ",
      String(web3.utils.fromWei(winnerShare.winningsKTY.toString())),
      "KTY"
    );
    await proxy.execute(
      "EndowmentFund",
      setMessage(endowmentFund, "claim", [gameId]),
      {from: winners.winner}
    ).should.be.fulfilled;
    let withdrawalState = await endowmentFund.getWithdrawalState(
      gameId,
      winners.winner
    );
    console.log("Withdrew funds from Winner? ", withdrawalState);

    let honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `);
    console.log(
      `     InitialEtH: ${web3.utils.fromWei(
        honeyPotInfo.initialEth.toString()
      )}   `
    );
    console.log(
      `     TotalETH: ${web3.utils.fromWei(
        honeyPotInfo.ethTotal.toString()
      )}   `
    );
    console.log(
      `     TotalKTY: ${web3.utils.fromWei(
        honeyPotInfo.ktyTotal.toString()
      )}   `
    );
    console.log("=======================\n");

    await timeout(1);

    let topBettorsShare = await endowmentFund.getWinnerShare(
      gameId,
      winners.topBettor
    );
    console.log(
      "\nTop Bettor withdrawing ",
      String(web3.utils.fromWei(topBettorsShare.winningsETH.toString())),
      "ETH"
    );
    console.log(
      "Top Bettor withdrawing ",
      String(web3.utils.fromWei(topBettorsShare.winningsKTY.toString())),
      "KTY"
    );
    await proxy.execute(
      "EndowmentFund",
      setMessage(endowmentFund, "claim", [gameId]),
      {from: winners.topBettor}
    ).should.be.fulfilled;
    withdrawalState = await endowmentFund.getWithdrawalState(
      gameId,
      winners.topBettor
    );
    console.log("Withdrew funds from Top Bettor? ", withdrawalState);

    honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `);
    console.log(
      `     InitialEtH: ${web3.utils.fromWei(
        honeyPotInfo.initialEth.toString()
      )}   `
    );
    console.log(
      `     TotalETH: ${web3.utils.fromWei(
        honeyPotInfo.ethTotal.toString()
      )}   `
    );
    console.log(
      `     TotalKTY: ${web3.utils.fromWei(
        honeyPotInfo.ktyTotal.toString()
      )}   `
    );
    console.log("=======================\n");

    await timeout(1);

    let secondTopBettorsShare = await endowmentFund.getWinnerShare(
      gameId,
      winners.secondTopBettor
    );
    console.log(
      "\nSecond Top Bettor withdrawing ",
      String(web3.utils.fromWei(secondTopBettorsShare.winningsETH.toString())),
      "ETH"
    );
    console.log(
      "Second Top Bettor withdrawing ",
      String(web3.utils.fromWei(secondTopBettorsShare.winningsKTY.toString())),
      "KTY"
    );
    await proxy.execute(
      "EndowmentFund",
      setMessage(endowmentFund, "claim", [gameId]),
      {from: winners.secondTopBettor}
    ).should.be.fulfilled;
    withdrawalState = await endowmentFund.getWithdrawalState(
      gameId,
      winners.secondTopBettor
    );
    console.log("Withdrew funds from Second Top Bettor? ", withdrawalState);

    honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `);
    console.log(
      `     InitialEtH: ${web3.utils.fromWei(
        honeyPotInfo.initialEth.toString()
      )}   `
    );
    console.log(
      `     TotalETH: ${web3.utils.fromWei(
        honeyPotInfo.ethTotal.toString()
      )}   `
    );
    console.log(
      `     TotalKTY: ${web3.utils.fromWei(
        honeyPotInfo.ktyTotal.toString()
      )}   `
    );
    console.log("=======================\n");

    await timeout(1);

    let {
      playerBlack,
      playerRed,
      kittyBlack,
      kittyRed
    } = await getterDB.getGamePlayers(gameId);

    if (winner === playerBlack) {
      numberOfSupporters = await getterDB.getSupporters(gameId, playerBlack);
      incrementingNumber = 10;
    } else {
      numberOfSupporters = await getterDB.getSupporters(gameId, playerRed);
      incrementingNumber = 30;
    }

    for (let i = 0; i < numberOfSupporters; i++) {
      claimer = accounts[i + incrementingNumber];
      if (claimer === winners.topBettor) continue;
      else if (claimer === winners.secondTopBettor) continue;
      else {
        share = await endowmentFund.getWinnerShare(gameId, claimer);
        console.log(
          "\nClaimer withdrawing ",
          String(web3.utils.fromWei(share.winningsETH.toString())),
          "ETH"
        );
        console.log(
          "Claimer withdrawing ",
          String(web3.utils.fromWei(share.winningsKTY.toString())),
          "KTY"
        );
        if (
          Number(String(web3.utils.fromWei(share.winningsETH.toString()))) != 0
        ) {
          await proxy.execute(
            "EndowmentFund",
            setMessage(endowmentFund, "claim", [gameId]),
            {from: claimer}
          ).should.be.fulfilled;
          withdrawalState = await endowmentFund.getWithdrawalState(
            gameId,
            claimer
          );
          console.log("Withdrew funds from Claimer? ", withdrawalState);
        }

        honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

        console.log(`\n==== HONEYPOT INFO ==== `);
        console.log(
          `     InitialEtH: ${web3.utils.fromWei(
            honeyPotInfo.initialEth.toString()
          )}   `
        );
        console.log(
          `     TotalETH: ${web3.utils.fromWei(
            honeyPotInfo.ethTotal.toString()
          )}   `
        );
        console.log(
          `     TotalKTY: ${web3.utils.fromWei(
            honeyPotInfo.ktyTotal.toString()
          )}   `
        );
        console.log("=======================\n");

        await timeout(1);
      }

      let endowmentShare = await endowmentFund.getEndowmentShare(gameId);
      console.log(`\n==== ENDOWMENT INFO ==== `);
      console.log(
        "\nEndowmentShare: ",
        String(web3.utils.fromWei(endowmentShare.winningsETH.toString())),
        "ETH"
      );
      console.log(
        "EndowmentShare: ",
        String(web3.utils.fromWei(endowmentShare.winningsKTY.toString())),
        "KTY"
      );
      console.log("=======================\n");
    }
  });

  it("the loser can redeem his/her kitty, dynamic redemption fee is burnt to kittieHELL, replacement kitties become permanent ghosts in kittieHELL", async () => {
    let gameId = 1;
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

    let resurrectionFee = await gameStore.getKittieRedemptionFee(gameId);
    let resurrectionCost = resurrectionFee[1];

    const sacrificeKitties = [1017555, 413830, 888];

    for (let i = 0; i < sacrificeKitties.length; i++) {
      await cryptoKitties.mint(loser, sacrificeKitties[i]);
    }

    for (let i = 0; i < sacrificeKitties.length; i++) {
      await cryptoKitties.approve(kittieHellDB.address, sacrificeKitties[i], {
        from: loser
      });
    }

    // await kittieFightToken.approve(kittieHell.address, resurrectionCost, {
    //   from: loser
    // });

    let ether_resurrection_cost = resurrectionFee[0];
    console.log("KTY resurrection cost:", weiToEther(resurrectionCost));
    console.log(
      "ether needed for swap KTY resurrection:",
      weiToEther(ether_resurrection_cost)
    );

    await proxy.execute(
      "KittieHell",
      setMessage(kittieHell, "payForResurrection", [
        loserKitty,
        gameId,
        loser,
        sacrificeKitties
      ]),
      {from: loser, value: ether_resurrection_cost}
    );

    let owner = await cryptoKitties.ownerOf(loserKitty);

    if (owner === kittieHellDB.address) {
      console.log("Loser kitty became ghost in kittieHELL FOREVER :(");
    }

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
    console.log("\n==== UNISWAP RESERVE RATIO ===");
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
  });

  it("extends the epoch end time and pool available/dissolve time dynamically depending on gaming delay", async () => {
    const epoch_0_end_unix_extended = await timeFrame._epochEndTime(0);
    console.log(
      "extended epoch 0 end time in unix time:",
      epoch_0_end_unix_extended.toNumber()
    );
    const pool_0_extended_details = await withdrawPool.weeklyPools(0);
    console.log(
      "extended date available for claiming from this pool:",
      pool_0_extended_details.dateAvailable.toString()
    );
    console.log(
      "extended time when this pool is dissolved:",
      pool_0_extended_details.dateDissolved.toString()
    );
    console.log(
      "epoch 0 end time extended by:",
      epoch_0_end_unix_extended.toNumber() - initial_epoch_0_end_time
    );
    console.log(
      "pool 0 available time extended by:",
      pool_0_extended_details.dateAvailable.toNumber() -
        initial_pool_0_available_time
    );
    console.log(
      "pool 0 dissolve time extended by:",
      pool_0_extended_details.dateDissolved.toNumber() -
        initial_pool_0_dissolve_time
    );
  });

  it("adds ether to pool associated with the active epoch", async () => {
    const initialETH_pool_0_wei = await endowmentDB.getETHinPool(0);
    const initialETH_pool_0 = weiToEther(initialETH_pool_0_wei);
    console.log(
      "\n******************* Initial Ethers Distributed to Pool 0 *******************"
    );
    console.log("Initial ether in pool 0: " + initialETH_pool_0);
  });

  it("an eligible staker of superDao tokens can claim yield from the active pool", async () => {
    let timeTillClaiming = await withdrawPool.timeUntilClaiming();
    console.log(
      "Time (in seconds) till claiming from the current pool:",
      timeTillClaiming.toNumber()
    );
    await timeout(timeTillClaiming.toNumber());
    console.log("Available for claiming...");
    for (let i = 1; i < 4; i++) {
      await proxy.execute(
        "WithdrawPool",
        setMessage(withdrawPool, "claimYield", [0]),
        {
          from: accounts[i]
        }
      );
    }
    const pool_0_details = await withdrawPool.weeklyPools(0);
    const numberOfClaimers = pool_0_details.stakersClaimed.toNumber();
    const etherPaidOutPool0 = await withdrawPool.getEthPaidOut();
    console.log(
      "\n******************* SuperDao Tokens Stakers Claim from Pool 0 *******************"
    );
    console.log(
      "epoch ID associated with this pool",
      pool_0_details.epochID.toString()
    );
    console.log(
      "block number when this pool was created",
      pool_0_details.blockNumber.toString()
    );
    console.log(
      "initial ether available in this pool:",
      weiToEther(pool_0_details.initialETHAvailable)
    );
    console.log(
      "ether available in this pool:",
      weiToEther(pool_0_details.ETHAvailable)
    );
    console.log(
      "date available for claiming from this pool:",
      pool_0_details.dateAvailable.toString()
    );
    console.log(
      "whether initial ether has been distributed to this pool:",
      pool_0_details.initialETHadded
    );
    console.log(
      "time when this pool is dissolved:",
      pool_0_details.dateDissolved.toString()
    );
    console.log(
      "Number of stakers who have claimed from this pool:",
      numberOfClaimers
    );
    console.log("ether paid out by pool 0:", weiToEther(etherPaidOutPool0));
    console.log("-------- Stakers who have claimed from this pool ------");

    let claimers = await withdrawPool.getAllClaimersForPool(0);
    console.log(claimers);

    console.log("********************************************************\n");
  });

  it("an investor can burn his Ethie Token NFT and receive ethers locked and interest accumulated", async () => {
    let tokenID = 1;

    let newLock = await earningsTracker.getPastEvents("EtherLocked", {
      fromBlock: 0,
      toBlock: "latest"
    });

    newLock.map(async e => {
      console.log("\n==== NEW LOCK HAPPENED ===");
      console.log("    Funder ", e.returnValues.funder);
      console.log("    TokenID ", e.returnValues.ethieTokenID);
      console.log("    Generation ", e.returnValues.generation);
      console.log("========================\n");
    });

    let owner = await ethieToken.ownerOf(tokenID);
    console.log(owner);

    let valueReturned = await earningsTrackerDB.calculateTotal(
      web3.utils.toWei("5"),
      0
    );
    console.log(web3.utils.fromWei(valueReturned.toString()));
    let burn_fee = await earningsTrackerDB.KTYforBurnEthie(tokenID);
    let ether_burn_ethie = burn_fee[0];
    let ktyFee = burn_fee[1];

    await ethieToken.approve(earningsTracker.address, tokenID, {from: owner});

    console.log("KTY burn ethie fee:", weiToEther(ktyFee));
    console.log(
      "ether needed for swap KTY burn ethie fee:",
      weiToEther(ether_burn_ethie)
    );

    // burn ethie
    await proxy.execute(
      "EarningsTracker",
      setMessage(earningsTracker, "burnNFT", [tokenID]),
      {
        from: owner,
        value: ether_burn_ethie
      }
    );
    let newBurn = await earningsTracker.getPastEvents("EthieTokenBurnt", {
      fromBlock: 0,
      toBlock: "latest"
    });

    newBurn.map(async e => {
      console.log("\n==== NEW BURN HAPPENED ===");
      console.log("    Burner ", e.returnValues.burner);
      console.log("    TokenID ", e.returnValues.ethieTokenID);
      console.log("    Generation ", e.returnValues.generation);
      console.log("    Investment ", e.returnValues.principalEther);
      console.log("    Interest ", e.returnValues.interestPaid);
      console.log("========================\n");
    });

    // uniswap reserve ratio
    console.log("\n==== UNISWAP RESERVE RATIO ===");
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
  });

  // ==============================  Upgrade TimeFrame.sol ============================== 
  it("Upgrades TimeFrame.sol", async () => {
    console.log("old timeFrame address:", timeFrame.address)
    timeFrame = await TimeFrame.new();
    console.log("new timeFrame address:", timeFrame.address);

    file = editJsonFile('build/contracts/TimeFrame.json');

    file.set("networks.999.address", timeFrame.address);
    file.save();

    console.log("SetProxy...");
    await timeFrame.setProxy(proxy.address);
    await proxy.updateContract('TimeFrame', timeFrame.address);

    console.log("new TimeFrame deployed...");

    console.log("Initialize...");
    await timeFrame.initialize();
    await earningsTracker.initialize();
    await withdrawPool.initialize(staking.address, superDaoToken.address);
    await gameStore.initialize();

    // only need to do this step in local test
    await timeFrame.setTimes(250, 120, 120);
})

  it("sets new epoch when finalized", async () => {
    let _wait = await timeFrame.timeUntilEpochEnd(0);
    _wait = _wait.toNumber();
    console.log(_wait);
    await timeout(_wait);
    // evm.increaseTime(web3, _wait)
    await proxy.executeScheduledJobs();
    console.log("Hi, new epoch!");

    const epoch_1_start_unix = await timeFrame._epochStartTime(1);
    console.log(
      "epoch 1 start time in unix time:",
      epoch_1_start_unix.toNumber()
    );
    const epoch_1_end_unix = await timeFrame._epochEndTime(1);
    initial_epoch_1_end_time = epoch_1_end_unix
    const epoch_1_start_human_readable = await timeFrame.epochStartTime(1);
    const epoch_1_end_human_readable = await timeFrame.epochEndTime(1);
    console.log("\n******************* Epoch 1 Start Time *****************");
    console.log(
      "Date:",
      epoch_1_start_human_readable[0].toNumber() +
        "-" +
        epoch_1_start_human_readable[1].toNumber() +
        "-" +
        epoch_1_start_human_readable[2].toNumber(),
      " ",
      "Time:",
      epoch_1_start_human_readable[3].toNumber() +
        ":" +
        epoch_1_start_human_readable[4].toNumber() +
        ":" +
        epoch_1_start_human_readable[5].toNumber()
    );
    console.log("\n******************* Epoch 1 End Time *******************");
    console.log(
      "Date:",
      epoch_1_end_human_readable[0].toNumber() +
        "-" +
        epoch_1_end_human_readable[1].toNumber() +
        "-" +
        epoch_1_end_human_readable[2].toNumber(),
      " ",
      "Time:",
      epoch_1_end_human_readable[3].toNumber() +
        ":" +
        epoch_1_end_human_readable[4].toNumber() +
        ":" +
        epoch_1_end_human_readable[5].toNumber()
    );
    console.log("********************************************************\n");
  });

  it("creates a new pool", async () => {
    const numberOfDissolvedPools = await withdrawPool.getNumberOfDissolvedPools();
    console.log(
      "Total number of dissolved Pools:",
      numberOfDissolvedPools.toNumber()
    );
    const numberOfPools = await withdrawPool.getTotalNumberOfPools();
    console.log("Total number of pools:", numberOfPools.toNumber());

    console.log("************* Details of New Pool Created ************");
    const pool_1_details = await withdrawPool.weeklyPools(1);
    const numberOfClaimers = pool_1_details.stakersClaimed.toNumber();
    console.log(
      "epoch ID associated with this pool",
      pool_1_details.epochID.toString()
    );
    console.log(
      "block number when this pool was created",
      pool_1_details.blockNumber.toString()
    );
    console.log(
      "initial ether available in this pool:",
      pool_1_details.initialETHAvailable.toString()
    );
    console.log(
      "ether remaining in this pool:",
      pool_1_details.ETHAvailable.toString()
    );
    console.log(
      "date available for claiming from this pool:",
      pool_1_details.dateAvailable.toString()
    );
    console.log(
      "whether initial ether has been distributed to this pool:",
      pool_1_details.initialETHadded
    );
    console.log(
      "time when this pool is dissolved:",
      pool_1_details.dateDissolved.toString()
    );
    console.log(
      "time (in seconds) till this pool will be dissolved: ",
      pool_1_details.dateDissolved.toNumber() - Math.floor(Date.now() / 1000)
    );
    console.log(
      "Number of stakers who have claimed from this pool:",
      numberOfClaimers
    );

    console.log("-------- Stakers who have claimed from this pool ------");

    let claimers = await withdrawPool.getAllClaimersForPool(1);
    console.log(claimers);

    initial_pool_1_available_time = pool_1_details.dateAvailable
    initial_pool_1_dissolve_time = pool_1_details.dateDissolved

    console.log("********************************************************\n");
  });

  

  // ============================== Epoch 1 ==============================
  it("Starts game 2 in Epoch 1", async () => {
    console.log("\n============================== Epoch 1 ==============================")
    console.log(
      "\n$$$$$$$$$$$$$$$$$$$$$$$$$$$$ GAME 2 $$$$$$$$$$$$$$$$$$$$$$$$$$$$"
    );
    let users = 40;

    for (let i = 1; i <= users; i++) {
      let isRegistered = await register.isRegistered(accounts[i]);
      assert.isTrue(isRegistered);
    }
  });

  it("mints kitties for 2 users", async () => {
    let users = 8;

    let kitties = [325, 1002, 1556108, 1267905, 454546, 334, 6667, 2112];
    let cividIds = [1, 2, 3, 4, 5, 6, 7, 8];

    await cryptoKitties.mint(accounts[1], kitties[0], {from: accounts[0]})
      .should.be.fulfilled;
    await cryptoKitties.approve(kittieHell.address, kitties[0], {
      from: accounts[1]
    }).should.be.fulfilled;

    await cryptoKitties.mint(accounts[2], kitties[1], {from: accounts[0]})
      .should.be.fulfilled;
    await cryptoKitties.approve(kittieHell.address, kitties[1], {
      from: accounts[2]
    }).should.be.fulfilled;
  });

  it("superDaoToken holders stake superDaoToken, and investors invest via EthieToken NFTs", async () => {
    const stakedTokens = new BigNumber(
      web3.utils.toWei("10000", "ether") //
    );

    for (let i = 5; i < 8; i++) {
      await superDaoToken.transfer(accounts[i], stakedTokens, {
        from: accounts[0]
      });
      let balBefore = await superDaoToken.balanceOf(accounts[i]);
      console.log(
        `Balance of staker ${i} before staking:`,
        weiToEther(balBefore)
      );

      await superDaoToken.approve(staking.address, stakedTokens, {
        from: accounts[i]
      });

      await staking.stake(stakedTokens, {from: accounts[i]});

      let balStaking = await superDaoToken.balanceOf(staking.address);
      console.log(
        "Balance of staking contract after staking:",
        weiToEther(balStaking)
      );

      let balAfter = await superDaoToken.balanceOf(accounts[i]);
      console.log(
        `Balance of staker ${i} after staking:`,
        weiToEther(balAfter)
      );
    }

    for (let i = 0; i < 6; i++) {
      let ethAmount = web3.utils.toWei(String(1 + i), "ether");
      console.log(ethAmount.toString());
      console.log(accounts[i]);
      await proxy.execute(
        "EarningsTracker",
        setMessage(earningsTracker, "lockETH", []),
        {
          gas: 900000,
          from: accounts[i],
          value: ethAmount.toString()
        }
      );
      let number_ethieToken = await ethieToken.balanceOf(accounts[i]);
      let ethieTokenID = await ethieToken.tokenOfOwnerByIndex(accounts[i], 0);
      ethieTokenID = ethieTokenID.toNumber();
      let tokenProperties = await ethieToken.properties(ethieTokenID);
      let ethAmountToken = weiToEther(tokenProperties.ethAmount);
      let generationToken = tokenProperties.generation.toNumber();
      let lockTime = tokenProperties.lockPeriod.toString();
      console.log(`\n************** Investor: accounts${i} **************`);
      console.log("EthieToken ID:", ethieTokenID);
      console.log("Oringinal ether amount held in this token:", ethAmountToken);
      console.log("This token's generation:", generationToken);
      console.log("This token's lock time(in seconds):", lockTime);
      console.log("****************************************************\n");
    }
  });

  it("manual matches kitties", async () => {
    let kittyRed = 325;
    let kittyBlack = 1002;
    let gameStartTimeGiven = Math.floor(Date.now() / 1000) + 70; //now + 80 secs, so for prestart 30 secs 50 secs to participate

    //Must take owners of Kitties here
    let playerBlack = await cryptoKitties.ownerOf(kittyBlack);
    let playerRed = await cryptoKitties.ownerOf(kittyRed);

    console.log("PlayerBlack: ", playerBlack);
    console.log("PlayerRed: ", playerRed);

    await proxy.execute(
      "GameCreation",
      setMessage(gameCreation, "manualMatchKitties", [
        playerRed,
        playerBlack,
        kittyRed,
        kittyBlack,
        gameStartTimeGiven
      ]),
      {from: accounts[0]}
    ).should.be.fulfilled;

    await timeout(3);

    let newGameEvents = await gameCreation.getPastEvents("NewGame", {
      fromBlock: 0,
      toBlock: "latest"
    });

    newGameEvents.map(async e => {
      let gameInfo = await getterDB.getGameTimes(e.returnValues.gameId);

      console.log("\n==== NEW GAME CREATED ===");
      console.log("    GameId ", e.returnValues.gameId);
      console.log("    Red Fighter ", e.returnValues.kittieRed);
      console.log("    Red Player ", e.returnValues.playerRed);
      console.log("    Black Fighter ", e.returnValues.kittieBlack);
      console.log("    Black Player ", e.returnValues.playerBlack);
      console.log("    Prestart Time:", formatDate(gameInfo.preStartTime));
      console.log("    Start Time ", formatDate(e.returnValues.gameStartTime));
      console.log("    End Time:", formatDate(gameInfo.endTime));
      console.log("========================\n");
    });
    //Take both Kitties game to see it is the same
    let gameId3 = await getterDB.getGameOfKittie(kittyRed);
    let gameId4 = await getterDB.getGameOfKittie(kittyBlack);

    if (gameId3 === gameId4) console.log("\nGameId: ", gameId3);

    //Take gameStartTime from blockchain to see if it is same as the one we gave
    let {preStartTime, startTime, endTime} = await getterDB.getGameTimes(
      gameId3
    );

    console.log("\nGame PreStart Time: ", formatDate(preStartTime));
    console.log("\nGame Start Time in UTC: ", formatDate(startTime));
    console.log("\nGame End Time: ", formatDate(endTime));
  });

  it("participates users for game 2", async () => {
    let gameId = 2;
    let blackParticipators = 6;
    let redParticipators = 6;
    let timeInterval = 2;

    let supportersForRed = [];
    let supportersForBlack = [];
    let ticketFee = await gameStore.getTicketFee(gameId);

    let KTY_escrow_before_swap = await kittieFightToken.balanceOf(
      escrow.address
    );

    let {
      playerBlack,
      playerRed,
      kittyBlack,
      kittyRed
    } = await getterDB.getGamePlayers(gameId);
    let participator;

    //accounts 10-29 can be supporters for black
    let blacks = Number(blackParticipators) + 10;
    let reds = Number(redParticipators) + 30;

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

    for (let i = 10; i < blacks; i++) {
      let participate_fee = await gameStore.getTicketFee(2);
      let ether_participate = participate_fee[0];
      let kty_participate = participate_fee[1];
      console.log(
        "ether needed for swapping participate_fee in kty:",
        weiToEther(ether_participate)
      );
      console.log("participate_fee in kty:", weiToEther(kty_participate));
      participator = accounts[i];
      await proxy.execute(
        "GameManager",
        setMessage(gameManager, "participate", [gameId, playerBlack]),
        {from: participator, value: ether_participate}
      );
      console.log("\nNew Participator for playerBlack: ", participator);
      supportersForBlack.push(participator);

      await timeout(timeInterval);
    }

    //accounts 30-49 can be supporters for red
    for (let j = 30; j < reds; j++) {
      participator = accounts[j];
      if (j == Number(reds) - 1) {
        let block = await dateTime.getBlockTimeStamp();
        console.log("\nblocktime: ", formatDate(block));

        let {preStartTime} = await getterDB.getGameTimes(gameId);

        while (block < preStartTime) {
          block = Math.floor(Date.now() / 1000);
          await timeout(3);
        }
      }
      let participate_fee = await gameStore.getTicketFee(2);
      let ether_participate = participate_fee[0];
      let kty_participate = participate_fee[1];
      console.log(
        "ether needed for swapping participate_fee in kty:",
        weiToEther(ether_participate)
      );
      console.log("participate_fee in kty:", weiToEther(kty_participate));

      await proxy.execute(
        "GameManager",
        setMessage(gameManager, "participate", [gameId, playerRed]),
        {from: participator, value: ether_participate}
      );
      console.log("\nNew Participator for playerRed: ", participator);
      supportersForRed.push(participator);

      await timeout(timeInterval);
    }

    console.log("\nSupporters for Black: ", supportersForBlack);
    console.log("\nSupporters for Red: ", supportersForRed);

    let newSwapEvents = await endowmentFund.getPastEvents("EthSwappedforKTY", {
      fromBlock: 0,
      toBlock: "latest"
    });

    newSwapEvents.map(async e => {
      console.log("\n==== NEW Swap CREATED ===");
      console.log("    sender ", e.returnValues.sender);
      console.log("    ether for swap ", e.returnValues.ethAmount);
      console.log("    KTY swapped ", e.returnValues.ktyAmount);
      console.log("    ether receiver ", e.returnValues.receiver);
      console.log("========================\n");
    });

    // escrow KTY balance
    let KTY_escrow_after_swap = await kittieFightToken.balanceOf(
      escrow.address
    );
    console.log(
      "escrow KTY balance before swap:",
      weiToEther(KTY_escrow_before_swap)
    );
    console.log(
      "escrow KTY balance after swap:",
      weiToEther(KTY_escrow_after_swap)
    );

    // uniswap reserve ratio

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
  });

  it("players press start for game 2", async () => {
    let gameId = 2;

    let {
      playerBlack,
      playerRed,
      kittyBlack,
      kittyRed
    } = await getterDB.getGamePlayers(gameId);

    await proxy.execute(
      "GameManager",
      setMessage(gameManager, "startGame", [
        gameId,
        randomValue(99),
        "512955438081049600613224346938352058409509756310147795204209859701881294"
      ]),
      {from: playerBlack}
    ).should.be.fulfilled;

    await timeout(3);

    await proxy.execute(
      "GameManager",
      setMessage(gameManager, "startGame", [
        gameId,
        randomValue(99),
        "24171491821178068054575826800486891805334952029503890331493652557302916"
      ]),
      {from: playerRed}
    ).should.be.fulfilled;

    console.log("\nGame Started: ", gameId);
    console.log("\nPlayerBlack: ", playerBlack);
    console.log("\nPlayerRed: ", playerRed);
  });

  it("players bet for game 2", async () => {
    let gameId = 2;
    let noOfBets = 100;
    let timeInterval = 2;

    let {
      playerBlack,
      playerRed,
      kittyBlack,
      kittyRed
    } = await getterDB.getGamePlayers(gameId);

    let supportersRed = await getterDB.getSupporters(gameId, playerRed);
    let supportersBlack = await getterDB.getSupporters(gameId, playerBlack);
    let totalBetAmount = 0;
    let betsBlack = [];
    let betsRed = [];
    let betAmount;
    let player;
    let supportedPlayer;
    let randomSupporter;

    let state = await getterDB.getGameState(gameId);
    console.log(state);

    for (let i = 0; i < noOfBets; i++) {
      let randomPlayer = randomValue(2);

      if (i == Number(noOfBets) - 1) {
        let block = await dateTime.getBlockTimeStamp();
        console.log(
          "\nWaiting to end as it last bet! \n BlockTime: ",
          formatDate(block)
        );

        let {endTime} = await getterDB.getGameTimes(gameId);
        console.log("\nEnd Time: ", endTime);

        while (block < endTime) {
          block = Math.floor(Date.now() / 1000);
          await timeout(3);
        }
      }
      //PlayerBlack
      if (randomPlayer == 1) {
        randomSupporter = randomValue(supportersBlack - 1);
        betAmount = randomValue(90);
        player = "playerBlack";
        supportedPlayer = accounts[Number(randomSupporter) + 10];

        await proxy.execute(
          "GameManager",
          setMessage(gameManager, "bet", [gameId, randomValue(98)]),
          {from: supportedPlayer, value: web3.utils.toWei(String(betAmount))}
        ).should.be.fulfilled;

        betsBlack.push(betAmount);
      }
      //PlayerRed
      else {
        randomSupporter = randomValue(Number(supportersRed) - 1);
        betAmount = randomValue(90);
        player = "playerRed";
        supportedPlayer = accounts[Number(randomSupporter) + 30];

        await proxy.execute(
          "GameManager",
          setMessage(gameManager, "bet", [gameId, randomValue(98)]),
          {from: supportedPlayer, value: web3.utils.toWei(String(betAmount))}
        ).should.be.fulfilled;

        betsRed.push(betAmount);
      }

      let betEvents = await betting.getPastEvents("BetPlaced", {
        filter: {gameId},
        fromBlock: 0,
        toBlock: "latest"
      });

      let betDetails = betEvents[betEvents.length - 1].returnValues;
      console.log(`\n==== NEW BET FOR ${player} ====`);
      console.log(
        " Amount:",
        web3.utils.fromWei(betDetails._lastBetAmount),
        "ETH"
      );
      console.log(" Bettor:", betDetails._bettor);
      console.log(" Attack Hash:", betDetails.attackHash);
      console.log(" Blocked?:", betDetails.isBlocked);
      console.log(
        ` Defense ${player}:`,
        betDetails.defenseLevelSupportedPlayer
      );
      console.log(" Defense Opponent:", betDetails.defenseLevelOpponent);

      let {endTime} = await getterDB.getGameTimes(gameId);

      if (player === "playerBlack") {
        let lastBetTimestamp = await betting.lastBetTimestamp(
          gameId,
          playerBlack
        );
        console.log(" Timestamp last Bet: ", formatDate(lastBetTimestamp));

        if (lastBetTimestamp >= endTime) {
          console.log("\nGame Ended during last bet!");
          break;
        }
      } else {
        let lastBetTimestamp = await betting.lastBetTimestamp(
          gameId,
          playerRed
        );
        console.log(" Timestamp last Bet: ", formatDate(lastBetTimestamp));

        if (lastBetTimestamp >= endTime) {
          console.log("\nGame Ended during last bet!");
          break;
        }
      }

      totalBetAmount = totalBetAmount + betAmount;
      await timeout(timeInterval);
    }

    console.log("\nBets Black: ", betsBlack);
    console.log("\nBets Red: ", betsRed);

    let honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `);
    console.log(
      `     InitialEtH: ${web3.utils.fromWei(
        honeyPotInfo.initialEth.toString()
      )}   `
    );
    console.log(
      `     TotalETH: ${web3.utils.fromWei(
        honeyPotInfo.ethTotal.toString()
      )}   `
    );
    console.log(
      `     TotalKTY: ${web3.utils.fromWei(
        honeyPotInfo.ktyTotal.toString()
      )}   `
    );
    console.log("=======================\n");
  });

  it("game is getting finalized", async () => {
    let gameId = 2;

    let {preStartTime, startTime, endTime} = await getterDB.getGameTimes(
      gameId
    );

    let {
      playerBlack,
      playerRed,
      kittyBlack,
      kittyRed
    } = await getterDB.getGamePlayers(gameId);

    let finalizer = accounts[20];

    console.log("\n==== WAITING FOR GAME OVER: ", formatDate(endTime));

    await timeout(2);

    await proxy.execute(
      "GameManager",
      setMessage(gameManager, "finalize", [gameId, randomValue(30)]),
      {from: finalizer}
    ).should.be.fulfilled;

    let gameEnd = await gameManager.getPastEvents("GameEnded", {
      filter: {gameId},
      fromBlock: 0,
      toBlock: "latest"
    });

    let state = await getterDB.getGameState(gameId);
    console.log(state);

    let {pointsBlack, pointsRed, loser} = gameEnd[0].returnValues;

    let winners = await getterDB.getWinners(gameId);

    let corner = winners.winner === playerBlack ? "Black Corner" : "Red Corner";

    console.log(`\n==== WINNER: ${corner} ==== `);
    console.log(`   Winner: ${winners.winner}   `);
    console.log(`   TopBettor: ${winners.topBettor}   `);
    console.log(`   SecondTopBettor: ${winners.secondTopBettor}   `);
    console.log("");
    console.log(`   Points Black: ${pointsBlack}   `);
    console.log(`   Point Red: ${pointsRed}   `);
    console.log("=======================\n");

    await timeout(3);

    let honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `);
    console.log(
      `     InitialEtH: ${web3.utils.fromWei(
        honeyPotInfo.initialEth.toString()
      )}   `
    );
    console.log(
      `     TotalETH: ${web3.utils.fromWei(
        honeyPotInfo.ethTotal.toString()
      )}   `
    );
    console.log(
      `     TotalKTY: ${web3.utils.fromWei(
        honeyPotInfo.ktyTotal.toString()
      )}   `
    );
    console.log("=======================\n");

    let finalHoneypot = await getterDB.getFinalHoneypot(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `);
    console.log(
      `     TotalETH: ${web3.utils.fromWei(
        finalHoneypot.totalEth.toString()
      )}   `
    );
    console.log(
      `     TotalKTY: ${web3.utils.fromWei(
        finalHoneypot.totalKty.toString()
      )}   `
    );
    console.log("=======================\n");
  });

  it("claims for everyone", async () => {
    let gameId = 2;

    let winners = await getterDB.getWinners(gameId);
    let winner = winners.winner;
    let numberOfSupporters;
    let incrementingNumber;
    let claimer;

    let winnerShare = await endowmentFund.getWinnerShare(
      gameId,
      winners.winner
    );
    console.log(
      "\nWinner withdrawing ",
      String(web3.utils.fromWei(winnerShare.winningsETH.toString())),
      "ETH"
    );
    console.log(
      "Winner withdrawing ",
      String(web3.utils.fromWei(winnerShare.winningsKTY.toString())),
      "KTY"
    );
    await proxy.execute(
      "EndowmentFund",
      setMessage(endowmentFund, "claim", [gameId]),
      {from: winners.winner}
    ).should.be.fulfilled;
    let withdrawalState = await endowmentFund.getWithdrawalState(
      gameId,
      winners.winner
    );
    console.log("Withdrew funds from Winner? ", withdrawalState);

    let honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `);
    console.log(
      `     InitialEtH: ${web3.utils.fromWei(
        honeyPotInfo.initialEth.toString()
      )}   `
    );
    console.log(
      `     TotalETH: ${web3.utils.fromWei(
        honeyPotInfo.ethTotal.toString()
      )}   `
    );
    console.log(
      `     TotalKTY: ${web3.utils.fromWei(
        honeyPotInfo.ktyTotal.toString()
      )}   `
    );
    console.log("=======================\n");

    await timeout(1);

    let topBettorsShare = await endowmentFund.getWinnerShare(
      gameId,
      winners.topBettor
    );
    console.log(
      "\nTop Bettor withdrawing ",
      String(web3.utils.fromWei(topBettorsShare.winningsETH.toString())),
      "ETH"
    );
    console.log(
      "Top Bettor withdrawing ",
      String(web3.utils.fromWei(topBettorsShare.winningsKTY.toString())),
      "KTY"
    );
    await proxy.execute(
      "EndowmentFund",
      setMessage(endowmentFund, "claim", [gameId]),
      {from: winners.topBettor}
    ).should.be.fulfilled;
    withdrawalState = await endowmentFund.getWithdrawalState(
      gameId,
      winners.topBettor
    );
    console.log("Withdrew funds from Top Bettor? ", withdrawalState);

    honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `);
    console.log(
      `     InitialEtH: ${web3.utils.fromWei(
        honeyPotInfo.initialEth.toString()
      )}   `
    );
    console.log(
      `     TotalETH: ${web3.utils.fromWei(
        honeyPotInfo.ethTotal.toString()
      )}   `
    );
    console.log(
      `     TotalKTY: ${web3.utils.fromWei(
        honeyPotInfo.ktyTotal.toString()
      )}   `
    );
    console.log("=======================\n");

    await timeout(1);

    let secondTopBettorsShare = await endowmentFund.getWinnerShare(
      gameId,
      winners.secondTopBettor
    );
    console.log(
      "\nSecond Top Bettor withdrawing ",
      String(web3.utils.fromWei(secondTopBettorsShare.winningsETH.toString())),
      "ETH"
    );
    console.log(
      "Second Top Bettor withdrawing ",
      String(web3.utils.fromWei(secondTopBettorsShare.winningsKTY.toString())),
      "KTY"
    );
    await proxy.execute(
      "EndowmentFund",
      setMessage(endowmentFund, "claim", [gameId]),
      {from: winners.secondTopBettor}
    ).should.be.fulfilled;
    withdrawalState = await endowmentFund.getWithdrawalState(
      gameId,
      winners.secondTopBettor
    );
    console.log("Withdrew funds from Second Top Bettor? ", withdrawalState);

    honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `);
    console.log(
      `     InitialEtH: ${web3.utils.fromWei(
        honeyPotInfo.initialEth.toString()
      )}   `
    );
    console.log(
      `     TotalETH: ${web3.utils.fromWei(
        honeyPotInfo.ethTotal.toString()
      )}   `
    );
    console.log(
      `     TotalKTY: ${web3.utils.fromWei(
        honeyPotInfo.ktyTotal.toString()
      )}   `
    );
    console.log("=======================\n");

    await timeout(1);

    let {
      playerBlack,
      playerRed,
      kittyBlack,
      kittyRed
    } = await getterDB.getGamePlayers(gameId);

    if (winner === playerBlack) {
      numberOfSupporters = await getterDB.getSupporters(gameId, playerBlack);
      incrementingNumber = 10;
    } else {
      numberOfSupporters = await getterDB.getSupporters(gameId, playerRed);
      incrementingNumber = 30;
    }

    for (let i = 0; i < numberOfSupporters; i++) {
      claimer = accounts[i + incrementingNumber];
      if (claimer === winners.topBettor) continue;
      else if (claimer === winners.secondTopBettor) continue;
      else {
        share = await endowmentFund.getWinnerShare(gameId, claimer);
        console.log(
          "\nClaimer withdrawing ",
          String(web3.utils.fromWei(share.winningsETH.toString())),
          "ETH"
        );
        console.log(
          "Claimer withdrawing ",
          String(web3.utils.fromWei(share.winningsKTY.toString())),
          "KTY"
        );
        if (
          Number(String(web3.utils.fromWei(share.winningsETH.toString()))) != 0
        ) {
          await proxy.execute(
            "EndowmentFund",
            setMessage(endowmentFund, "claim", [gameId]),
            {from: claimer}
          ).should.be.fulfilled;
          withdrawalState = await endowmentFund.getWithdrawalState(
            gameId,
            claimer
          );
          console.log("Withdrew funds from Claimer? ", withdrawalState);
        }

        honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

        console.log(`\n==== HONEYPOT INFO ==== `);
        console.log(
          `     InitialEtH: ${web3.utils.fromWei(
            honeyPotInfo.initialEth.toString()
          )}   `
        );
        console.log(
          `     TotalETH: ${web3.utils.fromWei(
            honeyPotInfo.ethTotal.toString()
          )}   `
        );
        console.log(
          `     TotalKTY: ${web3.utils.fromWei(
            honeyPotInfo.ktyTotal.toString()
          )}   `
        );
        console.log("=======================\n");

        await timeout(1);
      }

      let endowmentShare = await endowmentFund.getEndowmentShare(gameId);
      console.log(`\n==== ENDOWMENT INFO ==== `);
      console.log(
        "\nEndowmentShare: ",
        String(web3.utils.fromWei(endowmentShare.winningsETH.toString())),
        "ETH"
      );
      console.log(
        "EndowmentShare: ",
        String(web3.utils.fromWei(endowmentShare.winningsKTY.toString())),
        "KTY"
      );
      console.log("=======================\n");
    }
  });

  it("the loser can redeem his/her kitty, dynamic redemption fee is burnt to kittieHELL, replacement kitties become permanent ghosts in kittieHELL", async () => {
    let gameId = 2;
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

    let resurrectionFee = await gameStore.getKittieRedemptionFee(gameId);
    let resurrectionCost = resurrectionFee[1];

    const sacrificeKitties = [1017556, 413831, 889];

    for (let i = 0; i < sacrificeKitties.length; i++) {
      await cryptoKitties.mint(loser, sacrificeKitties[i]);
    }

    for (let i = 0; i < sacrificeKitties.length; i++) {
      await cryptoKitties.approve(kittieHellDB.address, sacrificeKitties[i], {
        from: loser
      });
    }

    // await kittieFightToken.approve(kittieHell.address, resurrectionCost, {
    //   from: loser
    // });

    let ether_resurrection_cost = resurrectionFee[0];
    console.log("KTY resurrection cost:", weiToEther(resurrectionCost));
    console.log(
      "ether needed for swap KTY resurrection:",
      weiToEther(ether_resurrection_cost)
    );

    await proxy.execute(
      "KittieHell",
      setMessage(kittieHell, "payForResurrection", [
        loserKitty,
        gameId,
        loser,
        sacrificeKitties
      ]),
      {from: loser, value: ether_resurrection_cost}
    );

    let owner = await cryptoKitties.ownerOf(loserKitty);

    if (owner === kittieHellDB.address) {
      console.log("Loser kitty became ghost in kittieHELL FOREVER :(");
    }

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
    console.log("\n==== UNISWAP RESERVE RATIO ===");
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
  });

  it("extends the epoch end time and pool available/dissolve time dynamically depending on gaming delay", async () => {
    const epoch_1_end_unix_extended = await timeFrame._epochEndTime(1);
    console.log(
      "extended epoch 0 end time in unix time:",
      epoch_1_end_unix_extended.toNumber()
    );
    const pool_1_extended_details = await withdrawPool.weeklyPools(1);
    console.log(
      "extended date available for claiming from this pool:",
      pool_1_extended_details.dateAvailable.toString()
    );
    console.log(
      "extended time when this pool is dissolved:",
      pool_1_extended_details.dateDissolved.toString()
    );
    console.log(
      "epoch 1 end time extended by:",
      epoch_1_end_unix_extended.toNumber() - initial_epoch_0_end_time
    );
    console.log(
      "pool 1 available time extended by:",
      pool_1_extended_details.dateAvailable.toNumber() -
        initial_pool_1_available_time.toNumber()
    );
    console.log(
      "pool 1 dissolve time extended by:",
      pool_1_extended_details.dateDissolved.toNumber() -
        initial_pool_1_dissolve_time.toNumber()
    );
  });

  it("adds ether to pool associated with the active epoch", async () => {
    const initialETH_pool_1_wei = await endowmentDB.getETHinPool(1);
    const initialETH_pool_1 = weiToEther(initialETH_pool_1_wei);
    console.log(
      "\n******************* Initial Ethers Distributed to Pool 1 *******************"
    );
    console.log("Initial ether in pool 1: " + initialETH_pool_1);
  });

  it("an eligible staker of superDao tokens can claim yield from the active pool", async () => {
    let timeTillClaiming = await withdrawPool.timeUntilClaiming();
    console.log(
      "Time (in seconds) till claiming from the current pool:",
      timeTillClaiming.toNumber()
    );
    await timeout(timeTillClaiming.toNumber());
    console.log("Available for claiming...");
    for (let i = 1; i < 4; i++) {
      await proxy.execute(
        "WithdrawPool",
        setMessage(withdrawPool, "claimYield", [1]),
        {
          from: accounts[i]
        }
      );
    }
    const pool_1_details = await withdrawPool.weeklyPools(1);
    const numberOfClaimers = pool_1_details.stakersClaimed.toNumber();
    const etherPaidOutPool1 = await withdrawPool.getEthPaidOut();
    console.log(
      "\n******************* SuperDao Tokens Stakers Claim from Pool 1 *******************"
    );
    console.log(
      "epoch ID associated with this pool",
      pool_1_details.epochID.toString()
    );
    console.log(
      "block number when this pool was created",
      pool_1_details.blockNumber.toString()
    );
    console.log(
      "initial ether available in this pool:",
      weiToEther(pool_1_details.initialETHAvailable)
    );
    console.log(
      "ether available in this pool:",
      weiToEther(pool_1_details.ETHAvailable)
    );
    console.log(
      "date available for claiming from this pool:",
      pool_1_details.dateAvailable.toString()
    );
    console.log(
      "whether initial ether has been distributed to this pool:",
      pool_1_details.initialETHadded
    );
    console.log(
      "time when this pool is dissolved:",
      pool_1_details.dateDissolved.toString()
    );
    console.log(
      "Number of stakers who have claimed from this pool:",
      numberOfClaimers
    );
    console.log("ether paid out by pool 1:", weiToEther(etherPaidOutPool1));
    console.log("-------- Stakers who have claimed from this pool ------");

    let claimers = await withdrawPool.getAllClaimersForPool(1);
    console.log(claimers);

    console.log("********************************************************\n");
  });

  it("an investor can burn his Ethie Token NFT and receive ethers locked and interest accumulated", async () => {
    let tokenID = 3;

    let newLock = await earningsTracker.getPastEvents("EtherLocked", {
      fromBlock: 0,
      toBlock: "latest"
    });

    newLock.map(async e => {
      console.log("\n==== NEW LOCK HAPPENED ===");
      console.log("    Funder ", e.returnValues.funder);
      console.log("    TokenID ", e.returnValues.ethieTokenID);
      console.log("    Generation ", e.returnValues.generation);
      console.log("========================\n");
    });

    let owner = await ethieToken.ownerOf(tokenID);
    console.log(owner);

    let valueReturned = await earningsTrackerDB.calculateTotal(
      web3.utils.toWei("3"),
      0
    );
    console.log(web3.utils.fromWei(valueReturned.toString()));
    let burn_fee = await earningsTrackerDB.KTYforBurnEthie(tokenID);
    let ether_burn_ethie = burn_fee[0];
    let ktyFee = burn_fee[1];

    await ethieToken.approve(earningsTracker.address, tokenID, {from: owner});

    console.log("KTY burn ethie fee:", weiToEther(ktyFee));
    console.log(
      "ether needed for swap KTY burn ethie fee:",
      weiToEther(ether_burn_ethie)
    );

    // burn ethie
    await proxy.execute(
      "EarningsTracker",
      setMessage(earningsTracker, "burnNFT", [tokenID]),
      {
        from: owner,
        value: ether_burn_ethie
      }
    );
    let newBurn = await earningsTracker.getPastEvents("EthieTokenBurnt", {
      fromBlock: 0,
      toBlock: "latest"
    });

    newBurn.map(async e => {
      console.log("\n==== NEW BURN HAPPENED ===");
      console.log("    Burner ", e.returnValues.burner);
      console.log("    TokenID ", e.returnValues.ethieTokenID);
      console.log("    Generation ", e.returnValues.generation);
      console.log("    Investment ", e.returnValues.principalEther);
      console.log("    Interest ", e.returnValues.interestPaid);
      console.log("========================\n");
    });

    // uniswap reserve ratio
    console.log("\n==== UNISWAP RESERVE RATIO ===");
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
  });

  it("sets new epoch when finalized", async () => {
    let _wait = await timeFrame.timeUntilEpochEnd(1);
    _wait = _wait.toNumber();
    console.log(_wait);
    await timeout(_wait);
    // evm.increaseTime(web3, _wait)
    await proxy.executeScheduledJobs();
    console.log("Hi, new epoch!");

    const epoch_2_start_unix = await timeFrame._epochStartTime(2);
    const epoch_2_end_unix = await timeFrame._epochEndTime(2);
    initial_epoch_2_end_time = epoch_2_end_unix;
    console.log(
      "epoch 2 start time in unix time:",
      epoch_2_start_unix.toNumber()
    );
    const epoch_2_start_human_readable = await timeFrame.epochStartTime(2);
    const epoch_2_end_human_readable = await timeFrame.epochEndTime(2);
    console.log("\n******************* Epoch 2 Start Time *****************");
    console.log(
      "Date:",
      epoch_2_start_human_readable[0].toNumber() +
        "-" +
        epoch_2_start_human_readable[1].toNumber() +
        "-" +
        epoch_2_start_human_readable[2].toNumber(),
      " ",
      "Time:",
      epoch_2_start_human_readable[3].toNumber() +
        ":" +
        epoch_2_start_human_readable[4].toNumber() +
        ":" +
        epoch_2_start_human_readable[5].toNumber()
    );
    console.log("\n******************* Epoch 2 End Time *******************");
    console.log(
      "Date:",
      epoch_2_end_human_readable[0].toNumber() +
        "-" +
        epoch_2_end_human_readable[1].toNumber() +
        "-" +
        epoch_2_end_human_readable[2].toNumber(),
      " ",
      "Time:",
      epoch_2_end_human_readable[3].toNumber() +
        ":" +
        epoch_2_end_human_readable[4].toNumber() +
        ":" +
        epoch_2_end_human_readable[5].toNumber()
    );
    console.log("********************************************************\n");
  });

  it("creates a new pool", async () => {
    const numberOfDissolvedPools = await withdrawPool.getNumberOfDissolvedPools();
    console.log(
      "Total number of dissolved Pools:",
      numberOfDissolvedPools.toNumber()
    );
    const numberOfPools = await withdrawPool.getTotalNumberOfPools();
    console.log("Total number of pools:", numberOfPools.toNumber());

    console.log("************* Details of New Pool Created ************");
    const pool_2_details = await withdrawPool.weeklyPools(2);
    const numberOfClaimers = pool_2_details.stakersClaimed.toNumber();
    console.log(
      "epoch ID associated with this pool",
      pool_2_details.epochID.toString()
    );
    console.log(
      "block number when this pool was created",
      pool_2_details.blockNumber.toString()
    );
    console.log(
      "initial ether available in this pool:",
      pool_2_details.initialETHAvailable.toString()
    );
    console.log(
      "ether remaining in this pool:",
      pool_2_details.ETHAvailable.toString()
    );
    console.log(
      "date available for claiming from this pool:",
      pool_2_details.dateAvailable.toString()
    );
    console.log(
      "whether initial ether has been distributed to this pool:",
      pool_2_details.initialETHadded
    );
    console.log(
      "time when this pool is dissolved:",
      pool_2_details.dateDissolved.toString()
    );
    console.log(
      "time (in seconds) till this pool will be dissolved: ",
      pool_2_details.dateDissolved.toNumber() - Math.floor(Date.now() / 1000)
    );
    console.log(
      "Number of stakers who have claimed from this pool:",
      numberOfClaimers
    );

    console.log("-------- Stakers who have claimed from this pool ------");

    let claimers = await withdrawPool.getAllClaimersForPool(2);
    console.log(claimers);

    initial_pool_2_available_time = pool_2_details.dateAvailable;
    initial_pool_2_dissolve_time = pool_2_details.dateDissolved;

    console.log("********************************************************\n");
  });

  // ============================== Epoch 2 ==============================
  it("Starts game 3 in Epoch 2", async () => {
    console.log("\n============================== EPOCH 2 ==============================")
    console.log(
      "\n$$$$$$$$$$$$$$$$$$$$$$$$$$$$ GAME 3 $$$$$$$$$$$$$$$$$$$$$$$$$$$$"
    );
    let users = 40;

    for (let i = 1; i <= users; i++) {
      let isRegistered = await register.isRegistered(accounts[i]);
      assert.isTrue(isRegistered);
    }
  });

  it("mints kitties for 2 users", async () => {
    let users = 8;

    let kitties = [334, 1011, 1555118, 1267914, 454555, 343, 6676, 2121];
    let cividIds = [1, 2, 3, 4, 5, 6, 7, 8];

    await cryptoKitties.mint(accounts[3], kitties[2], {from: accounts[0]})
      .should.be.fulfilled;
    await cryptoKitties.approve(kittieHell.address, kitties[2], {
      from: accounts[3]
    }).should.be.fulfilled;
    await proxy.execute(
      "Register",
      setMessage(register, "verifyAccount", [cividIds[2]]),
      {from: accounts[3]}
    ).should.be.fulfilled;

    console.log(`New Player ${accounts[3]} with Kitty ${kitties[2]}`);

    await cryptoKitties.mint(accounts[4], kitties[3], {from: accounts[0]})
      .should.be.fulfilled;
    await cryptoKitties.approve(kittieHell.address, kitties[3], {
      from: accounts[4]
    }).should.be.fulfilled;
    await proxy.execute(
      "Register",
      setMessage(register, "verifyAccount", [cividIds[3]]),
      {from: accounts[4]}
    ).should.be.fulfilled;

    console.log(`New Player ${accounts[4]} with Kitty ${kitties[3]}`);
  });

  it("superDaoToken holders stake superDaoToken, and investors invest via EthieToken NFTs", async () => {
    const stakedTokens = new BigNumber(
      web3.utils.toWei("10000", "ether") //
    );

    for (let i = 9; i < 12; i++) {
      await superDaoToken.transfer(accounts[i], stakedTokens, {
        from: accounts[0]
      });
      let balBefore = await superDaoToken.balanceOf(accounts[i]);
      console.log(
        `Balance of staker ${i} before staking:`,
        weiToEther(balBefore)
      );

      await superDaoToken.approve(staking.address, stakedTokens, {
        from: accounts[i]
      });

      await staking.stake(stakedTokens, {from: accounts[i]});

      let balStaking = await superDaoToken.balanceOf(staking.address);
      console.log(
        "Balance of staking contract after staking:",
        weiToEther(balStaking)
      );

      let balAfter = await superDaoToken.balanceOf(accounts[i]);
      console.log(
        `Balance of staker ${i} after staking:`,
        weiToEther(balAfter)
      );
    }

    for (let i = 7; i < 9; i++) {
      let ethAmount = web3.utils.toWei(String(1 + i), "ether");
      console.log(ethAmount.toString());
      console.log(accounts[i]);
      await proxy.execute(
        "EarningsTracker",
        setMessage(earningsTracker, "lockETH", []),
        {
          gas: 900000,
          from: accounts[i],
          value: ethAmount.toString()
        }
      );
      let number_ethieToken = await ethieToken.balanceOf(accounts[i]);
      let ethieTokenID = await ethieToken.tokenOfOwnerByIndex(accounts[i], 0);
      ethieTokenID = ethieTokenID.toNumber();
      let tokenProperties = await ethieToken.properties(ethieTokenID);
      let ethAmountToken = weiToEther(tokenProperties.ethAmount);
      let generationToken = tokenProperties.generation.toNumber();
      let lockTime = tokenProperties.lockPeriod.toString();
      console.log(`\n************** Investor: accounts${i} **************`);
      console.log("EthieToken ID:", ethieTokenID);
      console.log("Oringinal ether amount held in this token:", ethAmountToken);
      console.log("This token's generation:", generationToken);
      console.log("This token's lock time(in seconds):", lockTime);
      console.log("****************************************************\n");
    }
  });

  it("manual matches kitties", async () => {
    let kittyRed = 1555118;
    let kittyBlack = 1267914;
    let gameStartTimeGiven = Math.floor(Date.now() / 1000) + 70; //now + 80 secs, so for prestart 30 secs 50 secs to participate

    //Must take owners of Kitties here
    let playerBlack = await cryptoKitties.ownerOf(kittyBlack);
    let playerRed = await cryptoKitties.ownerOf(kittyRed);

    console.log("PlayerBlack: ", playerBlack);
    console.log("PlayerRed: ", playerRed);

    await proxy.execute(
      "GameCreation",
      setMessage(gameCreation, "manualMatchKitties", [
        playerRed,
        playerBlack,
        kittyRed,
        kittyBlack,
        gameStartTimeGiven
      ]),
      {from: accounts[0]}
    ).should.be.fulfilled;

    await timeout(3);

    let newGameEvents = await gameCreation.getPastEvents("NewGame", {
      fromBlock: 0,
      toBlock: "latest"
    });

    newGameEvents.map(async e => {
      let gameInfo = await getterDB.getGameTimes(e.returnValues.gameId);

      console.log("\n==== NEW GAME CREATED ===");
      console.log("    GameId ", e.returnValues.gameId);
      console.log("    Red Fighter ", e.returnValues.kittieRed);
      console.log("    Red Player ", e.returnValues.playerRed);
      console.log("    Black Fighter ", e.returnValues.kittieBlack);
      console.log("    Black Player ", e.returnValues.playerBlack);
      console.log("    Prestart Time:", formatDate(gameInfo.preStartTime));
      console.log("    Start Time ", formatDate(e.returnValues.gameStartTime));
      console.log("    End Time:", formatDate(gameInfo.endTime));
      console.log("========================\n");
    });
    //Take both Kitties game to see it is the same
    let gameId5 = await getterDB.getGameOfKittie(kittyRed);
    let gameId6 = await getterDB.getGameOfKittie(kittyBlack);

    if (gameId5 === gameId6) console.log("\nGameId: ", gameId5);

    //Take gameStartTime from blockchain to see if it is same as the one we gave
    let {preStartTime, startTime, endTime} = await getterDB.getGameTimes(
      gameId5
    );

    console.log("\nGame PreStart Time: ", formatDate(preStartTime));
    console.log("\nGame Start Time in UTC: ", formatDate(startTime));
    console.log("\nGame End Time: ", formatDate(endTime));
  });

  it("participates users for game 3", async () => {
    let gameId = 3;
    let blackParticipators = 6;
    let redParticipators = 6;
    let timeInterval = 2;

    let supportersForRed = [];
    let supportersForBlack = [];
    let ticketFee = await gameStore.getTicketFee(gameId);

    let KTY_escrow_before_swap = await kittieFightToken.balanceOf(
      escrow.address
    );

    let {
      playerBlack,
      playerRed,
      kittyBlack,
      kittyRed
    } = await getterDB.getGamePlayers(gameId);
    let participator;

    //accounts 10-29 can be supporters for black
    let blacks = Number(blackParticipators) + 10;
    let reds = Number(redParticipators) + 30;

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

    for (let i = 10; i < blacks; i++) {
      let participate_fee = await gameStore.getTicketFee(3);
      let ether_participate = participate_fee[0];
      let kty_participate = participate_fee[1];
      console.log(
        "ether needed for swapping participate_fee in kty:",
        weiToEther(ether_participate)
      );
      console.log("participate_fee in kty:", weiToEther(kty_participate));
      participator = accounts[i];
      await proxy.execute(
        "GameManager",
        setMessage(gameManager, "participate", [gameId, playerBlack]),
        {from: participator, value: ether_participate}
      );
      console.log("\nNew Participator for playerBlack: ", participator);
      supportersForBlack.push(participator);

      await timeout(timeInterval);
    }

    //accounts 30-49 can be supporters for red
    for (let j = 30; j < reds; j++) {
      participator = accounts[j];
      if (j == Number(reds) - 1) {
        let block = await dateTime.getBlockTimeStamp();
        console.log("\nblocktime: ", formatDate(block));

        let {preStartTime} = await getterDB.getGameTimes(gameId);

        while (block < preStartTime) {
          block = Math.floor(Date.now() / 1000);
          await timeout(3);
        }
      }
      let participate_fee = await gameStore.getTicketFee(3);
      let ether_participate = participate_fee[0];
      let kty_participate = participate_fee[1];
      console.log(
        "ether needed for swapping participate_fee in kty:",
        weiToEther(ether_participate)
      );
      console.log("participate_fee in kty:", weiToEther(kty_participate));

      await proxy.execute(
        "GameManager",
        setMessage(gameManager, "participate", [gameId, playerRed]),
        {from: participator, value: ether_participate}
      );
      console.log("\nNew Participator for playerRed: ", participator);
      supportersForRed.push(participator);

      await timeout(timeInterval);
    }

    console.log("\nSupporters for Black: ", supportersForBlack);
    console.log("\nSupporters for Red: ", supportersForRed);

    let newSwapEvents = await endowmentFund.getPastEvents("EthSwappedforKTY", {
      fromBlock: 0,
      toBlock: "latest"
    });

    newSwapEvents.map(async e => {
      console.log("\n==== NEW Swap CREATED ===");
      console.log("    sender ", e.returnValues.sender);
      console.log("    ether for swap ", e.returnValues.ethAmount);
      console.log("    KTY swapped ", e.returnValues.ktyAmount);
      console.log("    ether receiver ", e.returnValues.receiver);
      console.log("========================\n");
    });

    // escrow KTY balance
    let KTY_escrow_after_swap = await kittieFightToken.balanceOf(
      escrow.address
    );
    console.log(
      "escrow KTY balance before swap:",
      weiToEther(KTY_escrow_before_swap)
    );
    console.log(
      "escrow KTY balance after swap:",
      weiToEther(KTY_escrow_after_swap)
    );

    // uniswap reserve ratio

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
  });

  it("players press start for game 3", async () => {
    let gameId = 3;

    let {
      playerBlack,
      playerRed,
      kittyBlack,
      kittyRed
    } = await getterDB.getGamePlayers(gameId);

    await proxy.execute(
      "GameManager",
      setMessage(gameManager, "startGame", [
        gameId,
        randomValue(99),
        "512955438081049600613224346938352058409509756310147795204209859701881294"
      ]),
      {from: playerBlack}
    ).should.be.fulfilled;

    await timeout(3);

    await proxy.execute(
      "GameManager",
      setMessage(gameManager, "startGame", [
        gameId,
        randomValue(99),
        "24171491821178068054575826800486891805334952029503890331493652557302916"
      ]),
      {from: playerRed}
    ).should.be.fulfilled;

    console.log("\nGame Started: ", gameId);
    console.log("\nPlayerBlack: ", playerBlack);
    console.log("\nPlayerRed: ", playerRed);
  });

  it("players bet for game 3", async () => {
    let gameId = 3;
    let noOfBets = 100;
    let timeInterval = 2;

    let {
      playerBlack,
      playerRed,
      kittyBlack,
      kittyRed
    } = await getterDB.getGamePlayers(gameId);

    let supportersRed = await getterDB.getSupporters(gameId, playerRed);
    let supportersBlack = await getterDB.getSupporters(gameId, playerBlack);
    let totalBetAmount = 0;
    let betsBlack = [];
    let betsRed = [];
    let betAmount;
    let player;
    let supportedPlayer;
    let randomSupporter;

    let state = await getterDB.getGameState(gameId);
    console.log(state);

    for (let i = 0; i < noOfBets; i++) {
      let randomPlayer = randomValue(2);

      if (i == Number(noOfBets) - 1) {
        let block = await dateTime.getBlockTimeStamp();
        console.log(
          "\nWaiting to end as it last bet! \n BlockTime: ",
          formatDate(block)
        );

        let {endTime} = await getterDB.getGameTimes(gameId);
        console.log("\nEnd Time: ", endTime);

        while (block < endTime) {
          block = Math.floor(Date.now() / 1000);
          await timeout(3);
        }
      }
      //PlayerBlack
      if (randomPlayer == 1) {
        randomSupporter = randomValue(supportersBlack - 1);
        betAmount = randomValue(100);
        player = "playerBlack";
        supportedPlayer = accounts[Number(randomSupporter) + 10];

        await proxy.execute(
          "GameManager",
          setMessage(gameManager, "bet", [gameId, randomValue(98)]),
          {from: supportedPlayer, value: web3.utils.toWei(String(betAmount))}
        ).should.be.fulfilled;

        betsBlack.push(betAmount);
      }
      //PlayerRed
      else {
        randomSupporter = randomValue(Number(supportersRed) - 1);
        betAmount = randomValue(100);
        player = "playerRed";
        supportedPlayer = accounts[Number(randomSupporter) + 30];

        await proxy.execute(
          "GameManager",
          setMessage(gameManager, "bet", [gameId, randomValue(98)]),
          {from: supportedPlayer, value: web3.utils.toWei(String(betAmount))}
        ).should.be.fulfilled;

        betsRed.push(betAmount);
      }

      let betEvents = await betting.getPastEvents("BetPlaced", {
        filter: {gameId},
        fromBlock: 0,
        toBlock: "latest"
      });

      let betDetails = betEvents[betEvents.length - 1].returnValues;
      console.log(`\n==== NEW BET FOR ${player} ====`);
      console.log(
        " Amount:",
        web3.utils.fromWei(betDetails._lastBetAmount),
        "ETH"
      );
      console.log(" Bettor:", betDetails._bettor);
      console.log(" Attack Hash:", betDetails.attackHash);
      console.log(" Blocked?:", betDetails.isBlocked);
      console.log(
        ` Defense ${player}:`,
        betDetails.defenseLevelSupportedPlayer
      );
      console.log(" Defense Opponent:", betDetails.defenseLevelOpponent);

      let {endTime} = await getterDB.getGameTimes(gameId);

      if (player === "playerBlack") {
        let lastBetTimestamp = await betting.lastBetTimestamp(
          gameId,
          playerBlack
        );
        console.log(" Timestamp last Bet: ", formatDate(lastBetTimestamp));

        if (lastBetTimestamp >= endTime) {
          console.log("\nGame Ended during last bet!");
          break;
        }
      } else {
        let lastBetTimestamp = await betting.lastBetTimestamp(
          gameId,
          playerRed
        );
        console.log(" Timestamp last Bet: ", formatDate(lastBetTimestamp));

        if (lastBetTimestamp >= endTime) {
          console.log("\nGame Ended during last bet!");
          break;
        }
      }

      totalBetAmount = totalBetAmount + betAmount;
      await timeout(timeInterval);
    }

    console.log("\nBets Black: ", betsBlack);
    console.log("\nBets Red: ", betsRed);

    let honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `);
    console.log(
      `     InitialEtH: ${web3.utils.fromWei(
        honeyPotInfo.initialEth.toString()
      )}   `
    );
    console.log(
      `     TotalETH: ${web3.utils.fromWei(
        honeyPotInfo.ethTotal.toString()
      )}   `
    );
    console.log(
      `     TotalKTY: ${web3.utils.fromWei(
        honeyPotInfo.ktyTotal.toString()
      )}   `
    );
    console.log("=======================\n");
  });

  it("game is getting finalized", async () => {
    let gameId = 3;

    let {preStartTime, startTime, endTime} = await getterDB.getGameTimes(
      gameId
    );

    let {
      playerBlack,
      playerRed,
      kittyBlack,
      kittyRed
    } = await getterDB.getGamePlayers(gameId);

    let finalizer = accounts[20];

    console.log("\n==== WAITING FOR GAME OVER: ", formatDate(endTime));

    await timeout(2);

    await proxy.execute(
      "GameManager",
      setMessage(gameManager, "finalize", [gameId, randomValue(30)]),
      {from: finalizer}
    ).should.be.fulfilled;

    let gameEnd = await gameManager.getPastEvents("GameEnded", {
      filter: {gameId},
      fromBlock: 0,
      toBlock: "latest"
    });

    let state = await getterDB.getGameState(gameId);
    console.log(state);

    let {pointsBlack, pointsRed, loser} = gameEnd[0].returnValues;

    let winners = await getterDB.getWinners(gameId);

    let corner = winners.winner === playerBlack ? "Black Corner" : "Red Corner";

    console.log(`\n==== WINNER: ${corner} ==== `);
    console.log(`   Winner: ${winners.winner}   `);
    console.log(`   TopBettor: ${winners.topBettor}   `);
    console.log(`   SecondTopBettor: ${winners.secondTopBettor}   `);
    console.log("");
    console.log(`   Points Black: ${pointsBlack}   `);
    console.log(`   Point Red: ${pointsRed}   `);
    console.log("=======================\n");

    await timeout(3);

    let honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `);
    console.log(
      `     InitialEtH: ${web3.utils.fromWei(
        honeyPotInfo.initialEth.toString()
      )}   `
    );
    console.log(
      `     TotalETH: ${web3.utils.fromWei(
        honeyPotInfo.ethTotal.toString()
      )}   `
    );
    console.log(
      `     TotalKTY: ${web3.utils.fromWei(
        honeyPotInfo.ktyTotal.toString()
      )}   `
    );
    console.log("=======================\n");

    let finalHoneypot = await getterDB.getFinalHoneypot(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `);
    console.log(
      `     TotalETH: ${web3.utils.fromWei(
        finalHoneypot.totalEth.toString()
      )}   `
    );
    console.log(
      `     TotalKTY: ${web3.utils.fromWei(
        finalHoneypot.totalKty.toString()
      )}   `
    );
    console.log("=======================\n");
  });

  it("claims for everyone", async () => {
    let gameId = 3;

    let winners = await getterDB.getWinners(gameId);
    let winner = winners.winner;
    let numberOfSupporters;
    let incrementingNumber;
    let claimer;

    let winnerShare = await endowmentFund.getWinnerShare(
      gameId,
      winners.winner
    );
    console.log(
      "\nWinner withdrawing ",
      String(web3.utils.fromWei(winnerShare.winningsETH.toString())),
      "ETH"
    );
    console.log(
      "Winner withdrawing ",
      String(web3.utils.fromWei(winnerShare.winningsKTY.toString())),
      "KTY"
    );
    await proxy.execute(
      "EndowmentFund",
      setMessage(endowmentFund, "claim", [gameId]),
      {from: winners.winner}
    ).should.be.fulfilled;
    let withdrawalState = await endowmentFund.getWithdrawalState(
      gameId,
      winners.winner
    );
    console.log("Withdrew funds from Winner? ", withdrawalState);

    let honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `);
    console.log(
      `     InitialEtH: ${web3.utils.fromWei(
        honeyPotInfo.initialEth.toString()
      )}   `
    );
    console.log(
      `     TotalETH: ${web3.utils.fromWei(
        honeyPotInfo.ethTotal.toString()
      )}   `
    );
    console.log(
      `     TotalKTY: ${web3.utils.fromWei(
        honeyPotInfo.ktyTotal.toString()
      )}   `
    );
    console.log("=======================\n");

    await timeout(1);

    let topBettorsShare = await endowmentFund.getWinnerShare(
      gameId,
      winners.topBettor
    );
    console.log(
      "\nTop Bettor withdrawing ",
      String(web3.utils.fromWei(topBettorsShare.winningsETH.toString())),
      "ETH"
    );
    console.log(
      "Top Bettor withdrawing ",
      String(web3.utils.fromWei(topBettorsShare.winningsKTY.toString())),
      "KTY"
    );
    await proxy.execute(
      "EndowmentFund",
      setMessage(endowmentFund, "claim", [gameId]),
      {from: winners.topBettor}
    ).should.be.fulfilled;
    withdrawalState = await endowmentFund.getWithdrawalState(
      gameId,
      winners.topBettor
    );
    console.log("Withdrew funds from Top Bettor? ", withdrawalState);

    honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `);
    console.log(
      `     InitialEtH: ${web3.utils.fromWei(
        honeyPotInfo.initialEth.toString()
      )}   `
    );
    console.log(
      `     TotalETH: ${web3.utils.fromWei(
        honeyPotInfo.ethTotal.toString()
      )}   `
    );
    console.log(
      `     TotalKTY: ${web3.utils.fromWei(
        honeyPotInfo.ktyTotal.toString()
      )}   `
    );
    console.log("=======================\n");

    await timeout(1);

    let secondTopBettorsShare = await endowmentFund.getWinnerShare(
      gameId,
      winners.secondTopBettor
    );
    console.log(
      "\nSecond Top Bettor withdrawing ",
      String(web3.utils.fromWei(secondTopBettorsShare.winningsETH.toString())),
      "ETH"
    );
    console.log(
      "Second Top Bettor withdrawing ",
      String(web3.utils.fromWei(secondTopBettorsShare.winningsKTY.toString())),
      "KTY"
    );
    await proxy.execute(
      "EndowmentFund",
      setMessage(endowmentFund, "claim", [gameId]),
      {from: winners.secondTopBettor}
    ).should.be.fulfilled;
    withdrawalState = await endowmentFund.getWithdrawalState(
      gameId,
      winners.secondTopBettor
    );
    console.log("Withdrew funds from Second Top Bettor? ", withdrawalState);

    honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `);
    console.log(
      `     InitialEtH: ${web3.utils.fromWei(
        honeyPotInfo.initialEth.toString()
      )}   `
    );
    console.log(
      `     TotalETH: ${web3.utils.fromWei(
        honeyPotInfo.ethTotal.toString()
      )}   `
    );
    console.log(
      `     TotalKTY: ${web3.utils.fromWei(
        honeyPotInfo.ktyTotal.toString()
      )}   `
    );
    console.log("=======================\n");

    await timeout(1);

    let {
      playerBlack,
      playerRed,
      kittyBlack,
      kittyRed
    } = await getterDB.getGamePlayers(gameId);

    if (winner === playerBlack) {
      numberOfSupporters = await getterDB.getSupporters(gameId, playerBlack);
      incrementingNumber = 10;
    } else {
      numberOfSupporters = await getterDB.getSupporters(gameId, playerRed);
      incrementingNumber = 30;
    }

    for (let i = 0; i < numberOfSupporters; i++) {
      claimer = accounts[i + incrementingNumber];
      if (claimer === winners.topBettor) continue;
      else if (claimer === winners.secondTopBettor) continue;
      else {
        share = await endowmentFund.getWinnerShare(gameId, claimer);
        console.log(
          "\nClaimer withdrawing ",
          String(web3.utils.fromWei(share.winningsETH.toString())),
          "ETH"
        );
        console.log(
          "Claimer withdrawing ",
          String(web3.utils.fromWei(share.winningsKTY.toString())),
          "KTY"
        );
        if (
          Number(String(web3.utils.fromWei(share.winningsETH.toString()))) != 0
        ) {
          await proxy.execute(
            "EndowmentFund",
            setMessage(endowmentFund, "claim", [gameId]),
            {from: claimer}
          ).should.be.fulfilled;
          withdrawalState = await endowmentFund.getWithdrawalState(
            gameId,
            claimer
          );
          console.log("Withdrew funds from Claimer? ", withdrawalState);
        }

        honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

        console.log(`\n==== HONEYPOT INFO ==== `);
        console.log(
          `     InitialEtH: ${web3.utils.fromWei(
            honeyPotInfo.initialEth.toString()
          )}   `
        );
        console.log(
          `     TotalETH: ${web3.utils.fromWei(
            honeyPotInfo.ethTotal.toString()
          )}   `
        );
        console.log(
          `     TotalKTY: ${web3.utils.fromWei(
            honeyPotInfo.ktyTotal.toString()
          )}   `
        );
        console.log("=======================\n");

        await timeout(1);
      }

      let endowmentShare = await endowmentFund.getEndowmentShare(gameId);
      console.log(`\n==== ENDOWMENT INFO ==== `);
      console.log(
        "\nEndowmentShare: ",
        String(web3.utils.fromWei(endowmentShare.winningsETH.toString())),
        "ETH"
      );
      console.log(
        "EndowmentShare: ",
        String(web3.utils.fromWei(endowmentShare.winningsKTY.toString())),
        "KTY"
      );
      console.log("=======================\n");
    }
  });

  it("the loser can redeem his/her kitty, dynamic redemption fee is burnt to kittieHELL, replacement kitties become permanent ghosts in kittieHELL", async () => {
    let gameId = 3;
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

    let resurrectionFee = await gameStore.getKittieRedemptionFee(gameId);
    let resurrectionCost = resurrectionFee[1];

    const sacrificeKitties = [1017557, 413832, 899];

    for (let i = 0; i < sacrificeKitties.length; i++) {
      await cryptoKitties.mint(loser, sacrificeKitties[i]);
    }

    for (let i = 0; i < sacrificeKitties.length; i++) {
      await cryptoKitties.approve(kittieHellDB.address, sacrificeKitties[i], {
        from: loser
      });
    }

    // await kittieFightToken.approve(kittieHell.address, resurrectionCost, {
    //   from: loser
    // });

    let ether_resurrection_cost = resurrectionFee[0];
    console.log("KTY resurrection cost:", weiToEther(resurrectionCost));
    console.log(
      "ether needed for swap KTY resurrection:",
      weiToEther(ether_resurrection_cost)
    );

    await proxy.execute(
      "KittieHell",
      setMessage(kittieHell, "payForResurrection", [
        loserKitty,
        gameId,
        loser,
        sacrificeKitties
      ]),
      {from: loser, value: ether_resurrection_cost}
    );

    let owner = await cryptoKitties.ownerOf(loserKitty);

    if (owner === kittieHellDB.address) {
      console.log("Loser kitty became ghost in kittieHELL FOREVER :(");
    }

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
    console.log("\n==== UNISWAP RESERVE RATIO ===");
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
  });

  it("extends the epoch end time and pool available/dissolve time dynamically depending on gaming delay", async () => {
    const epoch_2_end_unix_extended = await timeFrame._epochEndTime(2);
    console.log(
      "extended epoch 2 end time in unix time:",
      epoch_2_end_unix_extended.toNumber()
    );
    const pool_2_extended_details = await withdrawPool.weeklyPools(2);
    console.log(
      "extended date available for claiming from this pool:",
      pool_2_extended_details.dateAvailable.toString()
    );
    console.log(
      "extended time when this pool is dissolved:",
      pool_2_extended_details.dateDissolved.toString()
    );
    console.log(
      "epoch 2 end time extended by:",
      epoch_2_end_unix_extended.toNumber() - initial_epoch_2_end_time.toNumber()
    );
    console.log(
      "pool 2 available time extended by:",
      pool_2_extended_details.dateAvailable.toNumber() -
        initial_pool_2_available_time.toNumber()
    );
    console.log(
      "pool 2 dissolve time extended by:",
      pool_2_extended_details.dateDissolved.toNumber() -
        initial_pool_2_dissolve_time.toNumber()
    );
  });

  it("adds ether to pool associated with the active epoch", async () => {
    const initialETH_pool_2_wei = await endowmentDB.getETHinPool(2);
    const initialETH_pool_2 = weiToEther(initialETH_pool_2_wei);
    console.log(
      "\n******************* Initial Ethers Distributed to Pool 2 *******************"
    );
    console.log("Initial ether in pool 2: " + initialETH_pool_2);
  });

  it("an eligible staker of superDao tokens can claim yield from the active pool", async () => {
    let timeTillClaiming = await withdrawPool.timeUntilClaiming();
    console.log(
      "Time (in seconds) till claiming from the current pool:",
      timeTillClaiming.toNumber()
    );
    await timeout(timeTillClaiming.toNumber());
    console.log("Available for claiming...");
    for (let i = 5; i < 8; i++) {
      await proxy.execute(
        "WithdrawPool",
        setMessage(withdrawPool, "claimYield", [2]),
        {
          from: accounts[i]
        }
      );
    }
    const pool_2_details = await withdrawPool.weeklyPools(2);
    const numberOfClaimers = pool_2_details.stakersClaimed.toNumber();
    const etherPaidOutPool2 = await withdrawPool.getEthPaidOut();
    console.log(
      "\n******************* SuperDao Tokens Stakers Claim from Pool 2 *******************"
    );
    console.log(
      "epoch ID associated with this pool",
      pool_2_details.epochID.toString()
    );
    console.log(
      "block number when this pool was created",
      pool_2_details.blockNumber.toString()
    );
    console.log(
      "initial ether available in this pool:",
      weiToEther(pool_2_details.initialETHAvailable)
    );
    console.log(
      "ether available in this pool:",
      weiToEther(pool_2_details.ETHAvailable)
    );
    console.log(
      "date available for claiming from this pool:",
      pool_2_details.dateAvailable.toString()
    );
    console.log(
      "whether initial ether has been distributed to this pool:",
      pool_2_details.initialETHadded
    );
    console.log(
      "time when this pool is dissolved:",
      pool_2_details.dateDissolved.toString()
    );
    console.log(
      "Number of stakers who have claimed from this pool:",
      numberOfClaimers
    );
    console.log("ether paid out by pool 1:", weiToEther(etherPaidOutPool2));
    console.log("-------- Stakers who have claimed from this pool ------");

    let claimers = await withdrawPool.getAllClaimersForPool(2);
    console.log(claimers);

    console.log("********************************************************\n");
  });

  it("an investor can burn his Ethie Token NFT and receive ethers locked and interest accumulated", async () => {
    let tokenID = 5;

    let newLock = await earningsTracker.getPastEvents("EtherLocked", {
      fromBlock: 0,
      toBlock: "latest"
    });

    newLock.map(async e => {
      console.log("\n==== NEW LOCK HAPPENED ===");
      console.log("    Funder ", e.returnValues.funder);
      console.log("    TokenID ", e.returnValues.ethieTokenID);
      console.log("    Generation ", e.returnValues.generation);
      console.log("========================\n");
    });

    let owner = await ethieToken.ownerOf(tokenID);
    console.log(owner);

    let valueReturned = await earningsTrackerDB.calculateTotal(
      web3.utils.toWei("5"),
      0
    );
    console.log(web3.utils.fromWei(valueReturned.toString()));
    let burn_fee = await earningsTrackerDB.KTYforBurnEthie(tokenID);
    let ether_burn_ethie = burn_fee[0];
    let ktyFee = burn_fee[1];

    await ethieToken.approve(earningsTracker.address, tokenID, {from: owner});

    console.log("KTY burn ethie fee:", weiToEther(ktyFee));
    console.log(
      "ether needed for swap KTY burn ethie fee:",
      weiToEther(ether_burn_ethie)
    );

    // burn ethie
    await proxy.execute(
      "EarningsTracker",
      setMessage(earningsTracker, "burnNFT", [tokenID]),
      {
        from: owner,
        value: ether_burn_ethie
      }
    );
    let newBurn = await earningsTracker.getPastEvents("EthieTokenBurnt", {
      fromBlock: 0,
      toBlock: "latest"
    });

    newBurn.map(async e => {
      console.log("\n==== NEW BURN HAPPENED ===");
      console.log("    Burner ", e.returnValues.burner);
      console.log("    TokenID ", e.returnValues.ethieTokenID);
      console.log("    Generation ", e.returnValues.generation);
      console.log("    Investment ", e.returnValues.principalEther);
      console.log("    Interest ", e.returnValues.interestPaid);
      console.log("========================\n");
    });

    // uniswap reserve ratio
    console.log("\n==== UNISWAP RESERVE RATIO ===");
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
  });

  it("sets new epoch when finalized", async () => {
    let _wait = await timeFrame.timeUntilEpochEnd(2);
    _wait = _wait.toNumber();
    console.log(_wait);
    await timeout(_wait);
    // evm.increaseTime(web3, _wait)
    await proxy.executeScheduledJobs();
    console.log("Hi, new epoch!");

    let totalEpochs = await timeFrame.getTotalEpochs();
    console.log("Total number of epochs:", totalEpochs.toString());

    const epoch_3_start_unix = await timeFrame._epochStartTime(3);
    console.log(
      "epoch 3 start time in unix time:",
      epoch_3_start_unix.toNumber()
    );
    const epoch_3_start_human_readable = await timeFrame.epochStartTime(3);
    const epoch_3_end_human_readable = await timeFrame.epochEndTime(3);
    console.log("\n******************* Epoch 3 Start Time *****************");
    console.log(
      "Date:",
      epoch_3_start_human_readable[0].toNumber() +
        "-" +
        epoch_3_start_human_readable[1].toNumber() +
        "-" +
        epoch_3_start_human_readable[2].toNumber(),
      " ",
      "Time:",
      epoch_3_start_human_readable[3].toNumber() +
        ":" +
        epoch_3_start_human_readable[4].toNumber() +
        ":" +
        epoch_3_start_human_readable[5].toNumber()
    );
    console.log("\n******************* Epoch 3 End Time *******************");
    console.log(
      "Date:",
      epoch_3_end_human_readable[0].toNumber() +
        "-" +
        epoch_3_end_human_readable[1].toNumber() +
        "-" +
        epoch_3_end_human_readable[2].toNumber(),
      " ",
      "Time:",
      epoch_3_end_human_readable[3].toNumber() +
        ":" +
        epoch_3_end_human_readable[4].toNumber() +
        ":" +
        epoch_3_end_human_readable[5].toNumber()
    );
    console.log("********************************************************\n");
  });

  it("creates a new pool", async () => {
    const numberOfDissolvedPools = await withdrawPool.getNumberOfDissolvedPools();
    console.log(
      "Total number of dissolved Pools:",
      numberOfDissolvedPools.toNumber()
    );
    const numberOfPools = await withdrawPool.getTotalNumberOfPools();
    console.log("Total number of pools:", numberOfPools.toNumber());

    console.log("************* Details of New Pool Created ************");
    const pool_3_details = await withdrawPool.weeklyPools(3);
    const numberOfClaimers = pool_3_details.stakersClaimed.toNumber();
    console.log(
      "epoch ID associated with this pool",
      pool_3_details.epochID.toString()
    );
    console.log(
      "block number when this pool was created",
      pool_3_details.blockNumber.toString()
    );
    console.log(
      "initial ether available in this pool:",
      pool_3_details.initialETHAvailable.toString()
    );
    console.log(
      "ether remaining in this pool:",
      pool_3_details.ETHAvailable.toString()
    );
    console.log(
      "date available for claiming from this pool:",
      pool_3_details.dateAvailable.toString()
    );
    console.log(
      "whether initial ether has been distributed to this pool:",
      pool_3_details.initialETHadded
    );
    console.log(
      "time when this pool is dissolved:",
      pool_3_details.dateDissolved.toString()
    );
    console.log(
      "time (in seconds) till this pool will be dissolved: ",
      pool_3_details.dateDissolved.toNumber() - Math.floor(Date.now() / 1000)
    );
    console.log(
      "Number of stakers who have claimed from this pool:",
      numberOfClaimers
    );

    console.log("-------- Stakers who have claimed from this pool ------");

    let claimers = await withdrawPool.getAllClaimersForPool(3);
    console.log(claimers);

    console.log("********************************************************\n");
  });

});
