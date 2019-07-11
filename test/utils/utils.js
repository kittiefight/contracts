const BigNumber = require('bignumber.js');
const chai = require('chai');
const chaiAsPromised = require('chai-as-promised');
const assert = chai.assert;
chai.use(chaiAsPromised);

const balanceOf = (web3, account) => {
  return new Promise((resolve, reject) => web3.eth.getBalance(account,
      (e, balance) => (e ? reject(e) : resolve(balance))))
};

const promFuncCall = (contInst, funcName, args, account) => {
  return new Promise(
      (resolve, reject) => contInst[funcName].apply(this,
          args.concat({from: account},
              (error, result) => (error ? reject(error) : resolve(result)))));
};

const isUnableToAccEther = async (contract, account, amount) => {
  const inst = await contract.deployed();
  assert.isRejected(new Promise((resolve, reject) => contract.web3.eth.sendTransaction(
      {
        to: inst.address,
        value: amount,
        from: account
      },
      (e) => (e ? reject(e) : resolve()))));
  assert.eventually.notEqual(balanceOf(contract.web3, inst.address), new BigNumber(amount));
};

function Reverter() {
  let snapshotId;

  this.revert = () => {
    return new Promise((resolve, reject) => {
      web3.currentProvider.send({
        jsonrpc: '2.0',
        method: 'evm_revert',
        id: new Date().getTime(),
        params: [snapshotId],
      }, (err, result) => {
        if (err) {
          return reject(err);
        }
        return resolve(this.snapshot());
      });
    });
  };

  this.snapshot = () => {
    return new Promise((resolve, reject) => {
      web3.currentProvider.send({
        jsonrpc: '2.0',
        method: 'evm_snapshot',
        id: new Date().getTime(),
      }, (err, result) => {
        if (err) {
          return reject(err);
        }
        snapshotId = web3.utils.hexToNumber(result.result);
        return resolve();
      });
    });
  };
}

Object.assign(exports, {
  balanceOf,
  promFuncCall,
  isUnableToAccEther,
  Reverter
});
