const BigNumber = web3.utils.BN;
require("chai")
  .use(require("chai-shallow-deep-equal"))
  .use(require("chai-bignumber")(BigNumber))
  .use(require("chai-as-promised"))
  .should();
  
const VestingVault12 = artifacts.require("VestingVault12");
const KittieFightToken = artifacts.require("KittieFightToken");

const KTY_AMOUNT = new BigNumber(
  web3.utils.toWei("1000000", "ether") // 1,000,000 KTY
);

const TOKEN_AMOUNT = new BigNumber(
  web3.utils.toWei("1000", "ether") // 10,000 KTY
);

//truffle exec scripts/FE/vesting/addTokenGrant.js noOfUsers(uint) (Till 39)

module.exports = async callback => {
  try {
    let vestingVault12 = await VestingVault12.deployed();
    let kittieFightToken = await KittieFightToken.deployed();

    accounts = await web3.eth.getAccounts();

    //Changed
    let amount = process.argv[4];

    // approve token before addTokenGrant
    kittieFightToken.approve(vestingVault12.address, KTY_AMOUNT);

    for (let i = 1; i <= amount; i++) {
      await vestingVault12.addTokenGrant(
        accounts[i],
        0,
        TOKEN_AMOUNT,
        100 + i * 10,
        10
      ).should.be.fulfilled;
    }

    let newGrants = await vestingVault12.getPastEvents("GrantAdded", {
      fromBlock: 0,
      toBlock: "latest"
    });

    newGrants.map(async e => {
      console.log("\n==== NEW GRANT ADDED ===");
      console.log("    Grant Recipient ", e.returnValues.recipient);
      console.log("    Vesting ID ", e.returnValues.vestingId);
      console.log("========================\n");
    });

    callback();
  } catch (e) {
    callback(e);
  }
};
