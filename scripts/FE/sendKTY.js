const EndowmentFund = artifacts.require('EndowmentFund')
const KittieFightToken = artifacts.require('KittieFightToken');

//truffle exec scripts/FE/sendKTY.js <#users> <amountKTY>

module.exports = async (callback) => {    

  try{
    let kittieFightToken = await KittieFightToken.deployed();
    let endowmentFund = await EndowmentFund.deployed();
    
    //Changed
    let users = process.argv[4];
    let amountKTY = process.argv[5];

    accounts = await web3.eth.getAccounts();

    for(let i = 1; i <= users; i++){
      await kittieFightToken.transfer(accounts[i], web3.utils.toWei(String(amountKTY)), {
          from: accounts[0]})

      await kittieFightToken.approve(endowmentFund.address, web3.utils.toWei(String(amountKTY)) , { from: accounts[i] })

      let userBalance = await kittieFightToken.balanceOf(accounts[i]);

      if(userBalance) console.log(`Sent ${amountKTY} KTY to ${accounts[i]}`);
    } 
    callback()
  }
  catch(e){
    callback(e)
  }
}
