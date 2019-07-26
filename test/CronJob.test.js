const Proxy = artifacts.require('KFProxy');
const GenericDB = artifacts.require('GenericDB');
const CronJob = artifacts.require('CronJob');
const CronJobTarget = artifacts.require('CronJobTarget');
const BigNumber = require('bignumber.js');
const evm = require('./utils/evm.js');

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

            let proxy = await this.cronJob.proxy();
            let genericDB = await this.cronJob.genericDB();

            proxy.should.be.equal(randomAddress);
            genericDB.should.be.equal(randomAddress);
        });

        it('does not allow unauthorized address to access proxy/db setter functions', async () => {
            await this.cronJob.setProxy(this.proxy.address, {from: unauthorizedUser}).should.be.rejected;
            await this.cronJob.setGenericDB(this.genericDB.address, {from: unauthorizedUser}).should.be.rejected;
        });

    });
    describe('CronJob::JobList', () => {
        it('should add job to list manually', async () => {
            let delay = 10;
            let randomVal = 1+Math.round(Math.random()*99);
            let now = (await web3.eth.getBlock(web3.eth.blockNumber)).timestamp;
            let scheduledTime = now + delay;
            //Create Job
            let receipt = await this.cronJob.addCronJobManually(
                'CronJobTarget',
                scheduledTime,
                web3.eth.abi.encodeFunctionCall({
                    name: 'setNonZeroValue',
                    type: 'function',
                    inputs: [{type: 'uint256',name: '_value'}]
                }, [randomVal]),
                0
            );
            //Check Job created
            let jobId = receipt.logs[0].args.jobId;
            let job = await this.cronJob.getJob(jobId);
            assert.equal(job[0].toNumber(), scheduledTime, 'Scheduled time for Job does not match');
        });
        it('should add job to list via target contract', async () => {
            let delay = 10;
            let randomVal = 1+Math.round(Math.random()*99);
            //Create Job
            let receipt = await this.cronJobTarget.scheduleSetNonZeroValue(randomVal, delay).should.be.fulfilled;
            let jobId = receipt.logs[0].args.scheduledJob;
            let scheduledTime = receipt.logs[0].args.time;
            //Check Job created
            let job = await this.cronJob.getJob(jobId);
            assert.equal(job[0].toString(), scheduledTime.toString(), 'Scheduled time for Job does not match');
        });
    });
    describe('CronJob::ExecuteViaProxy', () => {
        it('should execute added job', async () => {
            let delay = 10;
            let randomVal = 1+Math.round(Math.random()*99);
            //Create Job
            let receipt = await this.cronJobTarget.scheduleSetNonZeroValue(randomVal, delay).should.be.fulfilled;
            let jobId = receipt.logs[0].args.scheduledJob;
            let scheduledTime = receipt.logs[0].args.time;
            //Check Job created
            let job = await this.cronJob.getJob(jobId);
            assert.equal(job[0].toString(), scheduledTime.toString(), 'Scheduled time for Job does not match');
            let value = await this.cronJobTarget.value();
            assert.equal(value, 0, 'Value should not be set yet');
            // console.log('Before increase time: ', (await web3.eth.getBlock(web3.eth.blockNumber)).timestamp);
            // console.log('Current value:', (await this.cronJobTarget.value()).toString());
            //Fast-forward time & execute
            evm.increaseTime(web3, delay+1);
            receipt = await this.proxy.executeScheduledJobs();
            //Check job is done
            // console.log('After increase time: ', (await web3.eth.getBlock(web3.eth.blockNumber)).timestamp);
            // console.log('Current value:', (await this.cronJobTarget.value()).toString());
            value = await this.cronJobTarget.value();
            assert.equal(value, randomVal, 'Value should aready be set');
        });


    });

});
