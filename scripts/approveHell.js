const KittieHELL = artifacts.require('KittieHell')
const CryptoKitties = artifacts.require('MockERC721Token');

// truffle exec scripts/approveHell.js <accountIndex> <kittyId> --network rinkeby

module.exports = async (callback) => {    

  try{
    kittieHELL = await KittieHELL.deployed()
    cryptoKitties = await CryptoKitties.deployed();
    
    //Changed
    let index = process.argv[4];
    let kittyId = process.argv[5];

    allAccounts = await web3.eth.getAccounts();

    let account = allAccounts[index];

    await cryptoKitties.approve(kittieHELL.address, kittyId, { from: account })

    let approvedAddress = await cryptoKitties.getApproved(kittyId);

    if(approvedAddress === kittieHELL.address) console.log(`\n Kittie Id ${kittyId} approved to KittieHell!`);
     
    callback()
  }
  catch(e){
    callback(e)
  }
}
