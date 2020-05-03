const KFProxy = artifacts.require('KFProxy')
const GMGetterDB = artifacts.require('GMGetterDB')
const EndowmentFund = artifacts.require('EndowmentFund')

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

function timeout(s) {
  // console.log(`~~~ Timeout for ${s} seconds`);
  return new Promise(resolve => setTimeout(resolve, s * 1000));
}

//truffle exec scripts/FE/claim_others.js gameId(uint)
//                                        

module.exports = async (callback) => {
  try{
    let proxy = await KFProxy.deployed();
    let getterDB = await GMGetterDB.deployed();
    let endowmentFund = await EndowmentFund.deployed();

    accounts = await web3.eth.getAccounts();

    let gameId = process.argv[4];

    let winners = await getterDB.getWinners(gameId);
    let winner = winners.winner;
    let numberOfSupporters;
    let incrementingNumber;
    let claimer;

    let {playerBlack, playerRed, kittyBlack, kittyRed} = await getterDB.getGamePlayers(gameId);

    if(winner === playerBlack){
      numberOfSupporters = await getterDB.getSupporters(gameId, playerBlack);
      incrementingNumber = 10;
    }
    else{
      numberOfSupporters = await getterDB.getSupporters(gameId, playerRed);
      incrementingNumber = 30; 
    }

    for(let i=0; i<numberOfSupporters; i++){
      claimer = accounts[i+incrementingNumber];
      if(claimer === winners.topBettor) continue;
      else if(claimer === winners.secondTopBettor) continue;
      else{

        let share = await endowmentFund.getWinnerShare(gameId, claimer);
        console.log('\nClaimer withdrawing ', String(web3.utils.fromWei(share.winningsETH.toString())), 'ETH');
        if(Number(String(web3.utils.fromWei(share.winningsETH.toString()))) != 0){
          await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'claim',
            [gameId]), { from: claimer });
          let withdrawalState = await endowmentFund.getWithdrawalState(gameId, claimer);
          console.log('Withdrew funds from Claimer? ', withdrawalState);
        }

        await timeout(1);

      }
    }

    callback()
  }
  catch(e){callback(e)}
}