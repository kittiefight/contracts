const BigNumber = require('bignumber.js');
require('chai')
  .use(require('chai-shallow-deep-equal'))
  .use(require('chai-bignumber')(BigNumber))
  .use(require('chai-as-promised'))
  .should();

const KFProxy = artifacts.require('KFProxy')
const GenericDB = artifacts.require('GenericDB');
const ProfileDB = artifacts.require('ProfileDB')
const RoleDB = artifacts.require('RoleDB')
const GMSetterDB = artifacts.require('GMSetterDB')
const GMGetterDB = artifacts.require('GMGetterDB')
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

let proxy
let dateTime
let genericDB
let profileDB
let roleDB
let superDaoToken
let kittieFightToken
let cryptoKitties
let register
let gameVarAndFee
// endowmentFund
// distribution
let forfeiter
let scheduler
// betting
// hitsResolve
// rarityCalculator
// kittieHELL
let getterDB
let gameManagerDB
let gameManager

let errorMessage
let ERROR = {
  NO_PROXY: 'Only through Proxy',
  ONLY_SUPER_ADMIN: 'Only super admin',
  ONLY_ADMIN: 'Only admin',
  ONLY_PLAYER: 'Only player',
  ONLY_BETTOR: 'Only bettor',
  INVALID_PLAYER: 'Invalid player'
}

const kittie1 = 1234
const kittie2 = 32452
const kittie3 = 23134
const kittie4 = 44444
const kittie5 = 55555
const kittie6 = 6666

contract('GameManager', ([creator, user1, user2, unauthorizedUser, randomAddress]) => {

  beforeEach(async function () {
    this.timeout(10000);
    errorMessage = ''

    proxy = await KFProxy.new()
    dateTime = await DateTime.new()
    genericDB = await GenericDB.new()
    profileDB = await ProfileDB.new(genericDB.address);
    roleDB = await RoleDB.new(genericDB.address);
    superDaoToken = await SuperDaoToken.new(ERC20_TOKEN_SUPPLY);
    kittieFightToken = await KittieFightToken.new(ERC20_TOKEN_SUPPLY);
    cryptoKitties = await CryptoKitties.new();
    register = await Register.new()
    gameVarAndFee = await GameVarAndFee.new(genericDB.address, randomAddress)
    // endowmentFund = await EndowmentFund.new()
    // distribution = await Distribution.new()
    forfeiter = await Forfeiter.new()
    scheduler = await Scheduler.new()
    // betting = await Betting.new()
    // hitsResolve = await HitsResolve.new()
    // rarityCalculator = await RarityCalculator.new()
    // kittieHELL = await KittieHELL.new(contractManager.address)
    getterDB = await GMGetterDB.new(genericDB.address)
    gameManagerDB = await GMSetterDB.new(genericDB.address)
    gameManager = await GameManager.new()

    await proxy.addContract('TimeContract', dateTime.address)
    await proxy.addContract('GenericDB', genericDB.address)
    await proxy.addContract('CryptoKitties', cryptoKitties.address);
    await proxy.addContract('SuperDAOToken', superDaoToken.address);
    await proxy.addContract('KittieFightToken', kittieFightToken.address);
    await proxy.addContract('ProfileDB', profileDB.address);
    await proxy.addContract('RoleDB', roleDB.address);
    await proxy.addContract('Register', register.address)
    await proxy.addContract('GameVarAndFee', gameVarAndFee.address)
    // await proxy.addContract('EndowmentFund', endowmentFund.address)
    // await proxy.addContract('Distribution', distribution.address)
    await proxy.addContract('Forfeiter', forfeiter.address)
    await proxy.addContract('Scheduler', scheduler.address)
    // await proxy.addContract('Betting', betting.address)
    // await proxy.addContract('HitsResolve', hitsResolve.address)
    // await proxy.addContract('RarityCalculator', rarityCalculator.address)
    // await proxy.addContract('KittieHELL', kittieHELL.address)
    await proxy.addContract('GameManagerDB', gameManagerDB.address)
    await proxy.addContract('GetterDB', getterDB.address)
    await proxy.addContract('GameManager', gameManager.address)


    await genericDB.setProxy(proxy.address)
    await profileDB.setProxy(proxy.address);
    await roleDB.setProxy(proxy.address);
    await gameManagerDB.setProxy(proxy.address)
    await getterDB.setProxy(proxy.address)
    // await endowmentFund.setProxy(proxy.address)
    await gameVarAndFee.setProxy(proxy.address)
    // await distribution.setProxy(proxy.address)
    await forfeiter.setProxy(proxy.address)
    await dateTime.setProxy(proxy.address)
    await scheduler.setProxy(proxy.address)
    // await betting.setProxy(proxy.address)
    // await hitsResolve.setProxy(proxy.address)
    // await rarityCalculator.setProxy(proxy.address)
    await register.setProxy(proxy.address)
    // await kittieHELL.setProxy(proxy.address)
    await gameManager.setProxy(proxy.address)

    await dateTime.initialize()
    await gameVarAndFee.initialize()
    await forfeiter.updateContracts()
    await scheduler.initialize()
    await register.initialize()
    await gameManager.initialize()

    // Mint some kitties for the test addresses
    await cryptoKitties.mint(user1, kittie1).should.be.fulfilled;
    await cryptoKitties.mint(user2, kittie2).should.be.fulfilled;
    await cryptoKitties.mint(creator, kittie3).should.be.fulfilled;
    await cryptoKitties.mint(user1, kittie4).should.be.fulfilled;
    await cryptoKitties.mint(user2, kittie5).should.be.fulfilled;
    await cryptoKitties.mint(user2, kittie6).should.be.fulfilled;

    // Approve transfer operation for the system
    await cryptoKitties.approve(register.address, kittie1, { from: user1 }).should.be.fulfilled;
    await cryptoKitties.approve(register.address, kittie2, { from: user2 }).should.be.fulfilled;
    await cryptoKitties.approve(register.address, kittie3).should.be.fulfilled;
    await cryptoKitties.approve(register.address, kittie4, { from: user1 }).should.be.fulfilled;
    await cryptoKitties.approve(register.address, kittie5, { from: user2 }).should.be.fulfilled;
    await cryptoKitties.approve(register.address, kittie6, { from: user2 }).should.be.fulfilled;

    // Send some SuperDAO and KitttieFight tokens to users
    await superDaoToken.transfer(user1, 100000).should.be.fulfilled;
    await superDaoToken.transfer(user2, 100000).should.be.fulfilled;
    await kittieFightToken.transfer(user1, 100000).should.be.fulfilled;
    await kittieFightToken.transfer(user2, 100000).should.be.fulfilled;

    // Approve erc20 token transfer operation for the system
    await superDaoToken.approve(register.address, 100000, { from: user1 }).should.be.fulfilled;
    await superDaoToken.approve(register.address, 100000, { from: user2 }).should.be.fulfilled;
    await kittieFightToken.approve(register.address, 100000, { from: user1 }).should.be.fulfilled;
    await kittieFightToken.approve(register.address, 100000, { from: user2 }).should.be.fulfilled;

    // registers user to the system
    await proxy.register({ from: user1 }).should.be.fulfilled;
    await proxy.register({ from: user2 }).should.be.fulfilled;
  })


  describe('GameManager::Authority', () => {

    it('is not able to list kittie without proxy', async () => {
      try {
        await gameManager.listKittie(123, user1)
      } catch (err) {
        errorMessage = err.toString()
      }
      assert.include(errorMessage, ERROR.NO_PROXY)
    })

    it('is not able to manual match without proxy', async () => {
      try {
        await gameManager.manualMatchKitties(user1, user2, kittie1, kittie2, 123123)
      } catch (err) {
        errorMessage = err.toString()
      }
      assert.include(errorMessage, ERROR.NO_PROXY)
    })

    it('is not able to make a manual match without super admin role', async () => {
      try {
        await proxy.manualMatchKitties(user1, user2, kittie1, kittie2, 123123, { from: user1 })
      } catch (err) {
        errorMessage = err.toString()
      }
      assert.include(errorMessage, ERROR.ONLY_SUPER_ADMIN)
    })

    // it('is not able to list kittie without a player role', async () => {
    //   try{
    //     await proxy.listKittie(123, {from : user1})
    //   }catch(err){
    //     errorMessage = err.toString()
    //   }
    //   assert.include(errorMessage, ERROR.ONLY_PLAYER)
    // })
  })

  describe('GameManager::Features', () => {

    it('should be able to list kittie', async () => {
      await proxy.listKittie(kittie1, { from: user1 })
      let isListed = await scheduler.isKittyListedForMatching(kittie1)
      assert.isTrue(isListed)
    })

    it('should be a able to make a match from 4 listing', async () => {
      let currentGamesCount = await getterDB.getGames()

      // TODO should not allow to have a match with fighter of same owner
      await proxy.listKittie(kittie1, { from: user1 })
      await proxy.listKittie(kittie2, { from: user2 })
      await proxy.listKittie(kittie4, { from: user1 })
      await proxy.listKittie(kittie5, { from: user2 })

      let newGamesCount = await getterDB.getGames()

      assert.equal(currentGamesCount.length + 2, newGamesCount.length)
    })

    it('should be able to make a manual match', async () => {
      let currentGamesCount = await getterDB.getGames()
      await proxy.manualMatchKitties(user1, user2, kittie1, kittie2, 123123)
      let newGamesCount = await getterDB.getGames()

      assert.equal(currentGamesCount.length + 1, newGamesCount.length)
    })

    // it('is not able to manual match with either one invalid player', async () => {
    //   try{
    //     await proxy.manualMatchKitties(unauthorizedUser, user2, kittie1, kittie2, 123123)
    //   }catch(err){
    //     console.log('pasok' + err.toString())
    //     errorMessage = err.toString()
    //   }
    //   assert.include(errorMessage, ERROR.INVALID_PLAYER)
    // })

  })

  // it('is not able to list kittie without kitty ownership', async () => {

  // })

  // // participate()
  // it('should be able to participate with all valid pre-checks via proxy', async () => {

  // })

  // it('is not able to participate with all valid checks without proxy', async () => {

  // })

  // it('is not able to participate with invalid player to support', async () => {

  // })

  // it('is not able to participate with game finished or cancelled', async () => {

  // })

  // // startGame()
  // it('should be able to start game by either playerRed or playerBlack via proxy', async () => {

  // })

  // it('is not able to start game by either without proxy', async () => {

  // })

  // it('is not able to start game by invalid game player', async () => {

  // })

  // it('is not able to start game when state is not PRE-START', async () => {

  // })

  // // bet()
  // it('should be able to bet with bettor role via proxy', async () => {

  // })

  // it('is not able to bet without proxy', async () => {

  // })

  // it('is not able to bet if game is not yet started', async () => {

  // })
})