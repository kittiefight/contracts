const KittieHELL = artifacts.require('KittieHELL');
const KittieCore = artifacts.require('KittyCore');
const utils = require('./utils/utils.js');
const chai = require('chai');
const chaiAsPromised = require('chai-as-promised');
const assert = chai.assert;
chai.use(chaiAsPromised);


contract('KittieHELL', (accounts) => {

  it('should acquire kitty', async () => {
    const KittieHELLinst = await KittieHELL.deployed();
    const KittieCoreInst = await KittieCore.deployed();
    KittieHELLinst.acquireKitty(0, accounts[0]);
    assert.eventually.equal(KittieCoreInst.ownerOf(0), KittieHELLinst.address);
  });

  it('should not acquire already owned kitty', async () => {
    const KittieHELLinst = await KittieHELL.deployed();
    assert.isRejected(KittieHELLinst.acquireKitty(0, accounts[0]));
  });

  it('is not able to accept Ether', () => {
    utils.isUnableToAccEther(KittieHELL, accounts[1], 1e+18);
  });

});
