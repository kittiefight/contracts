const KFProxy = artifacts.require('KFProxy')
const GMGetterDB = artifacts.require('GMGetterDB')
const EndowmentFund = artifacts.require('EndowmentFund')
const EndowmentDB = artifacts.require('EndowmentDB')

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

//truffle exec scripts/FE/claim_top.js gameId(uint)
//                                        

module.exports = async (callback) => {
  try{
    let proxy = await KFProxy.deployed();
    let getterDB = await GMGetterDB.deployed();
    let endowmentFund = await EndowmentFund.deployed();
    let endowmentDB = await EndowmentDB.deployed();

    let balance = await endowmentDB.getEndowmentBalance();
    console.log(balance.endowmentBalanceETH.toString());
    console.log(balance.endowmentBalanceKTY.toString());

    accounts = await web3.eth.getAccounts();

    let gameId = process.argv[4];

    let winners = await getterDB.getWinners(gameId);
    let topBettorsShare = await endowmentFund.getWinnerShare(gameId, winners.topBettor);

    let share = await endowmentFund.getWinnerShare(gameId, winners.topBettor);
    console.log('\nTop Bettor withdrawing ', String(web3.utils.fromWei(share.winningsETH.toString())), 'ETH')
    await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'claim',
      [gameId]), { from: winners.topBettor });
    let withdrawalState = await endowmentFund.getWithdrawalState(gameId, winners.topBettor);
    console.log('Withdrew funds from Top Bettor? ', withdrawalState);


    callback()
  }
  catch(e){callback(e)}
}