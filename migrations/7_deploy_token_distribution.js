const BigNumber = web3.utils.BN;

//ARTIFACTS
const TokenDistribution = artifacts.require("TokenDistribution");
const KittieFightToken = artifacts.require("KittieFightToken");

//Rinkeby address of KittieFightToken
//const KTY_ADDRESS = '0x8d05f69bd9e804eb467c7e1f2902ecd5e41a72da';

const ERC20_TOKEN_SUPPLY = new BigNumber(
  web3.utils.toWei("100000000", "ether") //100 Million
);

module.exports = (deployer, network, accounts) => {
  deployer
    .deploy(TokenDistribution)
    .then(() => deployer.deploy(KittieFightToken, ERC20_TOKEN_SUPPLY))
    .then(async () => {
      console.log("\nGetting contract instances...");

      // YieldFarming
      tokenDistribution = await TokenDistribution.deployed();
      console.log("TokenDistribution:", tokenDistribution.address);

      // TOKENS
      kittieFightToken = await KittieFightToken.deployed();
      console.log("KTY:", kittieFightToken.address);
      //kittieFightToken = await KittieFightToken.at(KTY_ADDRESS);
      //console.log(kittieFightToken.address)
    });
};
