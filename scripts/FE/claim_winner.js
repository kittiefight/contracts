const KFProxy = artifacts.require('KFProxy')
const GMGetterDB = artifacts.require('GMGetterDB')
const EndowmentFund = artifacts.require('EndowmentFund')

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

//truffle exec scripts/FE/claim_winner.js gameId(uint)
//                                        

module.exports = async (callback) => {
  try{
    let proxy = await KFProxy.deployed();
    let getterDB = await GMGetterDB.deployed();
    let endowmentFund = await EndowmentFund.deployed();

    accounts = await web3.eth.getAccounts();

    let gameId = process.argv[4];

    let winners = await getterDB.getWinners(gameId);

    let share = await endowmentFund.getWinnerShare(gameId, winners.winner);
    console.log('\nWinner withdrawing ', String(web3.utils.fromWei(share.winningsETH.toString())), 'ETH')
    await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'claim',
      [gameId]), { from: winners.winner });
    let withdrawalState = await endowmentFund.getWithdrawalState(gameId, winners.winner);
    console.log('Withdrew funds from Winner? ', withdrawalState);


    callback()
  }
  catch(e){callback(e)}
}