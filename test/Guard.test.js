const BigNumber = require('bignumber.js');
require('chai')
  .use(require('chai-shallow-deep-equal'))
  .use(require('chai-bignumber')(BigNumber))
  .use(require('chai-as-promised'))
  .should();
const { ZERO_ADDRESS } = require('./utils/constants');
const GenericDB = artifacts.require('GenericDB');
const Proxy = artifacts.require('Proxy');
const RoleDB = artifacts.require('RoleDB');
const GuardImplementor = artifacts.require('GuardImplementor');
const ROLEDB_CONTRACT_NAME = 'RoleDB';
// We are faking the client contract, just avoiding to add extra contract names to Proxy for tests
// One can also create a mock Proxy contract to grant the access for mock guard implementor. But for
// the time being it's not neccessary, faking access through other contracts in system is easier solution.
const GUARD_IMPL_CONTRACT_NAME = 'Register';
const ROLES = {
  superAdmin: 'super_admin',
  admin: 'admin',
  player: 'player',
  bettor: 'bettor'
}

  
contract('RoleDB & Guard', ([owner, addr1, addr2, addr3, addr4, unauthorizedAddr, randomAddr]) => {

  beforeEach(async () => {
    this.genericDB = await GenericDB.new();
    this.roleDB = await RoleDB.new(this.genericDB.address);
    this.proxy = await Proxy.new();
    this.guardImplementor = await GuardImplementor.new(this.roleDB.address);

    // Add owner as if it is a client contract to be able to make calls to RoleDB contract for test purpose
    await this.proxy.addContract(GUARD_IMPL_CONTRACT_NAME, owner);
    // RoleDB should be added to proxy to grant access to GenericDB
    await this.proxy.addContract(ROLEDB_CONTRACT_NAME, this.roleDB.address);
    await this.genericDB.setProxy(this.proxy.address);
    await this.roleDB.setProxy(this.proxy.address);
  });

  describe('RoleDB::Authority', () => {
    it('sets proxy and db', async () => {
      await this.roleDB.setProxy(randomAddr).should.be.fulfilled;
      await this.roleDB.setGenericDB(randomAddr).should.be.fulfilled;

      let proxy = await this.roleDB.proxy();
      let genericDB = await this.roleDB.genericDB();

      proxy.should.be.equal(randomAddr);
      genericDB.should.be.equal(randomAddr);
    });

    it('does not allow unauthorized address to access proxy/db setter functions', async () => {
      await this.roleDB.setProxy(this.proxy.address, {from: unauthorizedAddr}).should.be.rejected;
      await this.roleDB.setGenericDB(this.genericDB.address, {from: unauthorizedAddr}).should.be.rejected;
    });

    it('does not allow unauthorized address to access functions', async () => {
      await this.roleDB.addRole(GUARD_IMPL_CONTRACT_NAME, ROLES.admin, addr1, {from: unauthorizedAddr}).should.be.rejected;

      await this.roleDB.addRole(GUARD_IMPL_CONTRACT_NAME, ROLES.admin, addr1).should.be.fulfilled;
      await this.roleDB.removeRole(GUARD_IMPL_CONTRACT_NAME, ROLES.admin, addr1, {from: unauthorizedAddr}).should.be.rejected;
    });
  });

  describe('RoleDB::Functions', () => {
    it('adds roles', async () => {
      // First add roles for some addresses
      await this.roleDB.addRole(GUARD_IMPL_CONTRACT_NAME, ROLES.superAdmin, addr1).should.be.fulfilled;
      await this.roleDB.addRole(GUARD_IMPL_CONTRACT_NAME, ROLES.admin, addr2).should.be.fulfilled;
      await this.roleDB.addRole(GUARD_IMPL_CONTRACT_NAME, ROLES.player, addr3).should.be.fulfilled;
      await this.roleDB.addRole(GUARD_IMPL_CONTRACT_NAME, ROLES.bettor, addr4).should.be.fulfilled;

      // Check the roles for the addresses
      (await this.roleDB.hasRole(ROLES.superAdmin, addr1)).should.be.true;
      (await this.roleDB.hasRole(ROLES.admin, addr2)).should.be.true;
      (await this.roleDB.hasRole(ROLES.player, addr3)).should.be.true;
      (await this.roleDB.hasRole(ROLES.bettor, addr4)).should.be.true;
    });

    it('removes roles', async () => {
      // First add roles for some addresses
      await this.roleDB.addRole(GUARD_IMPL_CONTRACT_NAME, ROLES.superAdmin, addr1).should.be.fulfilled;
      await this.roleDB.addRole(GUARD_IMPL_CONTRACT_NAME, ROLES.admin, addr2).should.be.fulfilled;
      await this.roleDB.addRole(GUARD_IMPL_CONTRACT_NAME, ROLES.player, addr3).should.be.fulfilled;
      await this.roleDB.addRole(GUARD_IMPL_CONTRACT_NAME, ROLES.bettor, addr4).should.be.fulfilled;

      // Check the roles for the addresses
      (await this.roleDB.hasRole(ROLES.superAdmin, addr1)).should.be.true;
      (await this.roleDB.hasRole(ROLES.admin, addr2)).should.be.true;
      (await this.roleDB.hasRole(ROLES.player, addr3)).should.be.true;
      (await this.roleDB.hasRole(ROLES.bettor, addr4)).should.be.true;

      await this.roleDB.removeRole(GUARD_IMPL_CONTRACT_NAME, ROLES.superAdmin, addr1).should.be.fulfilled;
      await this.roleDB.removeRole(GUARD_IMPL_CONTRACT_NAME, ROLES.admin, addr2).should.be.fulfilled;
      await this.roleDB.removeRole(GUARD_IMPL_CONTRACT_NAME, ROLES.player, addr3).should.be.fulfilled;
      await this.roleDB.removeRole(GUARD_IMPL_CONTRACT_NAME, ROLES.bettor, addr4).should.be.fulfilled;

      // Check the roles for the addresses after removal
      (await this.roleDB.hasRole(ROLES.superAdmin, addr1)).should.be.false;
      (await this.roleDB.hasRole(ROLES.admin, addr2)).should.be.false;
      (await this.roleDB.hasRole(ROLES.player, addr3)).should.be.false;
      (await this.roleDB.hasRole(ROLES.bettor, addr4)).should.be.false;
    });
  });

  describe('RoleDB::Functions::Negatives', () => {
    it('does not allow to add roles for zero address', async () => {
      await this.roleDB.addRole(GUARD_IMPL_CONTRACT_NAME, ROLES.superAdmin, ZERO_ADDRESS).should.be.rejected;
    });

    it('does not allow to add roles for an existent role-address pair', async () => {
      // First add a role for an address
      await this.roleDB.addRole(GUARD_IMPL_CONTRACT_NAME, ROLES.player, addr1).should.be.fulfilled;
      (await this.roleDB.hasRole(ROLES.player, addr1)).should.be.true;

      await this.roleDB.addRole(GUARD_IMPL_CONTRACT_NAME, ROLES.player, addr1).should.be.rejected;
    });

    it('does not allow to remove roles for a non-existent role-address pair', async () => {
      await this.roleDB.removeRole(GUARD_IMPL_CONTRACT_NAME, ROLES.player, addr1).should.be.rejected;
    });
  });

  describe('Guard::Modifiers', () => {
    beforeEach(async () => {
      // First add roles for some addresses
      await this.roleDB.addRole(GUARD_IMPL_CONTRACT_NAME, ROLES.superAdmin, addr1).should.be.fulfilled;
      await this.roleDB.addRole(GUARD_IMPL_CONTRACT_NAME, ROLES.admin, addr2).should.be.fulfilled;
      await this.roleDB.addRole(GUARD_IMPL_CONTRACT_NAME, ROLES.player, addr3).should.be.fulfilled;
      await this.roleDB.addRole(GUARD_IMPL_CONTRACT_NAME, ROLES.bettor, addr4).should.be.fulfilled;

      // Check the roles for the addresses
      (await this.roleDB.hasRole(ROLES.superAdmin, addr1)).should.be.true;
      (await this.roleDB.hasRole(ROLES.admin, addr2)).should.be.true;
      (await this.roleDB.hasRole(ROLES.player, addr3)).should.be.true;
      (await this.roleDB.hasRole(ROLES.bettor, addr4)).should.be.true;
    });

    it('allows only super admins to make call', async () => {
      // Call by an authorized address
      await this.guardImplementor.canCalledByOnlySuperAdmin({from: addr1}).should.be.fulfilled;
      // Call by an unauthorized address for negative test
      await this.guardImplementor.canCalledByOnlySuperAdmin({from: addr4}).should.be.rejected;
    });

    it('allows only admins to make call', async () => {
      // Call by an authorized address
      await this.guardImplementor.canCalledByOnlyAdmin({from: addr2}).should.be.fulfilled;
      // Call by an unauthorized address for negative test
      await this.guardImplementor.canCalledByOnlyAdmin({from: addr1}).should.be.rejected;
    });

    it('allows only players to make call', async () => {
      // Call by an authorized address
      await this.guardImplementor.canCalledByOnlyPlayer({from: addr3}).should.be.fulfilled;
      // Call by an unauthorized address for negative test
      await this.guardImplementor.canCalledByOnlyPlayer({from: addr2}).should.be.rejected;
    });

    it('allows only bettors to make call', async () => {
      // Call by an authorized address
      await this.guardImplementor.canCalledByOnlyBettor({from: addr4}).should.be.fulfilled;
      // Call by an unauthorized address for negative test
      await this.guardImplementor.canCalledByOnlyBettor({from: addr3}).should.be.rejected;
    });
  });
});
