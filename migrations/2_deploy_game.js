const DateTime = artifacts.require("DateTime");
const ContractManager = artifacts.require("ContractManager");

module.exports = (deployer, network, accounts) => {
  let contractManagerInst;

  deployer
    .deploy(ContractManager, { from: accounts[0] })
    .then(() => {
      contractManagerInst = new ContractManager.web3.eth.contract(
        ContractManager.abi
      ).at(ContractManager.address);
      return deployer.deploy(DateTime, ContractManager.address, {
        from: accounts[0]
      });
    })
    .then(() => {
      return promFuncCall(
        contractManagerInst,
        "addContract",
        ["DateTime", DateTime.address],
        accounts[0]
      );
    });
};

const promFuncCall = (contInst, funcName, args, account) => {
  return new Promise((resolve, reject) =>
    contInst[funcName].apply(
      this,
      args.concat({ from: account }, (error, result) =>
        error ? reject(error) : resolve(result)
      )
    )
  );
};
