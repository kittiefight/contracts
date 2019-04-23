const BigNumber = require("bignumber.js");
require("chai")
  .use(require("chai-shallow-deep-equal"))
  .use(require("chai-bignumber")(BigNumber))
  .use(require("chai-as-promised"))
  .should();

const GenericDB = artifacts.require("GenericDB");
const GameVarAndFee = artifacts.require("GameVarAndFee");
//const GameVarAndFeeDB = artifacts.require("GameVarAndFeeDB");
const Proxy = artifacts.require("Proxy");
const RoleDB = artifacts.require("RoleDB");

contract("GameVarAndFee", ([creator, randomAddress]) => {
  let futureGameTime = 12324353;

  beforeEach(async () => {
    this.proxy = await Proxy.new();
    this.genericDB = await GenericDB.new();
    this.gameVarAndFee = await GameVarAndFee.new(this.genericDB.address);
    //this.gameVarAndFeeDB = await GameVarAndFeeDB.new(this.genericDB.address);
    this.roleDB = await RoleDB.new(this.genericDB.address);

    await this.proxy.addContract("GameVarAndFee", this.gameVarAndFee.address);
    // await this.proxy.addContract(
    //   "GameVarAndFeeDB",
    //   this.gameVarAndFeeDB.address
    // );
    await this.proxy.addContract("RoleDB", this.roleDB.address);

    await this.gameVarAndFee.setProxy(this.proxy.address);
    //await this.gameVarAndFeeDB.setProxy(this.proxy.address);
    await this.roleDB.setProxy(this.proxy.address);
    await this.genericDB.setProxy(this.proxy.address);

    await this.gameVarAndFee.initialize();
  });

  describe("GameVarAndFee::Authority", () => {
    it("sets new proxy", async () => {
      await this.gameVarAndFee.setProxy(creator).should.be.fulfilled;
      let proxy = await this.gameVarAndFee.proxy();
      proxy.should.be.equal(creator);
    });

    it("is correct GenericDB Address", async () => {
      let dbAdd = await this.gameVarAndFee.genericDB();
      dbAdd.should.be.equal(this.genericDB.address);
    });

    it("does not allow set vars outside proxy", async () => {
      await this.gameVarAndFee.setVarAndFee("futureGameTime", futureGameTime, {
        from: randomAddress
      }).should.be.rejected;
    });

    it("only super admin", async () => {
      await this.proxy.setFutureGameTime(futureGameTime, {
        from: randomAddress
      }).should.be.rejected;
    });
  });

  describe("GameVarAndFee::Storage", () => {
    it("sets variable in DB", async () => {
      await this.proxy.setFutureGameTime(futureGameTime).should.be.fulfilled;
      let getVar = await this.gameVarAndFee.getFutureGameTime();

      getVar.toNumber().should.be.equal(futureGameTime);
    });
  });
});
