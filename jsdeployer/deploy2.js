var $ = jQuery;
jQuery(document).ready(function($) {
    const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
    const defaultSetupActions = ['addToProxy', 'setProxy', 'initialize'];
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
                   'abi': data.abi,
                   'bytecode': data.bytecode,
                   'deployedBytecode': data.deployedBytecode,
                   'deployArgs': contract.deployArgs?contract.deployArgs:[],
                   'setupActions': contract.setupActions?contract.setupActions:defaultSetupActions,
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
        $('#exportBtn').removeClass('disabled');
    });

    function createRegisteredContractsTable(){
        $tbody = $('#contractsTable tbody');
        $tbody.empty();
        contractSettings
        .filter(contract => contract.name != 'KFProxy')
        .map(contract=>contract.name)
        .forEach(contract => {
            let $row = $('<tr></tr>').appendTo($tbody);
            $row.data('contract', contract);
            fillRow($row, contract);
        });

        async function fillRow($row, contract){
            //console.log(`Filling row for ${contract}`);
            $row.append(`<td>${contract}</td>`);

            let contractAddress = await contractInstances.KFProxy.methods.getContract(contract).call();
            
            // Address column
            $addressCell = $('<div class="two fields"></div>').appendTo($('<td></td>').appendTo($row));
            $(`<div class="field"><input type="text" name="${contract}.address"></div>`).appendTo($addressCell);
            $addressActions = $('<div class="addressActions field"></div>').appendTo($addressCell);
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
                contractInstances[contract] = instance;

                //Check if actual contract is different from definition
                //checkCodeMatches(contract, instance, $infoGrid);

                //Read properties
                let props = contractDefinitions[contract].abi
                    .filter(entry => entry.type == 'function' && entry.constant && entry.inputs.length == 0)
                    .map(entry => entry.name);
                //console.log(`${contract} properties: `, props);
                for(property of props) {
                    createPropField(instance, property, $infoGrid);
                }
            }
        }
        async function checkCodeMatches(contract, instance, $infoGrid){
            let contractAddress = instance.options.address;
            if(contractDefinitions[contract].deployedBytecode && contractDefinitions[contract].deployedBytecode != '0x'){
                let deployedCode = await web3.eth.getCode(contractAddress);
                if(deployedCode != contractDefinitions[contract].deployedBytecode){
                    console.log(`Code of ${contract} at ${contractAddress} does not match with definition`, deployedCode, contractDefinitions[contract].deployedBytecode);
                    $infoGrid.before('<div class="error">Deployed bytecode does not match with specified in build file. Probaly redeploy is required.</div>')
                }
            }
        }
        async function createPropField(instance, property, $infoGrid){
            try {
                let value = await instance.methods[property]().call();
                //console.log(instance, property, value)
                if(typeof value == 'object') value = JSON.stringify(value, null, ' ');
                $(`<div>${property} = ${value}</div>`).appendTo($infoGrid);
           }catch(ex){
                //$(`<div>${property} read failed: ${ex.message}</div>`).appendTo($infoGrid);
                console.log(`Failed to read ${property} on `,instance.options.address/*, ex*/);
            }
        }
    }
    $('#contractsTable').on('click', '.addressActions button', async function(){
        //console.log('click on', this);
        let $this = $(this);     
        let contract = $this.parents("tr").data('contract');

        if($this.hasClass('actionDeploy') || $this.hasClass('actionRedeploy')){
            deployContract(contract)
            .then(function(){
                $('#loadData').click();
            });
        }else if($this.hasClass('actionSetAddress') || $this.hasClass('actionUpdateAddress')){
            let newAddress = $(`input[name=${contract}\\.address]`, $this.parents("tr")).val();
            setContractAddress(contract, newAddress)
            .then(function(){
                $('#loadData').click();
            });
        }else{
            console.error('Unknown button', this);
        }
    });
    async function setContractAddress(contract, newAddress){
        let oldContractAddress = await contractInstances.KFProxy.methods.getContract(contract).call();
        let method = (oldContractAddress == ZERO_ADDRESS)?'addContract':'updateContract';
        return callMethod('KFProxy', method, [contract, newAddress]);
    }
    async function setProxyAddress(contract){
        let proxyAddress = contractInstances.KFProxy.options.address;
        let instance = contractInstances[contract];
        if(instance.methods['setProxy']){
            return callMethod(contract, 'setProxy', [proxyAddress]);
        }else{
            return new Promise((resolve, reject) => {resolve(null)});
        }
    }
    async function initializeContract(contract){
        let instance = contractInstances[contract];
        if(instance.methods['initialize']){
            return callMethod(contract, 'initialize', []);
        }else{
            return new Promise((resolve, reject) => {resolve(null)});
        }
    }

    async function deployContract(contract){
        contractInstances[contract] = await _deploy(contract);
        $(`input[name=${contract}\\.address]`, $('#contractsTable')).val(contractInstances[contract].options.address);
        let ar = [];
        for(const action of contractDefinitions[contract].setupActions) {
            console.log(`Executing action ${action} for newly deployed ${contract} at ${contractInstances[contract].options.address}`);
            ar.push(actions[action].apply(this, [contract]));
        }
        Promise.all(ar).then(function(){
            //$('#loadData').click();   
        })
    }
    const actions = {
        addToProxy: async function(contract){
            return setContractAddress(contract, contractInstances[contract].options.address);
        },
        setProxy: async function(contract){
            return setProxyAddress(contract);
        },
        initialize: async function(contract){
            return initializeContract(contract);
        }
    }

    async function _deploy(contract){
        let obj = new web3.eth.Contract(contractDefinitions[contract].abi);
        let args = [];
        for(const deployArg of contractDefinitions[contract].deployArgs){
            let arg = interpolate(deployArg, contractInstances, null);
            args.push(arg);
        }
        console.log(`Deploying ${contract} with args: `, args);
        return new Promise( (resolve, reject) => {
            obj.deploy({
                data: contractDefinitions[contract].bytecode,
                arguments: args,
            }).send({from: web3.eth.defaultAccount})
            .on('error',function(error){
                console.log('Deploying failed: ', error);
                printError(error);
                reject(error);
            })
            .on('transactionHash',function(tx){
                console.log(`Deploy ${contract} tx: `, tx);
            })
            .on('receipt',function(receipt){
                let contractAddress = receipt.contractAddress;
                console.log(`${contract} deployed at ${contractAddress}`);
            })
            .then(function(instance){
                resolve(instance);
            });
        });
    }
    async function callMethod(contract, method, args){
        return new Promise( (resolve, reject) => {
            let instance = contractInstances[contract];
            instance.methods[method].apply(instance, args).send({from: web3.eth.defaultAccount})
            .on('error',function(error){
                console.log(`${contract}.${method}(`,args,') tx failed: ', error);
                printError(error);
                reject(error);
            })
            .on('transactionHash',function(tx){
                console.log(`${contract}.${method}(`,args,') tx: ', tx);
            })
            .on('receipt',function(receipt){
                console.log(`${contract}.${method}(`,args,') receipt: ', receipt);
                resolve(receipt);
            });
        });
    }


    $('#exportBtn').click(function(){
        let format = $('#exportFmt').dropdown('get value');
        let resultField = $('#exportResult');

        switch(format){
            case 'CSV_coma_headers':
            case 'CSV_tab':
            case 'Markdown':
                resultField.val(generateCSV(format));
                break;
            case 'JSON_ContractAbi':
                resultField.val(generateJSON_ContractAbi());
                break;
            case 'JSON_ContractAddress':
                resultField.val(generateJSON_ContractAddress());
                break;
            case 'JSON_ContractNetworkAddress':
                resultField.val(generateJSON_ContractNetworkAddress());
                break;
            default:
                printError(`Wrong export format: ${format}`);
        }


        function generateCSV(format){
            let columnTitles = ['Contract', 'Address'];
            let lineSeparator = "\n";
            let separator, headers, rowStart, rowEnd, cellMinWidth;
            switch(format){
                case 'CSV_coma_headers':
                    separator = ',';
                    headers = [columnTitles];
                    rowStart = ''; rowEnd = ''; cellMinWidth = [0,0];
                    break;
                case 'CSV_tab':
                    separator = "\t";
                    headers = [];
                    rowStart = ''; rowEnd = ''; cellMinWidth = [0,0];
                    break;
                case 'Markdown':
                    separator = " | ";
                    headers = [columnTitles, [':---', ':---:']];
                    rowStart = '| '; rowEnd = ' |'; cellMinWidth = [20,42];
                    break;
                default:
                    printError(`Wrong export format: ${format}`);
            }


            let data = [];
            contractSettings
            .forEach(contract => {
                let address = $(`input[name="${contract.name}.address"]`).val();
                if(typeof address == 'undefined') address = '';
                data.push([contract.name, address])
            });

            let csv = '';
            for(let line of headers){
                csv += formatLine(line, separator, rowStart, rowEnd, cellMinWidth)+lineSeparator;
            }
            for(let line of data){
                csv += formatLine(line, separator, rowStart, rowEnd, cellMinWidth)+lineSeparator;
            }
            return csv;

            function formatLine(row, separator, rowStart, rowEnd, cellMinWidth){
                let result = rowStart;
                for(let i=0; i< row.length; i++){
                    if(i!=0) result += separator;
                    result += row[i].padEnd(cellMinWidth[i], ' ');
                }
                result += rowEnd;
                return result;
            }
        }
        function generateJSON_ContractAbi(){
            let data = {};
            contractSettings
            .forEach(contract => {
                data[contract.name] = contractDefinitions[contract.name].abi;
            });
            return JSON.stringify(data);
        }
        function generateJSON_ContractAddress(){
            let data = {};
            contractSettings
            .forEach(contract => {
                let address = $(`input[name="${contract.name}.address"]`).val();
                if(typeof address == 'undefined') address = '';
                data[contract.name] = address;
            });
            return JSON.stringify(data);
        }
        function generateJSON_ContractNetworkAddress(){
            let network = web3.currentProvider.networkVersion;
            let data = {};
            contractSettings
            .forEach(contract => {
                let address = $(`input[name="${contract.name}.address"]`).val();
                if(typeof address == 'undefined') address = '';
                data[contract.name] = {};
                data[contract.name][String(network)] = address;
            });
            return JSON.stringify(data);
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

        if(window.ethereum){
            window.ethereum.on('networkChanged', document.location.reload);  //Metamask behaviour of reloading page on network change is deprecated          
        }
        

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
