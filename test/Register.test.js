const BigNumber = require('bignumber.js');
require('chai')
  .use(require('chai-shallow-deep-equal'))
  .use(require('chai-bignumber')(BigNumber))
  .use(require('chai-as-promised'))
  .should();

const GenericDB = artifacts.require('GenericDB');
const ProfileDB = artifacts.require('ProfileDB');
const RoleDB = artifacts.require('RoleDB');
const Register = artifacts.require('Register');
const Proxy = artifacts.require('Proxy');

const CryptoKitties = '0x06012c8cf97bead5deae237070f9587f8e7a266d';

  
contract('Register', ([creator, user1, user2, unauthorizedUser, randomAddress]) => {
  beforeEach(async () => {
    this.genericDB = await GenericDB.new();
    this.profileDB = await ProfileDB.new(this.genericDB.address);
    this.roleDB = await RoleDB.new(this.genericDB.address);
    this.proxy = await Proxy.new(this.roleDB.address);
    this.register = await Register.new();

    // Add the system contracts to the proxy
    await this.proxy.addContract('CryptoKitties', CryptoKitties);
    await this.proxy.addContract('ProfileDB', this.profileDB.address);
    await this.proxy.addContract('RoleDB', this.roleDB.address);
    await this.proxy.addContract('Register', this.register.address);

    // Set RoleDB address
    // await this.proxy.setRoleDB(this.roleDB.address).should.be.fulfilled;

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
      _cryptoKitties.toLowerCase().should.be.equal(CryptoKitties.toLowerCase());
    });

    it('does not allow an unauthorized address to set proxy and initialize', async () => {
      await this.register.setProxy(randomAddress, {from: unauthorizedUser}).should.be.rejected;
      await this.register.initialize({from: unauthorizedUser}).should.be.rejected;
    });
  });

  describe('Register::Features', () => {
    beforeEach(async () => {
      
    });

    it('registers user', async () => {
      let addr = await this.proxy.register(user1).should.be.fulfilled;
      let doesExist = await this.profileDB.doesProfileExist(user1);
      let hasRole = await this.roleDB.hasRole('bettor', user1);
      doesExist.should.be.true;
      hasRole.should.be.true;
    });
  });
});
