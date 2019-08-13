window.contractSettings = function() {
	return [
		//KFProxy and it's dependencies
		{"name":"KFProxy"},
		{"name":"GenericDB"},
		{"name":"FreezeInfo"},
		{
			"name":"CronJob",
			"deployArgs":["${KFPoxy.options.address}"],
			"setupActions":[
				{
					"contract":"KFProxy",
					"function":"addContract"
				}
			]
		},
		//Other system contract
		{"name":"RoleDB"},
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
		//{"name":"ProxiedTest"},
		//{"name":"CronJobTarget"},





	]
}();
