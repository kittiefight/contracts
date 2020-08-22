const TimeFrame = artifacts.require("TimeFrame");

//truffle exec scripts/FE/setTimes.js
module.exports = async callback => {
  try {
    let timeFrame = await TimeFrame.deployed();

    await timeFrame.setTimes(350, 30, 30);
    callback();
  } catch (e) {
    callback(e);
  }
};
