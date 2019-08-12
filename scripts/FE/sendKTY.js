
const KittieFightToken = artifacts.require('ERC20Standard')

const KTY_ADDRESS = '0x8d05f69bd9e804eb467c7e1f2902ecd5e41a72da';

//truffle exec scripts/FE/sendKTY.js <#users> <amountKTY>

//Assuming account[0] has KTY available

module.exports = async (callback) => {    

  try{
    kittieFightToken = await KittieFightToken.at(KTY_ADDRESS);

    let users = accounts[process.argv[4]];
    let amountKTY = process.argv[5];

    for(let i = 1; i <= users; i++){
      let balance = await kittieFightToken.balanceOf(accounts[0])
      await kittieFightToken.transfer(accounts[i], web3.utils.toWei(String(amountKTY)), {
          from: accounts[0]
      })

      let userBalance = await kittieFightToken.balanceOf(accounts[i])

      if(userBalance) console.log(`Sent ${amountKTY} KTY to ${accounts[i]}`);
    } 
    callback()
  }
  catch(e){callback(e)}
}
