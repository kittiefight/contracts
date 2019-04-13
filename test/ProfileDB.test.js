const ProfileDB = artifacts.require('ProfileDB');
const BigNumber = require('bignumber.js');
require('chai')
  .use(require('chai-shallow-deep-equal'))
  .use(require('chai-bignumber')(BigNumber))
  .use(require('chai-as-promised'))
  .should();


contract('ProfileDB', ([creator, user1, user2, unauthorizedUser]) => {
  const user1Profile = {
    id: 12345,
    owner: user1,
    losses: 23,
    totalFights: 50,
    kittyStatus: {
      dead: false,
      playing: true,
      deadAt: 500
    },
    nextFight: 0,
    listingStartAt: 12345,
    listingEndAt: 12315456,
    genes: BigNumber(5678342),
    cryptokittyId: 98765,
    torMagnetsImagelinks: [
      'torImageLink1',
      'torImageLink2',
      'torImageLink3'
    ],
    description: [
      'kittie description - 1',
      'kittie description - 2',
      'kittie description - 3',
      'kittie description - 4',
      'kittie description - 5'
    ],
    fees: {
      paidDate: 12313,
      feeType: 1,
      expirationDate: 45672,
      isPaid: false,
      feelimits: {
        fightFeeLimit: 100,
        resurrectionFeeLimit: 50
      }
    },
    fighterList: [
      '0x0000000000000000000000000000000000000000000000000000000000000001',
      '0x0000000000000000000000000000000000000000000000000000000000000002'
    ],
    kittieHashList: [
      '0x000000000000000000000000000000000000000000000000000000000000000f',
      '0x000000000000000000000000000000000000000000000000000000000000000e'
    ],
    referalHash: '0x00000000000000000000000000000000000000000000000000000000000000ff',
    totalWins: 11,
    totalLosses: 14,
    tokensWon: 200,
    lastDateListing: 12314,
    superDAOTokens: 100,
    kittieFightTokens: 50,
    lastFeeDate: 10000,
    feeHistory: 0,
    isStakingSuperDAO: false,
    isFreeToPlay: true,
  };

  beforeEach(async () => {
    this.profileDB = await ProfileDB.new();
  });

  describe('ProfileDB', () => {
    it('creates a profile item', async () => {
      await this.profileDB.create(user1Profile.id).should.be.fulfilled;
    });

    it('deletes a profile item', async () => {
      await this.profileDB.create(user1Profile.id).should.be.fulfilled;
      await this.profileDB.remove(user1Profile.id).should.be.fulfilled;
      // For double check, after deletion any attribute getter should be reverted
      await this.profileDB.setOwnerAddress(user1Profile.id).should.be.rejected;
    });

    it('gets table size', async () => {
      await this.profileDB.create(123).should.be.fulfilled;
      await this.profileDB.create(425).should.be.fulfilled;
      await this.profileDB.create(123413).should.be.fulfilled;
      let size = await this.profileDB.getTableSize().should.be.fulfilled;
      BigNumber(size).should.be.bignumber.equal(3);
    });
  
    it('sets & gets attribute::Owner', async () => {
      await this.profileDB.create(user1Profile.id).should.be.fulfilled;
      await this.profileDB.setOwnerAddress(user1Profile.id, user1Profile.owner).should.be.fulfilled;
      let _owner = await this.profileDB.getOwnerAddress(user1Profile.id).should.be.fulfilled;
      _owner.should.be.equal(user1Profile.owner);
    });
  
    it('sets & gets attribute::KittieStatus', async () => {
      await this.profileDB.create(user1Profile.id).should.be.fulfilled;
      await this.profileDB.setKittieStatus(
        user1Profile.id,
        user1Profile.kittyStatus.dead,
        user1Profile.kittyStatus.playing,
        user1Profile.kittyStatus.deadAt
      ).should.be.fulfilled;
      let status = await this.profileDB.getKittieStatus(user1Profile.id).should.be.fulfilled;
      status[0].should.be.equal(user1Profile.kittyStatus.dead);
      status[1].should.be.equal(user1Profile.kittyStatus.playing);
      BigNumber(status[2]).should.be.bignumber.equal(user1Profile.kittyStatus.deadAt);
    });

    it('sets & gets attribute::Genes', async () => {
      await this.profileDB.create(user1Profile.id).should.be.fulfilled;
      await this.profileDB.setKittieGenes(user1Profile.id, user1Profile.genes).should.be.fulfilled;
      let _genes = await this.profileDB.getKittieGenes(user1Profile.id).should.be.fulfilled;
      BigNumber(_genes).should.be.bignumber.equal(user1Profile.genes);
    });

    it('sets & gets attribute::CryptokittyId', async () => {
      await this.profileDB.create(user1Profile.id).should.be.fulfilled;
      await this.profileDB.setCryptokittyId(
        user1Profile.id,
        user1Profile.cryptokittyId
      ).should.be.fulfilled;
      let _cryptokittyId = await this.profileDB.getCryptokittyId(user1Profile.id).should.be.fulfilled;
      BigNumber(_cryptokittyId).should.be.bignumber.equal(user1Profile.cryptokittyId);
    });

    it('sets & gets attribute::torMagnetsImagelinks', async () => {
      await this.profileDB.create(user1Profile.id).should.be.fulfilled;
      // TODO: Implement this
    });

    it('sets & gets attribute::ListingDates', async () => {
      await this.profileDB.create(user1Profile.id).should.be.fulfilled;
      await this.profileDB.setListingDate(
        user1Profile.id,
        user1Profile.listingStartAt,
        user1Profile.listingEndAt
      ).should.be.fulfilled;
      let listingDates = await this.profileDB.getListingDate(user1Profile.id).should.be.fulfilled;
      BigNumber(listingDates[0]).should.be.bignumber.equal(user1Profile.listingStartAt);
      BigNumber(listingDates[1]).should.be.bignumber.equal(user1Profile.listingEndAt);
    });

    it('sets & gets attribute::NextFight', async () => {
      await this.profileDB.create(user1Profile.id).should.be.fulfilled;
      await this.profileDB.setNextFight(user1Profile.id, user1Profile.nextFight).should.be.fulfilled;
      let _nextFight = await this.profileDB.getNextFight(user1Profile.id).should.be.fulfilled;
      BigNumber(_nextFight).should.be.bignumber.equal(user1Profile.nextFight);
    });

    it('sets & gets attribute::Losses', async () => {
      await this.profileDB.create(user1Profile.id).should.be.fulfilled;
      await this.profileDB.setLosses(user1Profile.id, user1Profile.losses).should.be.fulfilled;
      let _losses = await this.profileDB.getLosses(user1Profile.id).should.be.fulfilled;
      BigNumber(_losses).should.be.bignumber.equal(user1Profile.losses);
    });

    it('sets & gets attribute::TotalFights', async () => {
      await this.profileDB.create(user1Profile.id).should.be.fulfilled;
      await this.profileDB.setTotalFights(user1Profile.id, user1Profile.totalFights).should.be.fulfilled;
      let _totalFights = await this.profileDB.getTotalFights(user1Profile.id).should.be.fulfilled;
      BigNumber(_totalFights).should.be.bignumber.equal(user1Profile.totalFights);
    });

    it('sets & gets attribute::Description', async () => {
      await this.profileDB.create(user1Profile.id).should.be.fulfilled;
      await this.profileDB.setDescription(user1Profile.id, user1Profile.description).should.be.fulfilled;
      let _description = await this.profileDB.getDescription(user1Profile.id).should.be.fulfilled;
      _description.should.shallowDeepEqual(user1Profile.description);
    });
  });
});