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
        {"name":'TimeContract', "contract":"DateTime"},
        {"name":'GenericDB'},
        {"name":'KittieFightToken'},
        {"name":'ProfileDB'},
        {"name":'RoleDB'},
        {"name":'Register'},
        {"name":'TimeFrame'},
        {"name":'GameVarAndFee'},
        {"name":'EndowmentFund'},
        {"name":'EndowmentDB'},
        {"name":'Forfeiter'},
        {"name":'Scheduler'},
        {"name":'Betting'},
        {"name":'HitsResolve'},
        {"name":'RarityCalculator'},
        {"name":'GMSetterDB'},
        {"name":'GMGetterDB'},
        {"name":'GameManager'},
        {"name":'GameStore'},
        {"name":'GameCreation'},
        {"name":'CronJob'},
        {"name":'FreezeInfo'},
        {"name":'CronJobTarget'},
        {"name":'KittieHell'},
        {"name":'KittieHellDB'},
        {"name":'HoneypotAllocationAlgo'},
        {"name":'EarningsTracker'},
        {"name":'WithdrawPool'},
        {"name":'EthieToken'},
        {"name":'CryptoKitties', "contract":"MockERC721Token"},
        {"name":'SuperDAOToken', "contract":"MockERC20Token"},

	]
}();
