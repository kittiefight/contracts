const BigNumber = require("bignumber.js");
require("chai")
  .use(require("chai-shallow-deep-equal"))
  .use(require("chai-bignumber")(BigNumber))
  .use(require("chai-as-promised"))
  .should();

const GenericDB = artifacts.require("GenericDB");
const GameVarAndFee = artifacts.require("GameVarAndFee");
const Proxy = artifacts.require("KFProxy");
const DateTime = artifacts.require("DateTime");
const RoleDB = artifacts.require("RoleDB");

contract("DateTime", ([creator, randomAddress]) => {
  beforeEach(async () => {
    this.proxy = await Proxy.new();
    this.genericDB = await GenericDB.new();
    this.gameVarAndFee = await GameVarAndFee.new(this.genericDB.address);
    this.roleDB = await RoleDB.new(this.genericDB.address);
    this.dateTime = await DateTime.new();

    await this.proxy.addContract("GameVarAndFee", this.gameVarAndFee.address);
    await this.proxy.addContract("RoleDB", this.roleDB.address);

    await this.gameVarAndFee.setProxy(this.proxy.address);
    await this.genericDB.setProxy(this.proxy.address);
    await this.dateTime.setProxy(this.proxy.address);
    await this.roleDB.setProxy(this.proxy.address);

    await this.gameVarAndFee.initialize();
    await this.dateTime.initialize();
  });

  describe("DateTime", () => {
    it("sets new proxy", async () => {
      await this.dateTime.setProxy(randomAddress).should.be.fulfilled;
      let proxy = await this.dateTime.proxy();
      proxy.should.be.equal(randomAddress);
    });

    it("calculates correct game duration time", async () => {
      await this.proxy.setGameDuration(300);

      let gameDurationTime = await this.dateTime.runGameDurationTime().should.be
        .fulfilled;

      block = await web3.eth.getBlock();

      Date.prototype.addMinutes = function (m) {
        this.setMinutes(this.getMinutes() + m);
        return this;
      };

      blockDate = Date(block.timestamp * 1000);
      var utcDate = new Date(blockDate);
      utcDate = utcDate.addMinutes(5);

      gameDurationTime._hour.toNumber().should.be.equal(utcDate.getUTCHours());
      gameDurationTime._minute
        .toNumber()
        .should.be.equal(utcDate.getUTCMinutes());
      gameDurationTime.second
        .toNumber()
        .should.be.equal(utcDate.getUTCSeconds());
    });
  });
});
