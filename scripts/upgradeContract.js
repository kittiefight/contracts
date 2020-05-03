const KFProxy = artifacts.require('KFProxy')
const GenericDB = artifacts.require('GenericDB');

// truffle exec scripts/upgradeContract.js <contractName> <needsGenericDB?(1 or 0)> --network rinkeby

// Only for contracts without constructor parameters. You will have to edit the file for that.

module.exports = async (callback) => {

	try{
        let contractName = process.argv[4];
        let needsGenericDB = process.argv[5];

        const contractArtifact = artifacts.require(`${contractName}`)

        genericDB = await GenericDB.deployed()
        proxy = await KFProxy.deployed()

        console.log(`Deploying new ${contractName} contract`)

        let contractInst;

        if(Number(needsGenericDB) === 1) contractInst = await contractArtifact.new(genericDB.address)
        else contractInst = await contractArtifact.new() 

        console.log(`New address of ${contractName}: ${contractInst.address}`)        

        console.log('Adding contract address to proxy...')
        await proxy.updateContract(contractName, contractInst.address)
        
        console.log('Setting proxy address to upgraded contract...')
        await contractInst.setProxy(proxy.address)

        console.log('\nDone!')
        callback();
        
	}
	catch(e){callback(e)}

}


    