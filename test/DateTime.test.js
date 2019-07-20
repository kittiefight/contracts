const BigNumber = require("bignumber.js");
require("chai")
  .use(require("chai-shallow-deep-equal"))
  .use(require("chai-bignumber")(BigNumber))
  .use(require("chai-as-promised"))
  .should();

const DateTime = artifacts.require("DateTime");

contract("DateTime", ([creator, randomAddress]) => {
  beforeEach(async () => {
    this.dateTime = await DateTime.new();
  });

  describe("DateTime", () => {

    it("calculates correct game duration time", async () => {

      let currentTime = await this.dateTime.getBlockchainTime();

      block = await web3.eth.getBlock();
      blockDate = Date(block.timestamp * 1000);
      var utcDate = new Date(blockDate);

      currentTime._hour.toString().should.be.equal(String(utcDate.getUTCHours()));

    });
  });
});
