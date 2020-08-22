const KFProxy = artifacts.require("KFProxy");
const WithdrawPool = artifacts.require("WithdrawPool");
const EarningsTracker = artifacts.require("EarningsTracker");
const TimeFrame = artifacts.require("TimeFrame");
const GenericDB = artifacts.require("GenericDB");
const Register = artifacts.require("Register");

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find(f => {
      return f.name == funcName;
    }),
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

function timeout(s) {
  // console.log(`~~~ Timeout for ${s} seconds`);
  return new Promise(resolve => setTimeout(resolve, s * 1000));
}

//truffle exec scripts/FE/setEpoch.js 41

module.exports = async callback => {
  try {
    let proxy = await KFProxy.deployed();
    let withdrawPool = await WithdrawPool.deployed();
    let earningsTracker = await EarningsTracker.deployed();
    let timeFrame = await TimeFrame.deployed();
    let genericDB = await GenericDB.deployed();
    let register = await Register.deployed();

    let accountId = process.argv[4];

    accounts = await web3.eth.getAccounts();
    const oldEpochID = await timeFrame.getActiveEpochID();
    const timeTillStartTime = await timeFrame.restDayEndTime();

    console.log("\n******************* Epoch 0 *****************");
    console.log("Time till start time:", formatDate(timeTillStartTime));
    console.log("********************************************************\n");

    if (timeTillStartTime.toNumber() > 0) {
      await timeout(timeTillStartTime.toNumber());
    }

    await proxy.execute("Register", setMessage(register, "register", []), {
      from: accounts[accountId]
    });
    console.log("New pool available...");

    const numberOfPools = await timeFrame.getTotalEpochs();

    console.log(
      `\n******************* Pool ${numberOfPools.toString()} Created*******************`
    );
    console.log("Number of pools:", numberOfPools.toNumber());
    callback();
  } catch (e) {
    callback(e);
  }
};
