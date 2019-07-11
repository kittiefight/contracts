'use strict';

const { Reverter } = require('./utils');
const Endowment = artifacts.require('EndowmentTestable');

contract('Endowment', (accounts) => {
  const reverter = new Reverter(web3);
  afterEach('revert', reverter.revert);

  let endowment;

  before('setup', async () => {
    endowment = await Endowment.new();
    await reverter.snapshot();
  });

  // Tests will be removed 
  it('should return true on increment', async () => {
    assert.isTrue(await endowment.increment.call());
  });

  it('should be possible to increment', async () => {
    assert.equal(await endowment.counter(), 0);
    await endowment.increment();
    assert.equal(await endowment.counter(), 1);
  });

  it('should be possible to increment from 0 after previous test revert', async () => {
    assert.equal(await endowment.counter(), 0);
    await endowment.increment();
    assert.equal(await endowment.counter(), 1);
  });
});
