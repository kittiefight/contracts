const GMSetterDB = artifacts.require('GMSetterDB')
const GMGetterDB = artifacts.require('GMGetterDB')
const GameManager = artifacts.require('GameManager')
const GameStore = artifacts.require('GameStore')
const GameCreation = artifacts.require('GameCreation')
const Forfeiter = artifacts.require('Forfeiter')
const Scheduler = artifacts.require('Scheduler')
const HitsResolve = artifacts.require('HitsResolve')
const Register = artifacts.require('Register')
const EndowmentFund = artifacts.require('EndowmentFund')
const KittieHELL = artifacts.require('KittieHell')
const KittieHellDB = artifacts.require('KittieHellDB')

// truffle exec scripts/initialize.js --network rinkeby

module.exports = async (callback) => {

	try{

        gameStore = await GameStore.deployed()
        gameCreation = await GameCreation.deployed()
        forfeiter = await Forfeiter.deployed()
        scheduler = await Scheduler.deployed()
        register = await Register.deployed()
        gameManager = await GameManager.deployed()
        getterDB = await GMGetterDB.deployed()
        setterDB = await GMSetterDB.deployed()
        endowmentFund = await EndowmentFund.deployed()
        kittieHellDB = await KittieHellDB.deployed()
        kittieHELL = await KittieHELL.deployed()
        hitsResolve = await HitsResolve.deployed()

        console.log('Initializing contract addresses...')
        await gameStore.initialize()
        await gameCreation.initialize()
        await forfeiter.initialize()
        await scheduler.initialize()
        await register.initialize()
        await gameManager.initialize()
        await getterDB.initialize()
        await setterDB.initialize()
        await endowmentFund.initialize()    
        await kittieHellDB.setKittieHELL()
        await kittieHELL.initialize()
        await hitsResolve.initialize()
        console.log('\nDone!')

		callback();
	}
	catch(e){callback(e)}

}


    