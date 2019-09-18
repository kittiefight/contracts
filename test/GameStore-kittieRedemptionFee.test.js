const BigNumber = require('bignumber.js')
require('chai')
  .use(require('chai-shallow-deep-equal'))
  .use(require('chai-bignumber')(BigNumber))
  .use(require('chai-as-promised'))
  .should()

const KFProxy = artifacts.require('KFProxy')
const GenericDB = artifacts.require('GenericDB')
const ProfileDB = artifacts.require('ProfileDB')
const RoleDB = artifacts.require('RoleDB')
const GMSetterDB = artifacts.require('GMSetterDB')
const GMGetterDB = artifacts.require('GMGetterDB')
const GameManager = artifacts.require('GameManager')
const GameStore = artifacts.require('GameStore')
const GameCreation = artifacts.require('GameCreation')
const GameVarAndFee = artifacts.require('GameVarAndFee')
const Distribution = artifacts.require('Distribution')
const Forfeiter = artifacts.require('Forfeiter')
const DateTime = artifacts.require('DateTime')
const Scheduler = artifacts.require('Scheduler')
const Betting = artifacts.require('Betting')
const HitsResolve = artifacts.require('HitsResolve')
// const RarityCalculator = artifacts.require('RarityCalculator')
const Register = artifacts.require('Register')
const EndowmentFund = artifacts.require('EndowmentFund')
const EndowmentDB = artifacts.require('EndowmentDB')
const Escrow = artifacts.require('Escrow')
const KittieHELL = artifacts.require('KittieHELL')
const SuperDaoToken = artifacts.require('MockERC20Token')
const KittieFightToken = artifacts.require('MockERC20Token')
const CryptoKitties = artifacts.require('MockERC721Token')
const ERC20_TOKEN_SUPPLY = new BigNumber(1000000)
const CronJob = artifacts.require('CronJob')
const FreezeInfo = artifacts.require('FreezeInfo')
const CronJobTarget = artifacts.require('CronJobTarget')

const PERCENTAGE_FOR_KITTIE_REDEMPTION_FEE = 1
const USD_KTY_PRICE = new BigNumber(web3.utils.toWei('0.4', 'ether')) // 0.4 USD to 1 KTY
const CONTRACT_NAME_GAMEVARANDFEE = 'GameVarAndFee'

// Contract instances
let proxy,
  dateTime,
  genericDB,
  profileDB,
  roleDB,
  superDaoToken,
  kittieFightToken,
  cryptoKitties,
  register,
  gameVarAndFee,
  endowmentFund,
  endowmentDB,
  distribution,
  forfeiter,
  scheduler,
  betting,
  hitsResolve,
  rarityCalculator,
  kittieHELL,
  getterDB,
  setterDB,
  gameManager,
  cronJob,
  freezeInfo,
  cronJobTarget

let errorMessage

function setMessage (contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find(f => {
      return f.name == funcName
    }),
    argArray
  )
}

before(async function () {
  this.timeout(10000)
  errorMessage = ''

  // PROXY
  proxy = await KFProxy.new()

  // DATABASES
  genericDB = await GenericDB.new()
  profileDB = await ProfileDB.new(genericDB.address)
  roleDB = await RoleDB.new(genericDB.address)
  endowmentDB = await EndowmentDB.new(genericDB.address)
  getterDB = await GMGetterDB.new(genericDB.address)
  setterDB = await GMSetterDB.new(genericDB.address)

  // TOKENS
  superDaoToken = await SuperDaoToken.new(ERC20_TOKEN_SUPPLY)
  kittieFightToken = await KittieFightToken.new(ERC20_TOKEN_SUPPLY)
  cryptoKitties = await CryptoKitties.new()

  // MODULES
  gameManager = await GameManager.new()
  gameStore = await GameStore.deployed()
  gameCreation = await GameCreation.deployed()
  register = await Register.new()
  dateTime = await DateTime.new()
  gameVarAndFee = await GameVarAndFee.new(
    genericDB.address,
    '0xE39451e34f8FB108a8F6d4cA6C68dd38f37d26E3'
  )
  distribution = await Distribution.new()
  forfeiter = await Forfeiter.new()
  scheduler = await Scheduler.new()
  betting = await Betting.new()
  hitsResolve = await HitsResolve.new()
  // rarityCalculator = await RarityCalculator.new()
  endowmentFund = await EndowmentFund.new()
  escrow = await Escrow.new()
  kittieHELL = await KittieHELL.new()
  cronJob = await CronJob.deployed()
  freezeInfo = await FreezeInfo.deployed()
  cronJobTarget = await CronJobTarget.deployed()

  await proxy.addContract('TimeContract', dateTime.address)
  await proxy.addContract('GenericDB', genericDB.address)
  await proxy.addContract('CryptoKitties', cryptoKitties.address)
  await proxy.addContract('SuperDAOToken', superDaoToken.address)
  await proxy.addContract('KittieFightToken', kittieFightToken.address)
  await proxy.addContract('ProfileDB', profileDB.address)
  await proxy.addContract('RoleDB', roleDB.address)
  await proxy.addContract('Register', register.address)
  await proxy.addContract('GameVarAndFee', gameVarAndFee.address)
  await proxy.addContract('EndowmentFund', endowmentFund.address)
  await proxy.addContract('EndowmentDB', endowmentDB.address)
  await proxy.addContract('Escrow', escrow.address)
  await proxy.addContract('Distribution', distribution.address)
  await proxy.addContract('Forfeiter', forfeiter.address)
  await proxy.addContract('Scheduler', scheduler.address)
  await proxy.addContract('Betting', betting.address)
  await proxy.addContract('HitsResolve', hitsResolve.address)
  // await proxy.addContract('RarityCalculator', rarityCalculator.address)
  await proxy.addContract('GMSetterDB', setterDB.address)
  await proxy.addContract('GMGetterDB', getterDB.address)
  await proxy.addContract('GameManager', gameManager.address)
  await proxy.addContract('GameStore', gameStore.address)
  await proxy.addContract('GameCreation', gameCreation.address)
  await proxy.addContract('KittieHell', kittieHELL.address)
  await proxy.addContract('CronJob', cronJob.address)
  await proxy.addContract('FreezeInfo', freezeInfo.address)

  await genericDB.setProxy(proxy.address)
  await profileDB.setProxy(proxy.address)
  await roleDB.setProxy(proxy.address)
  await setterDB.setProxy(proxy.address)
  await getterDB.setProxy(proxy.address)
  await endowmentFund.setProxy(proxy.address)
  await endowmentDB.setProxy(proxy.address)
  await gameVarAndFee.setProxy(proxy.address)
  await distribution.setProxy(proxy.address)
  await forfeiter.setProxy(proxy.address)
  await scheduler.setProxy(proxy.address)
  await betting.setProxy(proxy.address)
  await hitsResolve.setProxy(proxy.address)
  // await rarityCalculator.setProxy(proxy.address)
  await register.setProxy(proxy.address)
  await gameManager.setProxy(proxy.address)
  await gameStore.setProxy(proxy.address)
  await gameCreation.setProxy(proxy.address)
  await kittieHELL.setProxy(proxy.address)
  await freezeInfo.setProxy(proxy.address)

  await forfeiter.initialize()
  await scheduler.initialize()
  await register.initialize()
  await gameManager.initialize()
  await gameStore.initialize()
  await gameCreation.initialize()
  await getterDB.initialize()
  await endowmentFund.initialize()
  await kittieHELL.initialize()
})

contract('GameStore', accounts => {
  it('updates kittieRedemptionFee dynamically as a percentage of final honey pot', async () => {
    await proxy.addContract('Creator', accounts[0])
    await roleDB.addRole('Creator', 'super_admin', accounts[0])
    let message1 = web3.eth.abi.encodeFunctionCall(
      GameVarAndFee.abi.find(f => {
        return f.name == 'setVarAndFee'
      }),
      ['percentageForKittieRedemptionFee', PERCENTAGE_FOR_KITTIE_REDEMPTION_FEE]
    )
    await proxy.execute(CONTRACT_NAME_GAMEVARANDFEE, message1, {
      from: accounts[0]
    })

    let message2 = web3.eth.abi.encodeFunctionCall(
      GameVarAndFee.abi.find(f => {
        return f.name == 'setVarAndFee'
      }),
      ['usdKTYPrice', USD_KTY_PRICE.toString()]
    )
    await proxy.execute(CONTRACT_NAME_GAMEVARANDFEE, message2, {
      from: accounts[0]
    })

    gameStore.updateKittieRedemptionFee(12).should.be.fulfilled

    const res = await gameStore.getKittieRedemptionFee.call(12)
    const redemptionFee = web3.utils.fromWei(res.toString(), 'ether')
    const kittieRedemptionFee = Math.round(parseFloat(redemptionFee))
    console.log(kittieRedemptionFee)
    assert.isAbove(kittieRedemptionFee, 1)
  })
})
