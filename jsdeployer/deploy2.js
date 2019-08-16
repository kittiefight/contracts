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
            const defaultSetupActions = ['addToProxy', 'setProxy', 'initialize'];
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
                console.log(instance, property, value)
                if(typeof value == 'object') value = JSON.stringify(value, null, ' ');
                $(`<div>${property} = ${value}</div>`).appendTo($infoGrid);
           }catch(ex){
                //$(`<div>${property} read failed: ${ex.message}</div>`).appendTo($infoGrid);
                console.log(`Failed to read ${property} on  `,instance, ex);
            }
        }
    }
    $('#contractsTable').on('click', '.addressActions button', async function(){
        //console.log('click on', this);
        let $this = $(this);     
        let contract = $this.parents("tr").data('contract');
        let contractAddress = await contractInstances.KFProxy.methods.getContract(contract).call();

        if($this.hasClass('actionDeploy') || $this.hasClass('actionRedeploy')){
            deployContract(contract, contractAddress)
            .then(function(){
                $('#loadData').click();
            });
        }else if($this.hasClass('actionSetAddress') || $this.hasClass('actionUpdateAddress')){
            let newAddress = $(`input[name=${contract}\\.address]`, $this.parents("tr")).val();
            setContractAddress(contract, contractAddress, newAddress)
            .then(function(){
                $('#loadData').click();
            });
        }else{
            console.error('Unknown button', this);
        }
    });
    async function setContractAddress(contract, contractAddress, newAddress){
        return new Promise( (resolve, reject) => {
            let method = (contractAddress == ZERO_ADDRESS)?'addContract':'updateContract';
            contractInstances.KFProxy.methods[method](contract, newAddress).send({from: web3.eth.defaultAccount})
            .on('error',function(error){
                console.log(`KFProxy.${method} tx failed: `, error);
                printError(error);
                reject(error);
            })
            .on('transactionHash',function(tx){
                console.log(`KFProxy.${method} tx: `, tx);
            })
            .on('receipt',function(receipt){
                resolve(receipt);
            });
        });

        // let instance = new web3.eth.Contract(contractDefinitions[contract].abi, contractAddress);
        // contractInstances[contract] = instance;
    }

    async function deployContract(contract, contractAddress){
        let instance = await actionDeploy(contract);
        let setupActions = contractDefinitions[contract].setupActions;
        

        $('#loadData').click();   
    }
    async function actionDeploy(contract){
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
    async function actionAddToProxy(contract, contractAddress){

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
