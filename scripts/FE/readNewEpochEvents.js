const TimeFrame = artifacts.require("TimeFrame");

function formatDate(timestamp) {
  let date = new Date(null);
  date.setSeconds(timestamp);
  return date.toTimeString().replace(/.*(\d{2}:\d{2}:\d{2}).*/, "$1");
}

//truffle exec scripts/FE/setNewEpoch.js

module.exports = async (callback) => {    

  try{
    let timeFrame = await TimeFrame.deployed();

    accounts = await web3.eth.getAccounts();    
    let epochEvents = await timeFrame.getPastEvents('NewEpochSet', {
      fromBlock: 0,
      toBlock: "latest"
    })

    for(i = 0; i < epochEvents.length; i++) {
      let epochDetails = epochEvents[i].returnValues;
      console.log(`\n==== NEW EPOCH ====`);
      console.log(' ID:', epochDetails.newEpochId);
      console.log(' RestDayStart:', formatDate(epochDetails.newEpochStartTime));
    }

    const epochID = await timeFrame.getActiveEpochID();
    console.log(epochID.toString());
    callback()
  }
  catch(e){
    callback(e)
  }
}
