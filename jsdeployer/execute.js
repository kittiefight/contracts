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
        initElements();
        initContractSelect();
        initProxy();
    }
    function initElements(){
        $('#selectContract').dropdown({
            placeholder: 'Select contract ...',
            onChange: function(value, text, $selectedItem){
                if(typeof value == 'undefined' || value == ''){
                    $('#selectFunction').addClass('disabled');
                }else{
                    console.log('Contract selected: ', value);
                    $('#selectContract').data('contract', value);
                    initFunctionSelect(value);
                    fillTargetAddress(value);
                    initEventSelect(value);
                    clearArguments();
                }
            }
        });
        $('#selectFunction').dropdown({
            placeholder: 'Select function ...',
            onChange: function(value, text, $selectedItem){
                if(typeof value != 'undefined' && value != ''){
                    console.log('Function selected: ', value);
                    let contractName = $(this).parent().data('contract');
                    initArguments(contractName, value);
                }
            }
        });
        $('#selectMode').dropdown({
            onChange: function(value, text, $selectedItem){
                let contract = $('#selectContract').data('contract');
                if(typeof contract != undefined && contract != null && contract != ''){
                    initFunctionSelect(contract);
                    clearArguments();
                }
            }
        });
        $('#eventType').dropdown({
            onChange: function(value, text, $selectedItem){
                $('#eventType').data('type', value);
            }
        });
    }

    function initContractSelect(){
        $('#selectContract').parent().dropdown('setup menu', {
            values: Object.entries(contractDefinitions).map(entry => entry[1])
                //.filter(contract => contract.name != 'KFProxy')
                .map(contract => {return {'name':contract.name, 'value': contract.name}})
                .sort((a,b) => {return (a.name < b.name)?-1:(a.name > b.name)?1:0}),
        }).removeClass('disabled');
    }
    function initFunctionSelect(contractName){
        let mode = $('#selectMode').dropdown('get value');
        let constantFilter = (mode == 'read')?true:false;
        $field = $('#selectFunction').parent();
        $field.data('contract', contractName);
        $field.dropdown('restore placeholder text');
        let ncFunctions = contractDefinitions[contractName].abi.filter(entry => entry.type == 'function' && entry.constant == constantFilter);
        $field.dropdown('setup menu', {
            values: ncFunctions
            .map(ncf => {return {'name':ncf.name, 'value': ncf.name}})
            .sort((a,b) => {return (a.name < b.name)?-1:(a.name > b.name)?1:0}),
        }).removeClass('disabled');
    }
    function clearArguments(){
        $('#arguments').empty();
        $('#executeDirectlyBtn').addClass('disabled');
        $('#generatePayloadBtn').addClass('disabled');
        $('#executeViaProxyBtn').addClass('disabled');
    }
    function initArguments(contractName, functionName){
        let mode = $('#selectMode').dropdown('get value');
        let constantFilter = (mode == 'read')?true:false;
        let functionAbi = contractDefinitions[contractName].abi.find(entry => entry.type == 'function' && entry.constant == constantFilter && entry.name == functionName);
        console.log(`Arguments for ${contractName}.${functionName}`, functionAbi);
        $('#arguments').data('contract', contractName);
        $('#arguments').data('function', functionName);
        $('#arguments').empty();
        $('#argumentsCount').text(`Function ${contractName}.${functionName} has ${functionAbi.inputs.length} arguments.`);
        for(argument of functionAbi.inputs){
            let $field = $('<div class="field"></div>').appendTo($('#arguments'));
            switch(argument.type){
                case 'bool':
                    $(`<label><i>${argument.type}</i> ${argument.name}</label><select name="${argument.name}"><option value="false">false</option><option value="true">true</option></select>`)
                    .appendTo($field);
                    break;
                case 'address':
                    $(`<label><i>${argument.type}</i> ${argument.name}</label><input type="text" name="${argument.name}" placeholder="${ZERO_ADDRESS}">`)
                    .appendTo($field);
                    break;
                case 'uint8':
                case 'uint16':
                case 'uint32':
                case 'uint64':
                    $(`<label><i>${argument.type}</i> ${argument.name}</label><input type="number" name="${argument.name}" min="0" placeholder="0">`)
                    .appendTo($field);
                    break;
                case 'int8':
                case 'int16':
                case 'int32':
                case 'int64':
                case 'int128':
                case 'int256':
                    $(`<label><i>${argument.type}</i> ${argument.name}</label><input type="number" name="${argument.name}" placeholder="0">`)
                    .appendTo($field);
                    break;
                case 'uint128':
                case 'uint256':
                    $('<div class="two fields">')
                    .append(`<div class="field"><label><i>${argument.type}</i> ${argument.name}</label><input type="number" name="${argument.name}" min="0" placeholder="0"></div>`)
                    .append(`<div class="field"><label>Convert</label><select name="${argument.name}.convertWei"></select></div>`)
                    .appendTo($field);
                    $('select', $field).dropdown({
                        values: [
                            {name:'none/wei', value:'', selected : true},
                            {name:'gwei (value * 10**9)', value:'gwei'},
                            {name:'Ether/KTY (value * 10**18)', value:'ether'}
                        ],
                        placeholder: false,
                    });
                    break;
                case 'bytes':
                case 'bytes8':
                case 'bytes16':
                case 'bytes32':
                case 'bytes64':
                    $(`<label><i>${argument.type}</i> ${argument.name}</label><input type="text" name="${argument.name}" placeholder="0x0">`)
                    .appendTo($field);
                    break;
                case 'string':
                default:
                    if(!argument.type.endsWith('[]')){
                        //some other type
                        $(`<label><i>${argument.type}</i> ${argument.name}</label><input type="text" name="${argument.name}" placeholder="Put data of type ${argument.type}. No conversion will be applied.">`)
                        .appendTo($field);
                    }else{
                        //array
                        $(`<label><i>${argument.type}</i> ${argument.name} <small>Put one item per row. No conversion will be applied.</small></label><textarea name="${argument.name}">`)
                        .appendTo($field);
                    }
            }
        }

        if(mode == 'write'){
            $('#generatePayloadBtn').removeClass('disabled');
            $('#executeDirectlyBtn').addClass('disabled');
            $('#executeViaProxyBtn').addClass('disabled');
            $('#readBtn').addClass('disabled');
        }else{
            $('#generatePayloadBtn').addClass('disabled');
            $('#executeDirectlyBtn').addClass('disabled');
            $('#executeViaProxyBtn').addClass('disabled');
            $('#readBtn').removeClass('disabled');
        }
    }

    function initProxy(){
        if(contractInstances.KFProxy){
            $('#proxyAddress').val(contractInstances.KFProxy.options.address);
        }
    }
    async function fillTargetAddress(contract){
        if(contractInstances[contract]){
            $('#targetAddress').val(contractInstances[contract].options.address);
        }else if(contractInstances.KFProxy) {
            $('#targetAddress').val('...');
            let address = await contractInstances.KFProxy.methods.getContract(contract).call();
            if(address != ZERO_ADDRESS){
                $('#targetAddress').val(address);
            }else{
                $('#targetAddress').val('');
            }
        }else{
            $('#targetAddress').val('');
        }
    }

    function parseArguments(functionABI){
        let args = [];
        for(let i = 0; i < functionABI.inputs.length; i++){
            let argument = functionABI.inputs[i];
            let val;
            if(argument.type == 'bool'){
                val = ($(`select[name=${argument.name}]`).val() != 'false');
            } else if(argument.type.endsWith('[]')) {
                let text = $(`textarea[name=${argument.name}]`).val();
                val = text.trim().split('\n').map(line => line.trim());
            } else {
                val = $(`input[name=${argument.name}]`).val();
                let convertEl = $(`select[name='${argument.name}.convertWei']`);
                if(convertEl.length > 0){
                    let convertType = convertEl.parent().find('.selected').data('value'); //dropdown('get value') does not work
                    if(convertType != ''){
                        val = web3.utils.toWei(val, convertType);
                    }
                }
            }
            args.push(val);
        }
        return args;
    }

    function initEventSelect(contractName){
        $('#eventType').data('contract', contractName);
        $field = $('#eventType').parent();
        let ncFunctions = contractDefinitions[contractName].abi.filter(entry => entry.type == 'event');
        $field.dropdown('setup menu', {
            values: [{'name':'All', 'value': 'allEvents'}]
                .concat(
                    ncFunctions
                    .map(ncf => {return {'name':ncf.name, 'value': ncf.name}})
                    .sort((a,b) => {return (a.name < b.name)?-1:(a.name > b.name)?1:0})
                ),
        }).removeClass('disabled');



        $('#eventLoadBtn').removeClass('disabled');
    }


    $('#generatePayloadBtn').click(function(){
        let targetContract =  $('#arguments').data('contract');
        let targetFunction =  $('#arguments').data('function');

        let contractABI = contractDefinitions[targetContract].abi;
        let functionABI = contractABI.find((f)=>{return f.name == targetFunction;})

        if(!functionABI){
            printError(`Function ${targetFunction} in ${targetContract} not found!`);
            return;
        }

        let args = parseArguments(functionABI);
        console.log('Generating payload for ', functionABI, args);
        
        try{
            let message = web3.eth.abi.encodeFunctionCall(functionABI,args);
            $('#resultLabel').val('Generated payload');
            $('#resultData').val(message);
            $('#executeViaProxyBtn').removeClass('disabled');
            $('#executeDirectlyBtn').removeClass('disabled');
        }catch(e){
            printError(e.message)
        }
    });
    $('#executeViaProxyBtn').click(function(){
        let targetContract =  $('#arguments').data('contract');
        let payload = $('#resultData').val();
        if(!payload.startsWith('0x')){
            printError('Payload has incorrect format');
            return;
        }
        let messageValue = web3.utils.toWei($('#callValue').val(), 'ether');
        console.log(`Sending call to ${targetContract} via KFProxy at ${contractInstances.KFProxy.options.address}`, payload);

        contractInstances.KFProxy.methods.execute(targetContract, payload).send({
            from: web3.eth.defaultAccount,
            value: messageValue
        })
        .on('transactionHash', function(tx){
            console.log('Proxy call to '+targetContract+' tx: '+tx);
            $('#resultLabel').val('Transaction sent: '+tx);
            $('#resultData').val('');
        })
        .then(function(receipt){
            console.log('Proxy call to '+targetContract+' receipt: '+receipt);
            $('#resultLabel').val('Execution receipt');
            $('#resultData').val(JSON.stringify(receipt));
        });
    });
    $('#executeDirectlyBtn').click(function(){
        let targetContract =  $('#arguments').data('contract');
        let payload = $('#resultData').val();
        if(!payload.startsWith('0x')){
            printError('Payload has incorrect format');
            return;
        }
        let messageValue = web3.utils.toWei($('#callValue').val(), 'ether');
        console.log(`Sending call to ${targetContract} directly`, payload);

        web3.eth.sendTransaction({
            from: web3.eth.defaultAccount,
            to: $('#targetAddress').val(),
            value: messageValue,
            data: payload       
        })
        .on('transactionHash', function(tx){
            console.log('Call to '+targetContract+' tx: '+hash);
            $('#resultLabel').val('Transaction sent: '+tx);
            $('#resultData').val('');
        })
        .then(function(receipt){
            console.log('Call to '+targetContract+' receipt: '+receipt);
            $('#resultLabel').val('Execution receipt');
            $('#resultData').val(JSON.stringify(receipt));
        });
    });
    $('#readBtn').click(async function(){
        let targetContract =  $('#arguments').data('contract');
        let targetFunction =  $('#arguments').data('function');
        let targetAddress = $('#targetAddress').val();

        let contractABI = contractDefinitions[targetContract].abi;
        let functionABI = contractABI.find((f)=>{return f.name == targetFunction;})

        if(!functionABI){
            printError(`Function ${targetFunction} in ${targetContract} not found!`);
            return;
        }
        let args = parseArguments(functionABI);

        let instance = new web3.eth.Contract(contractABI, targetAddress);

        $('#resultLabel').val('Reading...');
        $('#resultData').val('');
        let result = await instance.methods[targetFunction].apply(instance, args).call();
        $('#resultLabel').val('Read result');
        $('#resultData').val(JSON.stringify(result));
    })

    $('#eventLoadBtn').click(async function(){
        let targetContract = $('#eventType').data('contract');
        let targetAddress = $('#targetAddress').val();
        if(targetAddress == ZERO_ADDRESS) return;
        let contractABI = contractDefinitions[targetContract].abi;

        let eventType = $('#eventType').data('type');
        let fromBlock = $('#eventFromBlock').val();
        let toBlock = $('#eventToBlock').val();


        let instance = new web3.eth.Contract(contractABI, targetAddress);
        let events = await instance.getPastEvents(eventType, {
            'fromBlock': fromBlock,
            'toBlock': toBlock
        });

        $logs = $('#eventLogs');
        $logs.empty();
        for(event of events){
            console.log(event);
            let args = Object.entries(event.returnValues)
                .filter(entry => !isNumber(entry[0]))
                .map(entry => `${entry[0]}="${entry[1]}"`)
                .join(', ');
            let eventStr = `${event.blockNumber}.${event.logIndex}\t${event.event}\t${args}`
            $logs.append(eventStr+"\n");
        }
    });

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
