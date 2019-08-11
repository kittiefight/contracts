var $ = jQuery;
jQuery(document).ready(function($) {
    const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

    let web3 = null;
    let contractDefinitions = {};
    let contractInstances = {};


    setTimeout(init, 1000);
    async function init(){
        web3 = await loadWeb3();
        if(web3 == null) {
            setTimeout(init, 5000);
            return;
        }
        // Load contracts 
        let loaders = [];
        for(let contract of window.contractSettings){
            let contractFile = (typeof contract.contract != 'undefined')?contract.contract:contract.name;
            let loader = loadContract(`../build/contracts/${contractFile}.json`);
            loader.then(function(data){
                contractDefinitions[contract.name] = {
                   'name': contract.name,
                   'abi': data.abi
                }
                console.log(`Loaded ABI for ${contract.name}`);
                let address = getUrlParam(contract.name);
                if(web3.utils.isAddress(address)){
                   contractInstances[contract.name] = new web3.eth.Contract(data.abi, address);
                    console.log(`Instance of ${contract.name} loaded at ${address}`);
                }
            });
            loaders.push(loader);
        }
        Promise.all(loaders).then(initForm);

    }
    function initForm(){
        if(contractInstances.KFProxy){
            $('#proxyAddress').val(contractInstances.KFProxy.options.address);
            $('#loadData').removeClass('disabled');
            $('#loadData').click();
        }
    }
    $('#loadData').click(function(){
        let address = $('#proxyAddress').val();
        if(!contractInstances.KFProxy || address != contractInstances.KFProxy.options.address){
            contractInstances.KFProxy = new web3.eth.Contract(contractDefinitions.KFProxy.abi, address);
        }
        createRegisteredContractsTable();
    });

    function createRegisteredContractsTable(){
        $tbody = $('#contractsTable tbody');
        contractSettings
        .filter(contract => contract.name != 'KFProxy')
        .map(contract=>contract.name)
        .forEach(async (contract) => {
            let contractAddress = await contractInstances.KFProxy.methods.getContract(contract).call();

            console.log(`Creating row for ${contract}`);
            $row = $('<tr></tr>').appendTo($tbody).append(`<td>${contract}</td>`);
            $row.data('contract', contract);
            
            // Address column
            $addressCell = $('<div class="two fields"></div>').appendTo($('<td></td>').appendTo($row));
            $(`<div class="field"><input type="text" name="${contract}.address"></div>`).appendTo($addressCell);
            $addressActions = $('<div class="field"></div>').appendTo($addressCell);
            if(contractAddress == ZERO_ADDRESS){
                $('<button type="button" class="actionDeploy ui button">Deploy</button>').appendTo($addressActions);
                $('<button type="button" class="actionSetAddress ui button">Set address</button>').appendTo($addressActions);
            }else{
                $('input', $addressCell).val(contractAddress);
                $('<button type="button" class="actionRedeploy ui button">Redeploy</button>').appendTo($addressActions);
                $('<button type="button" class="actionUpdateAddress ui button">Update address</button>').appendTo($addressActions);
            }

            // Info column
            $infoGrid = $('<div></div>').appendTo($('<td></td>').appendTo($row));
            if(contractAddress != ZERO_ADDRESS){
                let instance = new web3.eth.Contract(contractDefinitions[contract].abi, contractAddress);
                let props = contractDefinitions[contract].abi
                    .filter(entry => entry.type == 'function' && entry.constant && entry.inputs.length == 0)
                    .map(entry => entry.name);
                console.log(`${contract} properties: `, props);
                for(property of props) {
                    createPropField(instance, property, $infoGrid);
                }
                async function createPropField(instance, property, $infoGrid){
                    try {
                        let value = await instance.methods[property]().call();
                        $(`<div>${property} = ${value}</div>`).appendTo($infoGrid);
                   }catch(ex){
                        //$(`<div>${property} read failed: ${ex.message}</div>`).appendTo($infoGrid);
                        console.log(`Failed to read ${property} on  `,instance, ex);
                    }
                }
            }

        });
    }
 
    //====================================================

    async function loadWeb3(){
        printError('');
        if (typeof window.ethereum == 'undefined' && Web3.givenProvider == null) {
            printError('No MetaMask found');
            return null;
        }
        if(window.ethereum){
            await window.ethereum.enable();
        }
        // Web3 browser user detected. You can now use the provider.
        let web3 = new Web3(window.ethereum || Web3.givenProvider);
        

        let accounts = await web3.eth.getAccounts();
        if(typeof accounts[0] == 'undefined'){
            printError('Please, unlock MetaMask');
            return null;
        }
        // web3.eth.getBlock('latest', function(error, result){
        //     console.log('Current latest block: #'+result.number+' '+timestmapToString(result.timestamp), result);
        // });
        web3.eth.defaultAccount =  accounts[0];
        window.web3 = web3;
        return web3;
    }
    function loadContract(url){
        return new Promise((resolve, reject) => {
            $.ajax(url,{'dataType':'json', 'cache':'false', 'data':{'t':Date.now()}})
            .done((data)=>{resolve(data)})
            .fail((err)=>{reject(err)});
        });
    }

    function loadContractInstance(contractDef, address){
        if(typeof contractDef == 'undefined' || contractDef == null) return null;
        if(!web3.utils.isAddress(address)){printError('Contract '+contractDef.contract_name+' address '+address+' is not an Ethereum address'); return null;}
        return new web3.eth.Contract(contractDef.abi, address);
    }

    function timeStringToTimestamp(str){
        return Math.round(Date.parse(str)/1000);
    }
    function timestmapToString(timestamp){
        return (new Date(timestamp*1000)).toISOString();
    }



    /**
     * Parses ES6 template programatically
     * https://stackoverflow.com/a/47358102
     */
    function interpolate(template, variables, fallback) {
    	const regex = /\${[^{]+}/g;
    	//get the specified property or nested property of an object
    	function getObjPath(path, obj, fallback = '') {
        	return path.split('.').reduce((res, key) => res[key] || fallback, obj);
    	}

        return template.replace(regex, (match) => {
            const path = match.slice(2, -1).trim();
            return getObjPath(path, variables, fallback);
        });
    }


    /**
    * Take GET parameter from current page URL
    */
    function getUrlParam(name){
        if(window.location.search == '') return null;
        let params = window.location.search.substr(1).split('&').map(function(item){return item.split("=").map(decodeURIComponent);});
        let found = params.find(function(item){return item[0] == name});
        return (typeof found == "undefined")?null:found[1];
    }

    function printError(msg){
        let $errDiv = $('#errormsg');
        if(msg == null || msg == ''){
            $('p', $errDiv).html('');    
            $errDiv.addClass('hidden');
        }else{
            console.error(msg);
            $('p', $errDiv).html(msg);    
            $errDiv.removeClass('hidden');
        }
    }
});
