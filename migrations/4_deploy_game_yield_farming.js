// all percentage use a base of 1000,000 in kittieFight system
// for example, 0.3 % is set as 3,000
// and 90% is set as 900,000
const BigNumber = web3.utils.BN;

//ARTIFACTS
const YieldFarming = artifacts.require("YieldFarming");
const SuperDaoToken = artifacts.require("MockERC20Token");
const KittieFightToken = artifacts.require("KittieFightToken");

const Factory = artifacts.require("UniswapV2Factory");
const WETH = artifacts.require("WETH9");
const KtyWethPair = artifacts.require("UniswapV2Pair");
const KtyUniswapOracle = artifacts.require("KtyUniswapOracle");
const Dai = artifacts.require("Dai");
const DaiWethPair = artifacts.require("IDaiWethPair");

//Rinkeby address of KittieFightToken
//const KTY_ADDRESS = '0x8d05f69bd9e804eb467c7e1f2902ecd5e41a72da';

const ERC20_TOKEN_SUPPLY = new BigNumber(
  web3.utils.toWei("100000000", "ether") //100 Million
);

const TOTAL_KTY_REWARDS = new BigNumber(
  web3.utils.toWei("100000", "ether") //100,000 KTY
);

const TOTAL_SDAO_REWARDS = new BigNumber(
  web3.utils.toWei("100000", "ether") //100,000 SDAO
);

module.exports = (deployer, network, accounts) => {
  // deployer
  //   .deploy(YieldFarming)
  //   .then(() => deployer.deploy(SuperDaoToken, ERC20_TOKEN_SUPPLY))
  //   .then(() => deployer.deploy(KittieFightToken, ERC20_TOKEN_SUPPLY))
  //   .then(() => deployer.deploy(WETH))
  //   .then(() => deployer.deploy(Factory, accounts[0]))
  //   .then(() => deployer.deploy(KtyUniswapOracle))
  //   .then(() => deployer.deploy(Dai, 1))
  //   .then(async () => {
  //     console.log("\nGetting contract instances...");

  //     // YieldFarming
  //     yieldFarming = await YieldFarming.deployed();
  //     console.log("YieldFarming:", yieldFarming.address);

  //     // TOKENS
  //     superDaoToken = await SuperDaoToken.deployed();
  //     console.log(superDaoToken.address);
  //     kittieFightToken = await KittieFightToken.deployed();
  //     console.log(kittieFightToken.address);
  //     //kittieFightToken = await KittieFightToken.at(KTY_ADDRESS);
  //     //console.log(kittieFightToken.address)

  //     // uniswap kty
  //     weth = await WETH.deployed();
  //     console.log("weth:", weth.address);
  //     factory = await Factory.deployed();
  //     console.log("factory:", factory.address);
  //     dai = await Dai.deployed();
  //     console.log("DAI:", dai.address);

  //     await factory.createPair(weth.address, kittieFightToken.address);
  //     const ktyPairAddress = await factory.getPair(
  //       weth.address,
  //       kittieFightToken.address
  //     );
  //     console.log("ktyWethPair address", ktyPairAddress);
  //     const ktyWethPair = await KtyWethPair.at(ktyPairAddress);
  //     console.log("ktyWethPair:", ktyWethPair.address);

  //     await factory.createPair(weth.address, dai.address);
  //     const daiPairAddress = await factory.getPair(weth.address, dai.address);
  //     console.log("daiWethPair address", daiPairAddress);
  //     const daiWethPair = await DaiWethPair.at(daiPairAddress);
  //     console.log("daiWethPair:", daiWethPair.address);

  //     ktyUniswapOracle = await KtyUniswapOracle.deployed();
  //     console.log("ktyUiswapOracle:", ktyUniswapOracle.address);

  //     console.log("\nInitializing contracts...");
  //     await yieldFarming.initialize(
  //       ktyWethPair.address,
  //       kittieFightToken.address,
  //       superDaoToken.address,
  //       ktyUniswapOracle.address,
  //       TOTAL_KTY_REWARDS,
  //       TOTAL_SDAO_REWARDS
  //     );
  //     await ktyUniswapOracle.initialize(
  //       ktyWethPair.address,
  //       daiWethPair.address,
  //       kittieFightToken.address,
  //       weth.address,
  //       dai.address
  //     );

  //     // set up uniswap - only needed in truffle local test, not needed in rinkeby or mainnet
  //     const ethAmount = new BigNumber(
  //       web3.utils.toWei("100", "ether") //100 ethers
  //     );

  //     const ktyAmount = new BigNumber(
  //       web3.utils.toWei("50000", "ether") //100 ethers * 500 = 50,000 kty
  //     );

  //     const daiAmount = new BigNumber(
  //       web3.utils.toWei("24191.54", "ether") //100 ethers * 241.9154 dai/ether = 24191.54 kty
  //     );

  //     await dai.mint(accounts[0], daiAmount);
  //     await dai.transfer(daiWethPair.address, daiAmount);
  //     await weth.deposit({value: ethAmount});
  //     await weth.transfer(daiWethPair.address, ethAmount);
  //     await daiWethPair.mint(accounts[0]);

  //     await kittieFightToken.transfer(ktyWethPair.address, ktyAmount);
  //     await weth.deposit({value: ethAmount});
  //     await weth.transfer(ktyWethPair.address, ethAmount);
  //     await ktyWethPair.mint(accounts[0]);
  //   });
};
