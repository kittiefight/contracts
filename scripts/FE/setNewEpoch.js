const WithdrawPool = artifacts.require("WithdrawPool");
const EarningsTracker = artifacts.require("EarningsTracker");

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

//truffle exec scripts/FE/stake_and_invest.js <#users> <amountKTY>

module.exports = async (callback) => {    

  try{
    let withdrawPool = await WithdrawPool.deployed();
    let earningsTracker = await EarningsTracker.deployed();

    accounts = await web3.eth.getAccounts();

    await withdrawPool.setPool_0();


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
    console.log(
      "Investments in Pool:",
      amounts.investment.toString()
    );
    console.log("********************************************************\n");
    callback()
  }
  catch(e){
    callback(e)
  }
}
