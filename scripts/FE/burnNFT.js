const SuperDaoToken = artifacts.require("MockERC20Token");
const MockStaking = artifacts.require("MockStaking");
const EarningsTracker = artifacts.require("EarningsTracker");
const EthieToken = artifacts.require("EthieToken");
const WithdrawPool = artifacts.require("WithdrawPool");
const GameVarAndFee = artifacts.require("GameVarAndFee");
const EndowmentFund = artifacts.require('EndowmentFund')
const KittieFightToken = artifacts.require('KittieFightToken');
const KtyUniswap = artifacts.require("KtyUniswap");

const BigNumber = web3.utils.BN;
require("chai")
  .use(require("chai-shallow-deep-equal"))
  .use(require("chai-bignumber")(BigNumber))
  .use(require("chai-as-promised"))
  .should();

function weiToEther(w) {
  return web3.utils.fromWei(w.toString(), "ether")
  //let eth = web3.utils.fromWei(w.toString(), "ether");
  //return Math.round(parseFloat(eth));
}

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

//truffle exec scripts/FE/burnNFT.js tokenID

module.exports = async (callback) => {    

  try{
    let superDaoToken = await SuperDaoToken.deployed();
    let staking = await MockStaking.deployed();
    let earningsTracker = await EarningsTracker.deployed();
    let ethieToken = await EthieToken.deployed();
    let withdrawPool = await WithdrawPool.deployed();
    let gameVarAndFee = await GameVarAndFee.deployed();
    let kittieFightToken = await KittieFightToken.deployed();
    let endowmentFund = await EndowmentFund.deployed();
    let ktyUniswap = await KtyUniswap.deployed();

    accounts = await web3.eth.getAccounts();

    let tokenID = process.argv[4];

    let newLock = await earningsTracker.getPastEvents("EtherLocked", {
      fromBlock: 0,
      toBlock: "latest"
    });

    newLock.map(async (e) => {
      console.log('\n==== NEW LOCK HAPPENED ===');
      console.log('    Funder ', e.returnValues.funder)
      console.log('    TokenID ', e.returnValues.ethieTokenID)
      console.log('    Generation ', e.returnValues.generation)
      console.log('========================\n')
    })

    let owner = await ethieToken.ownerOf(tokenID);
    console.log(owner);

    let valueReturned = await earningsTracker.calculateTotal(web3.utils.toWei("5"), 0);
    console.log(web3.utils.fromWei(valueReturned.toString()));
    let burn_fee = await earningsTracker.KTYforBurnEthie(tokenID);
    let ktyFee = burn_fee[1]
    // await kittieFightToken.transfer(owner, ktyFee.toString(), {
    //   from: accounts[0]})

    // await kittieFightToken.approve(endowmentFund.address, ktyFee.toString(), { from: owner });
    // console.log(ktyFee.toString());
    // console.log(earningsTracker.address);
    await ethieToken.approve(earningsTracker.address, tokenID, { from: owner });

    ether_burn_ethie = await ktyUniswap.etherFor(ktyFee)
    console.log("KTY burn ethie fee:", weiToEther(ktyFee))
    console.log("ether needed for swap KTY burn ethie fee:", weiToEther(ether_burn_ethie))
    
    await earningsTracker.burnNFT(tokenID, { from: owner, value: ether_burn_ethie});
    let newBurn = await earningsTracker.getPastEvents("EthieTokenBurnt", {
      fromBlock: 0,
      toBlock: "latest"
    });

    newBurn.map(async (e) => {
      console.log('\n==== NEW BURN HAPPENED ===');
      console.log('    Burner ', e.returnValues.burner)
      console.log('    TokenID ', e.returnValues.ethieTokenID)
      console.log('    Generation ', e.returnValues.generation)
      console.log('    Investment ', e.returnValues.principalEther)
      console.log('    Interest ', e.returnValues.interestPaid)
      console.log('========================\n')
    })

    // uniswap reserve ratio
    console.log('\n==== UNISWAP RESERVE RATIO ===');
    ktyReserve = await ktyUniswap.getReserveKTY();
    ethReserve = await ktyUniswap.getReserveETH();
    console.log("reserveKTY:", weiToEther(ktyReserve));
    console.log("reserveETH:", weiToEther(ethReserve));

    ether_kty_ratio = await ktyUniswap.ETH_KTY_ratio();
    kty_ether_ratio = await ktyUniswap.KTY_ETH_ratio();
    console.log(
      "Ether to KTY ratio:",
      "1 ether to",
      weiToEther(ether_kty_ratio),
      "KTY"
    );
    console.log(
      "KTY to Ether ratio:",
      "1 KTY to",
      weiToEther(kty_ether_ratio),
      "ether"
    );
    

    callback()
  }
  catch(e){
    callback(e)
  }
}
