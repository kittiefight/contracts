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
const EndowmentDB = artifacts.require('EndowmentDB')
const KittieHELL = artifacts.require('KittieHELL')
const SuperDaoToken = artifacts.require('MockERC20Token');
const KittieFightToken = artifacts.require('MockERC20Token');
const CryptoKitties = artifacts.require('MockERC721Token');
const ERC20_TOKEN_SUPPLY = new BigNumber(1000000);

//Contract instances
let proxy, dateTime, genericDB, profileDB, roleDB, superDaoToken,
  kittieFightToken, cryptoKitties, register, gameVarAndFee, endowmentFund,
  endowmentDB, distribution, forfeiter, scheduler, betting, hitsResolve,
  rarityCalculator, kittieHELL, getterDB, setterDB, gameManager

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

const cividId1 = 1;
const cividId2 = 2;
const cividId3 = 3;
const cividId4 = 4;


function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

contract('GameManager', ([creator, user1, user2, user3, user4, user5, unauthorizedUser, randomAddress]) => {

  beforeEach(async function () {
    this.timeout(10000);
    errorMessage = ''

    // PROXY
    proxy = await KFProxy.new()

    // DATABASES
    genericDB = await GenericDB.new()
    profileDB = await ProfileDB.new(genericDB.address);
    roleDB = await RoleDB.new(genericDB.address);
    endowmentDB = await EndowmentDB.new(genericDB.address)
    getterDB = await GMGetterDB.new(genericDB.address)
    setterDB = await GMSetterDB.new(genericDB.address)

    // TOKENS
    superDaoToken = await SuperDaoToken.new(ERC20_TOKEN_SUPPLY);
    kittieFightToken = await KittieFightToken.new(ERC20_TOKEN_SUPPLY);
    cryptoKitties = await CryptoKitties.new();

    // MODULES
    gameManager = await GameManager.new()
    register = await Register.new()
    dateTime = await DateTime.new()
    gameVarAndFee = await GameVarAndFee.new(genericDB.address, randomAddress)
    distribution = await Distribution.new()
    forfeiter = await Forfeiter.new()
    scheduler = await Scheduler.new()
    betting = await Betting.new()
    hitsResolve = await HitsResolve.new()
    rarityCalculator = await RarityCalculator.new()
    endowmentFund = await EndowmentFund.new()
    // kittieHELL = await KittieHELL.new(contractManager.address)

    await proxy.addContract('TimeContract', dateTime.address)
    await proxy.addContract('GenericDB', genericDB.address)
    await proxy.addContract('CryptoKitties', cryptoKitties.address);
    await proxy.addContract('SuperDAOToken', superDaoToken.address);
    await proxy.addContract('KittieFightToken', kittieFightToken.address);
    await proxy.addContract('ProfileDB', profileDB.address);
    await proxy.addContract('RoleDB', roleDB.address);
    await proxy.addContract('Register', register.address)
    await proxy.addContract('GameVarAndFee', gameVarAndFee.address)
    await proxy.addContract('EndowmentFund', endowmentFund.address)
    await proxy.addContract('EndowmentDB', endowmentDB.address)
    await proxy.addContract('Distribution', distribution.address)
    await proxy.addContract('Forfeiter', forfeiter.address)
    await proxy.addContract('Scheduler', scheduler.address)
    await proxy.addContract('Betting', betting.address)
    await proxy.addContract('HitsResolve', hitsResolve.address)
    await proxy.addContract('RarityCalculator', rarityCalculator.address)
    await proxy.addContract('GMSetterDB', setterDB.address)
    await proxy.addContract('GMGetterDB', getterDB.address)
    await proxy.addContract('GameManager', gameManager.address)
    // await proxy.addContract('KittieHELL', kittieHELL.address)

    //Because of constructor
    // endowmentFund = await EndowmentFund.new()
    // await proxy.addContract('EndowmentFund', endowmentFund.address)


    await genericDB.setProxy(proxy.address)
    await profileDB.setProxy(proxy.address);
    await roleDB.setProxy(proxy.address);
    await setterDB.setProxy(proxy.address)
    await getterDB.setProxy(proxy.address)
    await endowmentFund.setProxy(proxy.address)
    await endowmentDB.setProxy(proxy.address)
    await gameVarAndFee.setProxy(proxy.address)
    await distribution.setProxy(proxy.address)
    await forfeiter.setProxy(proxy.address)
    await dateTime.setProxy(proxy.address)
    await scheduler.setProxy(proxy.address)
    await betting.setProxy(proxy.address)
    await hitsResolve.setProxy(proxy.address)
    await rarityCalculator.setProxy(proxy.address)
    await register.setProxy(proxy.address)
    await gameManager.setProxy(proxy.address)
    // await kittieHELL.setProxy(proxy.address)

    await dateTime.initialize()
    await gameVarAndFee.initialize()
    await forfeiter.initialize()
    await scheduler.initialize()
    await register.initialize()
    await gameManager.initialize()
    await endowmentFund.updateContracts()

    // Mint some kitties for the test addresses
    await cryptoKitties.mint(user1, kittie1).should.be.fulfilled;
    await cryptoKitties.mint(user2, kittie2).should.be.fulfilled;
    await cryptoKitties.mint(user3, kittie3).should.be.fulfilled;
    await cryptoKitties.mint(user4, kittie4).should.be.fulfilled;
    await cryptoKitties.mint(user5, kittie5).should.be.fulfilled;
    await cryptoKitties.mint(user2, kittie6).should.be.fulfilled;

    // Approve transfer operation for the system
    await cryptoKitties.approve(register.address, kittie1, { from: user1 }).should.be.fulfilled;
    await cryptoKitties.approve(register.address, kittie2, { from: user2 }).should.be.fulfilled;
    await cryptoKitties.approve(register.address, kittie3, { from: user3 }).should.be.fulfilled;
    await cryptoKitties.approve(register.address, kittie4, { from: user4 }).should.be.fulfilled;
    await cryptoKitties.approve(register.address, kittie5, { from: user5 }).should.be.fulfilled;
    await cryptoKitties.approve(register.address, kittie6, { from: user2 }).should.be.fulfilled;

    // Send some SuperDAO and KitttieFight tokens to users
    await superDaoToken.transfer(user1, 100000).should.be.fulfilled;
    await superDaoToken.transfer(user2, 100000).should.be.fulfilled;
    await kittieFightToken.transfer(user1, 100000).should.be.fulfilled;
    await kittieFightToken.transfer(user2, 100000).should.be.fulfilled;
    await kittieFightToken.transfer(user3, 100000).should.be.fulfilled;
    await kittieFightToken.transfer(user4, 100000).should.be.fulfilled;

    // Approve erc20 token transfer operation for the system
    await superDaoToken.approve(register.address, 100000, { from: user1 }).should.be.fulfilled;
    await superDaoToken.approve(register.address, 100000, { from: user2 }).should.be.fulfilled;
    await kittieFightToken.approve(endowmentFund.address, 100000, { from: user1 }).should.be.fulfilled;
    await kittieFightToken.approve(endowmentFund.address, 100000, { from: user2 }).should.be.fulfilled;
    await kittieFightToken.approve(endowmentFund.address, 100000, { from: user3 }).should.be.fulfilled;
    await kittieFightToken.approve(endowmentFund.address, 100000, { from: user4 }).should.be.fulfilled;

    // registers user to the system
    await proxy.execute('Register', setMessage(register, 'register', [user1]), {
      from: user1
    }).should.be.fulfilled;
    await proxy.execute('Register', setMessage(register, 'register', [user2]), {
      from: user2
    }).should.be.fulfilled;
    await proxy.execute('Register', setMessage(register, 'register', [user3]), {
      from: user3
    }).should.be.fulfilled;
    await proxy.execute('Register', setMessage(register, 'register', [user4]), {
      from: user4
    }).should.be.fulfilled;
    await proxy.execute('Register', setMessage(register, 'register', [user5]), {
      from: user5
    }).should.be.fulfilled;

    //verify users civid Id, gfives player role
    await proxy.execute('Register', setMessage(register, 'verifyAccount', [user1, cividId1]), {
      from: user1
    }).should.be.fulfilled;
    await proxy.execute('Register', setMessage(register, 'verifyAccount', [user2, cividId2]), {
      from: user2
    }).should.be.fulfilled;
    await proxy.execute('Register', setMessage(register, 'verifyAccount', [user3, cividId3]), {
      from: user3
    }).should.be.fulfilled;
    await proxy.execute('Register', setMessage(register, 'verifyAccount', [user4, cividId4]), {
      from: user4
    }).should.be.fulfilled;

  })


  describe('GameManager::Authority', () => {

    it('is not able to list kittie without proxy', async () => {
      try {
        await gameManager.listKittie(123, { from: user1 })
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
      await proxy.execute('GameManager', setMessage(gameManager, 'manualMatchKitties',
        [user1, user2, kittie1, kittie2, 123123]), { from: user1 }).should.be.rejected;
    })

    it('is not able to list kittie without a player role', async () => {
      await proxy.execute('GameManager', setMessage(gameManager, 'listKittie',
        [kittie5]), { from: user5 }).should.be.rejected;
    })

    it('is not able to manual match with either one invalid player', async () => {
      //user 5 is not a player, as it has not been registered
      await proxy.execute('GameManager', setMessage(gameManager, 'manualMatchKitties',
        [user5, user2, kittie1, kittie2, 123123]), { from: creator }).should.be.rejected;
    })

    it('is not able to list kittie without kitty ownership', async () => {
      //user2 not owner of kittie3
      await proxy.execute('GameManager', setMessage(gameManager, 'manualMatchKitties',
        [user1, user2, kittie1, kittie3, 123123]), { from: creator }).should.be.rejected;
    })

  })

  describe('GameManager::Listing and matching', () => {

    it('should be able to list kittie', async () => {
      await proxy.execute('GameManager', setMessage(gameManager, 'listKittie',
        [kittie1]), { from: user1 }).should.be.fulfilled;
      let isListed = await scheduler.isKittyListedForMatching(kittie1)
      assert.isTrue(isListed)
    })

    it('should be a able to make a match from 4 listing', async () => {
      let currentGames = await getterDB.getGames()

      // List Kitties
      await proxy.execute('GameManager', setMessage(gameManager, 'listKittie',
        [kittie1]), { from: user1 }).should.be.fulfilled;

      await proxy.execute('GameManager', setMessage(gameManager, 'listKittie',
        [kittie2]), { from: user2 }).should.be.fulfilled;

      await proxy.execute('GameManager', setMessage(gameManager, 'listKittie',
        [kittie3]), { from: user3 }).should.be.fulfilled;

      await proxy.execute('GameManager', setMessage(gameManager, 'listKittie',
        [kittie4]), { from: user4 }).should.be.fulfilled;


      let newGames = await getterDB.getGames()

      assert.equal(currentGames.length + 2, newGames.length)
    })

    // super admin role added in GameVarAndFee to creator!
    it('super admin should be able to make a manual match', async () => {
      let currentGamesCount = await getterDB.getGames()

      await proxy.execute('GameManager', setMessage(gameManager, 'manualMatchKitties',
        [user1, user2, kittie1, kittie2, 123123]), { from: creator }).should.be.fulfilled;

      let newGamesCount = await getterDB.getGames()

      assert.equal(currentGamesCount.length + 1, newGamesCount.length)
    })

  })

  describe('GameManager::Participating', () => {
    // participate()
    it('should be able to participate with all valid pre-checks via proxy', async () => {

    })


  })



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