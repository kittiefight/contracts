const TimeFrame = artifacts.require('TimeFrame');
const EarningsTracker = artifacts.require('EarningsTracker');

module.exports = async (callback) => {
	try {
		console.log("Starting....");
	    let timeFrame = await TimeFrame.at("0xc8C95099515eB228641B5D7eF0e4635b9651b7C4");
	    let earningsTracker = await EarningsTracker.at("0x03d5f19ed6c697031562c6a4741395eec4764e23");
	    let checkEpoch = await timeFrame.lifeTimeEpochs(2);
	    let total = await earningsTracker.calculateTotal(web3.utils.toWei("20"), 0);
	    console.log(checkEpoch);
	    console.log(web3.utils.fromWei(total.toString()));

	  	callback();
    }
    catch(e){callback(e)}
}
