const BigNumber = require('bignumber.js');
require('chai')
  .use(require('chai-shallow-deep-equal'))
  .use(require('chai-bignumber')(BigNumber))
  .use(require('chai-as-promised'))
  .should();
const { ZERO_ADDRESS } = require('./utils/constants');
const Proxy = artifacts.require('KFProxy');
const ProxiedTest = artifacts.require('ProxiedTest');
const PROXIED_TEST_CONTRACT_NAME = 'ProxiedTest';
 
contract('KFProxy', ([owner, addr1, unauthorizedAddr, randomAddr]) => {

  beforeEach(async () => {
    this.proxy = await Proxy.new();
    this.proxiedTest = await ProxiedTest.new();

    // Add owner as if it is a client contract to be able to make calls to RoleDB contract for test purpose
    await this.proxy.addContract(PROXIED_TEST_CONTRACT_NAME, this.proxiedTest.address);
    await this.proxiedTest.setProxy(this.proxy.address);
  });

  describe('ProxiedTest::access', () => {
    it('should reject direct calls', async () => {
      let randomPayload = web3.utils.randomHex(10);
      await this.proxiedTest.testFunction(randomPayload).should.be.rejected;
    });
  });
  describe('KFProxy::Proxying', () => {
    it('forwards a call to target', async () => {
      let randomPayload = web3.utils.randomHex(10);
      let message = web3.eth.abi.encodeFunctionCall(
        ProxiedTest.abi.find((f)=>{return f.name == 'testFunction';}),
        [randomPayload]
      );
      let result = await this.proxy.execute(PROXIED_TEST_CONTRACT_NAME, message);
      let resultPayload = await this.proxiedTest.lastPayload();
      assert.equal(randomPayload, resultPayload, 'Payload not matched');
    });

    it('forwards msg.sender to target', async () => {
      let randomPayload = web3.utils.randomHex(10);
      let message = web3.eth.abi.encodeFunctionCall(
        ProxiedTest.abi.find((f)=>{return f.name == 'testFunction';}),
        [randomPayload]
      );
      let result = await this.proxy.execute(PROXIED_TEST_CONTRACT_NAME, message);
      
      let proxiedEvents = await this.proxiedTest.getPastEvents("allEvents", {fromBlock: 0, toBlock: "latest"});
      let recordedSender = proxiedEvents[0].args.sender;
      assert.equal(recordedSender, owner, 'Sender received by target contract does not match to original sender');

      let resultPayload = await this.proxiedTest.lastPayload();
      assert.equal(randomPayload, resultPayload, 'Payload not matched');
    });

    it('forwards ether to target', async () => {
      let randomPayload = web3.utils.randomHex(10);
      let message = web3.eth.abi.encodeFunctionCall(
        ProxiedTest.abi.find((f)=>{return f.name == 'testFunction';}),
        [randomPayload]
      );
      let randomAmount = web3.utils.toWei(String(Math.round(Math.random()*100)), 'kwei');
      let result = await this.proxy.execute(PROXIED_TEST_CONTRACT_NAME, message, {'value': randomAmount});

      let resultPayload = await this.proxiedTest.lastPayload();
      assert.equal(randomPayload, resultPayload, 'Payload not matched');

      let proxyBalance = await web3.eth.getBalance(this.proxy.address);
      assert.equal('0', proxyBalance, 'Proxy balance should be zero');
      let proxiedBalance = await web3.eth.getBalance(this.proxiedTest.address);
      assert.equal(randomAmount, proxiedBalance, 'Ether value on Proxied contract does not match');
    });
  });

});
