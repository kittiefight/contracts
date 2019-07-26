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

const CONTRACT_NAME_GAMEVARANDFEE = 'GameVarAndFee';
const kovanMedianizer = '0xA944bd4b25C9F186A846fd5668941AA3d3B8425F'

contract("GameVarAndFee", ([creator, randomAddress, newProxy]) => {
  let requiredNumberMatches = 10;

  beforeEach(async () => {
    //Deploy contracts needed for testing GameVarAndFee
    this.proxy = await Proxy.new();
    this.genericDB = await GenericDB.new();
    this.gameVarAndFee = await GameVarAndFee.new(this.genericDB.address, kovanMedianizer);
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
      await this.gameVarAndFee.setProxy(newProxy).should.be.fulfilled;
      let proxy = await this.gameVarAndFee.proxy();
      proxy.should.be.equal(newProxy);
    });

    it("is correct GenericDB Address", async () => {
      let dbAdd = await this.gameVarAndFee.genericDB();
      dbAdd.should.be.equal(this.genericDB.address);
    });

    it("does not allow set vars without using proxy", async () => {
      await this.gameVarAndFee.setVarAndFee(requiredNumberMatches, {
        from: randomAddress
      }).should.be.rejected;

    });

    it("only super admin can set a var or fee", async () => {
      let message = web3.eth.abi.encodeFunctionCall(
        GameVarAndFee.abi.find((f) => { return f.name == 'setVarAndFee'; }),
        ['requiredNumberMatches', requiredNumberMatches]
      );
      await this.proxy.execute(CONTRACT_NAME_GAMEVARANDFEE, message, {
        from: randomAddress
      }).should.be.rejected;
    });

    it("correctly sets variable in DB using proxy", async () => {
      let message = web3.eth.abi.encodeFunctionCall(
        GameVarAndFee.abi.find((f) => { return f.name == 'setVarAndFee'; }),
        ['requiredNumberMatches', requiredNumberMatches]
      );
      await this.proxy.execute(CONTRACT_NAME_GAMEVARANDFEE, message, {
        from: creator
      }).should.be.fulfilled;

      let getVar = await this.gameVarAndFee.getRequiredNumberMatches();

      getVar.toNumber().should.be.equal(requiredNumberMatches);
    });

    it("correctly sets multiple variable in DB using proxy", async () => {
      let message = web3.eth.abi.encodeFunctionCall(
        GameVarAndFee.abi.find((f) => { return f.name == 'setMultipleValues'; }),
        [['gamePrestart', 'requiredNumberMatches'], [120, 20]]
      );
      await this.proxy.execute(CONTRACT_NAME_GAMEVARANDFEE, message, {
        from: creator
      }).should.be.fulfilled;

      let getVar = await this.gameVarAndFee.getGamePrestart();

      getVar.toNumber().should.be.equal(120);
    });
  });
});
