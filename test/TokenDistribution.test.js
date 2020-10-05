const BigNumber = web3.utils.BN;
require("chai")
  .use(require("chai-shallow-deep-equal"))
  .use(require("chai-bignumber")(BigNumber))
  .use(require("chai-as-promised"))
  .should();

//ARTIFACTS
const TokenDistribution = artifacts.require("TokenDistribution");
const KittieFightToken = artifacts.require("KittieFightToken");

const {assert} = require("chai");

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

//Contract instances
let tokenDistribution, kittieFightToken;

contract("TokenDistribution", accounts => {
  it("instantiate contracts", async () => {
    // TokenDistribution
    tokenDistribution = await TokenDistribution.deployed();
    // TOKENS
    kittieFightToken = await KittieFightToken.deployed();
  });

  it("initialize tokenDistribution contract", async () => {
    let investors = [], ethAmounts = [], eth_amount;
    let percentBonus = new BigNumber(
      web3.utils.toWei("1000", "ether") // 1000%
    );

    for (let i = 1; i < 11; i++) {
      eth_amount = new BigNumber(
        web3.utils.toWei(randomValue(20).toString(), "ether")
      );
      investors.push(accounts[i]);
      ethAmounts.push(eth_amount);
    }

    for (let i = 1; i < 9; i++) {
        eth_amount = new BigNumber(
          web3.utils.toWei(randomValue(10).toString(), "ether")
        );
        investors.push(accounts[i]);
        ethAmounts.push(eth_amount);
      }

      for (let i = 8; i < 19; i++) {
        eth_amount = new BigNumber(
          web3.utils.toWei(randomValue(15).toString(), "ether")
        );
        investors.push(accounts[i]);
        ethAmounts.push(eth_amount);
      }

    await tokenDistribution.initialize(
      investors,
      ethAmounts,
      kittieFightToken.address,
      Math.floor(new Date().getTime() / 1000) + 3 * 24 * 60 * 60, // withdraw after 3 days
      percentBonus
    ).should.be.fulfilled;

    let token_bonus = new BigNumber(
        web3.utils.toWei("5000000", "ether") // 5 million
      );

    await kittieFightToken.transfer(tokenDistribution.address, token_bonus)
  });

  it("imports investmet lists", async () => {
      let investmentInfo;
      for (let i = 1; i < 11; i++) {
          investmentInfo = await tokenDistribution.getInvestment(i)
          console.log("Investment ID:", i)
          console.log("Investor:", investmentInfo[0])
          console.log("Ether invested:", weiToEther(investmentInfo[1]))
          console.log("Has bonus been claimed from this investment?", investmentInfo[2])
      }
  })

  it("sets percentage bonus and withdraw date", async () => {
      let percentBonus = await tokenDistribution.percentBonus.call()
      console.log("Percentage Bonus:", weiToEther(percentBonus))
      let withdrawDate = await tokenDistribution.withdrawDate.call()
      console.log("Withdraw date:", withdrawDate.toString())
  })

  it("an investor cannot withdraw before withdraw date", async () => {
      let canWithdraw = await tokenDistribution.canWithdraw()
      console.log("Can withdraw?", canWithdraw[0])
      console.log("Time until withdraw:", canWithdraw[1].toString())
      for (let i=1; i<11; i++) {
        await tokenDistribution.withdraw({from: accounts[i]}).should.be.rejected;
      } 
  })

  it("an investor can withdraw after withdraw date", async () => {
    let canWithdraw = await tokenDistribution.canWithdraw()
    console.log("Can withdraw?", canWithdraw[0])
    let timeTillWithdraw = Number(canWithdraw[1].toString())
    console.log("Time until withdraw:", timeTillWithdraw)
    if (timeTillWithdraw > 0) {
        await advanceTimeAndBlock(timeTillWithdraw+180);
        console.log("Time flies...")
    }
    canWithdraw = await tokenDistribution.canWithdraw()
    console.log("Can withdraw?", canWithdraw[0])
  
      let investor = accounts[1], investmentIDs, ethAmount, bonus
      // get all investments belonging to this investor
      investmentIDs = await tokenDistribution.getInvestmentIDs(investor);
      for (let i=0; i<investmentIDs.length; i++) {
          console.log("Investment ID:", investmentIDs[i].toString())
          ethAmount = await tokenDistribution.getInvestment(Number(investmentIDs[i].toString()))
          console.log("Ether invested:", weiToEther(ethAmount[1]))
          eth_amount = new BigNumber(
            web3.utils.toWei(weiToEther(ethAmount[1]), "ether")
          );
          bonus = await tokenDistribution.calculateBonus(eth_amount)
          console.log("Token Bonus calculated:", weiToEther(bonus))
          await tokenDistribution.withdraw(Number(investmentIDs[i].toString()), { from: investor }).should.be.fulfilled;
      }

      let newWithdraw = await tokenDistribution.getPastEvents("WithDrawn", {
        fromBlock: 0,
        toBlock: "latest"
      });
  
      newWithdraw.map(async (e) => {
        console.log('\n==== NEW WITHDRAW HAPPENED ===');
        console.log('    Investor ', e.returnValues.investor)
        console.log('    InvestmentID ', e.returnValues.investmentID)
        console.log('    Bonus ', weiToEther(e.returnValues.bonus))
        console.log('    WithdrawTime ', e.returnValues.withdrawTime)
        console.log('========================\n')
      })
  })

  it("transfers leftover rewards to a new address", async () => {
    let advancement = 10 * 24 * 60 * 60;
    await advanceTimeAndBlock(advancement);

    let KTY_bal = await kittieFightToken.balanceOf(tokenDistribution.address);
    console.log(
      "Final KTY balance in YieldFarming contract:",
      weiToEther(KTY_bal)
    );
   
  });
});
