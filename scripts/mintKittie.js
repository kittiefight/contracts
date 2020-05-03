const CryptoKitties = artifacts.require('MockERC721Token');

// =================================================== //

// truffle exec scripts/mintKittie.js <kittieId> <addressTo> --network rinkeby
// accounts 0 must be owner of ckc contract

module.exports = async (callback) => {
	try{
		cryptoKitties = await CryptoKitties.deployed();
		let kittieId = process.argv[4];
		let to = process.argv[5];

		await cryptoKitties.mint(to, kittieId);

		owner = await cryptoKitties.ownerOf(kittieId);

		if (owner === to) console.log(`\nMinted kittie ${kittieId} to ${to} !`);
		else console.log(`\nError minting kittie`);

		callback();
	}
	catch(e){callback(e)}

}
