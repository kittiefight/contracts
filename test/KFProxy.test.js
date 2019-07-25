const BigNumber = require('bignumber.js');
require('chai')
  .use(require('chai-shallow-deep-equal'))
  .use(require('chai-bignumber')(BigNumber))
  .use(require('chai-as-promised'))
  .should();
const { ZERO_ADDRESS } = require('./utils/constants');
const Proxy = artifacts.require('KFProxy');
const GenericDB = artifacts.require('GenericDB');
const CronJob = artifacts.require('CronJob');
const FreezeInfo = artifacts.require('FreezeInfo');
const ProxiedTest = artifacts.require('ProxiedTest');
const PROXIED_TEST_CONTRACT_NAME = 'ProxiedTest';
 
contract('KFProxy', ([owner, addr1, unauthorizedAddr, randomAddr]) => {
  //console.log('Expected sender', owner);

  beforeEach(async () => {
    this.proxy = await Proxy.new();
    this.freezeInfo = await FreezeInfo.new();
    this.genericDB = await GenericDB.new();
    this.cronJob = await CronJob.new(this.genericDB.address);
    this.proxiedTest = await ProxiedTest.new();
    await this.proxy.addContract('GenericDB', this.genericDB.address);
    await this.proxy.addContract('FreezeInfo', this.freezeInfo.address);
    await this.proxy.addContract('CronJob', this.cronJob.address);

    await this.proxy.addContract(PROXIED_TEST_CONTRACT_NAME, this.proxiedTest.address);
    await this.proxiedTest.setProxy(this.proxy.address);
  });

  describe('ProxiedTest::access', () => {
    it('should reject direct calls', async () => {
      let randomPayload = web3.utils.randomHex(10);
      await this.proxiedTest.testFunctionBytes(randomPayload).should.be.rejected;
    });
  });
  
  describe('KFProxy::Proxying', () => {
    it('forwards a call to target', async () => {
      let randomPayload = web3.utils.randomHex(60);
      let message = web3.eth.abi.encodeFunctionCall(
        ProxiedTest.abi.find((f)=>{return f.name == 'testFunctionBytes';}),
        [randomPayload]
      );
      let result = await this.proxy.execute(PROXIED_TEST_CONTRACT_NAME, message);
      //console.log('TX result', result);
      let resultPayload = await this.proxiedTest.lastPayload();
      assert.equal(randomPayload, resultPayload, 'Payload not matched');
    });

    it('forwards a call with two args to target', async () => {
      let randomArg1 = web3.utils.toWei(String(Math.random()*100), 'ether');
      let randomArg2 = randomAddr;
      let message = web3.eth.abi.encodeFunctionCall(
        ProxiedTest.abi.find((f)=>{return f.name == 'testFunctionTwoArgs';}),
        [randomArg1, randomArg2]
      );
      let result = await this.proxy.execute(PROXIED_TEST_CONTRACT_NAME, message);
      let resultArg1 = await this.proxiedTest.lastArg1();
      let resultArg2 = await this.proxiedTest.lastArg2();
      assert.equal(randomArg1, resultArg1, 'Payload not matched: arg1');
      assert.equal(randomArg2, resultArg2, 'Payload not matched: arg2');

      let proxiedEvents = await this.proxiedTest.getPastEvents("allEvents", {fromBlock: 0, toBlock: "latest"});
      let recordedSender = proxiedEvents[0].args.sender;
      assert.equal(recordedSender, owner, 'Sender received by target contract does not match to original sender');
    });

    it('forwards msg.sender to target', async () => {
      let randomPayload = web3.utils.randomHex(10);
      let message = web3.eth.abi.encodeFunctionCall(
        ProxiedTest.abi.find((f)=>{return f.name == 'testFunctionBytes';}),
        [randomPayload]
      );
      let result = await this.proxy.execute(PROXIED_TEST_CONTRACT_NAME, message);
      
      let proxiedEvents = await this.proxiedTest.getPastEvents("allEvents", {fromBlock: 0, toBlock: "latest"});
      assert.notEqual(typeof proxiedEvents[0], 'undefined', 'No event log found');
      let recordedSender = proxiedEvents[0].args.sender;
      assert.equal(recordedSender, owner, 'Sender received by target contract does not match to original sender');

      let resultPayload = await this.proxiedTest.lastPayload();
      assert.equal(randomPayload, resultPayload, 'Payload not matched');
    });

    it('forwards ether to target', async () => {
      let randomPayload = web3.utils.randomHex(10);
      let message = web3.eth.abi.encodeFunctionCall(
        ProxiedTest.abi.find((f)=>{return f.name == 'testFunctionBytes';}),
        [randomPayload]
      );
      let randomAmount = web3.utils.toWei(String(Math.round(Math.random()*100)), 'kwei');
      let result = await this.proxy.execute(PROXIED_TEST_CONTRACT_NAME, message, {'value': randomAmount});

      let proxyBalance = await web3.eth.getBalance(this.proxy.address);
      assert.equal('0', proxyBalance, 'Proxy balance should be zero');
      let proxiedBalance = await web3.eth.getBalance(this.proxiedTest.address);
      assert.equal(randomAmount, proxiedBalance, 'Ether value on Proxied contract does not match');

      let resultPayload = await this.proxiedTest.lastPayload();
      assert.equal(randomPayload, resultPayload, 'Payload not matched');

    });

    it('forwards error message from reverted call', async () => {
      let message = web3.eth.abi.encodeFunctionCall(
        ProxiedTest.abi.find((f)=>{return f.name == 'testRevertMessage';}),
        []
      );
      try {
        let result = await this.proxy.execute(PROXIED_TEST_CONTRACT_NAME, message);
        throw null;
      }catch(error){
        assert.include(error.message, 'Test revert message', 'Revert message does not match');
      }

    });
   
  });

});
