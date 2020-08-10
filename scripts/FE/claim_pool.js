const KFProxy = artifacts.require("KFProxy");
const SuperDaoToken = artifacts.require("MockERC20Token");
const KittieFightToken = artifacts.require('KittieFightToken');
const Staking = artifacts.require("Staking");
const EarningsTracker = artifacts.require("EarningsTracker");
const EthieToken = artifacts.require("EthieToken");
const WithdrawPool = artifacts.require("WithdrawPool");
const WithdrawPoolGetters = artifacts.require("WithdrawPoolGetters");
const BigNumber = web3.utils.BN;
const Register = artifacts.require("Register");
const TimeFrame = artifacts.require("TimeFrame");
const EndowmentDB = artifacts.require('EndowmentDB');
require("chai")
  .use(require("chai-shallow-deep-equal"))
  .use(require("chai-bignumber")(BigNumber))
  .use(require("chai-as-promised"))
  .should();

function weiToEther(w) {
  let eth = web3.utils.fromWei(w.toString(), "ether");
  return Math.round(parseFloat(eth));
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

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

function increaseTime(addSeconds, web3Instance = web3) {
  const id = Date.now();

  return new Promise((resolve, reject) => {
    web3Instance.currentProvider.send(
      {
        jsonrpc: '2.0',
        method: 'evm_increaseTime',
        params: [addSeconds],
        id,
      },
      (err1) => {
        if (err1) return reject(err1);

        return web3Instance.currentProvider.send(
          {
            jsonrpc: '2.0',
            method: 'evm_mine',
            id: id + 1,
          },
          (err2, res) => (err2 ? reject(err2) : resolve(res)),
        );
      },
    );
  });
}

//truffle exec scripts/FE/claim_pool.js poolID

module.exports = async (callback) => {    

  try{
    let proxy = await KFProxy.deployed();
    let superDaoToken = await SuperDaoToken.deployed();
    let staking = await Staking.deployed();
    let earningsTracker = await EarningsTracker.deployed();
    let ethieToken = await EthieToken.deployed();
    let withdrawPool = await WithdrawPool.deployed();
    let withdrawPoolGetters = await WithdrawPoolGetters.deployed();
    let register = await Register.deployed();
    let timeFrame = await TimeFrame.deployed();
    let endowmentDB = await EndowmentDB.deployed();

    accounts = await web3.eth.getAccounts();

    let poolId = process.argv[4]
    let user = process.argv[5] === null ? 45 : process.argv[5];
    const stakedTokens = new BigNumber(
      web3.utils.toWei("5", "ether")
    );

    let epochID = await timeFrame.getActiveEpochID();
    console.log(epochID.toString());

    let timeTillClaiming = await withdrawPoolGetters.timeUntilClaiming();
    console.log(
      "Time (in seconds) till claiming from the current pool:",
      timeTillClaiming.toNumber()
    );
    if (timeTillClaiming.toNumber() > 0) {
      await timeout(timeTillClaiming.toNumber());
    }

    console.log(formatDate(await timeFrame.restDayStartTime()));
    console.log(formatDate(await timeFrame.restDayEndTime()));
    
    // await proxy.execute(
    //     "Register",
    //     setMessage(register, "register", []),
    //     {
    //       from: accounts[user]
    //     }
    //   )
    console.log("Available for claiming...");

    let boolean = await withdrawPoolGetters.getUnlocked(0);
    console.log(boolean);
    epochID = await timeFrame.getActiveEpochID();
    console.log("Current Epoch:", epochID.toString());

    for (let i = 1; i < 3; i++) {
      //await withdrawPool.claimYield(poolId, {from: accounts[i]});
      await proxy.execute(
        "WithdrawPool",
        setMessage(withdrawPool, "claimYield", [0]),
        {
          from: accounts[i]
        }
      )
    }

    const initialETHAvailable = await withdrawPoolGetters.getInitialETH(0);
    const ethAvailable = await endowmentDB.getETHinPool(0);
    const numberOfClaimers = await withdrawPoolGetters.getAllClaimersForPool(0);
    const etherPaidOutPool0 = await withdrawPoolGetters.getEthPaidOut();
    const dateAvailable = await timeFrame.restDayStartTime();
    const dateDissolved = await timeFrame.restDayEndTime();
    console.log(
      "\n******************* SuperDao Tokens Stakers Claim from Pool 0 *******************"
    );
    
    console.log(
      "initial ether available in this pool:",
      weiToEther(initialETHAvailable)
    );
    console.log(
      "ether available in this pool:",
      weiToEther(ethAvailable)
    );
    console.log(
      "date available for claiming from this pool:",
      dateAvailable.toString()
    );
    // console.log(
    //   "whether initial ether has been distributed to this pool:",
    //   pool_0_details.initialETHadded
    // );
    console.log(
      "time when this pool is dissolved:",
      dateDissolved.toString()
    );
    console.log(
      "Number of stakers who have claimed from this pool:",
      numberOfClaimers.toString()
    );
    console.log("ether paid out by pool 0:", weiToEther(etherPaidOutPool0));
    console.log("********************************************************\n");

    callback()
  }
  catch(e){
    callback(e)
  }
}
