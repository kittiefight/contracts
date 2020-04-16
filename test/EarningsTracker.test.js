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
  ethieToken,
  earningsTracker;

contract("EarningsTracker", accounts => {
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
  });

  it("sets Epoch 0", async () => {
    console.log("now:", Math.floor(Date.now() / 1000))
    await timeFrame.setEpoch_0(Math.floor(Date.now() / 1000)-2*24*60*60);
    const epoch_0_start_unix = await timeFrame._epochStartTime(0);
    console.log(
      "epoch 0 start time in unix time:",
      epoch_0_start_unix.toNumber()
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

  it("preset funding limit for each generation in initialization", async () => {
    let presetFundingLimit0 = await earningsTracker.getFundingLimit(0);
    presetFundingLimit0 = weiToEther(presetFundingLimit0);
    assert.equal(presetFundingLimit0, 500);
  });

  it("sets current funding limit", async () => {
    await earningsTracker.setCurrentFundingLimit();
    let currentFundingLimit = await earningsTracker.currentFundingLimit();
    currentFundingLimit = weiToEther(currentFundingLimit);
    assert.equal(currentFundingLimit, 500);
  });

  it("gets current generation based on current funding limit", async () => {
    let currentGeneration = await earningsTracker.getCurrentGeneration();
    currentGeneration = currentGeneration.toNumber();
    assert.equal(currentGeneration, 0);
  });

  it("adds minter role to EarningsTracker", async () => {
    await ethieToken.addMinter(earningsTracker.address);
    let isEarningsTrackerMinter = await ethieToken.isMinter(
      earningsTracker.address
    );
    assert.isTrue(isEarningsTrackerMinter);
  });

  it("an investor can deposit and lock ether, and receive an EthieToken NFT", async () => {
    for (let i = 0; i < 10; i++) {
      let ethAmount = web3.utils.toWei(String(40 + i), "ether");
      await earningsTracker.lockETH({from: accounts[i], value: ethAmount})
      let number_ethieToken = await ethieToken.balanceOf(accounts[i]);
      assert.equal(number_ethieToken.toNumber(), 1);
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

  it("A user can get the ID of the current weekly epoch", async () => {
    let currentEpochID = await earningsTracker.getCurrentEpoch()
    currentEpochID = currentEpochID.toNumber()
    assert.equal(currentEpochID, 0);
  })

  it("A user can check the current stage of the current epoch, and its start and end time", async () => {
    let startWorking = await timeFrame.workingDayStartTime()
    console.log("start working:", startWorking.toString())
    let endWorking = await timeFrame.workingDayEndTime()
    console.log("end working:", endWorking.toString())
    let startRest = await timeFrame.restDayStartTime()
    console.log("start resting:", startRest.toString())
    let endRest = await timeFrame.restDayEndTime()
    console.log("end resting:", endRest.toString())
    let blockInfo = await web3.eth.getBlock(web3.eth.blockNumber)
    console.log("latest block timestamp:", blockInfo.timestamp)
    let res1 = await timeFrame.isWorkingDay(0)
    console.log("Is working day?", res1)
    let res2 = await timeFrame.isRestDay(0)
    console.log("Is rest day?", res2)
    let stageStart = await earningsTracker.viewEpochStageStartTime()
    let stageEnd = await earningsTracker.viewEpochStageEndTime()
    console.log(`\n******************* Current Stage: ${stageStart.state} *******************`);
    console.log("\n******************* Stage Start Time *******************");
    console.log(
      "Date:",
        stageStart[1].toNumber() +
        "-" +
        stageStart[2].toNumber() +
        "-" +
        stageStart[3].toNumber(),
      " ",
      "Time:",
        stageStart[4].toNumber() +
        ":" +
        stageStart[5].toNumber() +
        ":" +
        stageStart[6].toNumber()
    );
    console.log("********************************************************\n");
    console.log("\n******************* Stage End Time *******************");
    console.log(
      "Date:",
        stageEnd[1].toNumber() +
        "-" +
        stageEnd[2].toNumber() +
        "-" +
        stageEnd[3].toNumber(),
      " ",
      "Time:",
        stageEnd[4].toNumber() +
        ":" +
        stageEnd[5].toNumber() +
        ":" +
        stageEnd[6].toNumber()
    );
    console.log("********************************************************\n");
  })

  it("tells how many more ethers needed to reach the current funding limit", async () => {
    let ethersNeeded = await earningsTracker.ethNeededToReachFundingLimit();
    console.log(weiToEther(ethersNeeded));
  });

  it("reaches the funding limit of the current generation", async () => {
    let ethAmount_12 = web3.utils.toWei(String(55), "ether");
    await earningsTracker.lockETH({from: accounts[12], value: ethAmount_12})
    let number_ethieToken_12 = await ethieToken.balanceOf(accounts[12]);
    assert.equal(number_ethieToken_12.toNumber(), 1);
    let ethieTokenID_12 = await ethieToken.tokenOfOwnerByIndex(accounts[12], 0);
    console.log(ethieTokenID_12.toNumber());

    let limitReached = await earningsTracker.hasReachedLimit(0);
    assert.isTrue(limitReached);

    let ethersNeeded1 = await earningsTracker.ethNeededToReachFundingLimit();
    assert.equal(weiToEther(ethersNeeded1), 0);
  });

  it("an investor cannot deposit ether if the funding limit of the current generation has been reached", async () => {
    let ethAmount_13 = web3.utils.toWei(String(10), "ether");
    await earningsTracker.lockETH({from: accounts[13], value: ethAmount_13}).should.be.rejected
    let number_ethieToken_13 = await ethieToken.balanceOf(accounts[13]);
    console.log(number_ethieToken_13.toNumber());
    assert.equal(number_ethieToken_13.toNumber(), 0);
  });

  it("The next generation starts when the admin sets the current funding limit", async () => {
    await earningsTracker.setCurrentFundingLimit();
    let currentFundingLimit1 = await earningsTracker.currentFundingLimit();
    currentFundingLimit1 = weiToEther(currentFundingLimit1);
    console.log(
      "New current funding limit is set:",
      currentFundingLimit1,
      "ether"
    );
    assert.equal(currentFundingLimit1, 1000);
    let currentGeneration1 = await earningsTracker.getCurrentGeneration();
    currentGeneration1 = currentGeneration1.toNumber();
    console.log("New generation starts:", currentGeneration1);
    assert.equal(currentGeneration1, 1);
  });

  it("The admin sets the current generation in EthieToken contract", async () => {
    await earningsTracker.incrementGenerationInEthieToken().should.be.fulfilled;
  });

  it("An investor can deposit and receive EthieToken NFT of generation 1", async () => {
    let ethAmount_13 = web3.utils.toWei(String(10), "ether");
    await await earningsTracker.lockETH({from: accounts[13], value: ethAmount_13}).should.be.fulfilled
    let number_ethieToken_13 = await ethieToken.balanceOf(accounts[13]);
    console.log(number_ethieToken_13.toNumber());
    assert.equal(number_ethieToken_13.toNumber(), 1);
    let ethieTokenID_13 = await ethieToken.tokenOfOwnerByIndex(accounts[13], 0);
    ethieTokenID_13 = ethieTokenID_13.toNumber();
    console.log(ethieTokenID_13);
    let tokenProperties = await ethieToken.properties(ethieTokenID_13);
    let ethAmount = weiToEther(tokenProperties.ethAmount);
    let generation = tokenProperties.generation.toNumber();
    let lockTime = tokenProperties.lockTime.toString();
    console.log("\n************** Investor: accounts[13] **************");
    console.log("EthieToken ID:", ethieTokenID_13);
    console.log("Oringinal ether amount held in this token:", ethAmount);
    console.log("This token's generation:", generation);
    console.log("This token's lock time(in seconds):", lockTime);
    console.log("****************************************************\n");
  });

  it("many investors deposit in generation 1", async () => {
    for (let i = 14; i < 25; i++) {
      let eth_amount = web3.utils.toWei(String(70+i), "ether");
      await earningsTracker.lockETH({from: accounts[i], value: eth_amount})
      let number_of_ethieToken = await ethieToken.balanceOf(accounts[i]);
      assert.equal(number_of_ethieToken.toNumber(), 1);
      let ethie_token_ID = await ethieToken.tokenOfOwnerByIndex(
        accounts[i],
        0
      );
      ethie_token_ID = ethie_token_ID.toNumber();
      let token_properties = await ethieToken.properties(ethie_token_ID);
      let eth_amount_token = weiToEther(token_properties.ethAmount);
      let generation_token = token_properties.generation.toNumber();
      let lock_time = token_properties.lockTime.toString();
      console.log(`\n************** Investor: accounts${i} **************`);
      console.log("EthieToken ID:", ethie_token_ID);
      console.log("Oringinal ether amount held in this token:", eth_amount_token);
      console.log("This token's generation:", generation_token);
      console.log("This token's lock time(in seconds):", lock_time);
      console.log("****************************************************\n");
    }
  });

  it("returns extra ether back to the investor if the total ether exceeds funding limit after this deposit", async () => {
    let ethersNeededGen1 = await earningsTracker.ethNeededToReachFundingLimit();
    ethersNeededGen1 = weiToEther(ethersNeededGen1);
    console.log("Ethers needed to reach funding limit of generation 1:", ethersNeededGen1)
    let balance_before_26 = await web3.eth.getBalance(accounts[26])
    balance_before_26 = weiToEther(balance_before_26)
    let eth_amount_26 = web3.utils.toWei(String(ethersNeededGen1+20), "ether");
      await earningsTracker.lockETH({from: accounts[26], value: eth_amount_26})
      let number_of_ethieToken_26 = await ethieToken.balanceOf(accounts[26]);
      assert.equal(number_of_ethieToken_26.toNumber(), 1);
      let ethie_token_ID_26 = await ethieToken.tokenOfOwnerByIndex(
        accounts[26],
        0
      );
      ethie_token_ID_26 = ethie_token_ID_26.toNumber();
      let token_properties_26 = await ethieToken.properties(ethie_token_ID_26);
      let eth_amount_token_26 = weiToEther(token_properties_26.ethAmount);
      let generation_token_26 = token_properties_26.generation.toNumber();
      let lock_time_26 = token_properties_26.lockTime.toString();

      let balance_after_26 = await web3.eth.getBalance(accounts[26])
      balance_after_26 = weiToEther(balance_after_26)

      console.log(`\n************** Investor: accounts 26 **************`);
      console.log("EthieToken ID:", ethie_token_ID_26);
      console.log("Oringinal ether amount held in this token:", eth_amount_token_26);
      console.log("This token's generation:", generation_token_26);
      console.log("This token's lock time(in seconds):", lock_time_26);
      console.log("investor's ether balance in his account before deposit:", balance_before_26)
      console.log("investor's ether balance in his account after deposit:", balance_after_26)
      console.log("extra ether returned to the investor:", (ethersNeededGen1+20) - (balance_before_26 - balance_after_26))
      console.log("****************************************************\n");
  })

  it("an investor cannot deposit because the funding limit of the current generation has been reached", async () => {
    let ethAmount_27 = web3.utils.toWei(String(10), "ether");
    await earningsTracker.lockETH({from: accounts[27], value: ethAmount_27}).should.be.rejected
    let number_ethieToken_27 = await ethieToken.balanceOf(accounts[27]);
    console.log(number_ethieToken_27.toNumber());
    assert.equal(number_ethieToken_27.toNumber(), 0);
  });

  it("an investor can burn his Ethie Token NFT after its locktime is over", async () => {
    let balance_before_24 = await web3.eth.getBalance(accounts[24])
    balance_before_24 = weiToEther(balance_before_24)
    console.log("balance before burning:", balance_before_24)

    let ethie_token_ID_24 = await ethieToken.tokenOfOwnerByIndex(
      accounts[24],
      0
    );
    ethie_token_ID_24 = ethie_token_ID_24.toNumber()

    let token_properties_24 = await ethieToken.properties(ethie_token_ID_24);
    let ethAmount_24 = token_properties_24.ethAmount
    let lock_time_24 = token_properties_24.lockTime;
    lock_time_24 = lock_time_24.toNumber() + 3600;
    console.log("lock time:", lock_time_24)

    evm.increaseTime(web3, lock_time_24);

    let interest = await earningsTracker.calculateInterest(ethAmount_24, lock_time_24)
    interest = weiToEther(interest)
    console.log("interest accumulated:", interest)

    await ethieToken.approve(earningsTracker.address, ethie_token_ID_24, { from: accounts[24] })
    await earningsTracker.burnNFT(ethie_token_ID_24, { from: accounts[24] })//.should.be.rejected;
    let balance_after_24 = await web3.eth.getBalance(accounts[24])
    balance_after_24 = weiToEther(balance_after_24)
    console.log("balance after burning:", balance_after_24)
  })

  it("burning tokens of current generation frees up some space within the funding limit for more deposit", async () => {
    let ethAmount_28 = web3.utils.toWei(String(20), "ether");
    await earningsTracker.lockETH({from: accounts[28], value: ethAmount_28}).should.be.fulfilled
    let number_ethieToken_28 = await ethieToken.balanceOf(accounts[28]);
    console.log(number_ethieToken_28.toNumber());
    assert.equal(number_ethieToken_28.toNumber(), 1);
    let ethieTokenID_28 = await ethieToken.tokenOfOwnerByIndex(accounts[28], 0);
    ethieTokenID_28 = ethieTokenID_28.toNumber();
    console.log(ethieTokenID_28);
    let tokenProperties_28 = await ethieToken.properties(ethieTokenID_28);
    let ethValue_28 = weiToEther(tokenProperties_28.ethAmount);
    let generation_28 = tokenProperties_28.generation.toNumber();
    let lockTime_28 = tokenProperties_28.lockTime.toString();
    console.log("\n************** Investor: accounts[28] **************");
    console.log("EthieToken ID:", ethieTokenID_28);
    console.log("Oringinal ether amount held in this token:", ethValue_28);
    console.log("This token's generation:", generation_28);
    console.log("This token's lock time(in seconds):", lockTime_28);
    console.log("****************************************************\n");
  });

  
});
