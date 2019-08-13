
const KFProxy = artifacts.require('KFProxy')


//truffle exec scripts/executeJobs.js  
// bet in a gameId from address of accounts[index] amountBet(eth)

module.exports = async (callback) => {
	try{
        proxy = await KFProxy.deployed()
        
        await proxy.executeScheduledJobs()

        console.log('Executed Cron jobs!');

		callback()
	}
	catch(e){callback(e)}

}