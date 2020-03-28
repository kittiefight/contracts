/**
 * When you run this test, sets the start time for epoch 0 as less than 3 weeks ago
 * to ensure epoch2 is an active epoch
 * const epoch_0_start = await timeFrame.timestampFromDateTime(
      2020, //year
      3,   //month
      10,  //day
      8,   //hour
      30,  //minute
      30   //second
    ); 
*/ 

const BigNumber = web3.utils.BN;
require("chai")
  .use(require("chai-shallow-deep-equal"))
  .use(require("chai-bignumber")(BigNumber))
  .use(require("chai-as-promised"))
  .should();

const KFProxy = artifacts.require("KFProxy");
const TimeFrame = artifacts.require("TimeFrame");

let proxy, timeFrame;

before(async () => {
  proxy = await KFProxy.deployed();
  timeFrame = await TimeFrame.deployed();

  await timeFrame.setProxy(proxy.address);
});

contract("TimeFrame", accounts => {
  it("sets epoch 0", async () => {
    const epoch_0_start = await timeFrame.timestampFromDateTime(
      2020, //year
      3,   //month
      10,  //day
      8,   //hour
      30,  //minute
      30   //second
    );
    await timeFrame.setEpoch_0(epoch_0_start.toNumber());
    const epoch0StartTime = await timeFrame._epochStartTime(0);
    assert.equal(epoch_0_start.toNumber(), epoch0StartTime);
    const epoch_0_gameDelay = await timeFrame.gamingDelay(0);
    assert.equal(epoch_0_gameDelay.toNumber(), 0);
    const lastEpochID = await timeFrame.getLastEpochID();
    console.log(lastEpochID.toNumber());
  });

  it("sets new epoch", async () => {
    await timeFrame.setNewEpoch();
    const lastEpochID = await timeFrame.getLastEpochID();
    console.log(lastEpochID.toNumber());
    const epoch0EndTime = await timeFrame._epochEndTime(0);
    const epoch1StartTime = await timeFrame._epochStartTime(1);
    assert.equal(epoch1StartTime.toNumber(), epoch0EndTime.toNumber());
    const epoch_1_gameDelay = await timeFrame.gamingDelay(1);
    assert.equal(epoch_1_gameDelay.toNumber(), 0);
  });

  it("sets more new epoch", async () => {
    await timeFrame.setNewEpoch();
    const lastEpochID = await timeFrame.getLastEpochID();
    console.log(lastEpochID.toNumber());
    const epoch1EndTime = await timeFrame._epochEndTime(1);
    const epoch2StartTime = await timeFrame._epochStartTime(2);
    assert.equal(epoch2StartTime.toNumber(), epoch1EndTime.toNumber());
    const epoch_2_gameDelay = await timeFrame.gamingDelay(2);
    assert.equal(epoch_2_gameDelay.toNumber(), 0);
  });

  it("adds gaming delay", async () => {
    const gamingDelay = 300;
    const epoch_2_gameDelay_before = await timeFrame.gamingDelay(2);
    const epoch_2_endTime_before = await timeFrame._epochEndTime(2);
    await timeFrame.addGamingDelayToEpoch(2, gamingDelay);

    const epoch_2_gameDelay_after = await timeFrame.gamingDelay(2);
    assert.equal(
      epoch_2_gameDelay_after.toNumber(),
      epoch_2_gameDelay_before.toNumber() + gamingDelay
    );
    const epoch_2_endTime_after = await timeFrame._epochEndTime(2);
    assert.equal(
      epoch_2_endTime_after.toNumber(),
      epoch_2_endTime_before.toNumber() + gamingDelay
    );
  });

  it("gets the end time of an epoch in both unix time and human-readable format", async () => {
    let startTimeUnix,
      startTimeHumanReadable,
      endTimeUnix,
      endTimeHumanReadable;
    for (let i = 0; i < 3; i++) {
      startTimeUnix = await timeFrame._epochStartTime(i);
      startTimeHumanReadable = await timeFrame.epochStartTime(i);

      console.log(`********************* Epoch ${i} *******************`);
      console.log("===========Epoch Start Time in Unix time=========");
      console.log(startTimeUnix.toNumber());
      console.log(
        "===========Epoch Start Time in Human Readable Format========="
      );
      console.log(
        "year:",
        startTimeHumanReadable[0].toNumber(),
        " month:",
        startTimeHumanReadable[1].toNumber(),
        " day:",
        startTimeHumanReadable[2].toNumber(),
        "hour:",
        startTimeHumanReadable[3].toNumber(),
        " minute:",
        startTimeHumanReadable[4].toNumber(),
        " second",
        startTimeHumanReadable[5].toNumber()
      );
      
      endTimeUnix = await timeFrame._epochEndTime(i);
      endTimeHumanReadable = await timeFrame.epochEndTime(i);

      console.log("===========Epoch End Time in Unix time=========");
      console.log(endTimeUnix.toNumber());
      console.log(
        "===========Epoch End Time in Human Readable Format========="
      );
      console.log(
        "year:",
        endTimeHumanReadable[0].toNumber(),
        " month:",
        endTimeHumanReadable[1].toNumber(),
        " day:",
        endTimeHumanReadable[2].toNumber(),
        "hour:",
        endTimeHumanReadable[3].toNumber(),
        " minute:",
        endTimeHumanReadable[4].toNumber(),
        " second",
        endTimeHumanReadable[5].toNumber()
      );
    }
  });

  it("checks if an epoch is active", async () => {
    const isEpoch1Active = await timeFrame.isEpochActive(1)
    assert.isFalse(isEpoch1Active)
    const isEpoch2Active = await timeFrame.isEpochActive(2)
    assert.isTrue(isEpoch2Active)
  });

  it("shows which epoch is active", async () => {
      const activeEpochID = await timeFrame.getActiveEpochID()
      assert.equal(activeEpochID.toNumber(), 2)
  })

  it ("determines the legit time during which a new game can start", async () => {
      const canGameStart1 = await timeFrame.canStartNewGame(1)
      assert.isFalse(canGameStart1)
      const canGameStart2 = await timeFrame.canStartNewGame(2)
      assert.isTrue(canGameStart2)
  })

  it ("shows whether an epoch has started or ended", async () => {
      const hasStarted1 = await timeFrame.hasEpochStarted(1)
      assert.isTrue(hasStarted1)
      const hasEnded1 = await timeFrame.hasEpochEnded(1)
      assert.isTrue(hasEnded1)
      const hasStarted2 = await timeFrame.hasEpochStarted(2)
      assert.isTrue(hasStarted2)
      const hasEnded2 = await timeFrame.hasEpochEnded(2)
      assert.isFalse(hasEnded2)
  })

  it ("shows time elapsed since epoch start", async () => {
      let timeElapsed
      for (let i=0; i<3; i++) {
          timeElapsed = await timeFrame.elapsedSinceEpochStart(i)
          console.log(`********************* Epoch ${i} : time(seconds) elapsed since start *******************`)
          console.log(timeElapsed.toNumber())
      }
  })

  it ("shows time left to the end of an epoch, if not ended", async () => {
      const timeUntilEnd = await timeFrame.timeUntilEpochEnd(2)
      console.log(`********************* Epoch 2 : time(seconds) left until end *******************`)
      console.log(timeUntilEnd.toNumber())
  })

  it("shows whether now is on working days or rest day of an epoch", async () => {
      const isWorkingDay = await timeFrame.isWorkingDay(2)
      assert.isTrue(isWorkingDay)
      const isRestDay = await timeFrame.isRestDay(2)
      assert.isFalse(isRestDay)
  })

  it("shows the entire length of an epoch", async () => {
      let lengthEpoch
      for (let i=0; i<3; i++) {
          lengthEpoch = await timeFrame.epochLength(i)
          console.log(`********************* Epoch ${i} : entire length (in seconds) *******************`)
          console.log(lengthEpoch.toNumber())    
      }
  })
});
