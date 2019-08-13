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

//truffle exec scripts/FE/claim_all.js gameId(uint)
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

    let winnerShare = await endowmentFund.getWinnerShare(gameId, winners.winner);
    console.log('\nWinner withdrawing ', String(web3.utils.fromWei(winnerShare.winningsETH.toString())), 'ETH')
    await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'claim',
      [gameId]), { from: winners.winner });
    let withdrawalState = await endowmentFund.getWithdrawalState(gameId, winners.winner);
    console.log('Withdrew funds from Winner? ', withdrawalState);

    await timeout(1);

    let topBettorsShare = await endowmentFund.getWinnerShare(gameId, winners.topBettor);
    console.log('\nTop Bettor withdrawing ', String(web3.utils.fromWei(topBettorsShare.winningsETH.toString())), 'ETH')
    await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'claim',
      [gameId]), { from: winners.topBettor });
    withdrawalState = await endowmentFund.getWithdrawalState(gameId, winners.topBettor);
    console.log('Withdrew funds from Top Bettor? ', withdrawalState);

    await timeout(1);

    let secondTopBettorsShare = await endowmentFund.getWinnerShare(gameId, winners.secondTopBettor);
    console.log('\nSecond Top Bettor withdrawing ', String(web3.utils.fromWei(secondTopBettorsShare.winningsETH.toString())), 'ETH')
    await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'claim',
      [gameId]), { from: winners.secondTopBettor });
    withdrawalState = await endowmentFund.getWithdrawalState(gameId, winners.secondTopBettor);
    console.log('Withdrew funds from Second Top Bettor? ', withdrawalState);

    await timeout(1);


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

        share = await endowmentFund.getWinnerShare(gameId, claimer);
        console.log('\nClaimer withdrawing ', String(web3.utils.fromWei(share.winningsETH.toString())), 'ETH')
        await proxy.execute('EndowmentFund', setMessage(endowmentFund, 'claim',
          [gameId]), { from: claimer });
        withdrawalState = await endowmentFund.getWithdrawalState(gameId, claimer);
        console.log('Withdrew funds from Claimer? ', withdrawalState);

        await timeout(1);

      }
    }

    callback()
  }
  catch(e){callback(e)}
}