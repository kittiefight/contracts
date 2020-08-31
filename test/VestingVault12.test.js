const BigNumber = web3.utils.BN;
require("chai")
  .use(require("chai-shallow-deep-equal"))
  .use(require("chai-bignumber")(BigNumber))
  .use(require("chai-as-promised"))
  .should();

const evm = require("./utils/evm.js");

//ARTIFACTS
const VestingVault12 = artifacts.require("VestingVault12");
const KittieFightToken = artifacts.require("KittieFightToken");

const editJsonFile = require("edit-json-file");
const {assert} = require("chai");
let file;

function timeout(s) {
  // console.log(`~~~ Timeout for ${s} seconds`);
  return new Promise(resolve => setTimeout(resolve, s * 1000));
}

function formatDate(timestamp) {
  let date = new Date(null);
  date.setSeconds(timestamp);
  return date.toTimeString().replace(/.*(\d{2}:\d{2}:\d{2}).*/, "$1");
}

function randomValue(num) {
  return Math.floor(Math.random() * num) + 1; // (1-num) value
}

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

const KTY_AMOUNT = new BigNumber(
  web3.utils.toWei("1000000", "ether") // 1,000,000 KTY
);

const TOKEN_AMOUNT = new BigNumber(
  web3.utils.toWei("1000", "ether") // 10,000 KTY
);

//Contract instances
let vestingVault12, kittieFightToken;

contract("VestingVault12", accounts => {
  it("instantiate contracts", async () => {
    // VestingVault12
    vestingVault12 = await VestingVault12.deployed();
    // TOKENS
    kittieFightToken = await KittieFightToken.deployed();
  });

  it("adds token grant", async () => {
    // approve token before addTokenGrant
    kittieFightToken.approve(vestingVault12.address, KTY_AMOUNT);

    for (let i = 1; i < 6; i++) {
      await vestingVault12.addTokenGrant(
        accounts[i],
        0,
        TOKEN_AMOUNT,
        100 + i * 10,
        10
      ).should.be.fulfilled;
    }

    let newGrants = await vestingVault12.getPastEvents("GrantAdded", {
      fromBlock: 0,
      toBlock: "latest"
    });

    newGrants.map(async e => {
      console.log("\n==== NEW GRANT ADDED ===");
      console.log("    Grant Recipient ", e.returnValues.recipient);
      console.log("    Vesting ID ", e.returnValues.vestingId);
      console.log("========================\n");
    });
  });

  it("an unauthorized person cannot add token grant", async () => {
    kittieFightToken.transfer(accounts[11], TOKEN_AMOUNT);
    kittieFightToken.approve(vestingVault12.address, TOKEN_AMOUNT, {
      from: accounts[11]
    });
    await vestingVault12.addTokenGrant(accounts[2], 0, TOKEN_AMOUNT, 100, 10, { from: accounts[11] })
      .should.be.rejected;
  });

  it("adds another token grant", async () => {
    let timeStart = Math.floor(new Date().getTime() / 1000) + 1000
    await vestingVault12.addTokenGrant(
      accounts[6],
      timeStart,
      TOKEN_AMOUNT,
      100,
      100)
      .should.be.fulfilled;
  })

  it("shows ID of active grants for a recipient", async () => {
    let activeGrants;
    let firstGrant;
    for (let i = 1; i < 6; i++) {
      activeGrants = await vestingVault12.getActiveGrants(accounts[i]);
      firstGrant = activeGrants[0].toNumber();
      assert.equal(firstGrant, i - 1);
    }
  });

  it("calculates Tokens Vested Per Day", async () => {
    let tokensVestedPerDay;
    for (let i = 0; i < 5; i++) {
      tokensVestedPerDay = await vestingVault12.tokensVestedPerDay(i);
      console.log("Grant ID:", i);
      console.log("Tokens Vested Per Day:", weiToEther(tokensVestedPerDay));
    }
  });

  it("calculates grant claim before vesting cliff is over and return 0", async () => {
    let grantClaim;
    for (let i = 0; i < 5; i++) {
      console.log("\n==== Grant Claim Before Vesting Cliff Is Over ===");
      grantClaim = await vestingVault12.calculateGrantClaim(i);
      console.log("grant ID:", i);
      console.log("Vested and unclaimed months:", grantClaim[0].toString());
      console.log("The entire left grant amount:", weiToEther(grantClaim[1]));
      console.log("========================\n");
    }
  });

  it("a grant cannot be claimed before its vesting cliff is over", async () => {
    for (let i = 0; i < 5; i++) {
      await vestingVault12.claimVestedTokens(i).should.be.rejected;
    }
  })

  it("calculates grant claim - after vesting cliff", async () => {
    console.log("During vesting cliff...");
    let advancement = 86400 * 10; // 10 Days
    await advanceTimeAndBlock(advancement);
    console.log("Vesting cliff is over...");
    let grantClaim;
    for (let i = 0; i < 5; i++) {
      console.log("\n==== Grant Claim After Vesting Cliff Is Over ===");
      grantClaim = await vestingVault12.calculateGrantClaim(i);
      console.log("grant ID:", i);
      console.log("Vested and unclaimed months:", grantClaim[0].toString());
      console.log("The entire left grant amount:", weiToEther(grantClaim[1]));
      console.log("========================\n");
    }
  });

  it("recipients can claim vested tokens after vesting cliff is over", async () => {
    for (let i = 0; i < 5; i++) {
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
  });

  it("an unauthorized person cannot terminate a token grant", async () => {
    await vestingVault12.removeTokenGrant(4, { from: accounts[15] }).should.be.rejected
  })

  it("authorized personel can terminate a token grant", async () => {
    await vestingVault12.removeTokenGrant(4).should.be.fulfilled;

    let terminatedGrants = await vestingVault12.getPastEvents("GrantRemoved", {
      fromBlock: "0",
      toBlock: "latest"
    });

    terminatedGrants.map(async e => {
      console.log("\n==== GRANT TOKENS TERMINATED ===");
      console.log("    Grant Recipient ", e.returnValues.recipient);
      console.log("    Amount Vested", weiToEther(e.returnValues.amountVested));
      console.log(
        "    Amount Not Vested",
        weiToEther(e.returnValues.amountNotVested)
      );
      console.log("========================\n");
    });
  });

  it("recipients can claim all left vested tokens after vesting duration is over", async () => {
    let advancement = 86400 * 200; // 200 Days
    await advanceTimeAndBlock(advancement);
    console.log("Vesting duration is over...");
    for (let i = 0; i < 6; i++) {
      if (i == 4) {
        continue;   // grantId 4 has been removed
      }
      await vestingVault12.claimVestedTokens(i).should.be.fulfilled;
    }

    let newGrants = await vestingVault12.getPastEvents("GrantTokensClaimed", {
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
  });

  it("a removed grant cannot be claimed any more", async () => {
    await vestingVault12.claimVestedTokens(4).should.be.rejected;
  });
});
