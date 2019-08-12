const Proxy = artifacts.require('KFProxy');
const GenericDB = artifacts.require('GenericDB');
const CronJob = artifacts.require('CronJob');
const FreezeInfo = artifacts.require('FreezeInfo');
const CronJobTarget = artifacts.require('CronJobTarget');
const RoleDB = artifacts.require('RoleDB');

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
        this.freezeInfo = await FreezeInfo.new();
        this.cronJob = await CronJob.new(this.genericDB.address);
        this.cronJobTarget= await CronJobTarget.new();

        await this.proxy.addContract('GenericDB', this.genericDB.address);
        await this.proxy.addContract('FreezeInfo', this.freezeInfo.address);
        await this.proxy.addContract('CronJob', this.cronJob.address);
        await this.proxy.addContract('CronJobTarget', this.cronJobTarget.address);
        await this.genericDB.setProxy(this.proxy.address);
        await this.cronJob.setProxy(this.proxy.address);
        await this.cronJobTarget.setProxy(this.proxy.address);

        //Add creator as admin (because only admins can call executeScheduledJobs())
        this.roleDB = await RoleDB.new(this.genericDB.address);
        await this.proxy.addContract('RoleDB', this.roleDB.address);
        await this.proxy.addContract('Creator', creator);
        await this.roleDB.setProxy(this.proxy.address);
        await this.roleDB.addRole('Creator', 'admin', creator);
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
        it('should delete job from the list', async () => {
            let delay = 2*10;
            let randomVal = 1+Math.round(Math.random()*99);
            let originalValue = await this.cronJobTarget.value();
            if(randomVal == originalValue) randomVal +=1;
            let jobPayload = web3.eth.abi.encodeFunctionCall({name: 'setNonZeroValue', type: 'function', inputs: [{type: 'uint256',name: '_value'}]}, [randomVal]);

            //Create Job
            let receipt = await this.cronJobTarget.scheduleSetNonZeroValue(randomVal, delay).should.be.fulfilled;
            let jobId = receipt.logs[0].args.scheduledJob;
            let scheduledTime = receipt.logs[0].args.time;

            //Check Job created
            let job = await this.cronJob.getJob(jobId);
            assert.equal(job[0].toString(), scheduledTime.toString(), 'Scheduled time for Job does not match');
            assert.equal(job[1].toString(), "CronJobTarget", 'Target Contract for Job does not match');
            assert.equal(job[2], jobPayload, 'Payload for Job does not match');

            //Delete the job
            evm.increaseTime(web3, Math.floor(delay/2));
            receipt = await this.cronJobTarget.removeJob(jobId).should.be.fulfilled;

            //Check Job NOT executed
            evm.increaseTime(web3, delay);
            await this.proxy.executeScheduledJobs();
            let newValue = await this.cronJobTarget.value();
            assert.equal(newValue.toString(), originalValue.toString(), 'Value should not be changed');
        });
        it('should reschedule job', async () => {
            let delay = 2*10;
            let randomVal = 1+Math.round(Math.random()*99);
            let originalValue = await this.cronJobTarget.value();
            if(randomVal == originalValue) randomVal +=1;
            let jobPayload = web3.eth.abi.encodeFunctionCall({name: 'setNonZeroValue', type: 'function', inputs: [{type: 'uint256',name: '_value'}]}, [randomVal]);

            //Create Job
            let receipt = await this.cronJobTarget.scheduleSetNonZeroValue(randomVal, delay).should.be.fulfilled;
            let jobId = receipt.logs[0].args.scheduledJob;
            let scheduledTime = receipt.logs[0].args.time;

            //Check Job created
            let job = await this.cronJob.getJob(jobId);
            assert.equal(job[0].toString(), scheduledTime.toString(), 'Scheduled time for Job does not match');
            assert.equal(job[1].toString(), "CronJobTarget", 'Target Contract for Job does not match');
            assert.equal(job[2], jobPayload, 'Payload for Job does not match');

            //Reschedule the job
            evm.increaseTime(web3, Math.floor(delay/2));
            receipt = await this.cronJobTarget.rescheduleJob(jobId, 2*delay).should.be.fulfilled;

            //Check Job NOT executed
            evm.increaseTime(web3, delay);
            await this.proxy.executeScheduledJobs();
            let newValue = await this.cronJobTarget.value();
            assert.equal(newValue.toString(), originalValue.toString(), 'Value should not be changed');

            //Check new Job executed
            evm.increaseTime(web3, delay*2);
            await this.proxy.executeScheduledJobs();
            newValue = await this.cronJobTarget.value();
            assert.equal(newValue.toString(), String(randomVal), 'Value should  be changed');
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
        it('should execute added job by id', async () => {
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
            receipt = await this.proxy.executeJob(jobId);
            //Check job is done
            // console.log('After increase time: ', (await web3.eth.getBlock(web3.eth.blockNumber)).timestamp);
            // console.log('Current value:', (await this.cronJobTarget.value()).toString());
            value = await this.cronJobTarget.value();
            assert.equal(value, randomVal, 'Value should aready be set');
        });
        it('should execute all added jobs', async () => {
            let delay = 10;
            //Create Job 1
            let random1Val = 1+Math.round(Math.random()*999999);
            let receipt = await this.cronJobTarget.scheduleSetNonZeroValue(random1Val, delay-1).should.be.fulfilled;
            let job1Id = receipt.logs[0].args.scheduledJob;
            //Create Job 2
            let random2Val = 1+Math.round(Math.random()*999999);
            receipt = await this.cronJobTarget.scheduleSetNonZeroValue(random2Val, delay).should.be.fulfilled;
            let job2Id = receipt.logs[0].args.scheduledJob;
            //Create Job 3
            let random3Val = 666; //Evil value which will cause job to delete itself
            receipt = await this.cronJobTarget.scheduleSetNonZeroValue(random3Val, delay+1).should.be.fulfilled;
            let job3Id = receipt.logs[0].args.scheduledJob;
            //Create Job 4
            let random4Val = 1+Math.round(Math.random()*999999);
            receipt = await this.cronJobTarget.scheduleSetNonZeroValue(random4Val, delay+2).should.be.fulfilled;
            let job4Id = receipt.logs[0].args.scheduledJob;
            //Create Job 5
            let random5Val = 1+Math.round(Math.random()*999999);
            receipt = await this.cronJobTarget.scheduleSetNonZeroValue(random5Val, delay+3).should.be.fulfilled;
            let job5Id = receipt.logs[0].args.scheduledJob;

            let logs = await this.cronJob.getPastEvents('JobAdded', {fromBlock: 0, toBlock:'latest'});
            //console.log("Added Jobs", logs.map(le => {return {'jobId': le.returnValues.jobId, 'data': le.returnValues.data}}));

            //Fast-forward time & execute
            evm.increaseTime(web3, 2*delay);
            receipt = await this.proxy.executeScheduledJobs();
            //Check first 2 jobs are executed
            logs = await this.cronJob.getPastEvents('JobExecuted', {fromBlock: 0, toBlock:'latest'});
            //console.log("logs", logs)
            //console.log("Executed Jobs", logs.map(le => le.returnValues.jobId));
            assert.equal(logs[0].returnValues.jobId, job1Id, "Job1 Not executed");
            assert.equal(logs[1].returnValues.jobId, job2Id, "Job2 Not executed");
            //Execute other jobs
            receipt = await this.proxy.executeScheduledJobs();
            logs = await this.cronJob.getPastEvents('JobExecuted', {fromBlock: 0, toBlock:'latest'});
            //console.log("Executed Jobs", logs.map(le => le.returnValues.jobId));
            assert.equal(logs[2].returnValues.jobId, job3Id, "Job3 Not executed");
            assert.equal(logs[3].returnValues.jobId, job4Id, "Job4 Not executed");
            //Execute other jobs
            receipt = await this.proxy.executeScheduledJobs();
            logs = await this.cronJob.getPastEvents('JobExecuted', {fromBlock: 0, toBlock:'latest'});
            //console.log("Executed Jobs", logs.map(le => le.returnValues.jobId));
            assert.equal(logs[4].returnValues.jobId, job5Id, "Job5 Not executed");
        });


    });



});
