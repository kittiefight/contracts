const BigNumber = web3.utils.BN;
require("chai")
  .use(require("chai-shallow-deep-equal"))
  .use(require("chai-bignumber")(BigNumber))
  .use(require("chai-as-promised"))
  .should();

function weiToEther(w) {
  // let eth = web3.utils.fromWei(w.toString(), "ether");
  // return Math.round(parseFloat(eth));
  return web3.utils.fromWei(w.toString(), "ether");
}

advanceTime = time => {
  return new Promise((resolve, reject) => {
    web3.currentProvider.send(
      {
        jsonrpc: "2.0",
        method: "evm_increaseTime",
        params: [time],
        id: new Date().getTime()
      },
      (err, result) => {
        if (err) {
          return reject(err);
        }
        return resolve(result);
      }
    );
  });
};

advanceBlock = () => {
  return new Promise((resolve, reject) => {
    web3.currentProvider.send(
      {
        jsonrpc: "2.0",
        method: "evm_mine",
        id: new Date().getTime()
      },
      (err, result) => {
        if (err) {
          return reject(err);
        }
        const newBlockHash = web3.eth.getBlock("latest").hash;

        return resolve(newBlockHash);
      }
    );
  });
};

advanceTimeAndBlock = async time => {
  await advanceTime(time);
  await advanceBlock();
  return Promise.resolve(web3.eth.getBlock("latest"));
};

const VestingVault12 = artifacts.require("VestingVault12");

//truffle exec scripts/FE/vesting/claimVestedTokens.js noOfGrants(uint)

module.exports = async callback => {
  try {
    let vestingVault12 = await VestingVault12.deployed();

    accounts = await web3.eth.getAccounts();

    //Changed
    let amount = process.argv[4];

    // claim vested tokens after vesting cliff is over
    console.log("During vesting cliff...");
    let advancement = 86400 * 10; // 10 Days
    await advanceTimeAndBlock(advancement);
    console.log("Vesting cliff is over...");

    for (let i = 0; i < amount; i++) {
      await vestingVault12.claimVestedTokens(i).should.be.fulfilled;
    }

    let newGrants = await vestingVault12.getPastEvents("GrantTokensClaimed", {
      fromBlock: 0,
      toBlock: "latest"
    });

    newGrants.map(async e => {
      console.log("\n==== GRANT TOKENS CLAIMED ===");
      console.log("    Grant Recipient ", e.returnValues.recipient);
      console.log(
        "    Grant Claimed",
        weiToEther(e.returnValues.amountClaimed)
      );
      console.log("========================\n");
    });

    // recipients can claim all left vested tokens after vesting duration is over
    advancement = 86400 * 200; // 200 Days
    await advanceTimeAndBlock(advancement);
    console.log("Vesting duration is over...");
    for (let i = 0; i < amount; i++) {
      await vestingVault12.claimVestedTokens(i).should.be.fulfilled;
    }

    newGrants = await vestingVault12.getPastEvents("GrantTokensClaimed", {
      fromBlock: "0",
      toBlock: "latest"
    });

    let n = newGrants.length;

    let latestGrants = newGrants.slice(n - 5, n);

    latestGrants.map(async e => {
      console.log("\n==== GRANT TOKENS CLAIMED ===");
      console.log("    Grant Recipient ", e.returnValues.recipient);
      console.log(
        "    Grant Claimed",
        weiToEther(e.returnValues.amountClaimed)
      );
      console.log("========================\n");
    });

    callback();
  } catch (e) {
    callback(e);
  }
};
