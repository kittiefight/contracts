const BigNumber = require('bignumber.js');
require('chai')
  .use(require('chai-shallow-deep-equal'))
  .use(require('chai-bignumber')(BigNumber))
  .use(require('chai-as-promised'))
  .should();

const CronJob = artifacts.require('CronJob');
const GenericDB = artifacts.require('GenericDB');
const ProfileDB = artifacts.require('ProfileDB');
const RoleDB = artifacts.require('RoleDB');
const Register = artifacts.require('Register');
const Proxy = artifacts.require('KFProxy');
const SuperDaoToken = artifacts.require('MockERC20Token');
const KittieFightToken = artifacts.require('MockERC20Token');
const CryptoKitties = artifacts.require('MockERC721Token');

const ERC20_TOKEN_SUPPLY = new BigNumber(1000000);

  
contract('Register', ([creator, user1, user2, unauthorizedUser, randomAddress]) => {
  beforeEach(async () => {
    this.genericDB = await GenericDB.new();
    this.profileDB = await ProfileDB.new(this.genericDB.address);
    this.roleDB = await RoleDB.new(this.genericDB.address);
    this.proxy = await Proxy.new();
    this.cronJob = await CronJob.new(this.genericDB.address);
    this.register = await Register.new();
    this.superDaoToken = await SuperDaoToken.new(ERC20_TOKEN_SUPPLY);
    this.kittieFightToken = await KittieFightToken.new(ERC20_TOKEN_SUPPLY);
    this.cryptoKitties = await CryptoKitties.new();

    // Add the system contracts to the proxy
    await this.proxy.addContract('CronJob', this.cronJob.address);
    await this.proxy.addContract('CryptoKitties', this.cryptoKitties.address);
    await this.proxy.addContract('SuperDAOToken', this.superDaoToken.address);
    await this.proxy.addContract('KittieFightToken', this.kittieFightToken.address);
    await this.proxy.addContract('ProfileDB', this.profileDB.address);
    await this.proxy.addContract('RoleDB', this.roleDB.address);
    await this.proxy.addContract('Register', this.register.address);

    await this.genericDB.setProxy(this.proxy.address);
    await this.profileDB.setProxy(this.proxy.address);
    await this.roleDB.setProxy(this.proxy.address);
    await this.register.setProxy(this.proxy.address);
    await this.register.initialize();
  });

  describe('Register::Authority', () => {
    it('sets proxy', async () => {
      await this.register.setProxy(randomAddress).should.be.fulfilled;
      let proxy = await this.register.proxy();
      proxy.should.be.equal(randomAddress);
    });

    it('initializes', async () => {
      await this.register.initialize().should.be.fulfilled;
      
      let _profileDB = await this.register.profileDB();
      let _roleDB = await this.register.roleDB();
      let _cryptoKitties = await this.register.cryptoKitties();

      _profileDB.should.be.equal(this.profileDB.address);
      _roleDB.should.be.equal(this.roleDB.address);
      _cryptoKitties.should.be.equal(this.cryptoKitties.address);
    });

    it('does not allow an unauthorized address to set proxy and initialize', async () => {
      await this.register.setProxy(randomAddress, {from: unauthorizedUser}).should.be.rejected;
      await this.register.initialize({from: unauthorizedUser}).should.be.rejected;
    });
  });

  describe('Register::Features', () => {
    const kittie1 = 1234;
    const kittie2 = 32452;
    const kittie3 = 23134;

    beforeEach(async () => {
      // Fake the proxy contract to be able to make calls directly to Register contract
      await this.register.setProxy(creator);
      // Mint some kitties for the test addresses
      await this.cryptoKitties.mint(user1, kittie1).should.be.fulfilled;
      await this.cryptoKitties.mint(user2, kittie2).should.be.fulfilled;
      await this.cryptoKitties.mint(creator, kittie3).should.be.fulfilled;

      // Approve transfer operation for the system
      await this.cryptoKitties.approve(this.register.address, kittie1, {from: user1}).should.be.fulfilled;
      await this.cryptoKitties.approve(this.register.address, kittie2, {from: user2}).should.be.fulfilled;
      await this.cryptoKitties.approve(this.register.address, kittie3).should.be.fulfilled;

      // Send some SuperDAO and KitttieFight tokens to users
      await this.superDaoToken.transfer(user1, 100000).should.be.fulfilled;
      await this.superDaoToken.transfer(user2, 100000).should.be.fulfilled;
      await this.kittieFightToken.transfer(user1, 100000).should.be.fulfilled;
      await this.kittieFightToken.transfer(user2, 100000).should.be.fulfilled;

      // Approve erc20 token transfer operation for the system
      await this.superDaoToken.approve(this.register.address, 100000, {from: user1}).should.be.fulfilled;
      await this.superDaoToken.approve(this.register.address, 100000,  {from: user2}).should.be.fulfilled;
      await this.kittieFightToken.approve(this.register.address, 100000, {from: user1}).should.be.fulfilled;
      await this.kittieFightToken.approve(this.register.address, 100000, {from: user2}).should.be.fulfilled;
    });

    it('registers user', async () => {
      await this.register.register(user1).should.be.fulfilled;
      let doesExist = await this.profileDB.doesProfileExist(user1);
      let hasRole = await this.roleDB.hasRole('bettor', user1);
      doesExist.should.be.true;
      hasRole.should.be.true;
    });

    it('verifies user', async () => {
      let civicId = 12345;
      await this.register.register(user1).should.be.fulfilled;
      let doesExist = await this.profileDB.doesProfileExist(user1);
      let bettorRole = await this.roleDB.hasRole('bettor', user1);
      doesExist.should.be.true;
      bettorRole.should.be.true;

      await this.register.verifyAccount(user1, civicId).should.be.fulfilled;

      let playerRole = await this.roleDB.hasRole('player', user1);
      playerRole.should.be.true;
    });

    it('stakes SuperDAO tokens', async () => {
      let stakeAmount = 1000;
      let preBalance = (await this.superDaoToken.balanceOf(user1)).toNumber();
      let postBalance;

      await this.register.register(user1).should.be.fulfilled;
      await this.register.stakeSuperDAO(user1, stakeAmount).should.be.fulfilled;

      postBalance = (await this.superDaoToken.balanceOf(user1)).toNumber();
      let isStaking = await this.genericDB.getBoolStorage('ProfileDB', web3.utils.soliditySha3(user1, "isStakingSuperDAO"));
      let superDaoStake = await this.genericDB.getUintStorage('ProfileDB', web3.utils.soliditySha3(user1, "superDAOTokens"));
      isStaking.should.be.true;
      superDaoStake.toNumber().should.be.equal(stakeAmount);
      postBalance.should.be.equal(preBalance - stakeAmount);
    });

    it('locks KittieFight tokens', async () => {
      let tokenAmount = 1000;
      let preBalance = (await this.kittieFightToken.balanceOf(user1)).toNumber();
      let postBalance;

      await this.register.register(user1).should.be.fulfilled;
      await this.register.lockTokens(user1, tokenAmount).should.be.fulfilled;

      let _tokenAmount = (await this.profileDB.getKittieFightTokens(user1)).toNumber();
      postBalance = (await this.kittieFightToken.balanceOf(user1)).toNumber();
      _tokenAmount.should.be.equal(tokenAmount);
      postBalance.should.be.equal(preBalance - tokenAmount);
    });

    it('releases KittieFight tokens', async () => {
      let tokenAmount = 1000;
      let releaseAmount = 500;
      let preBalance = (await this.kittieFightToken.balanceOf(user1)).toNumber();
      let postBalance;

      await this.register.register(user1).should.be.fulfilled;
      await this.register.lockTokens(user1, tokenAmount).should.be.fulfilled;
      await this.register.releaseTokens(user1, releaseAmount).should.be.fulfilled;

      let _tokenAmount = (await this.profileDB.getKittieFightTokens(user1)).toNumber();
      postBalance = (await this.kittieFightToken.balanceOf(user1)).toNumber();
      _tokenAmount.should.be.equal(tokenAmount - releaseAmount);
      postBalance.should.be.equal(preBalance - releaseAmount);
    });
  });

  describe('Register::Features:Negatives', () => {
    beforeEach(async () => {
      // Fake the proxy contract to be able to make calls directly to Register contract
      await this.register.setProxy(creator);
    });

    it('does not allow to register the same account more than once', async () => {
      await this.register.register(user1).should.be.fulfilled;
      let doesExist = await this.profileDB.doesProfileExist(user1);
      doesExist.should.be.true;
      await this.register.register(user1).should.be.rejected;
    });

    it('does not allow to verify two different account with the same civic id', async () => {
      let civicId = 12345;
      await this.register.register(user1).should.be.fulfilled;
      let doesExist = await this.profileDB.doesProfileExist(user1);
      let bettorRole = await this.roleDB.hasRole('bettor', user1);
      doesExist.should.be.true;
      bettorRole.should.be.true;

      await this.register.register(user2).should.be.fulfilled;
      doesExist = await this.profileDB.doesProfileExist(user2);
      bettorRole = await this.roleDB.hasRole('bettor', user2);
      doesExist.should.be.true;
      bettorRole.should.be.true;

      await this.register.verifyAccount(user1, civicId).should.be.fulfilled;
      await this.register.verifyAccount(user2, civicId).should.be.rejected;

      let playerRole = await this.roleDB.hasRole('player', user1);
      playerRole.should.be.true;
      playerRole = await this.roleDB.hasRole('player', user2);
      playerRole.should.be.false;
    });
  });
});
