const KFProxy = artifacts.require('KFProxy')
const GMGetterDB = artifacts.require('GMGetterDB')
const EndowmentFund = artifacts.require('EndowmentFund')

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

//truffle exec scripts/FE/claim_second.js gameId(uint)
//                                        

module.exports = async (callback) => {
  try{
    let proxy = await KFProxy.deployed();
    let getterDB = await GMGetterDB.deployed();
    let endowmentFund = await EndowmentFund.deployed();

    accounts = await web3.eth.getAccounts();

    let gameId = process.argv[4];

    let winners = await getterDB.getWinners(gameId);
    let secondTopBettorsShare = await endowmentFund.getWinnerShare(gameId, winners.secondTopBettor);

    let share = await endowmentFund.getWinnerShare(gameId, winners.secondTopBettor);
    console.log('\nSecond Top Bettor withdrawing ', String(web3.utils.fromWei(share.winningsETH.toString())), 'ETH')
    await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'claim',
      [gameId]), { from: winners.secondTopBettor });
    let withdrawalState = await endowmentFund.getWithdrawalState(gameId, winners.secondTopBettor);
    console.log('Withdrew funds from Second Top Bettor? ', withdrawalState);


    callback()
  }
  catch(e){callback(e)}
}