const MockStaking = artifacts.require('MockStaking');
const KFProxy = artifacts.require('KFProxy');
const MockERC20Token = artifacts.require('MockERC20Token');
const WithdrawPool =  artifacts.require('WithdrawPool');

module.exports = async (callback) => {
	try {
		console.log("Starting....");
	    let proxy = await KFProxy.at("0x89f64cbc0F7C7331e1630B27FF787aD811fFCaa4");
	    let mockERC20Token = await MockERC20Token.at("0x753c306d0B9ea5D4bCAE59A91d9CAb9D98c6402D");
	  	let mockStaking = await MockStaking.new();
	  	console.log("MockStaking deployed...");

	  	mockStaking.initialize(mockERC20Token.address);
	  	console.log(mockStaking.address);

	  	callback();
    }
    catch(e){callback(e)}
}
