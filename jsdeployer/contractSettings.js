window.contractSettings = function() {
	return [
		{
			"name":"KFProxy",
		},
		{
			"name":"GenericDB",
		},
		{
			"name":"FreezeInfo",
		},
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
		{
			"name":"GMGetterDB",
			"deployArgs":["${KFPoxy.options.address}"],
			"setupActions":[
				{
					"contract":"KFProxy",
					"function":"addContract"
				}
			]
		},
		{
			"name":"ProxiedTest",
		},
		{
			"name":"GameManager",
		},





	]
}();
