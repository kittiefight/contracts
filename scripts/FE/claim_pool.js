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

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

//truffle exec scripts/FE/claim_pool.js poolID

module.exports = async (callback) => {    

  try{
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

    for (let i = 1; i < 4; i++) {
      let checkClaim = await withdrawPool.checkYield(accounts[i], poolId);
      console.log(checkClaim.toString());
      await  withdrawPool.claimYield(poolId, {from: accounts[i]});
      let newClaim = await withdrawPool.getPastEvents("ClaimYield", {
        fromBlock: 0,
        toBlock: "latest"
      });

      newClaim.map(async (e) => {
        console.log('\n==== NEW CLAIM HAPPENED ===');
        console.log('    PoolID ', e.returnValues.pool_id)
        console.log('    Staker ', e.returnValues.account)
        console.log('    Amount ', e.returnValues.yield)
        console.log('========================\n')
      })
    }

    callback()
  }
  catch(e){
    callback(e)
  }
}
