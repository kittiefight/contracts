const ContractManager = artifacts.require('ContractManager');
const FailSafe = artifacts.require('FailSafe');
const utils = require('./utils/utils.js');
const chai = require('chai');
const chaiAsPromised = require('chai-as-promised');
const assert = chai.assert;

require('chai')
  .use(require('chai-shallow-deep-equal'))
  .use(require('chai-as-promised'))
  .should();

const EVMThrow = 'VM Exception'


contract('ContractManager', (accounts) => {
    
    const [ owner, notOwner, otherAccount ] = accounts;

    before('Setup contract test', async () => {
        this.ContractManager = await ContractManager.new();
        this.FailSafeContract = await FailSafe.new(); // Need for test contract address
        this.UpdatedFailSafeContract = await FailSafe.new(); // Need for update test
    });
    
   
    it('Should add Contract', async() => {
       await this.ContractManager.addContract("FailSafe", this.FailSafeContract.address);
       (await this.ContractManager.getContract("FailSafe")).should.be.equal(this.FailSafeContract.address);
    });

    it('Should raise VM exeption on wrong contract name', async() => {
        await this.ContractManager.getContract("wrongname").should.be.rejectedWith(EVMThrow)
        await this.ContractManager.getContract("failsafe").should.be.rejectedWith(EVMThrow)
    })

    it('Should update Contract', async() => {
        await this.ContractManager.updateContract("FailSafe", this.UpdatedFailSafeContract.address);
        (await this.ContractManager.getContract("FailSafe")).should.be.equal(this.UpdatedFailSafeContract.address);
        (await this.ContractManager.getContract("FailSafe")).should.not.equal(this.FailSafeContract.address);
    });

    it('Should remove Contract', async() => {
        await this.ContractManager.removeContract("FailSafe");
        await this.ContractManager.getContract("FailSafe").should.be.rejectedWith(EVMThrow)
    });

    it('Not Owner Should Not add Contract', async() => {
        await this.ContractManager.addContract("FailSafe", 
            this.FailSafeContract.address, { from : notOwner }).should.be.rejectedWith(EVMThrow);  
    });

});
