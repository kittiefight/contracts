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

    accounts = await web3.eth.getAccounts();

    let gameId = process.argv[4];

    let {endowmentBalanceKTY, endowmentBalanceETH} = await endowmentDB.getEndowmentBalance();
    console.log(Number(endowmentBalanceETH), Number(endowmentBalanceKTY));

    endowmentFund.dissolveTest(gameId, {from: accounts[0]});

    let {endowmentBalanceKTY1, endowmentBalanceETH1} = await endowmentDB.getEndowmentBalance();
    console.log(Number(endowmentBalanceETH1), Number(endowmentBalanceKTY1));
    let honeyPotInfo = await getterDB.getHoneypotInfo(gameId);

    console.log(`\n==== HONEYPOT INFO ==== `)
    console.log(`     InitialEtH: ${web3.utils.fromWei(honeyPotInfo.initialEth.toString())}   `);
    console.log(`     TotalETH: ${web3.utils.fromWei(honeyPotInfo.ethTotal.toString())}   `);
    console.log(`     TotalKTY: ${web3.utils.fromWei(honeyPotInfo.ktyTotal.toString())}   `);
    console.log('=======================\n')

    callback()
  }
  catch(e){callback(e)}
}