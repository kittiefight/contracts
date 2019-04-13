const BigNumber = require('bignumber.js');
const chai = require('chai');
const chaiAsPromised = require('chai-as-promised');
const assert = chai.assert;
chai.use(chaiAsPromised);

const mineBlock = (web3, reject, resolve) => {
    web3.currentProvider.sendAsync({
      method: "evm_mine",
      jsonrpc: "2.0",
      id: new Date().getTime()
    }, (e) => (e ? reject(e) : resolve()));
};

const increaseTimestamp = (web3, increase) => {
  return new Promise((resolve, reject) => {
    web3.currentProvider.sendAsync({
      method: "evm_increaseTime",
      params: [increase],
      jsonrpc: "2.0",
      id: new Date().getTime()
    }, (e) => (e ? reject(e) : mineBlock(web3, reject, resolve)))
  });
};

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

Object.assign(exports, {
  increaseTimestamp,
  balanceOf,
  promFuncCall,
  isUnableToAccEther
});
