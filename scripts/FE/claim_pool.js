const KFProxy = artifacts.require("KFProxy");
const SuperDaoToken = artifacts.require("MockERC20Token");
const KittieFightToken = artifacts.require('KittieFightToken');
const MockStaking = artifacts.require("MockStaking");
const EarningsTracker = artifacts.require("EarningsTracker");
const EthieToken = artifacts.require("EthieToken");
const WithdrawPool = artifacts.require("WithdrawPool");
const BigNumber = web3.utils.BN;
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

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

//truffle exec scripts/FE/claim_pool.js poolID

module.exports = async (callback) => {    

  try{
    let proxy = await KFProxy.deployed();
    let superDaoToken = await SuperDaoToken.deployed();
    let staking = await MockStaking.deployed();
    let earningsTracker = await EarningsTracker.deployed();
    let ethieToken = await EthieToken.deployed();
    let withdrawPool = await WithdrawPool.deployed();

    accounts = await web3.eth.getAccounts();

    let poolId = process.argv[4]
    const stakedTokens = new BigNumber(
      web3.utils.toWei("5", "ether")
    );

    let timeTillClaiming = await withdrawPool.timeUntilClaiming();
    console.log(
      "Time (in seconds) till claiming from the current pool:",
      timeTillClaiming.toNumber()
    );
    if (timeTillClaiming.toNumber() > 0) {
      await timeout(timeTillClaiming.toNumber());
    }
    
    console.log("Available for claiming...");

    for (let i = 1; i < 4; i++) {
      //await withdrawPool.claimYield(poolId, {from: accounts[i]});
      await proxy.execute(
        "WithdrawPool",
        setMessage(withdrawPool, "claimYield", [0]),
        {
          from: accounts[i]
        }
      )
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

    callback()
  }
  catch(e){
    callback(e)
  }
}
