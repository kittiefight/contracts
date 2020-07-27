const KFProxy = artifacts.require("KFProxy");
const Register = artifacts.require("Register");
const RoleDB = artifacts.require("RoleDB");

const BigNumber = web3.utils.BN;

require("chai")
  .use(require("chai-shallow-deep-equal"))
  .use(require("chai-bignumber")(BigNumber))
  .use(require("chai-as-promised"))
  .should();

function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find(f => {
      return f.name == funcName;
    }),
    argArray
  );
}

function timeout(s) {
  // console.log(`~~~ Timeout for ${s} seconds`);
  return new Promise(resolve => setTimeout(resolve, s * 1000));
}

function weiToEther(w) {
  //let eth = web3.utils.fromWei(w.toString(), "ether");
  //return Math.round(parseFloat(eth));
  return web3.utils.fromWei(w.toString(), "ether");
}

//truffle exec scripts/FE/multi_sig.js

module.exports = async callback => {
  try {
    accounts = await web3.eth.getAccounts();

    let register = await Register.deployed();
    let roleDB = await RoleDB.deployed();

    let isSuperAdmin0 = await roleDB.hasRole("super_admin", accounts[0])
    console.log("Is accounts[0] super admin?", isSuperAdmin0)

    let isSuperAdmin20 = await roleDB.hasRole("super_admin", accounts[20])
    console.log("Is accounts[20] super admin?", isSuperAdmin20)

    // request moveSuperAdmin
    await register.moveSuperAdmin(accounts[20]).should.be.fulfilled;

    let newRequestEvents = await register.getPastEvents(
      "RoleMoveRequestCreated",
      {
        fromBlock: 0,
        toBlock: "latest"
      }
    );

    newRequestEvents.map(async e => {
      console.log("\n==== NEW Request CREATED ===");
      console.log("    id ", e.returnValues.id);
      console.log("    creator ", e.returnValues.creator);
      console.log("    from ", e.returnValues.from);
      console.log("    to ", e.returnValues.to);
      console.log("    deadline ", e.returnValues.deadline);
      console.log("========================\n");
    });

    let totalRequests = await register.totalRoleMoveRequests.call();
    console.log("Total role move requests:", totalRequests.toString())

    for (let i = 1; i < 3; i++) {
      await register.addAdmin(accounts[i]);
    }

    // signRoleMoveRequest

    for (let i = 0; i < 3; i++) {
      await register.signRoleMoveRequest(0, { from: accounts[i] });
    }

    let newSignEvents = await register.getPastEvents("RoleMoveRequestSigned", {
      fromBlock: 0,
      toBlock: "latest"
    });

    newSignEvents.map(async e => {
      console.log("\n==== NEW Request SIGNED ===");
      console.log("    id ", e.returnValues.id);
      console.log("    signer ", e.returnValues.signer);
      console.log("========================\n");
    });

    let newExecutedEvents = await register.getPastEvents(
      "RoleMoveRequestExecuted",
      {
        fromBlock: 0,
        toBlock: "latest"
      }
    );

    newExecutedEvents.map(async e => {
      console.log("\n==== NEW Request EXECUTED ===");
      console.log("    id ", e.returnValues.id);
      console.log("========================\n");
    });

    isSuperAdmin0 = await roleDB.hasRole("super_admin", accounts[0])
    console.log("Is accounts[0] super admin?", isSuperAdmin0)

    isSuperAdmin20 = await roleDB.hasRole("super_admin", accounts[20])
    console.log("Is accounts[20] super admin?", isSuperAdmin20)

    callback();
  } catch (e) {
    callback(e);
  }
};
