const BigNumber = require("bignumber.js");
require("chai")
  .use(require("chai-shallow-deep-equal"))
  .use(require("chai-bignumber")(BigNumber))
  .use(require("chai-as-promised"))
  .should();

const GenericDB = artifacts.require("GenericDB");
const GameVarAndFee = artifacts.require("GameVarAndFee");
const Proxy = artifacts.require("KFProxy");
const RoleDB = artifacts.require("RoleDB");

contract("GameVarAndFee", ([creator, randomAddress]) => {
  let futureGameTime = 12324353;

  beforeEach(async () => {
    //Deploy contracts needed for testing GameVarAndFee
    this.proxy = await Proxy.new();
    this.genericDB = await GenericDB.new();
    this.gameVarAndFee = await GameVarAndFee.new(this.genericDB.address);
    this.roleDB = await RoleDB.new(this.genericDB.address);

    // Add contracts to Contract Manager mapping variable
    await this.proxy.addContract("GameVarAndFee", this.gameVarAndFee.address);
    await this.proxy.addContract("RoleDB", this.roleDB.address);

    // Set Proxy address in contracts
    await this.gameVarAndFee.setProxy(this.proxy.address);
    await this.roleDB.setProxy(this.proxy.address);
    await this.genericDB.setProxy(this.proxy.address);

    //Function only for testing, setting SuperAdmin Role to msg.sender
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

    it("does not allow set vars without using proxy", async () => {
      await this.gameVarAndFee.setVarAndFee("futureGameTime", futureGameTime, {
        from: randomAddress
      }).should.be.rejected;
    });

    it("only super admin can set variables", async () => {
      await this.proxy.setFutureGameTime(futureGameTime, {
        from: randomAddress
      }).should.be.rejected;
    });
  });

  describe("GameVarAndFee::Storage", () => {
    it("sets variable in DB from proxy", async () => {
      await this.proxy.setFutureGameTime(futureGameTime).should.be.fulfilled;
      let getVar = await this.gameVarAndFee.getFutureGameTime();

      getVar.toNumber().should.be.equal(futureGameTime);
    });
  });
});
