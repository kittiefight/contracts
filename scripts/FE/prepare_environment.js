const KFProxy = artifacts.require('KFProxy')
const Register = artifacts.require('Register')
const KittieHell = artifacts.require('KittieHell')
const CryptoKitties = artifacts.require('MockERC721Token');

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

//truffle exec scripts/FE/prepare_environment.js noOfUsersToBePlayers(uint) (please max 8 players)

module.exports = async (callback) => {
  try{

    let proxy = await KFProxy.deployed();
    let register = await Register.deployed();
    let kittieHell = await KittieHell.deployed();
    let cryptoKitties = await CryptoKitties.deployed()

    accounts = await web3.eth.getAccounts();

    let noOfPlayers = process.argv[4];

    const kitties = [324, 1001, 1555108, 1267904, 454545, 333, 6666, 2111];
    const cividIds = [1, 2, 3, 4, 5, 6, 7, 8];

    for (let i = 0; i < noOfPlayers; i++) {
      await cryptoKitties.mint(accounts[i + 1], kitties[i]);
      await cryptoKitties.approve(kittieHell.address, kitties[i], { from: accounts[i + 1] });
      await proxy.execute('Register', setMessage(register, 'verifyAccount', [cividIds[i]]), { from: accounts[i + 1]});

      console.log(`New Player ${accounts[i + 1]} with Kitty ${kitties[i]}`);
    }

    callback()
  }
  catch(e){callback(e)}
}