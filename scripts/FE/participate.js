const KFProxy = artifacts.require('KFProxy')
const GMGetterDB = artifacts.require('GMGetterDB')
const GameStore = artifacts.require('GameStore')
const GameManager = artifacts.require('GameManager')
const DateTime = artifacts.require('DateTime')
const RoleDB = artifacts.require('RoleDB')
const Escrow = artifacts.require('Escrow')
const EndowmentFund = artifacts.require('EndowmentFund')
const KtyUniswap = artifacts.require("KtyUniswap");
const KittieFightToken = artifacts.require('KittieFightToken')
const GameManagerHelper = artifacts.require('GameManagerHelper')

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

function formatDate(timestamp) {
  let date = new Date(null);
  date.setSeconds(timestamp);
  return date.toTimeString().replace(/.*(\d{2}:\d{2}:\d{2}).*/, "$1");
}

function weiToEther(w) {
  //let eth = web3.utils.fromWei(w.toString(), "ether");
  //return Math.round(parseFloat(eth));
  return web3.utils.fromWei(w.toString(), "ether");
}

//truffle exec scripts/FE/participate.js gameId(uint) noOfParticipatorsForBlack(uint) noOfParticipatorsForRed(uint) 
//                                       timeBetweenParticipates[uint(seconds)] 

module.exports = async (callback) => {
  try{
    let proxy = await KFProxy.deployed();
    let gameManager = await GameManager.deployed();
    let getterDB = await GMGetterDB.deployed();
    let gameStore = await GameStore.deployed();
    let dateTime = await DateTime.deployed();
    let roleDB = await RoleDB.deployed();
    let escrow = await Escrow.deployed();
    let endowmentFund = await EndowmentFund.deployed();
    let ktyUniswap = await KtyUniswap.deployed();
    let kittieFightToken = await KittieFightToken.deployed()
    let gameManagerHelper = await GameManagerHelper.deployed()

    accounts = await web3.eth.getAccounts();

    let gameId = process.argv[4];
    let blackParticipators = process.argv[5];
    let redParticipators = process.argv[6]; 
    let timeInterval = process.argv[7];
    let supportersForRed = [];
    let supportersForBlack = [];
    let ticketFee = await gameManagerHelper.getTicketFee(gameId);

    let KTY_escrow_before_swap = await kittieFightToken.balanceOf(escrow.address)

    let {playerBlack, playerRed, kittyBlack, kittyRed} = await getterDB.getGamePlayers(gameId);
    let participator;

    //accounts 10-29 can be supporters for black
    let blacks = Number(blackParticipators) + 10;
    let reds = Number(redParticipators) + 30;

    for(let i = 10; i < blacks; i++){
      let participate_fee = await gameManagerHelper.getTicketFee(gameId);
      let ether_participate = participate_fee[0]
      let kty_participate = participate_fee[1]
      console.log("ether needed for swapping participate_fee in kty:", weiToEther(ether_participate))
      console.log("participate_fee in kty:", weiToEther(kty_participate))
      participator = accounts[i];
      await proxy.execute('GameManager', setMessage(gameManager, 'participate',
      [gameId, playerBlack]), { from: participator, value: ether_participate })
      console.log('\nNew Participator for playerBlack: ', participator);
      supportersForBlack.push(participator);

      await timeout(timeInterval);
    }

    //accounts 30-49 can be supporters for red
    for(let j = 30; j < reds; j++){
      participator = accounts[j]; 
      if(j == (Number(reds) - 1)){
        let block = await dateTime.getBlockTimeStamp();
        console.log('\nblocktime: ', formatDate(block))

        let {preStartTime} = await getterDB.getGameTimes(gameId);

        while (block < preStartTime) {
          block = Math.floor(Date.now() / 1000);
          await timeout(3);
        }
      }
      let participate_fee = await gameManagerHelper.getTicketFee(1);
      let ether_participate = participate_fee[0]
      let kty_participate = participate_fee[1]
      console.log("ether needed for swapping participate_fee in kty:", weiToEther(ether_participate))
      console.log("participate_fee in kty:", weiToEther(kty_participate))

      await proxy.execute('GameManager', setMessage(gameManager, 'participate',
      [gameId, playerRed]), { from: participator, value: ether_participate });
      console.log('\nNew Participator for playerRed: ', participator);
      supportersForRed.push(participator);

      await timeout(timeInterval);

    }

    console.log('\nSupporters for Black: ', supportersForBlack);
    console.log('\nSupporters for Red: ', supportersForRed);
    
    let newSwapEvents = await endowmentFund.getPastEvents("EthSwappedforKTY", {
      fromBlock: 0,
      toBlock: "latest"
    });

    newSwapEvents.map(async (e) => {

      console.log('\n==== NEW Swap CREATED ===');
      console.log('    sender ', e.returnValues.sender)
      console.log('    ether for swap ', e.returnValues.ethAmount)
      console.log('    KTY swapped ', e.returnValues.ktyAmount)
      console.log('    ether receiver ', e.returnValues.receiver)
      console.log('========================\n')
    })

    // escrow KTY balance
    let KTY_escrow_after_swap = await kittieFightToken.balanceOf(escrow.address)
    console.log("escrow KTY balance before swap:", weiToEther(KTY_escrow_before_swap))
    console.log("escrow KTY balance after swap:", weiToEther(KTY_escrow_after_swap))

    // uniswap reserve ratio

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
  catch(e){callback(e)}

}

