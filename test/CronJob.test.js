const Proxy = artifacts.require('ProxyMock');
const GenericDB = artifacts.require('GenericDB');
const CronJob = artifacts.require('CronJob');
const CronJobTarget = artifacts.require('CronJobTarget');
const BigNumber = require('bignumber.js');

require('chai')
    .use(require('chai-shallow-deep-equal'))
    .use(require('chai-bignumber')(BigNumber))
    .use(require('chai-as-promised'))
    .should();

    
contract('CronJob', ([creator, unauthorizedUser, randomAddress]) => {

    beforeEach(async () => {
        this.proxy = await Proxy.new();
        this.genericDB = await GenericDB.new();
        this.cronJob = await CronJob.new(this.genericDB.address);
        this.cronJobTarget= await CronJobTarget.new();

        await this.proxy.addContract('CronJob', this.cronJob.address);
        await this.proxy.addContract('CronJobTarget', this.cronJobTarget.address);
        await this.genericDB.setProxy(this.proxy.address);
        await this.cronJob.setProxy(this.proxy.address);
        await this.cronJobTarget.setProxy(this.proxy.address);
    });

    describe('CronJob::Authority', () => {
        it('sets proxy and db', async () => {
            await this.cronJob.setProxy(randomAddress).should.be.fulfilled;
            await this.cronJob.setGenericDB(randomAddress).should.be.fulfilled;

            let proxy = await this.profileDB.proxy();
            let genericDB = await this.profileDB.genericDB();

            proxy.should.be.equal(randomAddress);
            genericDB.should.be.equal(randomAddress);
        });

        it('does not allow unauthorized address to access proxy/db setter functions', async () => {
            await this.cronJob.setProxy(this.proxy.address, {from: unauthorizedUser}).should.be.rejected;
            await this.cronJob.setGenericDB(this.genericDB.address, {from: unauthorizedUser}).should.be.rejected;
        });

        /*
        it('does not allow unauthorized address to access add job', async () => {
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
        */
    });

    describe('CronJob::JobList', () => {
        it('should add job to list', async () => {
            let testJobData = web3.eth.abi.encodeFunctionCall(
                CronJobTarget.abi.find((el)=>{return  el.name=='setNonZeroValue'}),
                
            );
            await this.proxy.scheduleJob(this.cronJobTarget.address, ).should.be.fulfilled;
        });


    });

});
