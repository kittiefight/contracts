const TimeFrame = artifacts.require('TimeFrame');

module.exports = async (callback) => {
	try {
		console.log("Starting....");
	    let timeFrame = await TimeFrame.at("0xc8C95099515eB228641B5D7eF0e4635b9651b7C4");
	    let checkEpoch = await timeFrame.lifeTimeEpochs(0);
	    console.log(checkEpoch);
	  	callback();
    }
    catch(e){callback(e)}
}
