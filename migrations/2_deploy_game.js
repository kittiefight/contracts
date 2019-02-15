const SafeMath = artifacts.require('libs/SafeMath');
const KittieHELL = artifacts.require('KittieHELL');
const KittieFIGHTToken = artifacts.require('KittieFIGHTToken');
const ContractManager = artifacts.require('ContractManager');
const KittyCoreMock = artifacts.require('KittyCore');

module.exports = (deployer, network, accounts) => {
  let contractManagerInst;

  deployer.deploy(SafeMath, {from: accounts[0]});
  deployer.link(SafeMath, KittieHELL);
  deployer.link(SafeMath, KittieFIGHTToken);
  deployer.deploy(KittieFIGHTToken, {from: accounts[0]}).then(() => {
    return deployer.deploy(ContractManager, {from: accounts[0]});
  }).then(()=> {
    contractManagerInst = ContractManager.web3.eth.contract(
      ContractManager.abi).at(ContractManager.address);
    return deployer.deploy(KittieHELL, ContractManager.address, {from: accounts[0]})
  }).then(() => {
    return deployer.deploy(KittieFIGHTToken, {from: accounts[0]});
  }).then(() => {
    return promFuncCall(contractManagerInst, 'addContract',
        ['KittieHELL', KittieHELL.address], accounts[0]);
  }).then(() => {
    return promFuncCall(contractManagerInst, 'addContract',
        ['KittieFIGHTToken', KittieFIGHTToken.address], accounts[0]);
  }).then(() => {
    if (network === 'live') {
      return promFuncCall(contractManagerInst, 'addContract',
          ['CryptoKittiesCore', '0x06012c8cf97BEaD5deAe237070F9587f8E7A266d'],
          accounts[0]);
    } else {
      return deployer.deploy(KittyCoreMock, {from: accounts[0]}).then(() => {
        return promFuncCall(contractManagerInst, 'addContract',
            ['CryptoKittiesCore', KittyCoreMock.address], accounts[0]);
      });
    }
  });
};

const promFuncCall = (contInst, funcName, args, account) => {
  return new Promise(
      (resolve, reject) => contInst[funcName].apply(this, args.concat({from: account},
          (error, result) => (error ? reject(error) : resolve(result)))));
};
