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

  
contract('Register', ([creator, user1, user2, unauthorizedUser, randomAddress]) => {
  beforeEach(async () => {
    this.proxy = await Proxy.new();
    this.genericDB = await GenericDB.new();
    this.profileDB = await ProfileDB.new(this.genericDB.address);
    this.roleDB = await RoleDB.new(this.genericDB.address);
    this.register = await Register.new();

    await this.proxy.addContract('CryptoKitties', '0x06012c8cf97bead5deae237070f9587f8e7a266d');
    await this.proxy.addContract('ProfileDB', this.profileDB.address);
    await this.proxy.addContract('RoleDB', this.roleDB.address);
    await this.proxy.addContract('Register', this.register.address);

    await this.genericDB.setProxy(this.proxy.address);
    await this.profileDB.setProxy(this.proxy.address);
    await this.register.setProxy(this.proxy.address);
    await this.register.initialize();
  });

  describe('Register::Authority', () => {
    it('sets proxy and db', async () => {
      await this.register.setProxy(randomAddress).should.be.fulfilled;
      let proxy = await this.register.proxy();
      proxy.should.be.equal(randomAddress);
    });
  });
});
