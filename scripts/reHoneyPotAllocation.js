const HoneypotAllocationAlgo = artifacts.require('HoneypotAllocationAlgo');
const KFProxy = artifacts.require('KFProxy');

module.exports = async (callback) => {
	try {
		console.log("Starting....");
	    let proxy = await KFProxy.at("0x1b6Eb91a521Ad7C1971F793dccCf20fA55E044AF");
	    console.log(proxy.address);
	  	let honeypotAllocationAlgo = await HoneypotAllocationAlgo.new();
	  	console.log("HoneypotAllocationAlgo deployed...");

	  	console.log(honeypotAllocationAlgo.address);

	  	await proxy.updateContract('HoneypotAllocationAlgo', honeypotAllocationAlgo.address);

	  	console.log("SetProxy...");
	  	await honeypotAllocationAlgo.setProxy(proxy.address);
	  	callback();
    }
    catch(e){callback(e)}
}
