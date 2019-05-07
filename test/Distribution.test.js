const BigNumber = require("bignumber.js");
require("chai")
  .use(require("chai-shallow-deep-equal"))
  .use(require("chai-bignumber")(BigNumber))
  .use(require("chai-as-promised"))
  .should();

const Proxy = artifacts.require("Proxy");
const Distribution = artifacts.require("Distribution");
const GenericDB = artifacts.require("GenericDB");
const GameVarAndFee = artifacts.require("GameVarAndFee");
const RoleDB = artifacts.require("RoleDB");
const KittieFightToken = artifacts.require('MockERC20Token');

const ERC20_TOKEN_SUPPLY = new BigNumber(1000000);


contract("Distribution", ([creator, randomAddress, winnerAddress]) => {

  beforeEach(async () => {
    //Deploy contracts needed for testing GameVarAndFee
    this.proxy = await Proxy.new();
    this.genericDB = await GenericDB.new();
    this.gameVarAndFee = await GameVarAndFee.new(this.genericDB.address);
    this.roleDB = await RoleDB.new(this.genericDB.address);
    this.kittieFightToken = await KittieFightToken.new(ERC20_TOKEN_SUPPLY);

    this.distribution = await Distribution.new();

    // Add contracts to Contract Manager mapping variable
    await this.proxy.addContract("GameVarAndFee", this.gameVarAndFee.address);
    await this.proxy.addContract("RoleDB", this.roleDB.address);
    await this.proxy.addContract("Distribution", this.distribution.address);


    // Set Proxy address in contracts
    await this.distribution.setProxy(this.proxy.address);
    await this.gameVarAndFee.setProxy(this.proxy.address);
    await this.roleDB.setProxy(this.proxy.address);
    await this.genericDB.setProxy(this.proxy.address);

    //Function only for testing, setting SuperAdmin Role to msg.sender
    await this.gameVarAndFee.initialize();

  });

  describe("Distribution", () => {
    it("sets new proxy", async () => {
      await this.distribution.setProxy(randomAddress).should.be.fulfilled;
      let proxy = await this.distribution.proxy();
      proxy.should.be.equal(randomAddress);
    });

    it("updates winner correctly", async () => {
      await this.proxy.setWinningKittie(35, { from: creator }).should.be.fulfilled;

      await this.distribution.newDistribution(1, 100, 1000).should.be.fulfilled;
      await this.distribution.updateWinner(winnerAddress, 1).should.be.fulfilled;

      let winner = await this.distribution.getWinner(1).should.be.fulfilled;

      winner.should.be.equal(winnerAddress);

    });

  });

});
