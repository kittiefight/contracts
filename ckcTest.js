require('dotenv').config()

const getKittyGenes = async (kittieId) => {
    let Web3 = require('web3');
    const jIKittyCore = require("./build/contracts/IKittyCore.json");
    const ckcAddress = '0x06012c8cf97bead5deae237070f9587f8e7a266d'       
    let myweb3 = new Web3(`https://mainnet.infura.io/v3/${process.env.INFURA_KEY}`);
    ckcMainnet = new myweb3.eth.Contract(jIKittyCore.abi, ckcAddress)
    let response = await ckcMainnet.methods.getKitty(kittieId).call()
    console.log('Kitty genes: ',response['9'].toString());
}

getKittyGenes(10001);