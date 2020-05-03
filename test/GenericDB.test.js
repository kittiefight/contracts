const GenericDB = artifacts.require('GenericDB');
const Proxy = artifacts.require('KFProxy');
const CronJob = artifacts.require('CronJob');
const BigNumber = require('bignumber.js');
const { ZERO_ADDRESS } = require('./utils/constants');
const CONTRACT_NAME = 'ProfileDB';
const DB_TABLE_NAME = 'TestTable';

require('chai')
  .use(require('chai-shallow-deep-equal'))
  .use(require('chai-bignumber')(BigNumber))
  .use(require('chai-as-promised'))
  .should();


contract('GenericDB', ([creator, unauthorizedAddr, randomAddr]) => {
  let nodeId = 12324353;
  let addrNodeId = '0x0000000000000000000000000000000000000001';

  beforeEach(async () => {
    this.genericDB = await GenericDB.new();
    this.proxy = await Proxy.new();
    this.cronJob = await CronJob.new(this.genericDB.address);
    await this.proxy.addContract('CronJob', this.cronJob.address);

    // Set the primary address as if it is ProfileDB Contract to use GenericDB for testing purpose
    await this.proxy.addContract('ProfileDB', creator);
    await this.genericDB.setProxy(this.proxy.address);
  });

  describe('GenericDB::Authority', () => {
    it('sets proxy', async () => {
      await this.genericDB.setProxy(randomAddr).should.be.fulfilled;
      let proxy = await this.genericDB.proxy();
      proxy.should.be.equal(randomAddr);
    });

    it('does not allow unauthorized address to access proxy setter function', async () => {
      await this.genericDB.setProxy(this.proxy.address, {from: unauthorizedAddr}).should.be.rejected;
    });

    it('does not allow unauthorized address to access attribute setter functions', async () => {
      let key = web3.utils.soliditySha3('data_key');
      let tableKey = web3.utils.soliditySha3(DB_TABLE_NAME);
      await this.genericDB.setIntStorage(CONTRACT_NAME, key, -123, {from: unauthorizedAddr}).should.be.rejected;
      await this.genericDB.setUintStorage(CONTRACT_NAME, key, 123, {from: unauthorizedAddr}).should.be.rejected;
      await this.genericDB.setAddressStorage(CONTRACT_NAME, key, randomAddr, {from: unauthorizedAddr}).should.be.rejected;
      await this.genericDB.setBoolStorage(CONTRACT_NAME, key, true, {from: unauthorizedAddr}).should.be.rejected;
      await this.genericDB.setBytesStorage(CONTRACT_NAME, key, web3.utils.toHex(123), {from: unauthorizedAddr}).should.be.rejected;
      await this.genericDB.setStringStorage(CONTRACT_NAME, key, 'asdad', {from: unauthorizedAddr}).should.be.rejected;
      await this.genericDB.pushNodeToLinkedList(CONTRACT_NAME, tableKey, nodeId, {from: unauthorizedAddr}).should.be.rejected;
      await this.genericDB.pushNodeToLinkedListAddr(CONTRACT_NAME, tableKey, addrNodeId, {from: unauthorizedAddr}).should.be.rejected;
      
      // Create a linked list and an item in the list with authorized address to test the remaining functions
      await this.genericDB.pushNodeToLinkedList(CONTRACT_NAME, tableKey, nodeId).should.be.fulfilled;
      await this.genericDB.removeNodeFromLinkedList(CONTRACT_NAME, tableKey, nodeId, {from: unauthorizedAddr}).should.be.rejected;

      // Create a linked list(address) and an item in the list with authorized address to test the remaining functions
      await this.genericDB.pushNodeToLinkedListAddr(CONTRACT_NAME, tableKey, addrNodeId).should.be.fulfilled;
      await this.genericDB.removeNodeFromLinkedListAddr(CONTRACT_NAME, tableKey, addrNodeId, {from: unauthorizedAddr}).should.be.rejected;
    });
  });

  describe('GenericDB::Setters/Getters', () => {
    it('sets/gets data', async () => {
      let _int = -123;
      let _uint = 456;
      let _address = randomAddr;
      let _bool = true;
      let _bytes = web3.utils.toHex('asdadadasdadadasdadasdasdasdqweqweqfadsfdgdghdgfsjhskfjhskfsjfnsjfsf');
      let _string = 'asdadadasdadadasdadasdasdasdqweqweqfadsfdgdghdgfsjhskfjhskfsjfnsjfsf';

      await this.genericDB.setIntStorage(CONTRACT_NAME, web3.utils.soliditySha3('int_data'), _int).should.be.fulfilled;
      await this.genericDB.setUintStorage(CONTRACT_NAME, web3.utils.soliditySha3('uint_data'), _uint).should.be.fulfilled;
      await this.genericDB.setAddressStorage(CONTRACT_NAME, web3.utils.soliditySha3('address_data'), _address).should.be.fulfilled;
      await this.genericDB.setBoolStorage(CONTRACT_NAME, web3.utils.soliditySha3('bool_data'), _bool).should.be.fulfilled;
      await this.genericDB.setBytesStorage(CONTRACT_NAME, web3.utils.soliditySha3('bytes_data'), _bytes).should.be.fulfilled;
      await this.genericDB.setStringStorage(CONTRACT_NAME, web3.utils.soliditySha3('string_data'), _string).should.be.fulfilled;

      // Get data back for the keys and compare them with the actual values
      let int = await this.genericDB.getIntStorage(CONTRACT_NAME, web3.utils.soliditySha3('int_data'));
      let uint = await this.genericDB.getUintStorage(CONTRACT_NAME, web3.utils.soliditySha3('uint_data'));
      let address = await this.genericDB.getAddressStorage(CONTRACT_NAME, web3.utils.soliditySha3('address_data'));
      let bool = await this.genericDB.getBoolStorage(CONTRACT_NAME, web3.utils.soliditySha3('bool_data'));
      let bytes = await this.genericDB.getBytesStorage(CONTRACT_NAME, web3.utils.soliditySha3('bytes_data'));
      let string = await this.genericDB.getStringStorage(CONTRACT_NAME, web3.utils.soliditySha3('string_data'));

      int.toNumber().should.be.equal(_int);
      uint.toNumber().should.be.equal(_uint);
      address.should.be.equal(_address);
      bool.should.be.equal(_bool);
      bytes.should.be.equal(_bytes);
      string.should.be.equal(_string);
    });

    it('creates and modifies linklist', async () => {
      let tableKey = web3.utils.soliditySha3(DB_TABLE_NAME);

      await this.genericDB.pushNodeToLinkedList(CONTRACT_NAME, tableKey, nodeId).should.be.fulfilled;
      let doesExist = await this.genericDB.doesNodeExist(CONTRACT_NAME, tableKey, nodeId);
      doesExist.should.be.true;

      doesExist = await this.genericDB.doesListExist(CONTRACT_NAME, tableKey);
      doesExist.should.be.true;

      await this.genericDB.removeNodeFromLinkedList(CONTRACT_NAME, tableKey, nodeId).should.be.fulfilled;
      doesExist = await this.genericDB.doesNodeExist(CONTRACT_NAME, tableKey, nodeId);
      doesExist.should.be.false;

      doesExist = await this.genericDB.doesListExist(CONTRACT_NAME, tableKey);
      doesExist.should.be.false;

      await this.genericDB.pushNodeToLinkedListAddr(CONTRACT_NAME, tableKey, addrNodeId).should.be.fulfilled;
      doesExist = await this.genericDB.doesNodeAddrExist(CONTRACT_NAME, tableKey, addrNodeId);
      doesExist.should.be.true;

      doesExist = await this.genericDB.doesListAddrExist(CONTRACT_NAME, tableKey);
      doesExist.should.be.true;

      await this.genericDB.removeNodeFromLinkedListAddr(CONTRACT_NAME, tableKey, addrNodeId).should.be.fulfilled;
      doesExist = await this.genericDB.doesNodeAddrExist(CONTRACT_NAME, tableKey, addrNodeId);
      doesExist.should.be.false;

      doesExist = await this.genericDB.doesListAddrExist(CONTRACT_NAME, tableKey);
      doesExist.should.be.false;
    });

    it('iterates all items in linklist', async () => {
      let tableKey = web3.utils.soliditySha3(DB_TABLE_NAME);
      let nodeIds = [1234, 45667, 34456, 342452, 123178];

      // First create some nodes in DB
      for (let i = 0; i < nodeIds.length; i++) {
        await this.genericDB.pushNodeToLinkedList(CONTRACT_NAME, tableKey, nodeIds[i]).should.be.fulfilled;
      }

      let totalUsers = (await this.genericDB.getLinkedListSize(CONTRACT_NAME, tableKey)).toNumber();
      totalUsers.should.be.equal(nodeIds.length);

      let node = 0; // Start from the HEAD. HEAD is always 0.
      let index = totalUsers - 1;
      do {
        let ret = await this.genericDB.getAdjacent(CONTRACT_NAME, tableKey, node, true);
        // ret value includes direction and node id. Ex => {'0': true, '1': 1234}
        node = ret['1'].toNumber();

        // it means that we reach the end of the list
        if (!node) break;
        // The first item in TRUE direction is the last item pushed => LIFO (stack)
        node.should.be.equal(nodeIds[index]);
        index--;
      } while (node)
    });

    it('gets all items in linklist', async () => {
      let tableKey = web3.utils.soliditySha3(DB_TABLE_NAME);
      let nodeIds = [1234, 45667, 34456, 342452, 123178];

      // First create some nodes in DB
      for (let i = 0; i < nodeIds.length; i++) {
        await this.genericDB.pushNodeToLinkedList(CONTRACT_NAME, tableKey, nodeIds[i]).should.be.fulfilled;
      }

      let totalUsers = (await this.genericDB.getLinkedListSize(CONTRACT_NAME, tableKey)).toNumber();
      totalUsers.should.be.equal(nodeIds.length);

      let allNodes = await this.genericDB.getAll(CONTRACT_NAME, tableKey);

      allNodes.map((node, index) => {
        // The nodes are aquired in first in last out order
        node.toNumber().should.be.equal(nodeIds[nodeIds.length - 1 - index]);
      });
    });

    it('iterates all items in linklistAddr', async () => {
      let tableKey = web3.utils.soliditySha3(DB_TABLE_NAME);
      let addrNodeIds = [
        '0x0000000000000000000000000000000000000001',
        '0x0000000000000000000000000000000000000002',
        '0x0000000000000000000000000000000000000003',
        '0x0000000000000000000000000000000000000004',
        '0x0000000000000000000000000000000000000005'
      ];

      // First create some nodes in DB
      for (let i = 0; i < addrNodeIds.length; i++) {
        await this.genericDB.pushNodeToLinkedListAddr(CONTRACT_NAME, tableKey, addrNodeIds[i]).should.be.fulfilled;
      }

      let totalUsers = (await this.genericDB.getLinkedListAddrSize(CONTRACT_NAME, tableKey)).toNumber();
      totalUsers.should.be.equal(addrNodeIds.length);

      let node = ZERO_ADDRESS; // Start from the HEAD. HEAD is always 0x0.
      let index = totalUsers - 1;
      do {
        let ret = await this.genericDB.getAdjacentAddr(CONTRACT_NAME, tableKey, node, true);
        // ret value includes direction and node id. Ex => {'0': true, '1': 0xa0a214...}
        node = ret['1'];

        // it means that we reach the end of the list
        if (node === ZERO_ADDRESS) break;
        // The first item in TRUE direction is the last item pushed => LIFO (stack)
        node.should.be.equal(addrNodeIds[index]);
        index--;
      } while (node)
    });

    it('gets all items in linklistAddr', async () => {
      let tableKey = web3.utils.soliditySha3(DB_TABLE_NAME);
      let addrNodeIds = [
        '0x0000000000000000000000000000000000000001',
        '0x0000000000000000000000000000000000000002',
        '0x0000000000000000000000000000000000000003',
        '0x0000000000000000000000000000000000000004',
        '0x0000000000000000000000000000000000000005'
      ];

      // First create some nodes in DB
      for (let i = 0; i < addrNodeIds.length; i++) {
        await this.genericDB.pushNodeToLinkedListAddr(CONTRACT_NAME, tableKey, addrNodeIds[i]).should.be.fulfilled;
      }

      let totalUsers = (await this.genericDB.getLinkedListAddrSize(CONTRACT_NAME, tableKey)).toNumber();
      totalUsers.should.be.equal(addrNodeIds.length);

      let allAddrNodes = await this.genericDB.getAllAddr(CONTRACT_NAME, tableKey);

      allAddrNodes.map((node, index) => {
        // The nodes are aquired in first in last out order
        node.should.be.equal(addrNodeIds[addrNodeIds.length - 1 - index]);
      });
    });
  });
});
