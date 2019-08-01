const BigNumber = require('bignumber.js');
require('chai')
  .use(require('chai-shallow-deep-equal'))
  .use(require('chai-bignumber')(BigNumber))
  .use(require('chai-as-promised'))
  .should();

const GenericDB = artifacts.require('GenericDB');
const ProfileDB = artifacts.require('ProfileDB');
const Proxy = artifacts.require('KFProxy');
const CronJob = artifacts.require('CronJob');

const CONTRACT_NAME = 'ProfileDB';
const TABLE_NAME_PROFILE = 'ProfileTable';
const TABLE_NAME_KITTIE = 'KittieTable';


contract('ProfileDB', ([creator, user1, user2, unauthorizedUser, randomAddress]) => {
  let userId = user1;

  beforeEach(async () => {
    this.genericDB = await GenericDB.new();
    this.profileDB = await ProfileDB.new(this.genericDB.address);
    this.proxy = await Proxy.new();
    this.cronJob = await CronJob.new(this.genericDB.address);
    await this.proxy.addContract('CronJob', this.cronJob.address);

    await this.proxy.addContract('ProfileDB', this.profileDB.address);
    // Set the primary address as if it is Register Contract to call ProfileDB for testing purpose
    await this.proxy.addContract('Register', creator);
    await this.genericDB.setProxy(this.proxy.address);
    await this.profileDB.setProxy(this.proxy.address);
    await this.profileDB.setGenericDB(this.genericDB.address);
  });

  describe('ProfileDB::Authority', () => {
    it('sets proxy and db', async () => {
      await this.profileDB.setProxy(randomAddress).should.be.fulfilled;
      await this.profileDB.setGenericDB(randomAddress).should.be.fulfilled;

      let proxy = await this.profileDB.proxy();
      let genericDB = await this.profileDB.genericDB();

      proxy.should.be.equal(randomAddress);
      genericDB.should.be.equal(randomAddress);
    });

    it('does not allow unauthorized address to access proxy/db setter functions', async () => {
      await this.profileDB.setProxy(this.proxy.address, { from: unauthorizedUser }).should.be.rejected;
      await this.profileDB.setGenericDB(this.genericDB.address, { from: unauthorizedUser }).should.be.rejected;
    });

    it('does not allow unauthorized address to access attribute setter functions', async () => {
      let tableKey = web3.utils.soliditySha3(TABLE_NAME_PROFILE);

<<<<<<< HEAD
      await this.profileDB.create(userId, { from: unauthorizedUser }).should.be.rejected;
=======
      await this.profileDB.create(userId, { from: unauthorizedUser }).should.be.rejected;
>>>>>>> feature/gameManager

      // Create a user with authorized address to test authorization for setter functions
      await this.profileDB.create(userId).should.be.fulfilled;
      // Check whether the node with the given user id is added to profile linked list
      (await this.genericDB.doesNodeAddrExist(CONTRACT_NAME, tableKey, userId)).should.be.true;

      await this.profileDB.setGamingAttributes(userId, 1, 2, 3, 4, 5, true, { from: unauthorizedUser }).should.be.rejected;
      await this.profileDB.setFightingAttributes(userId, 1, 2, 3, 4, { from: unauthorizedUser }).should.be.rejected;
      await this.profileDB.setFeeAttributes(userId, 1, 2, 3, false, { from: unauthorizedUser }).should.be.rejected;
      await this.profileDB.setSuperDAOTokens(userId, 2, true, { from: unauthorizedUser }).should.be.rejected;
      await this.profileDB.setKittieFightTokens(userId, 1, { from: unauthorizedUser }).should.be.rejected;
      await this.profileDB.addKittie(userId, 1, 2, 'dead', { from: unauthorizedUser }).should.be.rejected;

      // First add a kittie to test update and remove functions
      await this.profileDB.addKittie(userId, 1, 2, 'dead').should.be.fulfilled;
<<<<<<< HEAD
      await this.profileDB.removeKittie(userId, 1, { from: unauthorizedUser }).should.be.rejected;
      await this.profileDB.setKittieAttributes(userId, 1, 2, 'dead', { from: unauthorizedUser }).should.be.rejected;
=======
      await this.profileDB.removeKittie(userId, 1, { from: unauthorizedUser }).should.be.rejected;
      await this.profileDB.setKittieAttributes(userId, 1, 2, 'dead', { from: unauthorizedUser }).should.be.rejected;
>>>>>>> feature/gameManager
    });
  });

  describe('ProfileDB::Attributes', () => {
    it('creates a profile', async () => {
<<<<<<< HEAD
=======
      let tableKey = web3.utils.soliditySha3(TABLE_NAME_PROFILE);

      await this.profileDB.create(userId).should.be.fulfilled;
      // Check whether the node with the given user id is added to profile linked list
      (await this.genericDB.doesNodeAddrExist(CONTRACT_NAME, tableKey, userId)).should.be.true;
    });

    it('sets a civic id', async () => {
>>>>>>> feature/gameManager
      let tableKey = web3.utils.soliditySha3(TABLE_NAME_PROFILE);
      let _civicId = 12345;

      await this.profileDB.create(userId).should.be.fulfilled;
      // Check whether the node with the given user id is added to profile linked list
      (await this.genericDB.doesNodeAddrExist(CONTRACT_NAME, tableKey, userId)).should.be.true;
<<<<<<< HEAD
=======

      await this.profileDB.setCivicId(userId, _civicId).should.be.fulfilled;
      let civicId = await this.profileDB.getCivicId(userId);
      civicId.toNumber().should.be.equal(_civicId);
>>>>>>> feature/gameManager
    });

    it('sets/gets gaming attributes', async () => {
      let totalWins = 20;
      let totalLosses = 34;
      let tokensWon = 12000;
      let lastFeeDate = 1233242;
      let feeHistory = 1236742;
      let isFreeToPlay = true;
      // First create a user in DB
      await this.profileDB.create(userId).should.be.fulfilled;
      // Set gaming attributes
      await this.profileDB.setGamingAttributes(
        userId,
        totalWins,
        totalLosses,
        tokensWon,
        lastFeeDate,
        feeHistory,
        isFreeToPlay
      ).should.be.fulfilled;

      let attrWin = await this.genericDB.getUintStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'totalWins'));
      let attrLoss = await this.genericDB.getUintStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'totalLosses'));
      let attrTokens = await this.genericDB.getUintStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'tokensWon'));
      let attrFeeDate = await this.genericDB.getUintStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'lastFeeDate'));
      let attrFeeHistory = await this.genericDB.getUintStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'feeHistory'));
      let attrIsFree = await this.genericDB.getBoolStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'isFreeToPlay'));

      attrWin.toNumber().should.be.equal(totalWins);
      attrLoss.toNumber().should.be.equal(totalLosses);
      attrTokens.toNumber().should.be.equal(tokensWon);
      attrFeeDate.toNumber().should.be.equal(lastFeeDate);
      attrFeeHistory.toNumber().should.be.equal(feeHistory);
      attrIsFree.should.be.equal(isFreeToPlay);
    });

    it('sets/gets fighting attributes', async () => {
      let totalFights = 101;
      let nextFight = 12348678;
      let listingStart = 675413;
      let listingEnd = 7562424;
      // First create a user in DB
      await this.profileDB.create(userId).should.be.fulfilled;
      // Set fighting attributes
      await this.profileDB.setFightingAttributes(
        userId,
        totalFights,
        nextFight,
        listingStart,
        listingEnd
      ).should.be.fulfilled;

      let attrTotalFights = await this.genericDB.getUintStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'totalFights'));
      let attrNextFight = await this.genericDB.getUintStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'nextFight'));
      let attrListingStart = await this.genericDB.getUintStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'listingStart'));
      let attrListingEnd = await this.genericDB.getUintStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'listingEnd'));

      attrTotalFights.toNumber().should.be.equal(totalFights);
      attrNextFight.toNumber().should.be.equal(nextFight);
      attrListingStart.toNumber().should.be.equal(listingStart);
      attrListingEnd.toNumber().should.be.equal(listingEnd);
    });

    it('sets/gets fee attributes', async () => {
      let feeType = 1;
      let paidDate = 12348678;
      let expirationDate = 11236777;
      let isPaid = false;
      // First create a user in DB
      await this.profileDB.create(userId).should.be.fulfilled;
      // Set fee attributes
      await this.profileDB.setFeeAttributes(
        userId,
        feeType,
        paidDate,
        expirationDate,
        isPaid
      ).should.be.fulfilled;

      let attrFeeType = await this.genericDB.getUintStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'feeType'));
      let attrPaidDate = await this.genericDB.getUintStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'paidDate'));
      let attrExpirationDate = await this.genericDB.getUintStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'expirationDate'));
      let attrIsPaid = await this.genericDB.getBoolStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'isPaid'));

      attrFeeType.toNumber().should.be.equal(feeType);
      attrPaidDate.toNumber().should.be.equal(paidDate);
      attrExpirationDate.toNumber().should.be.equal(expirationDate);
      attrIsPaid.should.be.equal(isPaid);
    });

    it('sets/gets DAO tokens', async () => {
      let superDAOTokens = 5000;
      let isStakingSuperDAO = true;
      // First create a user in DB
      await this.profileDB.create(userId).should.be.fulfilled;
      // Set token economy attributes
      await this.profileDB.setSuperDAOTokens(
        userId,
        superDAOTokens,
        isStakingSuperDAO
      ).should.be.fulfilled;
<<<<<<< HEAD

=======

>>>>>>> feature/gameManager
      let attrSuperDAOTokens = await this.genericDB.getUintStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'superDAOTokens'));
      let attrIsStakingSuperDAO = await this.genericDB.getBoolStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'isStakingSuperDAO'));

      attrSuperDAOTokens.toNumber().should.be.equal(superDAOTokens);
      attrIsStakingSuperDAO.should.be.equal(isStakingSuperDAO);
    });

    it('sets/gets Kittie Fight tokens', async () => {
      let kittieFightTokens = 1000;
      // First create a user in DB
      await this.profileDB.create(userId).should.be.fulfilled;
      // Set token economy attributes
      await this.profileDB.setKittieFightTokens(
        userId,
        kittieFightTokens
      ).should.be.fulfilled;

      let attrKittieFightTokens = await this.genericDB.getUintStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'kittieFightTokens'));
      attrKittieFightTokens.toNumber().should.be.equal(kittieFightTokens);
    });

    it('adds/updates/removes kittie and attributes', async () => {
      let kittieId = 1000;
      let deadAt = 1134567945;
      let kittieStatus = 'dead';
      // First create a user in DB
      await this.profileDB.create(userId).should.be.fulfilled;

      // Add a kittie under this account
      await this.profileDB.addKittie(userId, kittieId, deadAt, kittieStatus).should.be.fulfilled;
      // Check if the kittie is added and its attributes\
      let doesExist = await this.genericDB.doesNodeExist(CONTRACT_NAME, web3.utils.soliditySha3(userId, TABLE_NAME_KITTIE), kittieId);
      let attrDeadAt = await this.genericDB.getUintStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, kittieId, 'deadAt'));
      let attrKittieStatus = await this.genericDB.getStringStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, kittieId, 'kittieStatus'));
      doesExist.should.be.true;
      attrDeadAt.toNumber().should.be.equal(deadAt);
      attrKittieStatus.should.be.equal(kittieStatus);

      // Set kittie attributes
      await this.profileDB.setKittieAttributes(userId, kittieId, deadAt = 1134567995, kittieStatus = 'alive').should.be.fulfilled;
      // Check the attributes
      attrDeadAt = await this.genericDB.getUintStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, kittieId, 'deadAt'));
      attrKittieStatus = await this.genericDB.getStringStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, kittieId, 'kittieStatus'));
      attrDeadAt.toNumber().should.be.equal(deadAt);
      attrKittieStatus.should.be.equal(kittieStatus);

      // Remove kittie
      await this.profileDB.removeKittie(userId, kittieId).should.be.fulfilled;
      // Check if the kittie is removed and the number of kitties decremented by one
      doesExist = await this.genericDB.doesNodeExist(CONTRACT_NAME, web3.utils.soliditySha3(userId, TABLE_NAME_KITTIE), kittieId);
      doesExist.should.be.false;
    });
  });

  describe('ProfileDB::Attributes::Negatives', () => {
    it('does not allow to create duplicate profiles', async () => {
      let tableKey = web3.utils.soliditySha3(TABLE_NAME_PROFILE);

      await this.profileDB.create(userId).should.be.fulfilled;
      // Check whether the node with the given user id is added to profile linked list
      (await this.genericDB.doesNodeAddrExist(CONTRACT_NAME, tableKey, userId)).should.be.true;

      await this.profileDB.create(userId).should.be.rejected;
    });

    it('does not allow to set an existent civic id with a different account', async () => {
      let tableKey = web3.utils.soliditySha3(TABLE_NAME_PROFILE);
      let _civicId = 12345;

      await this.profileDB.create(user1).should.be.fulfilled;
      await this.profileDB.create(user2).should.be.fulfilled;
      // Check whether the node with the given user id is added to profile linked list
      (await this.genericDB.doesNodeAddrExist(CONTRACT_NAME, tableKey, user1)).should.be.true;
      (await this.genericDB.doesNodeAddrExist(CONTRACT_NAME, tableKey, user2)).should.be.true;

      await this.profileDB.setCivicId(user1, _civicId).should.be.fulfilled;
      await this.profileDB.setCivicId(user2, _civicId).should.be.rejected;
    });
  });
});
