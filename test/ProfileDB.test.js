const GenericDB = artifacts.require('GenericDB');
const ProfileDB = artifacts.require('ProfileDB');
const Proxy = artifacts.require('Proxy');
const BigNumber = require('bignumber.js');
const CONTRACT_NAME = 'ProfileDB';
const DB_TABLE_NAME = 'ProfileTable';

require('chai')
  .use(require('chai-shallow-deep-equal'))
  .use(require('chai-bignumber')(BigNumber))
  .use(require('chai-as-promised'))
  .should();

  
contract('ProfileDB', ([creator, user1, user2, unauthorizedUser, randomAddress]) => {
  let userId = 12324353;

  beforeEach(async () => {
    this.genericDB = await GenericDB.new();
    this.profileDB = await ProfileDB.new();
    this.proxy = await Proxy.new();

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
      await this.profileDB.setProxy(this.proxy.address, {from: unauthorizedUser}).should.be.rejected;
      await this.profileDB.setGenericDB(this.genericDB.address, {from: unauthorizedUser}).should.be.rejected;
    });

    it('does not allow unauthorized address to access attribute setter functions', async () => {
      await this.profileDB.create(userId, {from: unauthorizedUser}).should.be.rejected;

      // Create a user with authorized address to test authorization for setter functions
      await this.profileDB.create(userId).should.be.fulfilled;
      // Check whether the node with the given user id is added to profile linked list
      (await this.genericDB.doesNodeExist(CONTRACT_NAME, DB_TABLE_NAME, userId)).should.be.true;

      await this.profileDB.setLoginStatus(userId, true, {from: unauthorizedUser}).should.be.rejected;
      await this.profileDB.setAccountAttributes(userId, user1, web3.utils.utf8ToHex('asadad'), web3.utils.utf8ToHex('asdad'), {from: unauthorizedUser}).should.be.rejected;
      await this.profileDB.setGamingAttributes(userId, 1, 2, 3, 4, 5, true, {from: unauthorizedUser}).should.be.rejected;
      await this.profileDB.setFightingAttributes(userId, 1, 2, 3, 4, {from: unauthorizedUser}).should.be.rejected;
      await this.profileDB.setFeeAttributes(userId, 1, 2, 3, false, {from: unauthorizedUser}).should.be.rejected;
      await this.profileDB.setTokenEconomyAttributes(userId, 1, 2, true, {from: unauthorizedUser}).should.be.rejected;
      await this.profileDB.setKittieAttributes(userId, 1, 2, 3, 'test', 'dead', {from: unauthorizedUser}).should.be.rejected;
    });
  });

  describe('ProfileDB::Attributes', () => {
    it('creates a profile', async () => {
      await this.profileDB.create(userId).should.be.fulfilled;
      // Check whether the node with the given user id is added to profile linked list
      (await this.genericDB.doesNodeExist(CONTRACT_NAME, DB_TABLE_NAME, userId)).should.be.true;
    });

    it('sets/gets account attributes', async () => {
      let genes = web3.utils.utf8ToHex('0x0101110110100101101011010');
      let description = web3.utils.utf8ToHex('%$*_&random description which does not make sense at all...');
      // First create a user in DB
      await this.profileDB.create(userId).should.be.fulfilled;
      // Set account attributes
      await this.profileDB.setAccountAttributes(
        userId,
        user1,
        genes,
        description
      ).should.be.fulfilled;
      // Get attributes back for the given user and compare them with the actual values
      let attrOwner = await this.genericDB.getAddressStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'ownerAddress'));
      let attrGenes = await this.genericDB.getBytesStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'genes'));
      let attrDescription = await this.genericDB.getBytesStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'description'));
      attrOwner.should.be.equal(user1);
      attrGenes.should.be.equal(genes);
      attrDescription.should.be.equal(description);
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

    it('sets/gets token economy attributes', async () => {
      let kittieFightTokens = 1000;
      let superDAOTokens = 5000;
      let isStakingSuperDAO = true;
      // First create a user in DB
      await this.profileDB.create(userId).should.be.fulfilled;
      // Set token economy attributes
      await this.profileDB.setTokenEconomyAttributes(
        userId,
        kittieFightTokens,
        superDAOTokens,
        isStakingSuperDAO
      ).should.be.fulfilled;
      
      let attrKittieFightTokens = await this.genericDB.getUintStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'kittieFightTokens'));
      let attrSuperDAOTokens = await this.genericDB.getUintStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'superDAOTokens'));
      let attrIsStakingSuperDAO = await this.genericDB.getBoolStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'isStakingSuperDAO'));

      attrKittieFightTokens.toNumber().should.be.equal(kittieFightTokens);
      attrSuperDAOTokens.toNumber().should.be.equal(superDAOTokens);
      attrIsStakingSuperDAO.should.be.equal(isStakingSuperDAO);
    });

    it('sets/gets kittie attributes', async () => {
      let kittieId = 1000;
      let kittieHash = 5000;
      let deadAt = 1134567945;
      let kittieReferalHash = 'asdasdkjifhfamdbv';
      let kittieStatus = 'dead';
      // First create a user in DB
      await this.profileDB.create(userId).should.be.fulfilled;
      // Set kittie attributes
      await this.profileDB.setKittieAttributes(
        userId,
        kittieId,
        kittieHash,
        deadAt,
        kittieReferalHash,
        kittieStatus
      ).should.be.fulfilled;
      
      let attrKittieId = await this.genericDB.getUintStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'kittieId'));
      let attrKittieHash = await this.genericDB.getUintStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'kittieHash'));
      let attrDeadAt = await this.genericDB.getUintStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'deadAt'));
      let attrKittieReferalHash = await this.genericDB.getStringStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'kittieReferalHash'));
      let attrKittieStatus = await this.genericDB.getStringStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'kittieStatus'));

      attrKittieId.toNumber().should.be.equal(kittieId);
      attrKittieHash.toNumber().should.be.equal(kittieHash);
      attrDeadAt.toNumber().should.be.equal(deadAt);
      attrKittieReferalHash.should.be.equal(kittieReferalHash);
      attrKittieStatus.should.be.equal(kittieStatus);
    });

    it('sets/gets login status', async () => {
      let isLoggedIn = true;
      // First create a user in DB
      await this.profileDB.create(userId).should.be.fulfilled;
      // Set kittie attributes
      await this.profileDB.setLoginStatus(userId, isLoggedIn).should.be.fulfilled;
      // Get login status back
      let attrIsLoggedIn = await this.genericDB.getBoolStorage(CONTRACT_NAME, web3.utils.soliditySha3(userId, 'isLoggedIn'));

      attrIsLoggedIn.should.be.equal(isLoggedIn);
    });

    it('can iterate all profiles', async () => {
      let userIds = [1234, 45667, 34456, 342452, 123178];

      // First create some profiles in DB
      for (let i = 0; i < userIds.length; i++) {
        await this.profileDB.create(userIds[i]).should.be.fulfilled;
      }

      let totalUsers = (await this.genericDB.getLinkedListSize(CONTRACT_NAME, DB_TABLE_NAME)).toNumber();
      totalUsers.should.be.equal(userIds.length);

      let profile = 0; // Start from the HEAD. HEAD is always 0.
      let index = totalUsers - 1;
      do {
        let ret = await this.genericDB.getAdjacent(CONTRACT_NAME, DB_TABLE_NAME, profile, true);
        // ret value includes direction and node id. Ex => {'0': true, '1': 1234}
        profile = ret['1'].toNumber();

        // Means that we reach the end of the list
        if (!profile) break;
        // The first item in TRUE direction is the last item pushed => LIFO (stack)
        profile.should.be.equal(userIds[index]);
        index--;
      } while (profile)
    });
  });

  describe('ProfileDB::Attributes::Negatives', () => {
    it('does not allow to create duplicate profiles', async () => {
      await this.profileDB.create(userId).should.be.fulfilled;
      // Check whether the node with the given user id is added to profile linked list
      (await this.genericDB.doesNodeExist(CONTRACT_NAME, DB_TABLE_NAME, userId)).should.be.true;

      await this.profileDB.create(userId).should.be.rejected;
    });

    it('does not allow to set an attribute for a non-existent profile', async () => {
      await this.profileDB.setLoginStatus(userId, true).should.be.rejected;
    });
  });
});
