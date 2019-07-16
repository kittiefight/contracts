exports.mineBlock = (web3, reject, resolve) => {
  web3.currentProvider.send({
    method: "evm_mine",
    jsonrpc: "2.0",
    id: new Date().getTime()
  }, (e) => (e ? reject(e) : resolve()));
};

exports.increaseTime = (web3, increase) => {
  return new Promise((resolve, reject) => {
    web3.currentProvider.send({
      method: "evm_increaseTime",
      params: [increase],
      jsonrpc: "2.0",
      id: new Date().getTime()
    }, (e) => (e ? reject(e) : this.mineBlock(web3, reject, resolve)))
  });
};

exports.getCurrentTimestamp = () => {
  return web3.eth.getBlock('latest').timestamp;
};
