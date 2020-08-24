const Scheduler = artifacts.require("Scheduler");

// truffle exec scripts/FE/changeMode.js
module.exports = async callback => {
  try {
    scheduler = await Scheduler.deployed();
    await scheduler.changeMode();

    callback();
  } catch (e) {
    callback(e);
  }
};
