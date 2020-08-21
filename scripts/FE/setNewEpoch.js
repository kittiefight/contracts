const WithdrawPool = artifacts.require("WithdrawPool");
const WithdrawPoolGetters = artifacts.require("WithdrawPoolGetters");
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

function weiToEther(w) {
  let eth = web3.utils.fromWei(w.toString(), "ether");
  return Math.round(parseFloat(eth));
}

//truffle exec scripts/FE/setNewEpoch.js

module.exports = async (callback) => {    

  try{
    let withdrawPool = await WithdrawPool.deployed();
    let withdrawPoolGetters = await WithdrawPoolGetters.deployed();
    let earningsTracker = await EarningsTracker.deployed();
    let timeFrame = await TimeFrame.deployed();
    let genericDB = await GenericDB.deployed();

    accounts = await web3.eth.getAccounts();

    await timeFrame.setTimes(205, 50, 50);

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
    const epochID = await timeFrame.getActiveEpochID()
    const stakersClaimed = await withdrawPoolGetters.getAllClaimersForPool(epochID);

    console.log("\n******************* Pool 0 Created*******************");
    console.log("Number of pools:", numberOfPools.toNumber());
    console.log(
      "epoch ID associated with this pool",
      epochID.toString()
    );
    console.log(
      "initial ether available in this pool:",
      weiToEther(await withdrawPoolGetters.getInitialETH(epochID))
    );
    console.log(
      "date available for claiming from this pool:",
      formatDate(await timeFrame.restDayStartTime())
    );
    console.log(
      "Number of stakers who have claimed from this pool:",
      stakersClaimed.toString()
    );
    console.log("********************************************************\n");
    callback()
  }
  catch(e){
    callback(e)
  }
}
