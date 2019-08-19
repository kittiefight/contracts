var $ = jQuery;
jQuery(document).ready(function($) {
    const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
    const INFURA_ID = '615f9abed6d04d3abf8f2c3a66159ac5'; //Infura Project ID (public)

    let web3 = null;
    let web3s = null;    //Subscriptions provider
    let contractDefinitions = {};
    let contractInstances = {};
    let addressToContractMap = {};
    let subscription = null;


    setTimeout(init, 1000);
    async function init(){
        web3 = await loadWeb3();
        if(web3 == null) {
            setTimeout(init, 5000);
            return;
        }
        // Load contracts
        $('#status').text('Loading contract definitions...');
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
        initProxy();
    }
    function initProxy(){
        $('#startListening').removeClass('disabled');
        if(contractInstances.KFProxy){
            $('#proxyAddress').val(contractInstances.KFProxy.options.address);
            $('#startListening').click();
        }
    }

    $('#startListening').click(async function(){
        if(!contractInstances.KFProxy) {
            let address = $('#proxyAddress').val();
            if(address == '') return;
            try{
                contractInstances.KFProxy = new web3.eth.Contract(contractDefinitions.KFProxy.abi, address);
            }catch(ex){
                printError(ex);
                return;
            }
        }
        console.log(`loading from ${contractInstances.KFProxy.options.address}`);
        $('#status').text('Loading contract addresses...');
        $('#startListening').addClass('disabled');
        let addresses = (await loadContracts())
            .filter(address => (address != ZERO_ADDRESS))
            .concat(['0x0C3b3A4fABc2c1DcFbeFff428ec3CeC83B95cB2a']);
        addressToContractMap[contractInstances.KFProxy.options.address] = 'KFProxy';
        console.log('Listening to events on addresses:', addresses);
        $('#status').text('Listening to events...')
        let $logs = $('#eventLogs');
        $('#stopListening').removeClass('disabled');
        subscription = web3s.eth.subscribe('logs', {
            'address': addresses
        })
        .on('error', function(err){
            console.log('Subscription error', err);
            $('#stopListening').addClass('disabled');
            $('#startListening').removeClass('disabled');
        })
        .on('data', function(rawEvent){
            let contract = addressToContractMap[rawEvent.address];
            let event = contractInstances[contract]
                ._decodeEventABI.call({
                    name: 'ALLEVENTS',
                    jsonInterface: contractInstances[contract].options.jsonInterface
                }, rawEvent);
            //console.log('Event received', rawEvent, event);
            let args = Object.entries(event.returnValues)
                .filter(entry => !isNumber(entry[0]))
                .map(entry => `${entry[0]}="${entry[1]}"`)
                .join(', ');
            let eventStr = `${event.blockNumber}.${event.logIndex}\t${contract.padEnd(20)}\t${event.event.padEnd(20)}\t${args}`
            $logs.append(eventStr+"\n");
        })
    });
    $('#stopListening').click(function(){
        if(subscription != null){
            subscription.unsubscribe(function(error, success){
                if(success){
                    $('#status').text('Ready');
                    $('#stopListening').addClass('disabled');
                    $('#startListening').removeClass('disabled'); 
                    subscription = null;
                }else{
                    printError(error);
                }
            });
        }
    })

    async function loadContracts(){
        let loadTasks = [];
        for(contract in contractDefinitions){
            async function loadContract(contract){
                let address = await contractInstances.KFProxy.methods.getContract(contract).call();
                if(address != ZERO_ADDRESS){
                    contractInstances[contract] = new web3.eth.Contract(contractDefinitions[contract].abi, address);
                    console.log(`Instance of ${contract} loaded at ${address}`);
                    addressToContractMap[address] = contract;
                }
                return address;
            }
            loadTasks.push(loadContract(contract));
        }
        return Promise.all(loadTasks);
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

        //Subscriptions provider
        let network = await web3.eth.net.getNetworkType();
        web3s = new Web3(`wss://${network}.infura.io/ws/v3/${INFURA_ID}`);
        window.web3s = web3s;

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
    function isNumber(str){
        return !isNaN(str);
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
