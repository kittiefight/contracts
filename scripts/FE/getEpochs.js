const TimeFrame = artifacts.require("TimeFrame");

function formatDate(timestamp) {
  let date = new Date(null);
  date.setSeconds(timestamp);
  return date.toTimeString().replace(/.*(\d{2}:\d{2}:\d{2}).*/, "$1");
}

//truffle exec scripts/FE/getEpochs.js
module.exports = async callback => {
  try {
    let timeFrame = await TimeFrame.deployed();

    let newEpochEvents = await timeFrame.getPastEvents("NewEpochSet", {
      fromBlock: 0,
      toBlock: "latest"
    });

    for (let i = 0; i < newEpochEvents.length; i++) {
      let epochDetails = newEpochEvents[i].returnValues;
      let restDayStart = await timeFrame.restDayStartTime();
      let restDayEnd = await timeFrame.restDayEndTime();
      console.log(`\n==== NEW EPOCH with id ${epochDetails.newEpochId} ====`);
      console.log(
        "WorkingDayStartTime: ",
        formatDate(epochDetails.newEpochStartTime)
      );
      console.log("   RestDayStartTime: ", formatDate(restDayStart));
      console.log("     RestDayEndTime: ", formatDate(restDayEnd));
    }
    callback();
  } catch (e) {
    callback(e);
  }
};
