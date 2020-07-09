const KFProxy = artifacts.require("KFProxy");
const EndowmentFund = artifacts.require("EndowmentFund");
const Escrow = artifacts.require("Escrow");
const KittieFightToken = artifacts.require("KittieFightToken");
const MultiSig = artifacts.require("Multisig5of12");

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

//truffle exec scripts/FE/multi_sig.js

module.exports = async callback => {
  try {
    accounts = await web3.eth.getAccounts();

    let proxy = await KFProxy.deployed();
    let endowmentFund = await EndowmentFund.deployed();
    let escrow = await Escrow.deployed();
    let kittieFightToken = await KittieFightToken.deployed();
    let multiSig = await MultiSig.deployed();

    let requiredSigKittieFight = await multiSig.requiredSigKittieFight.call();
    console.log(
      "required number of approvals from team:",
      requiredSigKittieFight.toString()
    );

    let requiredSigExternal = await multiSig.requiredSigExternal.call();
    console.log(
      "required number of approvals from other organizations:",
      requiredSigExternal.toString()
    );

    console.log("\n================== Sign up... ==================");

    let organization, name;
    for (let i = 0; i < 8; i++) {
      organization = "kittieFight";
      name = "name" + i;
      await proxy.execute(
        "Multisig5of12",
        setMessage(multiSig, "signup", [name, organization]),
        {from: accounts[i]}
      );
    }
    for (let i = 8; i < 12; i++) {
      organization = "decentralizedInc";
      name = "name" + i;
      await proxy.execute(
        "Multisig5of12",
        setMessage(multiSig, "signup", [name, organization]),
        {from: accounts[i]}
      );
    }
    for (let i = 12; i < 16; i++) {
      organization = "blockchainCity";
      name = "name" + i;
      await proxy.execute(
        "Multisig5of12",
        setMessage(multiSig, "signup", [name, organization]),
        {from: accounts[i]}
      );
    }

    console.log("\n================== Approve signers... ==================");
    for (let i = 1; i < 7; i++) {
      organization = "kittieFight";
      await proxy.execute(
        "Multisig5of12",
        setMessage(multiSig, "approveSigner", [accounts[i], organization])
      );
    }

    for (let i = 8; i < 11; i++) {
      organization = "decentralizedInc";
      await proxy.execute(
        "Multisig5of12",
        setMessage(multiSig, "approveSigner", [accounts[i], organization])
      );
    }

    for (let i = 12; i < 15; i++) {
      organization = "blockchainCity";
      await proxy.execute(
        "Multisig5of12",
        setMessage(multiSig, "approveSigner", [accounts[i], organization])
      );
    }

    let allSigners = await multiSig.getSigners();
    let allKittieFightSigners = await multiSig.getSignersKittieFight();
    let allExternalSigners = await multiSig.getSignersExternal();

    console.log("All approved signers:", allSigners);
    console.log("All approved kittieFight signers:", allKittieFightSigners);
    console.log("All approved external signers:", allExternalSigners);

    console.log("\nUpgrading Escrow fails before signers approve the transfer");
    await endowmentFund.initUpgradeEscrow(escrow.address, 1).should.be.rejected;

    console.log(
      "\n================== Signers approve transfers... =================="
    );

    for (let i = 1; i < 4; i++) {
      await proxy.execute(
        "Multisig5of12",
        setMessage(multiSig, "approveTransfer", [1, escrow.address]),
        {from: accounts[i]}
      );
    }

    await proxy.execute(
      "Multisig5of12",
      setMessage(multiSig, "approveTransfer", [1, escrow.address]),
      {from: accounts[8]}
    );

    console.log("\nAn un-approved signer cannot approve a transfer");
    await proxy.execute(
      "Multisig5of12",
      setMessage(multiSig, "approveTransfer", [1, escrow.address]),
      {from: accounts[7]}
    ).should.be.rejected;

    console.log("\nAn approved signer cannot approve a transfer more than once");
    await proxy.execute(
      "Multisig5of12",
      setMessage(multiSig, "approveTransfer", [1, escrow.address]),
      {from: accounts[8]}
    ).should.be.rejected;

    console.log(
      "\n================== Before numbers of approvals meeting the required signatures =================="
    );

    console.log(
      "\nUpgrading Escrow fails before numbers of approvals meeting the required signatures"
    );
    await endowmentFund.initUpgradeEscrow(escrow.address, 1).should.be.rejected;

    await proxy.execute(
      "Multisig5of12",
      setMessage(multiSig, "approveTransfer", [1, escrow.address]),
      {from: accounts[12]}
    );

    console.log(
      "\n================== Required Signatures are met =================="
    );

    console.log(
      "\nUpgrading Escrow fails if new escrow address is not the approved one"
    );
    await endowmentFund.initUpgradeEscrow(kittieFightToken.address, 1).should.be
      .rejected;

    console.log(
      "\nUpgrading Escrow fails if transferNumber is not the approved one"
    );
    await endowmentFund.initUpgradeEscrow(escrow.address, 3).should.be.rejected;

    console.log(
      "\nUpgrading Escrow fails if it is not called by superAdmin"
    );
    await endowmentFund.initUpgradeEscrow(escrow.address, 1, { from: accounts[10] }).should.be.rejected;

    console.log("\nUpgrading Escrow...only when all is correct");
    await endowmentFund.initUpgradeEscrow(escrow.address, 1);

    callback();
  } catch (e) {
    callback(e);
  }
};
