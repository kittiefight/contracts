const KFProxy = artifacts.require('KFProxy')

// truffle exec scripts/upgradeContract.js <contractName> --network rinkeby

module.exports = async (callback) => {

	try{
        let contractName = process.argv[4];
        const contractArtifact = artifacts.require(`${contractName}`)

        proxy = await KFProxy.deployed()

        console.log(`Deploying new ${contractName}`)
        contractInst = await contractArtifact.new()        

        console.log('Adding contract address to proxy...')
        await proxy.updateContract(contractName, contractInst.address)
        
        console.log('Setting proxy address to upgraded contract...')
        await contractInst.setProxy(proxy.address)

        callback();
        
	}
	catch(e){callback(e)}

}


    