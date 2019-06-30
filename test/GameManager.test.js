const BigNumber = require('bignumber.js');
require('chai')
  .use(require('chai-shallow-deep-equal'))
  .use(require('chai-bignumber')(BigNumber))
  .use(require('chai-as-promised'))
  .should();

const KFProxy = artifacts.require('GameManagerProxy') // temporary point to GameManagerProxy
const GenericDB = artifacts.require('GenericDB');
const ProfileDB = artifacts.require('ProfileDB')
const RoleDB = artifacts.require('RoleDB')
const GameManagerSetterDB = artifacts.require('GameManagerSetterDB')
const GameManagerGetterDB = artifacts.require('GameManagerGetterDB')
const GameManager = artifacts.require('GameManager')
const GameVarAndFee = artifacts.require('GameVarAndFee')
const Distribution = artifacts.require('Distribution')
const Forfeiter = artifacts.require('Forfeiter')
const DateTime = artifacts.require('DateTime')
const Scheduler = artifacts.require('Scheduler')
const Betting = artifacts.require('Betting')
const HitsResolve = artifacts.require('HitsResolve')
const RarityCalculator = artifacts.require('RarityCalculator')
const Register = artifacts.require('Register')
const EndowmentFund = artifacts.require('EndowmentFund')
const KittieHELL = artifacts.require('KittieHELL')
const SuperDaoToken = artifacts.require('MockERC20Token');
const KittieFightToken = artifacts.require('MockERC20Token');
const CryptoKitties = artifacts.require('MockERC721Token');
const ERC20_TOKEN_SUPPLY = new BigNumber(1000000);

before(async function(){
  this.timeout(10000);
  this.proxy = await KFProxy.new()
  this.dateTime = await DateTime.new()
  this.genericDB = await GenericDB.new()
  this.profileDB = await ProfileDB.new(this.genericDB.address);
  this.roleDB = await RoleDB.new(this.genericDB.address);
  this.superDaoToken = await SuperDaoToken.new(ERC20_TOKEN_SUPPLY);
  this.kittieFightToken = await KittieFightToken.new(ERC20_TOKEN_SUPPLY);
  this.cryptoKitties = await CryptoKitties.new();
  this.register = await Register.new()
  this.gameVarAndFee = await GameVarAndFee.new(this.genericDB.address)
  // this.endowmentFund = await EndowmentFund.new()
  // this.distribution = await Distribution.new()
  this.forfeiter = await Forfeiter.new()
  this.scheduler = await Scheduler.new()
  // this.betting = await Betting.new()
  // this.hitsResolve = await HitsResolve.new()
  // this.rarityCalculator = await RarityCalculator.new()
  // this.kittieHELL = await KittieHELL.new(this.contractManager.address)
  this.gameManagerGetter = await GameManagerGetterDB.new(this.genericDB.address)
  this.gameManagerSetter = await GameManagerSetterDB.new(this.genericDB.address)
  this.gameManager = await GameManager.new()

  await this.proxy.addContract('TimeContract', this.dateTime.address)
  await this.proxy.addContract('GenericDB', this.genericDB.address)
  await this.proxy.addContract('CryptoKitties', this.cryptoKitties.address);
  await this.proxy.addContract('SuperDAOToken', this.superDaoToken.address);
  await this.proxy.addContract('KittieFightToken', this.kittieFightToken.address);
  await this.proxy.addContract('ProfileDB', this.profileDB.address);
  await this.proxy.addContract('RoleDB', this.roleDB.address);
  await this.proxy.addContract('Register', this.register.address)
  await this.proxy.addContract('GameVarAndFee', this.gameVarAndFee.address)
  // await this.proxy.addContract('EndowmentFund', this.endowmentFund.address)
  // await this.proxy.addContract('Distribution', this.distribution.address)
  await this.proxy.addContract('Forfeiter', this.forfeiter.address)
  await this.proxy.addContract('Scheduler', this.scheduler.address)
  // await this.proxy.addContract('Betting', this.betting.address)
  // await this.proxy.addContract('HitsResolve', this.hitsResolve.address)
  // await this.proxy.addContract('RarityCalculator', this.rarityCalculator.address)
  // await this.proxy.addContract('KittieHELL', this.kittieHELL.address)
  await this.proxy.addContract('GameManagerSetterDB', this.gameManagerSetter.address)
  await this.proxy.addContract('GameManagerGetterDB', this.gameManagerGetter.address)
  await this.proxy.addContract('GameManager', this.gameManager.address)


  await this.genericDB.setProxy(this.proxy.address)
  await this.profileDB.setProxy(this.proxy.address);
  await this.roleDB.setProxy(this.proxy.address);
  await this.gameManagerSetter.setProxy(this.proxy.address)
  await this.gameManagerGetter.setProxy(this.proxy.address)
  // await this.endowmentFund.setProxy(this.proxy.address)
  await this.gameVarAndFee.setProxy(this.proxy.address)
  // await this.distribution.setProxy(this.proxy.address)
  await this.forfeiter.setProxy(this.proxy.address)
  await this.dateTime.setProxy(this.proxy.address)
  await this.scheduler.setProxy(this.proxy.address)
  // await this.betting.setProxy(this.proxy.address)
  // await this.hitsResolve.setProxy(this.proxy.address)
  // await this.rarityCalculator.setProxy(this.proxy.address)
  await this.register.setProxy(this.proxy.address)
  // await this.kittieHELL.setProxy(this.proxy.address)
  await this.gameManager.setProxy(this.proxy.address)

  await this.dateTime.initialize()
  await this.gameVarAndFee.initialize()
  await this.forfeiter.updateContracts()
  await this.scheduler.initialize()
  await this.register.initialize()
  await this.gameManager.initialize()

})

contract('GameManager', (accounts) => {

    // listKittie()
    it('should be able to list kittie with valid account and kitty via proxy', async () => {

    })

    it('is not able to list kittie without proxy', async () => {

    })

    it('is not able to list kittie without a player role', async () => {

    })

    it('is not able to list kittie without kitty ownership', async () => {

    })


    // manualMatchKitties()
    it('should be able to manual match by admin and valid players via proxy', async () => {

    })

    it('is not able to manual match without proxy', async () => {

    })

    it('is not able to manual match without admin role', async () => {

    })

    it('is not able to manual match with either one invalid player', async () => {

    })

    // participate()
    it('should be able to participate with all valid pre-checks via proxy', async () => {

    })

    it('is not able to participate with all valid checks without proxy', async () => {

    })

    it('is not able to participate with invalid player to support', async () => {

    })

    it('is not able to participate with game finished or cancelled', async () => {

    })

    // startGame()
    it('should be able to start game by either playerRed or playerBlack via proxy', async () => {

    })

    it('is not able to start game by either without proxy', async () => {

    })

    it('is not able to start game by invalid game player', async () => {

    })

    it('is not able to start game when state is not PRE-START', async () => {

    })
    
    // bet()
    it('should be able to bet with bettor role via proxy', async () => {

    })

    it('is not able to bet without proxy', async () => {

    })

    it('is not able to bet if game is not yet started', async () => {

    })
})