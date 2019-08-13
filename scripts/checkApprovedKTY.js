const EndowmentFund = artifacts.require('EndowmentFund')
const KittieFightToken = artifacts.require('KittieFightToken');

const KTY_ADDRESS = '0x8d05f69bd9e804eb467c7e1f2902ecd5e41a72da';

// truffle exec scripts/checkApprovedKTY.js <account> --network rinkeby

module.exports = async (callback) => {    

  try{
    kittieFightToken = await KittieFightToken.at(KTY_ADDRESS);
    endowmentFund = await EndowmentFund.deployed();
    
    //Changed
    let account = process.argv[4];

    let approvedTokens = await kittieFightToken.allowance(account, endowmentFund.address);

    if(approvedTokens) console.log(`\n${web3.utils.fromWei(approvedTokens.toString())} KTY are approved to endowment for address ${account}`);
     
    callback()
  }
  catch(e){
    callback(e)
  }
}
