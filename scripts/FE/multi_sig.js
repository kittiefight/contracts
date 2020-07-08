const KFProxy = artifacts.require("KFProxy");
const EndowmentFund = artifacts.require("EndowmentFund");
const Escrow = artifacts.require("Escrow");
const KittieFightToken = artifacts.require("KittieFightToken");
const MultiSig = artifacts.require("MultiSig");

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

//truffle exec scripts/FE/uniswap_setup.js

module.exports = async callback => {
  try {
    accounts = await web3.eth.getAccounts();

    let proxy = await KFProxy.deployed();
    let endowmentFund = await EndowmentFund.deployed();
    let escrow = await Escrow.deployed();
    let kittieFightToken = await KittieFightToken.deployed();
    let multiSig = await MultiSig.deployed();

    for (let i = 0; i < 6; i++) {
        let team_member = await multiSig.team.call(i)
        console.log('team member',i, ":", team_member)
    }

    for (let j = 0; j < 6; j++) {
        let otherOrg_member = await multiSig.otherOrg.call(j)
        console.log('other organization member',j, ":", otherOrg_member)
    }

    let requiredTeam = await multiSig.requiredTeam.call()
    console.log("required number of approvals from team:", requiredTeam.toString())

    let requiredOtherOrg = await multiSig.requiredOtherOrg.call()
    console.log("required number of approvals from other organizations:", requiredOtherOrg.toString())

    console.log('\n================== Before multiSig.sign() ==================')

    let countTeam = await multiSig.countTeam.call()
    console.log("number of approvals from team:", countTeam.toString())

    let countOtherOrg = await multiSig.countOtherOrg.call()
    console.log("number of approvals from other organizations:", countOtherOrg.toString())

    let isConfirmed = await multiSig.isConfirmed()
    console.log("Confirmed?", isConfirmed)

    console.log('\nUpgrading Escrow fails');
    await endowmentFund.initUpgradeEscrow(escrow.address).should.be.rejected;

    for (let i = 0; i < 3; i++) {
        await proxy.execute(
            "MultiSig",
            setMessage(multiSig, "sign", []),
            {
              from: accounts[i]
            }
          )
    }

    for (let j = 10; j < 12; j++) {
        await proxy.execute(
            "MultiSig",
            setMessage(multiSig, "sign", []),
            {
              from: accounts[j]
            }
          )
    }

    console.log('\n================== After multiSig.sign() && before transfering funds  ==================')

    countTeam = await multiSig.countTeam.call()
    console.log("number of approvals from the team:", countTeam.toString())

    countOtherOrg = await multiSig.countOtherOrg.call()
    console.log("number of approvals from the other organization:", countOtherOrg.toString())

    isConfirmed = await multiSig.isConfirmed()
    console.log("Confirmed?", isConfirmed)

    console.log('\nUpgrading Escrow...');
    await endowmentFund.initUpgradeEscrow(escrow.address)

    console.log('\n================== After transfering funds  ==================')
    countTeam = await multiSig.countTeam.call()
    console.log("number of approvals from the team:", countTeam.toString())

    countOtherOrg = await multiSig.countOtherOrg.call()
    console.log("number of approvals from the other organization:", countOtherOrg.toString())

    isConfirmed = await multiSig.isConfirmed()
    console.log("Confirmed?", isConfirmed)

    callback();
  } catch (e) {
    callback(e);
  }
};
