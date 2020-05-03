const KFProxy = artifacts.require('KFProxy')
const EndowmentFund = artifacts.require('EndowmentFund')

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

//truffle exec scripts/claim.js <gameId> <accountIndex> --network rinkeby
                                      

module.exports = async (callback) => {
  try{
    let proxy = await KFProxy.deployed();
    let endowmentFund = await EndowmentFund.deployed();

    let gameId = process.argv[4];
    let accountIndex = process.argv[5];

    allAccounts = await web3.eth.getAccounts();

    let account = allAccounts[accountIndex];

    let share = await endowmentFund.getWinnerShare(gameId, account);

    console.log('\nWithdrawing ', String(web3.utils.fromWei(share.winningsETH.toString())), 'ETH ...')
    await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'claim',
      [gameId]), { from: account });

    let withdrawalState = await endowmentFund.getWithdrawalState(gameId, account);
    console.log('Withdrew funds ? ', withdrawalState, "\n");


    callback()
  }
  catch(e){callback(e)}
}