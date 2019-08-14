const CryptoKitties = artifacts.require('MockERC721Token');
const KittieHELL = artifacts.require('KittieHell');

// =================================================== //

// truffle exec scripts/checkKittie.js <kittieId> --network rinkeby

module.exports = async (callback) => {
	try{
		cryptoKitties = await CryptoKitties.deployed();
		kittieHELL = await KittieHELL.deployed()
        
        let kittieId = process.argv[4];
		let owner = await cryptoKitties.ownerOf(kittieId);		
		let approved = await cryptoKitties.getApproved(kittieId);

		console.log(`\n Kittie Id: ${kittieId}`);
		console.log(` Kittie Owner: ${owner}`);
		console.log(` Approved to KittiHell?: ${approved === kittieHELL.address}`);

		callback();
	}
	catch(e){callback(e)}

}
