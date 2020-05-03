const EndowmentFund = artifacts.require('EndowmentFund')
const KittieFightToken = artifacts.require('KittieFightToken');

const KTY_ADDRESS = '0x8d05f69bd9e804eb467c7e1f2902ecd5e41a72da';

// truffle exec scripts/approveKTY.js <accountIndex> <amountKTY> --network rinkeby

module.exports = async (callback) => {    

  try{
    kittieFightToken = await KittieFightToken.at(KTY_ADDRESS);
    endowmentFund = await EndowmentFund.deployed();
    
    //Changed
    let index = process.argv[4];
    let amountKTY = process.argv[5];

    allAccounts = await web3.eth.getAccounts();

    let account = allAccounts[index];

    await kittieFightToken.approve(endowmentFund.address, web3.utils.toWei(String(amountKTY)) , 
        { from: account })

    let approvedTokens = await kittieFightToken.allowance(account, endowmentFund.address);

    if(approvedTokens) console.log(`\n${account} approved ${amountKTY} KTY to endowment`);
     
    callback()
  }
  catch(e){
    callback(e)
  }
}
