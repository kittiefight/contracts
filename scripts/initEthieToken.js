const EthieToken = artifacts.require('EthieToken');
const KFProxy = artifacts.require('KFProxy');

module.exports = async (callback) => {
	try {
		console.log("Starting....");
	    let proxy = await KFProxy.at("0x89f64cbc0F7C7331e1630B27FF787aD811fFCaa4");
	  	let ethieToken = await EthieToken.at("0xe802C319fc1be0aB27E3f2B8854Aadb73633Fd2a");

	  	console.log(ethieToken.address);

	  	await proxy.addContract('EthieToken', ethieToken.address);
	  	callback();
    }
    catch(e){callback(e)}
}
