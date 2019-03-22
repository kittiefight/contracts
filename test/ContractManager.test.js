const ContractManager = artifacts.require('ContractManager');
const utils = require('./utils/utils.js');
const chai = require('chai');
const chaiAsPromised = require('chai-as-promised');
const assert = chai.assert;
//chai.use(chaiAsPromised);

require('chai')
  .use(require('chai-shallow-deep-equal'))
  .use(require('chai-bignumber')(BigNumber))
  .use(require('chai-as-promised'))
  .should();



contract('ContractManager', (accounts) => {

    before('Setup contract test', async () => {
        this.ContractManager = await ContractManager.new();
    });
    
    it('Just Facke test', async () => {
        "test".should.be.equal("test")
    });

});
