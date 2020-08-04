const WithdrawPool = artifacts.require("WithdrawPool");
const EarningsTracker = artifacts.require("EarningsTracker");
const TimeFrame = artifacts.require("TimeFrame");
const GenericDB = artifacts.require("GenericDB");

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
    let timeFrame = await TimeFrame.deployed();
    let genericDB = await GenericDB.deployed();

    accounts = await web3.eth.getAccounts();

    await timeFrame.setTimes(250, 120, 120)

    await withdrawPool.setPool_0();

    const epoch_0_start_unix = await timeFrame.workingDayStartTime();
    const epoch_0_end_unix = await timeFrame.restDayEndTime();
 
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

    const numberOfPools = await timeFrame.getTotalEpochs();
    console.log("Number of pools:", numberOfPools.toNumber());
    console.log("\n******************* Pool 0 Created*******************");
    const pool_0_details = await withdrawPool.weeklyPools(0);
    const epochID = await timeFrame.getActiveEpochID()
    console.log(
      "epoch ID associated with this pool",
      epochID.toString()
    );
    console.log(
      "initial ether available in this pool:",
      await withdrawPool.getInitialETH(epochID)
    );
    console.log(
      "date available for claiming from this pool:",
      formatDate(await timeFrame.restDayStartTime())
    );
    console.log(
      "stakers who have claimed from this pool:",
      pool_0_details.stakersClaimed[0]
    );
    console.log("********************************************************\n");

    console.log(formatDate(await withdrawPool.restDayStart1()));
    callback()
  }
  catch(e){
    callback(e)
  }
}
