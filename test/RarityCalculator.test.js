const chai = require('chai')
const chaiAsPromised = require('chai-as-promised')
const assert = chai.assert
chai.use(chaiAsPromised)

const Proxy = artifacts.require('KFProxy')
const GenericDB = artifacts.require('GenericDB')
const RoleDB = artifacts.require('RoleDB')
const ProfileDB = artifacts.require('ProfileDB')
const Register = artifacts.require('Register')
const CryptoKitties = artifacts.require('MockERC721Token')
const KittieFightToken = artifacts.require('MockERC20Token')
const SuperDaoToken = artifacts.require('MockERC20Token')
const RarityCalculator = artifacts.require('RarityCalculator')
const Betting = artifacts.require('Betting')


let ProxyInst
let GenericDBinst
let RoleDBinst
let ProfileDBinst
let RegisterInst
let cryptoKitties
let SuperDaoTokenInst
let KittieFightTokenInst
let BettingInst
let RarityCalculatorInst

const sleep = ms => new Promise(res => setTimeout(res, ms))

// this is the kittieId for kittie1
// https://www.cryptokitties.co/kitty/1001
const kittie1 = 1001
// this is the gene for kittie with kittieID 1001, which is used in truffle test
const gene1 =
  '512955438081049600613224346938352058409509756310147795204209859701881294'

// kittie2 is a fancy kittie - Krakitten, Gen 5
// https://www.cryptokitties.co/kitty/1555108
const kittie2 = 1555108
const gene2 =
  '24171491821178068054575826800486891805334952029503890331493652557302916'

// https://www.cryptokitties.co/kitty/1267904
const kittie3 = 1267904
const gene3 =
  '290372710203698797209297887795752417072070342201768110150904359522134138'


contract('RarityCalculator', accounts => {
  before(async () => {
    ProxyInst = await Proxy.new()
    GenericDBinst = await GenericDB.new()
    RoleDBinst = await RoleDB.new(GenericDBinst.address)
    ProfileDBinst = await ProfileDB.new(GenericDBinst.address)
    RegisterInst = await Register.new()
    cryptoKitties = await CryptoKitties.new()
    SuperDaoTokenInst = await SuperDaoToken.new(100000)
    KittieFightTokenInst = await KittieFightToken.new(100000)
    RarityCalculatorInst = await RarityCalculator.new()
    BettingInst = await Betting.new()
  
    await ProxyInst.addContract("GenericDB", GenericDBinst.address)
    await ProxyInst.addContract('RoleDB', RoleDBinst.address)
    await ProxyInst.addContract('ProfileDB', ProfileDBinst.address)
    await ProxyInst.addContract('Register', RegisterInst.address)
    await ProxyInst.addContract('CryptoKitties', cryptoKitties.address)
    await ProxyInst.addContract('SuperDAOToken', SuperDaoTokenInst.address)
    await ProxyInst.addContract('KittieFightToken', KittieFightTokenInst.address)
    await ProxyInst.addContract('RarityCalculator', RarityCalculatorInst.address)
    await ProxyInst.addContract('Betting', BettingInst.address)
  
    await GenericDBinst.setProxy(ProxyInst.address)
    await RoleDBinst.setProxy(ProxyInst.address)
    await RoleDBinst.setProxy(ProxyInst.address)
    await ProfileDBinst.setProxy(ProxyInst.address)
    await RegisterInst.setProxy(ProxyInst.address)
    await RarityCalculatorInst.setProxy(ProxyInst.address)
    await BettingInst.setProxy(ProxyInst.address)
  
    await RegisterInst.initialize()
    await RegisterInst.addSuperAdmin(accounts[0])
  
    await RarityCalculatorInst.fillKaiValue()
    await RarityCalculatorInst.updateTotalKitties(1600000)
    await RarityCalculatorInst.setDefenseLevelLimit(1832353, 9175, 1600000)
  
    for (let i = 0; i < 32; i++) {
      await RarityCalculatorInst.updateCattributes(
        'body',
        Object.keys(kaiToCattributesData[0].body.kai)[i],
        Object.values(kaiToCattributesData[0].body.kai)[i]
      )
    }
    for (let i = 0; i < 32; i++) {
      await RarityCalculatorInst.updateCattributes(
        'pattern',
        Object.keys(kaiToCattributesData[1].pattern.kai)[i],
        Object.values(kaiToCattributesData[1].pattern.kai)[i]
      )
    }
  
    for (let i = 0; i < 32; i++) {
      await RarityCalculatorInst.updateCattributes(
        'coloreyes',
        Object.keys(kaiToCattributesData[2].coloreyes.kai)[i],
        Object.values(kaiToCattributesData[2].coloreyes.kai)[i]
      )
    }
  
    for (let i = 0; i < 32; i++) {
      await RarityCalculatorInst.updateCattributes(
        'eyes',
        Object.keys(kaiToCattributesData[3].eyes.kai)[i],
        Object.values(kaiToCattributesData[3].eyes.kai)[i]
      )
    }
  
    for (let i = 0; i < 32; i++) {
      await RarityCalculatorInst.updateCattributes(
        'color1',
        Object.keys(kaiToCattributesData[4].color1.kai)[i],
        Object.values(kaiToCattributesData[4].color1.kai)[i]
      )
    }
  
    for (let i = 0; i < 32; i++) {
      await RarityCalculatorInst.updateCattributes(
        'color2',
        Object.keys(kaiToCattributesData[5].color2.kai)[i],
        Object.values(kaiToCattributesData[5].color2.kai)[i]
      )
    }
  
    for (let i = 0; i < 32; i++) {
      await RarityCalculatorInst.updateCattributes(
        'color3',
        Object.keys(kaiToCattributesData[6].color3.kai)[i],
        Object.values(kaiToCattributesData[6].color3.kai)[i]
      )
    }
  
    for (let i = 0; i < 32; i++) {
      await RarityCalculatorInst.updateCattributes(
        'wild',
        Object.keys(kaiToCattributesData[7].wild.kai)[i],
        Object.values(kaiToCattributesData[7].wild.kai)[i]
      )
    }
  
    for (let i = 0; i < 32; i++) {
      await RarityCalculatorInst.updateCattributes(
        'mouth',
        Object.keys(kaiToCattributesData[8].mouth.kai)[i],
        Object.values(kaiToCattributesData[8].mouth.kai)[i]
      )
    }
  
    for (let i = 0; i < 32; i++) {
      await RarityCalculatorInst.updateCattributes(
        'environment',
        Object.keys(kaiToCattributesData[9].environment.kai)[i],
        Object.values(kaiToCattributesData[9].environment.kai)[i]
      )
    }
  
    for (let j = 0; j < cattributesData.length; j++) {
      await RarityCalculatorInst.updateCattributesScores(
        cattributesData[j].description,
        Number(cattributesData[j].total)
      )
    }
  
    for (let m = 0; m < FancyKitties.length; m++) {
      for (let n = 1; n < FancyKitties[m].length; n++) {
        await RarityCalculatorInst.updateFancyKittiesList(
          FancyKitties[m][n],
          FancyKitties[m][0]
        )
      }
    }
  })
  
  it('is able to convert the genome of a kitty to binary', async () => {
    await RarityCalculatorInst.getDominantGeneBinary(kittie1, gene1)
    const kittie1BodyGeneBinary = await RarityCalculatorInst.kittiesDominantGeneBinary.call(
      kittie1,
      0
    )
    const kittie1PatternGeneBinary = await RarityCalculatorInst.kittiesDominantGeneBinary.call(
      kittie1,
      1
    )
    const kittie1ColoreyesGeneBinary = await RarityCalculatorInst.kittiesDominantGeneBinary.call(
      kittie1,
      2
    )
    const kittie1EyesGeneBinary = await RarityCalculatorInst.kittiesDominantGeneBinary.call(
      kittie1,
      3
    )
    const kittie1Color1GeneBinary = await RarityCalculatorInst.kittiesDominantGeneBinary.call(
      kittie1,
      4
    )
    const kittie1Color2GeneBinary = await RarityCalculatorInst.kittiesDominantGeneBinary.call(
      kittie1,
      5
    )
    const kittie1Color3GeneBinary = await RarityCalculatorInst.kittiesDominantGeneBinary.call(
      kittie1,
      6
    )
    const kittie1WildGeneBinary = await RarityCalculatorInst.kittiesDominantGeneBinary.call(
      kittie1,
      7
    )
    const kittie1MouthGeneBinary = await RarityCalculatorInst.kittiesDominantGeneBinary.call(
      kittie1,
      8
    )
    const kittie1EnvironmentGeneBinary = await RarityCalculatorInst.kittiesDominantGeneBinary.call(
      kittie1,
      9
    )
    assert.equal(kittie1BodyGeneBinary, '01110')
    assert.equal(kittie1PatternGeneBinary, '01001')
    assert.equal(kittie1ColoreyesGeneBinary, '00011')
    assert.equal(kittie1EyesGeneBinary, '00110')
    assert.equal(kittie1Color1GeneBinary, '00000')
    assert.equal(kittie1Color2GeneBinary, '01000')
    assert.equal(kittie1Color3GeneBinary, '00100')
    assert.equal(kittie1WildGeneBinary, '00000')
    assert.equal(kittie1MouthGeneBinary, '01110')
    assert.equal(kittie1EnvironmentGeneBinary, '00001')

    await RarityCalculatorInst.getDominantGeneBinary(kittie3, gene3)
    const kittie3BodyGeneBinary = await RarityCalculatorInst.kittiesDominantGeneBinary.call(
      kittie3,
      0
    )
    const kittie3PatternGeneBinary = await RarityCalculatorInst.kittiesDominantGeneBinary.call(
      kittie3,
      1
    )
    const kittie3ColoreyesGeneBinary = await RarityCalculatorInst.kittiesDominantGeneBinary.call(
      kittie3,
      2
    )
    const kittie3EyesGeneBinary = await RarityCalculatorInst.kittiesDominantGeneBinary.call(
      kittie3,
      3
    )
    const kittie3Color1GeneBinary = await RarityCalculatorInst.kittiesDominantGeneBinary.call(
      kittie3,
      4
    )
    const kittie3Color2GeneBinary = await RarityCalculatorInst.kittiesDominantGeneBinary.call(
      kittie3,
      5
    )
    const kittie3Color3GeneBinary = await RarityCalculatorInst.kittiesDominantGeneBinary.call(
      kittie3,
      6
    )
    const kittie3WildGeneBinary = await RarityCalculatorInst.kittiesDominantGeneBinary.call(
      kittie3,
      7
    )
    const kittie3MouthGeneBinary = await RarityCalculatorInst.kittiesDominantGeneBinary.call(
      kittie3,
      8
    )
    const kittie3EnvironmentGeneBinary = await RarityCalculatorInst.kittiesDominantGeneBinary.call(
      kittie3,
      9
    )
    assert.equal(kittie3BodyGeneBinary, '11010')
    assert.equal(kittie3PatternGeneBinary, '00101')
    assert.equal(kittie3ColoreyesGeneBinary, '01111')
    assert.equal(kittie3EyesGeneBinary, '01110')
    assert.equal(kittie3Color1GeneBinary, '11011')
    assert.equal(kittie3Color2GeneBinary, '00110')
    assert.equal(kittie3Color3GeneBinary, '00011')
    assert.equal(kittie3WildGeneBinary, '00010')
    assert.equal(kittie3MouthGeneBinary, '00100')
    assert.equal(kittie3EnvironmentGeneBinary, '00011')
  })

  it('is able to convert the genome in binary to kai value', async () => {
    await RarityCalculatorInst.getDominantGeneBinary(kittie1, gene1)
    await RarityCalculatorInst.binaryToKai(kittie1)
    const kittie1BodyGeneKai = await RarityCalculatorInst.kittiesDominantGeneKai.call(
      kittie1,
      0
    )
    const kittie1PatternGeneKai = await RarityCalculatorInst.kittiesDominantGeneKai.call(
      kittie1,
      1
    )
    const kittie1ColoreyesGeneKai = await RarityCalculatorInst.kittiesDominantGeneKai.call(
      kittie1,
      2
    )
    const kittie1EyesGeneKai = await RarityCalculatorInst.kittiesDominantGeneKai.call(
      kittie1,
      3
    )
    const kittie1Color1GeneKai = await RarityCalculatorInst.kittiesDominantGeneKai.call(
      kittie1,
      4
    )
    const kittie1Color2GeneKai = await RarityCalculatorInst.kittiesDominantGeneKai.call(
      kittie1,
      5
    )
    const kittie1Color3GeneKai = await RarityCalculatorInst.kittiesDominantGeneKai.call(
      kittie1,
      6
    )
    const kittie1WildGeneKai = await RarityCalculatorInst.kittiesDominantGeneKai.call(
      kittie1,
      7
    )
    const kittie1MouthGeneKai = await RarityCalculatorInst.kittiesDominantGeneKai.call(
      kittie1,
      8
    )
    const kittie1EnvironmentGeneKai = await RarityCalculatorInst.kittiesDominantGeneKai.call(
      kittie1,
      9
    )
    assert.equal(kittie1BodyGeneKai, 'f')
    assert.equal(kittie1PatternGeneKai, 'a')
    assert.equal(kittie1ColoreyesGeneKai, '4')
    assert.equal(kittie1EyesGeneKai, '7')
    assert.equal(kittie1Color1GeneKai, '1')
    assert.equal(kittie1Color2GeneKai, '9')
    assert.equal(kittie1Color3GeneKai, '5')
    assert.equal(kittie1WildGeneKai, '1')
    assert.equal(kittie1MouthGeneKai, 'f')
    assert.equal(kittie1EnvironmentGeneKai, '2')
  })

  it('is able to convert the genome in kai to cattributes', async () => {
    await RarityCalculatorInst.getDominantGeneBinary(kittie1, gene1)
    await RarityCalculatorInst.binaryToKai(kittie1)
    await RarityCalculatorInst.kaiToCattribute(kittie1)

    const kittie1BodyCattribute = await RarityCalculatorInst.kittiesDominantCattributes.call(
      kittie1,
      0
    )
    const kittie1PatternCattribute = await RarityCalculatorInst.kittiesDominantCattributes.call(
      kittie1,
      1
    )
    const kittie1ColoreyesCattribute = await RarityCalculatorInst.kittiesDominantCattributes.call(
      kittie1,
      2
    )
    const kittie1EyesCattribute = await RarityCalculatorInst.kittiesDominantCattributes.call(
      kittie1,
      3
    )
    const kittie1Color1Cattribute = await RarityCalculatorInst.kittiesDominantCattributes.call(
      kittie1,
      4
    )
    const kittie1Color2Cattribute = await RarityCalculatorInst.kittiesDominantCattributes.call(
      kittie1,
      5
    )
    const kittie1Color3Cattribute = await RarityCalculatorInst.kittiesDominantCattributes.call(
      kittie1,
      6
    )
    const kittie1WildCattribute = await RarityCalculatorInst.kittiesDominantCattributes.call(
      kittie1,
      7
    )
    const kittie1MouthCattribute = await RarityCalculatorInst.kittiesDominantCattributes.call(
      kittie1,
      8
    )
    const kittie1EnvironmentCattribute = await RarityCalculatorInst.kittiesDominantCattributes.call(
      kittie1,
      9
    )

    assert.equal(kittie1BodyCattribute, 'ragamuffin')
    assert.equal(kittie1PatternCattribute, 'luckystripe')
    assert.equal(kittie1ColoreyesCattribute, 'mintgreen')
    assert.equal(kittie1EyesCattribute, 'crazy')
    assert.equal(kittie1Color1Cattribute, 'shadowgrey')
    assert.equal(kittie1Color2Cattribute, 'swampgreen')
    assert.equal(kittie1Color3Cattribute, 'granitegrey')
    assert.equal(kittie1WildCattribute, '')
    assert.equal(kittie1MouthCattribute, 'happygokitty')
    assert.equal(kittie1EnvironmentCattribute, '')

    await RarityCalculatorInst.getDominantGeneBinary(kittie3, gene3)
    await RarityCalculatorInst.binaryToKai(kittie3)
    await RarityCalculatorInst.kaiToCattribute(kittie3)
    const kittie3BodyCattribute = await RarityCalculatorInst.kittiesDominantCattributes.call(
      kittie3,
      0
    )
    const kittie3PatternCattribute = await RarityCalculatorInst.kittiesDominantCattributes.call(
      kittie3,
      1
    )
    const kittie3ColoreyesCattribute = await RarityCalculatorInst.kittiesDominantCattributes.call(
      kittie3,
      2
    )
    const kittie3EyesCattribute = await RarityCalculatorInst.kittiesDominantCattributes.call(
      kittie3,
      3
    )
    const kittie3Color1Cattribute = await RarityCalculatorInst.kittiesDominantCattributes.call(
      kittie3,
      4
    )
    const kittie3Color2Cattribute = await RarityCalculatorInst.kittiesDominantCattributes.call(
      kittie3,
      5
    )
    const kittie3Color3Cattribute = await RarityCalculatorInst.kittiesDominantCattributes.call(
      kittie3,
      6
    )
    const kittie3WildCattribute = await RarityCalculatorInst.kittiesDominantCattributes.call(
      kittie3,
      7
    )
    const kittie3MouthCattribute = await RarityCalculatorInst.kittiesDominantCattributes.call(
      kittie3,
      8
    )
    const kittie3EnvironmentCattribute = await RarityCalculatorInst.kittiesDominantCattributes.call(
      kittie3,
      9
    )

    assert.equal(kittie3BodyCattribute, 'toyger')
    assert.equal(kittie3PatternCattribute, 'camo')
    assert.equal(kittie3ColoreyesCattribute, 'cyan')
    assert.equal(kittie3EyesCattribute, 'wiley')
    assert.equal(kittie3Color1Cattribute, 'martian')
    assert.equal(kittie3Color2Cattribute, 'royalpurple')
    assert.equal(kittie3Color3Cattribute, 'icy')
    assert.equal(kittie3WildCattribute, '')
    assert.equal(kittie3MouthCattribute, 'confuzzled')
    assert.equal(kittie3EnvironmentCattribute, '')
  })

  it('is able to tell whether a kittie is a valule fancy kitite or not', async () => {
    const isFancyKittie3 = await RarityCalculatorInst.isFancy(kittie3)
    const isFancyKittie2 = await RarityCalculatorInst.isFancy(kittie2)
    assert.isFalse(isFancyKittie3)
    assert.isTrue(isFancyKittie2)
  })

  it('is able to calculate the rarity of the cattributes of a kittie', async () => {
    await RarityCalculatorInst.getDominantGeneBinary(kittie1, gene1)
    await RarityCalculatorInst.binaryToKai(kittie1)
    await RarityCalculatorInst.kaiToCattribute(kittie1)
    const rarityKittie1 = await RarityCalculatorInst.calculateRarity(kittie1)
    console.log(rarityKittie1.toNumber())
    assert.isNumber(rarityKittie1.toNumber())

    await RarityCalculatorInst.getDominantGeneBinary(kittie2, gene2)
    await RarityCalculatorInst.binaryToKai(kittie2)
    await RarityCalculatorInst.kaiToCattribute(kittie2)
    const rarityKittie2 = await RarityCalculatorInst.calculateRarity(kittie2)
    console.log(rarityKittie2.toNumber())
    assert.isNumber(rarityKittie2.toNumber())

    await RarityCalculatorInst.getDominantGeneBinary(kittie3, gene3)
    await RarityCalculatorInst.binaryToKai(kittie3)
    await RarityCalculatorInst.kaiToCattribute(kittie3)
    const rarityKittie3 = await RarityCalculatorInst.calculateRarity(kittie3)
    console.log(rarityKittie3.toNumber())
    assert.isNumber(rarityKittie3.toNumber())
  })

  it('is able to calculate the defense level of a kittie', async () => {
    // if kittieId of the kittie is lower than 10000, then its defense level should be default to 6
    const res1 = await RarityCalculatorInst.getDefenseLevel.call(kittie1, gene1)
    const defenseLevelKittie1 = res1.toNumber()
    console.log(defenseLevelKittie1)
    assert.equal(defenseLevelKittie1, 6)

    // if the kittie is a valuable fancy kittie, then its defense level should be default to 5
    const res2 = await RarityCalculatorInst.getDefenseLevel.call(kittie2, gene2)
    const defenseLevelKittie2 = res2.toNumber()
    console.log(defenseLevelKittie2)
    assert.equal(defenseLevelKittie2, 5)

    // a kitties has a defense level between 1 and 6
    const res3 = await RarityCalculatorInst.getDefenseLevel.call(kittie3, gene3)
    const defenseLevelKittie3 = res3.toNumber()
    console.log(defenseLevelKittie3)
    assert.isAtLeast(defenseLevelKittie3, 1)
    assert.isAtMost(defenseLevelKittie3, 6)
  })
})


// original data based on
// https://api.cryptokitties.co/cattributes
// RarityCalculationsDBs are built based on these original data.
const cattributesData = [
  { description: 'totesbasic', type: 'pattern', gene: 15, total: '357328' },
  { description: 'thicccbrowz', type: 'eyes', gene: 7, total: '261737' },
  { description: 'pouty', type: 'mouth', gene: 9, total: '239894' },
  {
    description: 'granitegrey',
    type: 'colortertiary',
    gene: 4,
    total: '231062'
  },
  {
    description: 'kittencream',
    type: 'colortertiary',
    gene: 6,
    total: '228748'
  },
  { description: 'happygokitty', type: 'mouth', gene: 14, total: '217675' },
  {
    description: 'royalpurple',
    type: 'colorsecondary',
    gene: 6,
    total: '208081'
  },
  {
    description: 'swampgreen',
    type: 'colorsecondary',
    gene: 8,
    total: '207611'
  },
  {
    description: 'lemonade',
    type: 'colorsecondary',
    gene: 13,
    total: '198827'
  },
  {
    description: 'greymatter',
    type: 'colorprimary',
    gene: 10,
    total: '197753'
  },
  { description: 'coffee', type: 'colorsecondary', gene: 12, total: '187877' },
  { description: 'soserious', type: 'mouth', gene: 15, total: '181556' },
  { description: 'ragdoll', type: 'body', gene: 15, total: '178290' },
  { description: 'crazy', type: 'eyes', gene: 6, total: '175398' },
  { description: 'luckystripe', type: 'pattern', gene: 9, total: '173368' },
  {
    description: 'cottoncandy',
    type: 'colorprimary',
    gene: 4,
    total: '170075'
  },
  { description: 'strawberry', type: 'coloreyes', gene: 7, total: '158208' },
  { description: 'mintgreen', type: 'coloreyes', gene: 3, total: '152137' },
  { description: 'amur', type: 'pattern', gene: 10, total: '151854' },
  { description: 'mauveover', type: 'colorprimary', gene: 5, total: '151251' },
  { description: 'munchkin', type: 'body', gene: 12, total: '145716' },
  { description: 'selkirk', type: 'body', gene: 1, total: '143269' },
  { description: 'sizzurp', type: 'coloreyes', gene: 5, total: '139728' },
  { description: 'shadowgrey', type: 'colorprimary', gene: 0, total: '134554' },
  { description: 'sphynx', type: 'body', gene: 13, total: '132919' },
  {
    description: 'bananacream',
    type: 'colorprimary',
    gene: 15,
    total: '126658'
  },
  { description: 'saycheese', type: 'mouth', gene: 10, total: '124120' },
  { description: 'simple', type: 'eyes', gene: 5, total: '122615' },
  { description: 'wiley', type: 'eyes', gene: 14, total: '121061' },
  { description: 'topaz', type: 'coloreyes', gene: 2, total: '119943' },
  { description: 'spock', type: 'pattern', gene: 12, total: '119683' },
  { description: 'icy', type: 'colortertiary', gene: 3, total: '117836' },
  {
    description: 'chocolate',
    type: 'colorsecondary',
    gene: 14,
    total: '113092'
  },
  {
    description: 'egyptiankohl',
    type: 'colorsecondary',
    gene: 2,
    total: '112992'
  },
  { description: 'tiger', type: 'pattern', gene: 1, total: '112653' },
  {
    description: 'purplehaze',
    type: 'colortertiary',
    gene: 10,
    total: '110145'
  },
  {
    description: 'sandalwood',
    type: 'colortertiary',
    gene: 1,
    total: '106106'
  },
  { description: 'sapphire', type: 'coloreyes', gene: 8, total: '105881' },
  { description: 'himalayan', type: 'body', gene: 11, total: '105273' },
  { description: 'slyboots', type: 'eyes', gene: 13, total: '104984' },
  { description: 'thundergrey', type: 'coloreyes', gene: 0, total: '104672' },
  { description: 'rascal', type: 'pattern', gene: 2, total: '103387' },
  { description: 'chronic', type: 'eyes', gene: 12, total: '103102' },
  { description: 'birman', type: 'body', gene: 3, total: '102891' },
  { description: 'cyan', type: 'coloreyes', gene: 15, total: '102604' },
  { description: 'wonky', type: 'eyes', gene: 1, total: '100311' },
  { description: 'aquamarine', type: 'colorprimary', gene: 6, total: '100184' },
  { description: 'frosting', type: 'colortertiary', gene: 15, total: '99477' },
  { description: 'ragamuffin', type: 'body', gene: 14, total: '97745' },
  { description: 'chestnut', type: 'coloreyes', gene: 6, total: '97512' },
  { description: 'gold', type: 'coloreyes', gene: 1, total: '96770' },
  { description: 'orangesoda', type: 'colorprimary', gene: 3, total: '96512' },
  { description: 'wuvme', type: 'mouth', gene: 2, total: '96487' },
  { description: 'raisedbrow', type: 'eyes', gene: 19, total: '96319' },
  { description: 'grim', type: 'mouth', gene: 11, total: '95561' },
  { description: 'cymric', type: 'body', gene: 9, total: '94958' },
  { description: 'googly', type: 'eyes', gene: 3, total: '93886' },
  {
    description: 'emeraldgreen',
    type: 'colortertiary',
    gene: 7,
    total: '93291'
  },
  { description: 'cinderella', type: 'colorprimary', gene: 9, total: '92005' },
  { description: 'koladiviya', type: 'body', gene: 4, total: '91854' },
  { description: 'salmon', type: 'colorprimary', gene: 1, total: '90701' },
  {
    description: 'barkbrown',
    type: 'colorsecondary',
    gene: 11,
    total: '83274'
  },
  { description: 'whixtensions', type: 'mouth', gene: 0, total: '80845' },
  { description: 'coralsunrise', type: 'coloreyes', gene: 11, total: '78633' },
  {
    description: 'azaleablush',
    type: 'colortertiary',
    gene: 12,
    total: '77153'
  },
  { description: 'bobtail', type: 'body', gene: 5, total: '77039' },
  { description: 'scarlet', type: 'colorsecondary', gene: 10, total: '75289' },
  { description: 'dahlia', type: 'coloreyes', gene: 10, total: '68885' },
  { description: 'beard', type: 'mouth', gene: 8, total: '67190' },
  { description: 'rorschach', type: 'pattern', gene: 6, total: '66836' },
  { description: 'belleblue', type: 'colortertiary', gene: 0, total: '66308' },
  { description: 'cashewmilk', type: 'colortertiary', gene: 5, total: '64540' },
  { description: 'tongue', type: 'mouth', gene: 23, total: '64236' },
  { description: 'spangled', type: 'pattern', gene: 7, total: '62049' },
  { description: 'cloudwhite', type: 'colorprimary', gene: 16, total: '61823' },
  { description: 'gerbil', type: 'mouth', gene: 3, total: '61148' },
  { description: 'calicool', type: 'pattern', gene: 8, total: '61079' },
  { description: 'brownies', type: 'colorprimary', gene: 12, total: '60039' },
  { description: 'skyblue', type: 'colorsecondary', gene: 22, total: '53131' },
  { description: 'savannah', type: 'body', gene: 0, total: '50522' },
  { description: 'olive', type: 'coloreyes', gene: 12, total: '50428' },
  { description: 'pixiebob', type: 'body', gene: 7, total: '50346' },
  { description: 'leopard', type: 'pattern', gene: 4, total: '49552' },
  {
    description: 'morningglory',
    type: 'colortertiary',
    gene: 14,
    total: '49516'
  },
  { description: 'ganado', type: 'pattern', gene: 3, total: '47030' },
  { description: 'laperm', type: 'body', gene: 22, total: '46224' },
  { description: 'bloodred', type: 'colortertiary', gene: 19, total: '43398' },
  { description: 'kalahari', type: 'colortertiary', gene: 8, total: '42713' },
  { description: 'confuzzled', type: 'mouth', gene: 4, total: '42440' },
  {
    description: 'doridnudibranch',
    type: 'coloreyes',
    gene: 13,
    total: '42250'
  },
  { description: 'asif', type: 'eyes', gene: 11, total: '41891' },
  { description: 'oldlace', type: 'colorprimary', gene: 18, total: '41208' },
  { description: 'parakeet', type: 'coloreyes', gene: 14, total: '41064' },
  { description: 'limegreen', type: 'coloreyes', gene: 17, total: '38424' },
  { description: 'peach', type: 'colortertiary', gene: 2, total: '37550' },
  { description: 'rollercoaster', type: 'mouth', gene: 7, total: '37170' },
  { description: 'lilac', type: 'colorsecondary', gene: 4, total: '35515' },
  { description: 'swarley', type: 'eyes', gene: 0, total: '35461' },
  { description: 'jaguar', type: 'pattern', gene: 11, total: '33928' },
  { description: 'shale', type: 'colortertiary', gene: 9, total: '32405' },
  { description: 'otaku', type: 'eyes', gene: 4, total: '32399' },
  { description: 'fangtastic', type: 'mouth', gene: 12, total: '31869' },
  { description: 'apricot', type: 'colorsecondary', gene: 5, total: '31322' },
  { description: 'stunned', type: 'eyes', gene: 15, total: '30699' },
  { description: 'nachocheez', type: 'colorprimary', gene: 7, total: '30052' },
  {
    description: 'poisonberry',
    type: 'colorsecondary',
    gene: 3,
    total: '28719'
  },
  { description: 'tigerpunk', type: 'pattern', gene: 20, total: '27526' },
  { description: 'serpent', type: 'eyes', gene: 2, total: '27220' },
  { description: 'sass', type: 'eyes', gene: 22, total: '26666' },
  { description: 'dali', type: 'mouth', gene: 20, total: '25472' },
  { description: 'henna', type: 'pattern', gene: 21, total: '25407' },
  { description: 'impish', type: 'mouth', gene: 5, total: '25067' },
  { description: 'norwegianforest', type: 'body', gene: 16, total: '24860' },
  {
    description: 'springcrocus',
    type: 'colorsecondary',
    gene: 1,
    total: '24317'
  },
  { description: 'chartreux', type: 'body', gene: 10, total: '23641' },
  { description: 'onyx', type: 'colorprimary', gene: 25, total: '23223' },
  { description: 'forgetmenot', type: 'coloreyes', gene: 9, total: '23046' },
  { description: 'bubblegum', type: 'coloreyes', gene: 19, total: '22469' },
  { description: 'moue', type: 'mouth', gene: 13, total: '21851' },
  { description: 'siberian', type: 'body', gene: 8, total: '21823' },
  { description: 'chantilly', type: 'body', gene: 2, total: '20909' },
  { description: 'camo', type: 'pattern', gene: 5, total: '20427' },
  { description: 'fabulous', type: 'eyes', gene: 18, total: '19858' },
  {
    description: 'missmuffett',
    type: 'colortertiary',
    gene: 13,
    total: '19413'
  },
  { description: 'baddate', type: 'eyes', gene: 10, total: '19360' },
  { description: 'violet', type: 'colorsecondary', gene: 9, total: '18679' },
  { description: 'elk', type: 'wild', gene: 17, total: '17707' },
  { description: 'salty', type: 'environment', gene: 16, total: '17489' },
  { description: 'caffeine', type: 'eyes', gene: 8, total: '16555' },
  {
    description: 'padparadscha',
    type: 'colorsecondary',
    gene: 7,
    total: '16226'
  },
  { description: 'wolfgrey', type: 'colorsecondary', gene: 20, total: '15757' },
  { description: 'persian', type: 'body', gene: 23, total: '14624' },
  { description: 'eclipse', type: 'coloreyes', gene: 23, total: '14536' },
  { description: 'martian', type: 'colorprimary', gene: 27, total: '14436' },
  { description: 'tundra', type: 'colorprimary', gene: 11, total: '14348' },
  { description: 'mittens', type: 'pattern', gene: 13, total: '14292' },
  { description: 'manul', type: 'body', gene: 6, total: '14032' },
  { description: 'daffodil', type: 'colortertiary', gene: 16, total: '13619' },
  { description: 'cerulian', type: 'colorsecondary', gene: 21, total: '13586' },
  {
    description: 'butterscotch',
    type: 'colorsecondary',
    gene: 15,
    total: '13361'
  },
  { description: 'hintomint', type: 'colorprimary', gene: 14, total: '13248' },
  { description: 'wasntme', type: 'mouth', gene: 1, total: '13053' },
  { description: 'highlander', type: 'body', gene: 18, total: '12969' },
  { description: 'neckbeard', type: 'mouth', gene: 26, total: '12636' },
  { description: 'verdigris', type: 'colorprimary', gene: 23, total: '12274' },
  { description: 'belch', type: 'mouth', gene: 6, total: '12168' },
  { description: 'dippedcone', type: 'pattern', gene: 18, total: '11874' },
  { description: 'alien', type: 'eyes', gene: 17, total: '11654' },
  { description: 'dragonwings', type: 'wild', gene: 28, total: '11591' },
  { description: 'koala', type: 'colorprimary', gene: 19, total: '11574' },
  { description: 'dragontail', type: 'wild', gene: 24, total: '11366' },
  { description: 'harbourfog', type: 'colorprimary', gene: 8, total: '11103' },
  { description: 'wingtips', type: 'eyes', gene: 25, total: '10855' },
  { description: 'flapflap', type: 'wild', gene: 22, total: '10740' },
  {
    description: 'patrickstarfish',
    type: 'colortertiary',
    gene: 23,
    total: '10688'
  },
  {
    description: 'dragonfruit',
    type: 'colorprimary',
    gene: 13,
    total: '10569'
  },
  { description: 'thunderstruck', type: 'pattern', gene: 17, total: '10122' },
  {
    description: 'safetyvest',
    type: 'colorsecondary',
    gene: 17,
    total: '10102'
  },
  { description: 'toyger', type: 'body', gene: 26, total: '9949' },
  { description: 'arcreactor', type: 'pattern', gene: 22, total: '9660' },
  { description: 'ducky', type: 'wild', gene: 18, total: '9581' },
  { description: 'sweetmeloncakes', type: 'eyes', gene: 23, total: '9279' },
  { description: 'sully', type: 'colortertiary', gene: 28, total: '9253' },
  {
    description: 'peppermint',
    type: 'colorsecondary',
    gene: 24,
    total: '9249'
  },
  { description: 'roadtogold', type: 'environment', gene: 26, total: '9198' },
  { description: 'wowza', type: 'eyes', gene: 9, total: '9071' },
  { description: 'cheeky', type: 'mouth', gene: 16, total: '8966' },
  { description: 'lynx', type: 'body', gene: 20, total: '8832' },
  { description: 'pumpkin', type: 'coloreyes', gene: 16, total: '8597' },
  { description: 'atlantis', type: 'colortertiary', gene: 20, total: '8502' },
  { description: 'shamrock', type: 'colorprimary', gene: 29, total: '8351' },
  { description: 'periwinkle', type: 'colortertiary', gene: 22, total: '7998' },
  { description: 'buzzed', type: 'eyes', gene: 27, total: '7992' },
  { description: 'manx', type: 'body', gene: 27, total: '7932' },
  { description: 'littlefoot', type: 'wild', gene: 16, total: '7768' },
  { description: 'starstruck', type: 'mouth', gene: 17, total: '7700' },
  { description: 'unicorn', type: 'wild', gene: 27, total: '7639' },
  { description: 'grimace', type: 'mouth', gene: 21, total: '7596' },
  { description: 'daemonhorns', type: 'wild', gene: 23, total: '7568' },
  { description: 'hotrod', type: 'pattern', gene: 26, total: '7487' },
  { description: 'hanauma', type: 'colortertiary', gene: 11, total: '7295' },
  { description: 'highsociety', type: 'pattern', gene: 19, total: '7120' },
  { description: 'royalblue', type: 'colorsecondary', gene: 26, total: '6995' },
  { description: 'redvelvet', type: 'colorprimary', gene: 22, total: '6984' },
  { description: 'mainecoon', type: 'body', gene: 21, total: '6973' },
  {
    description: 'finalfrontier',
    type: 'environment',
    gene: 21,
    total: '6775'
  },
  { description: 'pearl', type: 'colorsecondary', gene: 29, total: '6743' },
  { description: 'palejade', type: 'coloreyes', gene: 21, total: '6396' },
  { description: 'kaleidoscope', type: 'coloreyes', gene: 30, total: '6126' },
  { description: 'razzledazzle', type: 'pattern', gene: 25, total: '6072' },
  { description: 'allyouneed', type: 'pattern', gene: 27, total: '6035' },
  { description: 'universe', type: 'colorsecondary', gene: 25, total: '5962' },
  {
    description: 'turtleback',
    type: 'colorsecondary',
    gene: 18,
    total: '5608'
  },
  { description: 'satiated', type: 'mouth', gene: 27, total: '5522' },
  { description: 'pinefresh', type: 'coloreyes', gene: 22, total: '5508' },
  {
    description: 'inflatablepool',
    type: 'colorsecondary',
    gene: 28,
    total: '5420'
  },
  { description: 'firedup', type: 'eyes', gene: 26, total: '5410' },
  { description: 'mekong', type: 'body', gene: 17, total: '5270' },
  { description: 'meowgarine', type: 'colorprimary', gene: 2, total: '5248' },
  { description: 'chameleon', type: 'eyes', gene: 16, total: '5222' },
  { description: 'hyacinth', type: 'colorprimary', gene: 26, total: '4885' },
  { description: 'daemonwings', type: 'wild', gene: 20, total: '4751' },
  { description: 'buttercup', type: 'colortertiary', gene: 18, total: '4744' },
  { description: 'fox', type: 'body', gene: 24, total: '4697' },
  { description: 'yokel', type: 'mouth', gene: 24, total: '4565' },
  {
    description: 'twilightsparkle',
    type: 'coloreyes',
    gene: 20,
    total: '4534'
  },
  { description: 'splat', type: 'pattern', gene: 16, total: '4530' },
  { description: 'flamingo', type: 'colortertiary', gene: 17, total: '4485' },
  { description: 'seafoam', type: 'colortertiary', gene: 24, total: '4384' },
  {
    description: 'rosequartz',
    type: 'colorsecondary',
    gene: 19,
    total: '4380'
  },
  { description: 'vigilante', type: 'pattern', gene: 0, total: '4318' },
  { description: 'juju', type: 'environment', gene: 18, total: '4210' },
  { description: 'cobalt', type: 'colortertiary', gene: 25, total: '4173' },
  { description: 'dioscuri', type: 'coloreyes', gene: 29, total: '4090' },
  { description: 'topoftheworld', type: 'mouth', gene: 25, total: '4087' },
  { description: 'tinybox', type: 'environment', gene: 19, total: '3738' },
  { description: 'avatar', type: 'pattern', gene: 28, total: '3644' },
  { description: 'glacier', type: 'colorprimary', gene: 21, total: '3592' },
  { description: 'samwise', type: 'mouth', gene: 18, total: '3560' },
  { description: 'trioculus', type: 'wild', gene: 19, total: '3552' },
  {
    description: 'mintmacaron',
    type: 'colortertiary',
    gene: 27,
    total: '3477'
  },
  { description: 'garnet', type: 'colorsecondary', gene: 23, total: '3356' },
  { description: 'bornwithit', type: 'eyes', gene: 28, total: '3328' },
  { description: 'cyborg', type: 'colorsecondary', gene: 0, total: '2757' },
  { description: 'hotcocoa', type: 'colorprimary', gene: 28, total: '2695' },
  { description: 'wyrm', type: 'wild', gene: 30, total: '2677' },
  { description: 'drift', type: 'environment', gene: 23, total: '2623' },
  { description: 'alicorn', type: 'wild', gene: 29, total: '2619' },
  { description: 'walrus', type: 'mouth', gene: 28, total: '2517' },
  { description: 'lavender', type: 'colorprimary', gene: 20, total: '2504' },
  { description: 'majestic', type: 'mouth', gene: 22, total: '2495' },
  { description: 'oohshiny', type: 'prestige', gene: null, total: '2484' },
  { description: 'lykoi', type: 'body', gene: 28, total: '2320' },
  { description: 'drama', type: 'eyes', gene: 30, total: '2319' },
  { description: 'kurilian', type: 'body', gene: 25, total: '2309' },
  { description: 'aflutter', type: 'wild', gene: 25, total: '2268' },
  { description: 'delite', type: 'mouth', gene: 30, total: '2170' },
  { description: 'frozen', type: 'environment', gene: 25, total: '2077' },
  { description: 'babypuke', type: 'coloreyes', gene: 24, total: '2043' },
  { description: 'balinese', type: 'body', gene: 19, total: '1930' },
  { description: 'oceanid', type: 'eyes', gene: 24, total: '1927' },
  {
    description: 'prairierose',
    type: 'colorsecondary',
    gene: 30,
    total: '1919'
  },
  { description: 'tendertears', type: 'eyes', gene: 20, total: '1875' },
  { description: 'candyshoppe', type: 'eyes', gene: 29, total: '1864' },
  { description: 'autumnmoon', type: 'coloreyes', gene: 26, total: '1855' },
  { description: 'hacker', type: 'eyes', gene: 21, total: '1845' },
  { description: 'myparade', type: 'environment', gene: 20, total: '1786' },
  { description: 'moonrise', type: 'pattern', gene: 30, total: '1754' },
  { description: 'gyre', type: 'pattern', gene: 29, total: '1686' },
  { description: 'isotope', type: 'coloreyes', gene: 4, total: '1653' },
  { description: 'prism', type: 'environment', gene: 29, total: '1600' },
  { description: 'ruhroh', type: 'mouth', gene: 19, total: '1582' },
  { description: 'icicle', type: 'colorprimary', gene: 24, total: '1537' },
  { description: 'featherbrain', type: 'wild', gene: 21, total: '1533' },
  { description: 'junglebook', type: 'environment', gene: 30, total: '1515' },
  { description: 'foghornpawhorn', type: 'wild', gene: 26, total: '1467' },
  { description: 'scorpius', type: 'pattern', gene: 24, total: '1454' },
  { description: 'jacked', type: 'environment', gene: 27, total: '1432' },
  { description: 'cornflower', type: 'colorprimary', gene: 17, total: '1398' },
  { description: 'firstblush', type: 'colorprimary', gene: 30, total: '1381' },
  { description: 'purrbados', type: 'prestige', gene: null, total: '1344' },
  { description: 'floorislava', type: 'environment', gene: 28, total: '1286' },
  { description: 'hooked', type: 'prestige', gene: null, total: '1277' },
  { description: 'oasis', type: 'coloreyes', gene: 27, total: '1275' },
  { description: 'duckduckcat', type: 'prestige', gene: null, total: '1249' },
  { description: 'dreamcloud', type: 'prestige', gene: null, total: '1246' },
  { description: 'alpacacino', type: 'prestige', gene: null, total: '1220' },
  { description: 'gemini', type: 'coloreyes', gene: 28, total: '1220' },
  { description: 'secretgarden', type: 'environment', gene: 24, total: '1186' },
  { description: 'mertail', type: 'colorsecondary', gene: 27, total: '1185' },
  {
    description: 'summerbonnet',
    type: 'colortertiary',
    gene: 21,
    total: '1158'
  },
  { description: 'liger', type: 'body', gene: 30, total: '1149' },
  { description: 'dune', type: 'environment', gene: 17, total: '1144' },
  { description: 'dreamboat', type: 'colortertiary', gene: 30, total: '1141' },
  { description: 'inaband', type: 'prestige', gene: null, total: '1048' },
  { description: 'lit', type: 'prestige', gene: null, total: '1006' },
  { description: 'furball', type: 'prestige', gene: null, total: '998' },
  { description: 'struck', type: 'mouth', gene: 29, total: '961' },
  { description: 'wrecked', type: 'prestige', gene: null, total: '959' },
  { description: 'downbythebay', type: 'coloreyes', gene: 25, total: '934' },
  { description: 'alpunka', type: 'prestige', gene: null, total: '926' },
  { description: 'prune', type: 'prestige', gene: null, total: '921' },
  { description: 'cindylou', type: 'prestige', gene: null, total: '905' },
  { description: 'burmilla', type: 'body', gene: 29, total: '904' },
  { description: 'uplink', type: 'prestige', gene: null, total: '870' },
  { description: 'metime', type: 'environment', gene: 22, total: '863' },
  { description: 'reindeer', type: 'prestige', gene: null, total: '854' },
  { description: 'huacool', type: 'prestige', gene: null, total: '837' },
  { description: 'ooze', type: 'colorsecondary', gene: 16, total: '832' },
  {
    description: 'mallowflower',
    type: 'colortertiary',
    gene: 26,
    total: '809'
  },
  { description: 'beatlesque', type: 'prestige', gene: null, total: '783' },
  { description: 'gauntlet', type: 'prestige', gene: null, total: '781' },
  { description: 'scratchingpost', type: 'prestige', gene: null, total: '772' },
  { description: 'holidaycheer', type: 'prestige', gene: null, total: '759' },
  { description: 'fallspice', type: 'colortertiary', gene: 29, total: '758' },
  { description: 'bridesmaid', type: 'coloreyes', gene: 18, total: '740' },
  { description: 'landlubber', type: 'prestige', gene: null, total: '711' },
  { description: 'squelch', type: 'prestige', gene: null, total: '652' },
  { description: 'maraud', type: 'prestige', gene: null, total: '620' },
  { description: 'thatsawrap', type: 'prestige', gene: null, total: '615' },
  { description: 'fileshare', type: 'prestige', gene: null, total: '515' },
  { description: 'timbers', type: 'prestige', gene: null, total: '472' },
  { description: 'catterypack', type: 'prestige', gene: null, total: '340' },
  { description: 'pawsfree', type: 'prestige', gene: null, total: '264' },
  { description: 'bionic', type: 'prestige', gene: null, total: '195' }
]

// original data based on
// https://github.com/openblockchains/programming-cryptocollectibles/blob/master/02_genereader.md

const kaiToCattributesData = [
  {
    body: {
      genes: '0-3',
      name: 'Fur',
      code: 'FU',
      kai: {
        '1': 'savannah',
        '2': 'selkirk',
        '3': 'chantilly',
        '4': 'birman',
        '5': 'koladiviya',
        '6': 'bobtail',
        '7': 'manul',
        '8': 'pixiebob',
        '9': 'siberian',
        a: 'cymric',
        b: 'chartreux',
        c: 'himalayan',
        d: 'munchkin',
        e: 'sphynx',
        f: 'ragamuffin',
        g: 'ragdoll',
        h: 'norwegianforest',
        i: 'mekong',
        j: 'highlander',
        k: 'balinese',
        m: 'lynx',
        n: 'mainecoon',
        o: 'laperm',
        p: 'persian',
        q: 'fox',
        r: 'kurilian',
        s: 'toyger',
        t: 'manx',
        u: 'lykoi',
        v: 'burmilla',
        w: 'liger',
        x: ''
      }
    }
  },
  {
    pattern: {
      genes: '4-7',
      name: 'Pattern',
      code: 'PA',
      kai: {
        '1': 'vigilante',
        '2': 'tiger',
        '3': 'rascal',
        '4': 'ganado',
        '5': 'leopard',
        '6': 'camo',
        '7': 'rorschach',
        '8': 'spangled',
        '9': 'calicool',
        a: 'luckystripe',
        b: 'amur',
        c: 'jaguar',
        d: 'spock',
        e: 'mittens',
        f: 'totesbasic',
        g: 'totesbasic',
        h: 'splat',
        i: 'thunderstruck',
        j: 'dippedcone',
        k: 'highsociety',
        m: 'tigerpunk',
        n: 'henna',
        o: 'arcreactor',
        p: 'totesbasic',
        q: 'scorpius',
        r: 'razzledazzle',
        s: 'hotrod',
        t: 'allyouneed',
        u: 'avatar',
        v: 'gyre',
        w: 'moonrise',
        x: ''
      }
    }
  },
  {
    coloreyes: {
      genes: '8-11',
      name: 'Eye Color',
      code: 'EC',
      kai: {
        '1': 'thundergrey',
        '2': 'gold',
        '3': 'topaz',
        '4': 'mintgreen',
        '5': 'isotope',
        '6': 'sizzurp',
        '7': 'chestnut',
        '8': 'strawberry',
        '9': 'sapphire',
        a: 'forgetmenot',
        b: 'dahlia',
        c: 'coralsunrise',
        d: 'olive',
        e: 'doridnudibranch',
        f: 'parakeet',
        g: 'cyan',
        h: 'pumpkin',
        i: 'limegreen',
        j: 'bridesmaid',
        k: 'bubblegum',
        m: 'twilightsparkle',
        n: 'palejade',
        o: 'pinefresh',
        p: 'eclipse',
        q: 'babypuke',
        r: 'downbythebay',
        s: 'autumnmoon',
        t: 'oasis',
        u: 'gemini',
        v: 'dioscuri',
        w: 'kaleidoscope',
        x: ''
      }
    }
  },
  {
    eyes: {
      genes: '12-15',
      name: 'Eye Shape',
      code: 'ES',
      kai: {
        '1': 'swarley',
        '2': 'wonky',
        '3': 'serpent',
        '4': 'googly',
        '5': 'otaku',
        '6': 'simple',
        '7': 'crazy',
        '8': 'thicccbrowz',
        '9': 'caffeine',
        a: 'wowza',
        b: 'baddate',
        c: 'asif',
        d: 'chronic',
        e: 'slyboots',
        f: 'wiley',
        g: 'stunned',
        h: 'chameleon',
        i: 'alien',
        j: 'fabulous',
        k: 'raisedbrow',
        m: 'tendertears',
        n: 'hacker',
        o: 'sass',
        p: 'sweetmeloncakes',
        q: 'oceanid',
        r: 'wingtips',
        s: 'firedup',
        t: 'buzzed',
        u: 'bornwithit',
        v: 'candyshoppe',
        w: 'drama',
        x: ''
      }
    }
  },
  {
    color1: {
      genes: '16-19',
      name: 'Base Color',
      code: 'BC',
      kai: {
        '1': 'shadowgrey',
        '2': 'salmon',
        '3': 'meowgarine',
        '4': 'orangesoda',
        '5': 'cottoncandy',
        '6': 'mauveover',
        '7': 'aquamarine',
        '8': 'nachocheez',
        '9': 'harbourfog',
        a: 'cinderella',
        b: 'greymatter',
        c: 'tundra',
        d: 'brownies',
        e: 'dragonfruit',
        f: 'hintomint',
        g: 'bananacream',
        h: 'cloudwhite',
        i: 'cornflower',
        j: 'oldlace',
        k: 'koala',
        m: 'lavender',
        n: 'glacier',
        o: 'redvelvet',
        p: 'verdigris',
        q: 'icicle',
        r: 'onyx',
        s: 'hyacinth',
        t: 'martian',
        u: 'hotcocoa',
        v: 'shamrock',
        w: 'firstblush',
        x: ''
      }
    }
  },
  {
    color2: {
      genes: '20-23',
      name: 'Highlight Color',
      code: 'HC',
      kai: {
        '1': 'cyborg',
        '2': 'springcrocus',
        '3': 'egyptiankohl',
        '4': 'poisonberry',
        '5': 'lilac',
        '6': 'apricot',
        '7': 'royalpurple',
        '8': 'padparadscha',
        '9': 'swampgreen',
        a: 'violet',
        b: 'scarlet',
        c: 'barkbrown',
        d: 'coffee',
        e: 'lemonade',
        f: 'chocolate',
        g: 'butterscotch',
        h: 'ooze',
        i: 'safetyvest',
        j: 'turtleback',
        k: 'rosequartz',
        m: 'wolfgrey',
        n: 'cerulian',
        o: 'skyblue',
        p: 'garnet',
        q: 'peppermint',
        r: 'universe',
        s: 'royalblue',
        t: 'mertail',
        u: 'inflatablepool',
        v: 'pearl',
        w: 'prairierose',
        x: ''
      }
    }
  },
  {
    color3: {
      genes: '24-27',
      name: 'Accent Color',
      code: 'AC',
      kai: {
        '1': 'belleblue',
        '2': 'sandalwood',
        '3': 'peach',
        '4': 'icy',
        '5': 'granitegrey',
        '6': 'cashewmilk',
        '7': 'kittencream',
        '8': 'emeraldgreen',
        '9': 'kalahari',
        a: 'shale',
        b: 'purplehaze',
        c: 'hanauma',
        d: 'azaleablush',
        e: 'missmuffett',
        f: 'morningglory',
        g: 'frosting',
        h: 'daffodil',
        i: 'flamingo',
        j: 'buttercup',
        k: 'bloodred',
        m: 'atlantis',
        n: 'summerbonnet',
        o: 'periwinkle',
        p: 'patrickstarfish',
        q: 'seafoam',
        r: 'cobalt',
        s: 'mallowflower',
        t: 'mintmacaron',
        u: 'sully',
        v: 'fallspice',
        w: 'dreamboat',
        x: ''
      }
    }
  },
  {
    wild: {
      genes: '28-31',
      name: 'Wild',
      code: 'WE',
      kai: {
        '1': '',
        '2': '',
        '3': '',
        '4': '',
        '5': '',
        '6': '',
        '7': '',
        '8': '',
        '9': '',
        a: '',
        b: '',
        c: '',
        d: '',
        e: '',
        f: '',
        g: '',
        h: 'littlefoot',
        i: 'elk',
        j: 'ducky',
        k: 'trioculus',
        m: 'daemonwings',
        n: 'featherbrain',
        o: 'flapflap',
        p: 'daemonhorns',
        q: 'dragontail',
        r: 'aflutter',
        s: 'foghornpawhorn',
        t: 'unicorn',
        u: 'dragonwings',
        v: 'alicorn',
        w: 'wyrm',
        x: ''
      }
    }
  },
  {
    mouth: {
      genes: '32-35',
      name: 'Mouth',
      code: 'MO',
      kai: {
        '1': 'whixtensions',
        '2': 'wasntme',
        '3': 'wuvme',
        '4': 'gerbil',
        '5': 'confuzzled',
        '6': 'impish',
        '7': 'belch',
        '8': 'rollercoaster',
        '9': 'beard',
        a: 'pouty',
        b: 'saycheese',
        c: 'grim',
        d: 'fangtastic',
        e: 'moue',
        f: 'happygokitty',
        g: 'soserious',
        h: 'cheeky',
        i: 'starstruck',
        j: 'samwise',
        k: 'ruhroh',
        m: 'dali',
        n: 'grimace',
        o: 'majestic',
        p: 'tongue',
        q: 'yokel',
        r: 'topoftheworld',
        s: 'neckbeard',
        t: 'satiated',
        u: 'walrus',
        v: 'struck',
        w: 'delite',
        x: ''
      }
    }
  },
  {
    environment: {
      genes: '36-39',
      name: 'Environment',
      code: 'EN',
      kai: {
        '1': '',
        '2': '',
        '3': '',
        '4': '',
        '5': '',
        '6': '',
        '7': '',
        '8': '',
        '9': '',
        a: '',
        b: '',
        c: '',
        d: '',
        e: '',
        f: '',
        g: '',
        h: 'salty',
        i: 'dune',
        j: 'juju',
        k: 'tinybox',
        m: 'myparade',
        n: 'finalfrontier',
        o: 'metime',
        p: 'drift',
        q: 'secretgarden',
        r: 'frozen',
        s: 'roadtogold',
        t: 'jacked',
        u: 'floorislava',
        v: 'prism',
        w: 'junglebook',
        x: ''
      }
    }
  },
  {
    secret: {
      genes: '40-43',
      name: 'Secret Y Gene',
      code: 'SE',
      kai: {}
    }
  },
  {
    prestige: { genes: '44-47', name: 'Purrstige', code: 'PU', kai: {} }
  }
]

// Samples of original data for fill in the db FancyKitties for testing purpose
// based on https://www.cryptokitties.co/catalogue/fancy-cats
// Fancy kitties are selected based on the rank of generation (low to high).
// For complete data set, please refer to sourceData/FancyKitties.js

const FancyKitties = [
  [
    'Catamari',
    1642629,
    1642657,
    1641933,
    1642019,
    1646755,
    1639921,
    1643320,
    1646438,
    1649667,
    1645264,
    1643775,
    1644114,
    1640134,
    1647228,
    1643862,
    1647294,
    1641007,
    1646945,
    1646255,
    1642591,
    1644179,
    1643528,
    1647854,
    1649527,
    1646945,
    1643862,
    1640134,
    1641704,
    1649527,
    1641007,
    1643252,
    1644544,
    1647485,
    1649133,
    1649632,
    1640061
  ],

  [
    'Magmeow',
    1631726,
    1634450,
    1632058,
    1631206,
    1631875,
    1629596,
    1635110,
    1633445,
    1634369,
    1632890,
    1631778,
    1634504,
    1635234,
    1634504,
    1631965,
    1632890,
    1635110,
    1634369,
    1632233,
    1635107,
    1632190,
    1630243,
    1634301,
    1633445,
    1632841,
    1631778,
    1632233,
    1633445,
    1635107,
    1635234,
    1635028,
    1633281,
    1635449,
    1633501,
    1633378,
    1633885
  ],

  [
    'Kitijira',
    1616077,
    1626771,
    1624378,
    1621802,
    1620498,
    1620920,
    1620827,
    1622099,
    1620131,
    1625850,
    1627335,
    1621018,
    1621802,
    1619371,
    1622012,
    1628854,
    1621378,
    1619639,
    1621078,
    1618937,
    1622779,
    1623096,
    1621843,
    1622632,
    1620432,
    1619639,
    1622012,
    1621078,
    1619371,
    1616707,
    1628854,
    1621843,
    1621907,
    1623096,
    1623973,
    1618937,
    1621078,
    1620578,
    1621508,
    1624223,
    1621330,
    1622707,
    1619208,
    1628279,
    1625513,
    1627029,
    1620855,
    1621197
  ],

  [
    'Whisper',
    1600063,
    1598628,
    1595078,
    1598372,
    1596604,
    1610037,
    1602063,
    1597556,
    1597306,
    1605931,
    1606998,
    1607247,
    1606998,
    1607247,
    1598164,
    1600894,
    1597556,
    1597306,
    1610037,
    1601338,
    1599641,
    1598638,
    1600664,
    1599655,
    1597774,
    1601113,
    1600664,
    1604885,
    1598748,
    1599655,
    1600074,
    1600727,
    1599641,
    1598638,
    1602861,
    1605716
  ],

  [
    'Krakitten',
    1549620,
    1551317,
    1549815,
    1566316,
    1551090,
    1549243,
    1551803,
    1552014,
    1554967,
    1549707,
    1550485,
    1550517,
    1550517,
    1560149,
    1550554,
    1549707,
    1555405,
    1560460,
    1549243,
    1566316,
    1551090,
    1554967,
    1563186,
    1549402,
    1555405,
    1560376,
    1555375,
    1555108,
    1554116,
    1551753,
    1551012,
    1555717,
    1553405,
    1560593,
    1555566,
    1566504,
    1560696,
    1560593,
    1560945,
    1550568,
    1554116,
    1566504,
    1551753,
    1553323,
    1555108,
    1560376,
    1555375,
    1550523,
    1555108,
    1563428,
    1564177,
    1551401,
    1555657,
    1560945,
    1560376,
    1554116,
    1555717,
    1553405,
    1550523,
    1550507
  ]
]

