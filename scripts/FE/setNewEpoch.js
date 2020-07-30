const WithdrawPool = artifacts.require("WithdrawPool");
const EarningsTracker = artifacts.require("EarningsTracker");
const TimeFrame = artifacts.require("TimeFrame")

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

function formatDate(timestamp) {
  let date = new Date(null);
  date.setSeconds(timestamp);
  return date.toTimeString().replace(/.*(\d{2}:\d{2}:\d{2}).*/, "$1");
}

//truffle exec scripts/FE/setNewEpoch.js

module.exports = async (callback) => {    

  try{
    let withdrawPool = await WithdrawPool.deployed();
    let earningsTracker = await EarningsTracker.deployed();
    let timeFrame = await TimeFrame.deployed()

    accounts = await web3.eth.getAccounts();

    await timeFrame.setTimes(250, 120, 120)

    await withdrawPool.setPool_0();

    const epoch_0_start_unix = await timeFrame._epochStartTime(0);
    const epoch_0_end_unix = await timeFrame._epochEndTime(0);
 
    console.log("\n******************* Epoch 0 *****************");
    console.log(
      "epoch 0 start time in unix time:",
      epoch_0_start_unix.toNumber()
    );
    console.log(
      "epoch 0 end time in unix time:",
      epoch_0_end_unix.toNumber()
    );
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
    callback()
  }
  catch(e){
    callback(e)
  }
}
