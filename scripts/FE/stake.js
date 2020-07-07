const KFProxy = artifacts.require('KFProxy')
const SuperDaoToken = artifacts.require("MockERC20Token");
const KittieFightToken = artifacts.require('KittieFightToken');
const MockStaking = artifacts.require("MockStaking");
const EarningsTracker = artifacts.require("EarningsTracker");
const EthieToken = artifacts.require("EthieToken");
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

//truffle exec scripts/FE/stake_and_invest.js

module.exports = async (callback) => {    

  try{
    let proxy = await KFProxy.deployed();
    let superDaoToken = await SuperDaoToken.deployed();
    let staking = await MockStaking.deployed();
    let earningsTracker = await EarningsTracker.deployed();
    let ethieToken = await EthieToken.deployed();

    accounts = await web3.eth.getAccounts();

    for (let i = 0; i < 6; i++) {
      let ethAmount = new BigNumber(web3.utils.toWei('10'));
      console.log(ethAmount.toString());
      console.log(accounts[i]);
      //await earningsTracker.lockETH({gas: 900000, from: accounts[i], value: ethAmount.toString()});
      await proxy.execute(
        "EarningsTracker",
        setMessage(earningsTracker, "lockETH", []),
        {
          gas: 900000,
          from: accounts[i],
          value: ethAmount.toString()
        }
      )
      let number_ethieToken = await ethieToken.balanceOf(accounts[i]);
      let ethieTokenID = await ethieToken.tokenOfOwnerByIndex(accounts[i], 0);
      ethieTokenID = ethieTokenID.toNumber();
      let tokenProperties = await ethieToken.properties(ethieTokenID);
      let ethAmountToken = weiToEther(tokenProperties.ethAmount);
      let generationToken = tokenProperties.generation.toNumber();
      let lockTime = tokenProperties.lockPeriod.toString();
      console.log(`\n************** Investor: accounts${i} **************`);
      console.log("EthieToken ID:", ethieTokenID);
      console.log("Oringinal ether amount held in this token:", ethAmountToken);
      console.log("This token's generation:", generationToken);
      console.log("This token's lock time(in seconds):", lockTime);
      console.log("****************************************************\n");
    }

    callback()
  }
  catch(e){
    callback(e)
  }
}
