window.contractSettings = function() {
	/**
	 * == Default setup actions ==
	 * A set of default actions will be applied to a newly deployed contract
	 * if there is no property "setupActions". If there is such property, 
	 * default actions will not be applied, instead a list of specified actions will be executed.
	 * All actions have one argument: contract name.
	 * - addToProxy - adds/updates address of the contract in KFProxy;
	 * - setProxy	- calls setProxy() method on a contract, if it has it;
	 * - initialize - calls initialize() method on a contract if it has it;
	 *   //NOT implemented - initializeDeps - calls initialize() method on all contracts which specify this contract as their dependecy
	 */

	return [
		//KFProxy and it's dependencies
		{"name":"KFProxy"},
		{"name":"GenericDB"},
		{"name":"FreezeInfo"},
		{
			"name":"CronJob",
			"deployArgs":["${KFPoxy.options.address}"],
		},
		//Other system contract
		{"name":"RoleDB", "deployArgs":["${GenericDB.options.address}"],},
		{"name":"ProfileDB"},
		{"name":"GMSetterDB"},
		{"name":"GMGetterDB"},
		{"name":"GameManager"},
		{"name":"GameStore"},
		{"name":"GameCreation"},
		{"name":"GameVarAndFee"},
		{"name":"Forfeiter"},
		{"name":"DateTime"},
		{"name":"Scheduler"},
		{"name":"Betting"},
		{"name":"HitsResolve"},
		{"name":"RarityCalculator"},
		{"name":"Register"},
		{"name":"EndowmentFund"},
		{"name":"EndowmentDB"},
		{"name":"Escrow"},
		{"name":"KittieHell"},
		{"name":"KittieHellDB"},
		{"name":"SuperDaoToken", "contract":"MockERC20Token"},
		{"name":"KittieFightToken"},
		{"name":"CryptoKitties", "contract":"MockERC721Token"},

		//Tests
		{"name":"ProxiedTest"},
		{"name":"CronJobTarget"},





	]
}();
