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
  let eth = web3.utils.fromWei(w.toString(), "ether");
  return Math.round(parseFloat(eth));
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
  ethieToken;

let initial_epoch_0_end_time, initial_pool_0_available_time, initial_pool_0_dissolve_time

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

  it("registers 40 users", async () => {
    let users = 40;

    for (let i = 1; i <= users; i++) {
      await proxy.execute("Register", setMessage(register, "register", []), {
        from: accounts[i]
      }).should.be.fulfilled;
    }
  });

  it("sends 30000 KTYs to 40 users", async () => {
    let amountKTY = 30000;
    let users = 40;

    for (let i = 1; i <= users; i++) {
      await kittieFightToken.transfer(
        accounts[i],
        web3.utils.toWei(String(amountKTY)),
        {
          from: accounts[0]
        }
      ).should.be.fulfilled;

      await kittieFightToken.approve(
        endowmentFund.address,
        web3.utils.toWei(String(amountKTY)),
        {from: accounts[i]}
      ).should.be.fulfilled;
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
    await earningsTracker.setCurrentFundingLimit();

    for (let i = 0; i < 6; i++) {
      let ethAmount = web3.utils.toWei(String(10 + i), "ether");
      console.log(ethAmount.toString());
      console.log(accounts[i]);
      await earningsTracker.lockETH({
        gas: 900000,
        from: accounts[i],
        value: ethAmount.toString()
      });
      let number_ethieToken = await ethieToken.balanceOf(accounts[i]);
      let ethieTokenID = await ethieToken.tokenOfOwnerByIndex(accounts[i], 0);
      ethieTokenID = ethieTokenID.toNumber();
      let tokenProperties = await ethieToken.properties(ethieTokenID);
      let ethAmountToken = weiToEther(tokenProperties.ethAmount);
      let generationToken = tokenProperties.generation.toNumber();
      let lockTime = tokenProperties.lockTime.toString();
      console.log(`\n************** Investor: accounts${i} **************`);
      console.log("EthieToken ID:", ethieTokenID);
      console.log("Oringinal ether amount held in this token:", ethAmountToken);
      console.log("This token's generation:", generationToken);
      console.log("This token's lock time(in seconds):", lockTime);
      console.log("****************************************************\n");
    }
  });

  it("sets Epoch 0, Pool 0, and sets investment for Epoch 0", async () => {
    await withdrawPool.setPool_0();

    const epoch_0_start_unix = await timeFrame._epochStartTime(0);
    const epoch_0_end_unix = await timeFrame._epochEndTime(0);
    initial_epoch_0_end_time = epoch_0_end_unix.toNumber();
    console.log(
      "epoch 0 start time in unix time:",
      epoch_0_start_unix.toNumber()
    );
    console.log(
      "epoch 0 end time in unix time:",
      epoch_0_end_unix.toNumber()
    );
    const epoch_0_start_human_readable = await timeFrame.epochStartTime(0);
    const epoch_0_end_human_readable = await timeFrame.epochEndTime(0);
    console.log("\n******************* Epoch 0 Start Time *****************");
    console.log(
      "Date:",
      epoch_0_start_human_readable[0].toNumber() +
        "-" +
        epoch_0_start_human_readable[1].toNumber() +
        "-" +
        epoch_0_start_human_readable[2].toNumber(),
      " ",
      "Time:",
      epoch_0_start_human_readable[3].toNumber() +
        ":" +
        epoch_0_start_human_readable[4].toNumber() +
        ":" +
        epoch_0_start_human_readable[5].toNumber()
    );
    console.log("\n******************* Epoch 0 End Time *******************");
    console.log(
      "Date:",
      epoch_0_end_human_readable[0].toNumber() +
        "-" +
        epoch_0_end_human_readable[1].toNumber() +
        "-" +
        epoch_0_end_human_readable[2].toNumber(),
      " ",
      "Time:",
      epoch_0_end_human_readable[3].toNumber() +
        ":" +
        epoch_0_end_human_readable[4].toNumber() +
        ":" +
        epoch_0_end_human_readable[5].toNumber()
    );
    console.log("********************************************************\n");

    let amounts = await earningsTracker.amountsPerEpoch(0);
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
      "stakers who have claimed from this pool:",
      pool_0_details.stakersClaimed[0]
    );
    initial_pool_0_available_time = pool_0_details.dateAvailable.toNumber()
    initial_pool_0_dissolve_time = pool_0_details.dateDissolved.toNumber()
    console.log("Investments in Pool:", weiToEther(amounts.investment));
    console.log("********************************************************\n");
  });

  it("manual matches kitties", async () => {
    let kittyRed = 324;
    let kittyBlack = 1001;
    let gameStartTimeGiven = Math.floor(Date.now() / 1000) + 100 + 250; //now + 80 secs, so for prestart 30 secs 50 secs to participate

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

    console.log(ticketFee);

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

    for (let i = 10; i < blacks; i++) {
      participator = accounts[i];
      await proxy.execute(
        "GameManager",
        setMessage(gameManager, "participate", [gameId, playerBlack]),
        {from: participator}
      ).should.be.fulfilled;
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
      await proxy.execute(
        "GameManager",
        setMessage(gameManager, "participate", [gameId, playerRed]),
        {from: participator}
      ).should.be.fulfilled;
      console.log("\nNew Participator for playerRed: ", participator);
      supportersForRed.push(participator);
      await timeout(timeInterval);
    }

    let KTYforBlack = blackParticipators * ticketFee;
    let KTYforRed = redParticipators * ticketFee;

    console.log("\nSupporters for Black: ", supportersForBlack);
    console.log("\nSupporters for Red: ", supportersForRed);

    console.log("\nTotal KTY for Black (only participators): ", KTYforBlack);
    console.log("\nTotal KTY for Red (only participators): ", KTYforRed);
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

    let resurrectionCost = await kittieHell.getResurrectionCost(
      loserKitty,
      gameId
    );
    const redemptionFee = web3.utils.fromWei(
      resurrectionCost.toString(),
      "ether"
    );
    const kittieRedemptionFee = parseFloat(redemptionFee);
    console.log("Loser's Kitty redemption fee in KTY: " + kittieRedemptionFee);

    const sacrificeKitties = [1017555, 413830, 888];

    for (let i = 0; i < sacrificeKitties.length; i++) {
      await cryptoKitties.mint(loser, sacrificeKitties[i]);
    }

    for (let i = 0; i < sacrificeKitties.length; i++) {
      await cryptoKitties.approve(kittieHellDB.address, sacrificeKitties[i], {
        from: loser
      });
    }

    await kittieFightToken.approve(kittieHell.address, resurrectionCost, {
      from: loser
    });

    await proxy.execute(
      "KittieHell",
      setMessage(kittieHell, "payForResurrection", [
        loserKitty,
        gameId,
        loser,
        sacrificeKitties
      ]),
      {from: loser}
    ).should.be.fulfilled;

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
    )
    console.log(
      "pool 0 available time extended by:",
      pool_0_extended_details.dateAvailable.toNumber() - initial_pool_0_available_time
    )
    console.log(
      "pool 0 dissolve time extended by:",
      pool_0_extended_details.dateDissolved.toNumber() - initial_pool_0_dissolve_time
    )
  })

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
      await withdrawPool.claimYield(0, {from: accounts[i]});
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
    
    let balance_before_2 = await web3.eth.getBalance(accounts[2])
    balance_before_2 = weiToEther(balance_before_2)

    let ethie_token_ID_2 = await ethieToken.tokenOfOwnerByIndex(
      accounts[2],
      0
    );
    ethie_token_ID_2 = ethie_token_ID_2.toNumber()

    let res11 = await earningsTracker.isWorkingDay()
    console.log("Is working day?", res11)
    let stageStart1 = await earningsTracker.viewEpochStageStartTime()
    let stageEnd1 = await earningsTracker.viewEpochStageEndTime()
    console.log(`\n******************* Current Stage: ${stageStart1.state} *******************`);
    console.log("\n******************* Stage Start Time *******************");
    console.log(
      "Date:",
        stageStart1[1].toNumber() +
        "-" +
        stageStart1[2].toNumber() +
        "-" +
        stageStart1[3].toNumber(),
      " ",
      "Time:",
        stageStart1[4].toNumber() +
        ":" +
        stageStart1[5].toNumber() +
        ":" +
        stageStart1[6].toNumber()
    );
    console.log("********************************************************\n");
    console.log("\n******************* Stage End Time *******************");
    console.log(
      "Date:",
        stageEnd1[1].toNumber() +
        "-" +
        stageEnd1[2].toNumber() +
        "-" +
        stageEnd1[3].toNumber(),
      " ",
      "Time:",
        stageEnd1[4].toNumber() +
        ":" +
        stageEnd1[5].toNumber() +
        ":" +
        stageEnd1[6].toNumber()
    );
    console.log("********************************************************\n");

    await ethieToken.approve(earningsTracker.address, ethie_token_ID_2, { from: accounts[2] })
    await earningsTracker.burnNFT(ethie_token_ID_2, { from: accounts[2] }).should.be.fulfilled;
    let balance_after_2 = await web3.eth.getBalance(accounts[2])
    balance_after_2 = weiToEther(balance_after_2)

    console.log("balance of accounts[2] before burning:", balance_before_2)
    console.log("balance of accounts[2] after burning:", balance_after_2)
  })

  
  it("sets new epoch when finalized", async () => {
    let _wait = await timeFrame.timeUntilEpochEnd(0);
    _wait = _wait.toNumber()
    console.log(_wait)
    await timeout(_wait)
    // evm.increaseTime(web3, _wait)
    await proxy.executeScheduledJobs();
    console.log("Hi, new epoch!");
    
    const epoch_1_start_unix = await timeFrame._epochStartTime(1);
    console.log(
      "epoch 1 start time in unix time:",
      epoch_1_start_unix.toNumber()
    );
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

    console.log("********************************************************\n");
  });


});
