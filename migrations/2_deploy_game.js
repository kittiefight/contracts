const BigNumber = web3.utils.BN;

//ARTIFACTS
const KFProxy = artifacts.require('KFProxy')
const GenericDB = artifacts.require('GenericDB');
const ProfileDB = artifacts.require('ProfileDB')
const RoleDB = artifacts.require('RoleDB')
const GMSetterDB = artifacts.require('GMSetterDB')
const GMGetterDB = artifacts.require('GMGetterDB')
const GameManager = artifacts.require('GameManager')
const GameStore = artifacts.require('GameStore')
const GameCreation = artifacts.require('GameCreation')
const GameVarAndFee = artifacts.require('GameVarAndFee')
const Forfeiter = artifacts.require('Forfeiter')
const DateTime = artifacts.require('DateTime')
const Scheduler = artifacts.require('Scheduler')
const Betting = artifacts.require('Betting')
const HitsResolve = artifacts.require('HitsResolve')
const RarityCalculator = artifacts.require('RarityCalculator')
const Register = artifacts.require('Register')
const EndowmentFund = artifacts.require('EndowmentFund')
const EndowmentDB = artifacts.require('EndowmentDB')
const Escrow = artifacts.require('Escrow')
const KittieHELL = artifacts.require('KittieHell')
const KittieHellDB = artifacts.require('KittieHellDB')
const SuperDaoToken = artifacts.require('MockERC20Token');
const KittieFightToken = artifacts.require('ERC20Standard') // Rinkeby
const CryptoKitties = artifacts.require('MockERC721Token');
const CronJob = artifacts.require('CronJob');
const FreezeInfo = artifacts.require('FreezeInfo');
const CronJobTarget = artifacts.require('CronJobTarget');

//Rinkeby address of KittieFightToken
const KTY_ADDRESS = '0x8d05f69bd9e804eb467c7e1f2902ecd5e41a72da';

const ERC20_TOKEN_SUPPLY = new BigNumber(
    web3.utils.toWei("100000000", "ether") //100 Million
);

module.exports = (deployer, network, accounts) => {

    let medianizer;

    if (network === 'mainnet') medianizer = '0x729D19f657BD0614b4985Cf1D82531c67569197B'
    else if (network === 'rinkeby') medianizer = '0xbfFf80B73F081Cc159534d922712551C5Ed8B3D3'
    else medianizer = '0xA944bd4b25C9F186A846fd5668941AA3d3B8425F' //Kovan and other networks

    deployer.deploy(GenericDB)
        .then(() => deployer.deploy(ProfileDB, GenericDB.address))
        .then(() => deployer.deploy(EndowmentDB, GenericDB.address))
        .then(() => deployer.deploy(GMGetterDB, GenericDB.address))
        .then(() => deployer.deploy(GMSetterDB, GenericDB.address))
        .then(() => deployer.deploy(GameVarAndFee, GenericDB.address, medianizer))
        .then(() => deployer.deploy(KittieHellDB, GenericDB.address))
        .then(() => deployer.deploy(RoleDB, GenericDB.address))
        .then(() => deployer.deploy(CronJob, GenericDB.address))
        .then(() => deployer.deploy(FreezeInfo))
        .then(() => deployer.deploy(CronJobTarget))
        .then(() => deployer.deploy(SuperDaoToken, ERC20_TOKEN_SUPPLY))
        .then(() => deployer.deploy(CryptoKitties))
        .then(() => deployer.deploy(GameManager))
        .then(() => deployer.deploy(GameStore))
        .then(() => deployer.deploy(GameCreation))
        .then(() => deployer.deploy(Register))
        .then(() => deployer.deploy(DateTime))
        .then(() => deployer.deploy(Forfeiter))
        .then(() => deployer.deploy(Scheduler))
        .then(() => deployer.deploy(Betting))
        .then(() => deployer.deploy(HitsResolve))
        .then(() => deployer.deploy(EndowmentFund))
        .then(() => deployer.deploy(KittieHELL))
        .then(() => deployer.deploy(Escrow))
        .then(async (escrow) => {
            await escrow.transferOwnership(EndowmentFund.address)
        })
        .then(() => deployer.deploy(KFProxy))
        .then(async (proxy) => {

            //Contracts not deployed
            rarityCalculator = await RarityCalculator.deployed()

            console.log('\nAdding contract names to proxy...');
            await proxy.addContract('TimeContract', DateTime.address)
            await proxy.addContract('GenericDB', GenericDB.address)
            await proxy.addContract('CryptoKitties', CryptoKitties.address);
            await proxy.addContract('SuperDAOToken', SuperDaoToken.address);
            await proxy.addContract('KittieFightToken', KTY_ADDRESS)
            await proxy.addContract('ProfileDB', ProfileDB.address);
            await proxy.addContract('RoleDB', RoleDB.address);
            await proxy.addContract('Register', Register.address)
            await proxy.addContract('GameVarAndFee', GameVarAndFee.address)
            await proxy.addContract('EndowmentFund', EndowmentFund.address)
            await proxy.addContract('EndowmentDB', EndowmentDB.address)
            await proxy.addContract('Forfeiter', Forfeiter.address)
            await proxy.addContract('Scheduler', Scheduler.address)
            await proxy.addContract('Betting', Betting.address)
            await proxy.addContract('HitsResolve', HitsResolve.address)
            await proxy.addContract('RarityCalculator', RarityCalculator.address)
            await proxy.addContract('GMSetterDB', GMSetterDB.address)
            await proxy.addContract('GMGetterDB', GMGetterDB.address)
            await proxy.addContract('GameManager', GameManager.address)
            await proxy.addContract('GameStore', GameStore.address)
            await proxy.addContract('GameCreation', GameCreation.address)
            await proxy.addContract('CronJob', CronJob.address)
            await proxy.addContract('FreezeInfo', FreezeInfo.address);
            await proxy.addContract('CronJobTarget', CronJobTarget.address);
            await proxy.addContract('KittieHell', KittieHELL.address)
            await proxy.addContract('KittieHellDB', KittieHellDB.address)
        })
        .then(async () => {
            console.log('\nGetting contract instances...');
            // PROXY
            proxy = await KFProxy.deployed()

            // DATABASES
            genericDB = await GenericDB.deployed()
            profileDB = await ProfileDB.deployed();
            roleDB = await RoleDB.deployed();
            endowmentDB = await EndowmentDB.deployed()
            getterDB = await GMGetterDB.deployed()
            setterDB = await GMSetterDB.deployed()
            kittieHellDB = await KittieHellDB.deployed()

            // CRONJOB
            cronJob = await CronJob.deployed()
            freezeInfo = await FreezeInfo.deployed();
            cronJobTarget = await CronJobTarget.deployed();


            // TOKENS
            superDaoToken = await SuperDaoToken.deployed();
            kittieFightToken = await KittieFightToken.at(KTY_ADDRESS);
            cryptoKitties = await CryptoKitties.deployed();

            // MODULES
            gameManager = await GameManager.deployed()
            gameStore = await GameStore.deployed()
            gameCreation = await GameCreation.deployed()
            register = await Register.deployed()
            dateTime = await DateTime.deployed()
            gameVarAndFee = await GameVarAndFee.deployed()
            forfeiter = await Forfeiter.deployed()
            scheduler = await Scheduler.deployed()
            betting = await Betting.deployed()
            hitsResolve = await HitsResolve.deployed()
            rarityCalculator = await RarityCalculator.deployed()
            endowmentFund = await EndowmentFund.deployed()
            kittieHELL = await KittieHELL.deployed()

            //ESCROW
            escrow = await Escrow.deployed()

            console.log('\nSetting Proxy...');
            await genericDB.setProxy(proxy.address)
            await profileDB.setProxy(proxy.address);
            await roleDB.setProxy(proxy.address);
            await setterDB.setProxy(proxy.address)
            await getterDB.setProxy(proxy.address)
            await endowmentFund.setProxy(proxy.address)
            await endowmentDB.setProxy(proxy.address)
            await gameVarAndFee.setProxy(proxy.address)
            await forfeiter.setProxy(proxy.address)
            await scheduler.setProxy(proxy.address)
            await betting.setProxy(proxy.address)
            await hitsResolve.setProxy(proxy.address)
            await rarityCalculator.setProxy(proxy.address);
            await register.setProxy(proxy.address)
            await gameManager.setProxy(proxy.address)
            await gameStore.setProxy(proxy.address)
            await gameCreation.setProxy(proxy.address)
            await cronJob.setProxy(proxy.address)
            await kittieHELL.setProxy(proxy.address)
            await kittieHellDB.setProxy(proxy.address)
            await cronJobTarget.setProxy(proxy.address);
            await freezeInfo.setProxy(proxy.address);

            console.log('\nInitializing contracts...');
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

            console.log('\nAdding Super Admin and Admin to Account 0...');
            await register.addSuperAdmin(accounts[0])
            await register.addAdmin(accounts[0])

            //Then, run 
            // truffle exec scripts/upgradeEscrow.js --network rinkeby

            // truffle exec scripts/setAllGameVars.js --network rinkeby

        })
};
