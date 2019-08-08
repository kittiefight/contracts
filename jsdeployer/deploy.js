var $ = jQuery;
jQuery(document).ready(function($) {
    const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

    let web3 = null;
    let contractDefinitions = {
        // Main contracts
        KFProxy: null,
        GenericDB: null,
        FreezeInfo: null,
        CronJob: null,
        // Test contracts
        ProxiedTest:null
    };
    let contractInstances = {};


    setTimeout(init, 1000);
    async function init(){
        web3 = await loadWeb3();
        if(web3 == null) {
            setTimeout(init, 5000);
            return;
        }
        // Load main contracts 
        loadContract('../build/contracts/KFProxy.json', function(data){
            contractDefinitions.KFProxy = data;
            $('#KFProxy_ABI').text(JSON.stringify(data.abi));
            let address = getUrlParam(data.contractName);
            if(web3.utils.isAddress(address)){
                contractInstances.proxy = loadContractInstance(data, address);
                prepareResultTd('#mainContractsDeployTable', 'Load '+data.contractName).text('at '+address);
                $('#executeLink').attr('href', 'execute.html?KFProxy='+address);
            } 
        });
        loadContract('../build/contracts/GenericDB.json', function(data){
            contractDefinitions.GenericDB = data;
            $('#GenericDB_ABI').text(JSON.stringify(data.abi));
            let address = getUrlParam(data.contractName);
            if(web3.utils.isAddress(address)){
                contractInstances.genericDB = loadContractInstance(data, address);
                prepareResultTd('#mainContractsDeployTable', 'Load '+data.contractName).text('at '+address);
            } 
        });
        loadContract('../build/contracts/CronJob.json', function(data){
            contractDefinitions.CronJob = data;
            $('#CronJob_ABI').text(JSON.stringify(data.abi));
            let address = getUrlParam(data.contractName);
            if(web3.utils.isAddress(address)){
                contractInstances.cronJob = loadContractInstance(data, address);
                prepareResultTd('#mainContractsDeployTable', 'Load '+data.contractName).text('at '+address);
            } 
        });
        loadContract('../build/contracts/FreezeInfo.json', function(data){
            contractDefinitions.FreezeInfo = data;
            $('#FreezeInfo_ABI').text(JSON.stringify(data.abi));
            let address = getUrlParam(data.contractName);
            if(web3.utils.isAddress(address)){
                contractInstances.freezeInfo = loadContractInstance(data, address);
                prepareResultTd('#mainContractsDeployTable', 'Load '+data.contractName).text('at '+address);
            } 
        });
        // Load test contracts 
        loadContract('../build/contracts/ProxiedTest.json', function(data){
            contractDefinitions.ProxiedTest = data;
            $('#ProxiedTest_ABI').text(JSON.stringify(data.abi));
            let address = getUrlParam(data.contractName);
            if(web3.utils.isAddress(address)){
                contractInstances.proxiedTest = loadContractInstance(data, address);
                prepareResultTd('#testContractsDeployTable', 'Load '+data.contractName).text('at '+address);
            } 
        });

        initPublishAndConfigureForm();
        window.deployer = {
            'contractDefinitions': contractDefinitions,
            'contractInstances': contractInstances,
            'deployContract': deployContract,
            'sendMessage': sendMessage,
        };
    }

    function initPublishAndConfigureForm(){
        let $form = $('#publishAndConfigureForm');
        $('input[type=button]', $form).prop( "disabled", false);
    }



    $('#deployMainContracts').click(async function(){
        let table = $('#mainContractsDeployTable');
        $('tbody', table).empty();

        contractInstances.proxy = await deployContract(contractDefinitions.KFProxy, [], table);
        contractInstances.genericDB = await deployContract(contractDefinitions.GenericDB, [], table);
        contractInstances.cronJob = await deployContract(contractDefinitions.CronJob, [contractInstances.genericDB.options.address], table);
        contractInstances.freezeInfo = await deployContract(contractDefinitions.FreezeInfo, [], table);
    });

    $('#deployTestContracts').click(async function(){
        let table = $('#testContractsDeployTable');
        $('tbody', table).empty();

        contractInstances.proxiedTest = await deployContract(contractDefinitions.ProxiedTest, [], table);
    });

    $('#setupMainContracts').click(async function(){
        let table = $('#mainContractsSetupTable');
        $('tbody', table).empty();

        sendMessage(contractInstances.proxy, 'addContract', ['GenericDB', contractInstances.genericDB.options.address], table);
        sendMessage(contractInstances.proxy, 'addContract', ['FreezeInfo', contractInstances.freezeInfo.options.address], table);
        sendMessage(contractInstances.proxy, 'addContract', ['CronJob', contractInstances.cronJob.options.address], table);

        sendMessage(contractInstances.genericDB,  'setProxy', [contractInstances.proxy.options.address], table);
        sendMessage(contractInstances.cronJob,    'setProxy', [contractInstances.proxy.options.address], table);
        sendMessage(contractInstances.freezeInfo, 'setProxy', [contractInstances.proxy.options.address], table);
    });

    $('#setupTestContracts').click(async function(){
        let table = $('#testContractsSetupTable');
        $('tbody', table).empty();

        sendMessage(contractInstances.proxiedTest,  'setProxy', [contractInstances.proxy.options.address], table);
        addOrUpdateContractAddressOnProxy('ProxiedTest', contractInstances.proxiedTest.options.address, table);

    });


    $('#generatePayload').click(async function(){
        let $form = $('#prepareCallForm');

        let targetContract = $('input[name=targetContract]', $form).val().trim();
        let contractDef = contractDefinitions[targetContract];
        if(!contractDef){
            printError('Contract '+targetContract+' not found!');
            return;
        }

        let targetFunction =  $('input[name=targetFunction]', $form).val().trim();
        let functionABI = contractDef.abi.find((f)=>{return f.name == targetFunction;})
        if(!functionABI){
            printError('Function '+targetFunction+' in '+targetContract+' not found!');
            return;
        }

        let args = [];
        for(let i=0; i < 2; i++){
            let arg = $('input[name=arg_'+i+']', $form).val();
            if(arg != ''){
                args.push(arg);
            }
        }

        let message = web3.eth.abi.encodeFunctionCall(functionABI,args);
        $('textarea[name=payload]', $form).val(message);

    });
    $('#sendCall').click(async function(){
        let $form = $('#prepareCallForm');

        if(!contractInstances.proxy){
            printError('Proxy is not deployed');
            return;
        }
        let targetContract = $('input[name=targetContract]', $form).val().trim();
        if(!targetContract){
            printError('Target contract not set');
            return;
        }
        let payload = $('textarea[name=payload]', $form).val();
        if(!payload){
            printError('Payload not set');
            return;
        }
        let messageValueTxt = $('input[name=messageValue]', $form).val();
        let messageValue = (messageValueTxt == '')?0:web3.utils.toWei(messageValueTxt, 'ether');

        contractInstances.proxy.methods.execute(targetContract, payload).send({
            from: web3.eth.defaultAccount,
            value: messageValue
        })
        .on('transactionHash', function(hash){
            console.log('Proxy call to '+targetContract+' tx: '+hash);
        })
        .then(function(receipt){
            console.log('Proxy call to '+targetContract+' receipt: '+receipt);
            resolve(receipt);
        });

    });

    async function addOrUpdateContractAddressOnProxy(contractName, contractAddress, table=null){
        let oldAddress = await contractInstances.proxy.methods.getContract(contractName).call();
        if(oldAddress == ZERO_ADDRESS){
            sendMessage(contractInstances.proxy, 'addContract', [contractName, contractAddress], table);
        }else{
            sendMessage(contractInstances.proxy, 'updateContract', [contractName, contractAddress], table);
        }
    }

    async function sendMessage(contract, method, args, table=null, action=null) {
        return new Promise((resolve, reject) => {
            if(action == null) action = 'Call  '+method+'('+JSON.stringify(args)+') on '+contract.options.address;
            console.log(action);
            let resultTd = prepareResultTd(table, action);
            contract.methods[method].apply(contract.methods, args).send({
                from: web3.eth.defaultAccount,
            })
            .on('error',function(error){
                console.log(action+' failed:', error);
                if(resultTd) resultTd.text('Error: '+error);
                printError(error);
                reject(error);
            })
            .on('transactionHash', function(hash){
                console.log(action+' tx: '+hash);
            })
            .then(function(receipt){
                console.log(action+' receipt: '+receipt);
                resolve(receipt);
            });
        });
    }


    async function deployContract(contract, args=[], table=null) {
        return new Promise((resolve, reject) => {
            let resultTd = prepareResultTd(table, 'Deploy '+contract.contractName);

            console.log('Deploy '+contract.contractName+' with arguments:', args);
            let obj = new web3.eth.Contract(contract.abi);
            obj.deploy({
                data: contract.bytecode,
                arguments: args
            })
            .send({
                from: web3.eth.defaultAccount,
            })
            .on('error',function(error){
                console.log('Deploy contract '+contract.contractName+' failed:', error);
                if(resultTd) resultTd.text('Error: '+error);
                printError(error);
                reject(error);
            })
            .on('transactionHash',function(tx){
                if(resultTd) resultTd.text('Waiting tx: '+tx);
                console.log('Deploy contract '+contract.contractName+' tx sent:', tx);
            })
            .on('receipt',function(receipt){
                if(resultTd) resultTd.text('Deployed: '+receipt.contractAddress);
                console.log('Deploy contract '+contract.contractName+' receipt:', receipt);  
            })
            .then(function(contractInstance){
                console.log('Contract '+contract.contractName+' address:', contractInstance.options.address);  
                resolve(contractInstance);
            });
        });
    }


    function prepareResultTd(table, action){
        let resultTd = null;
        if(table != null){
            let tbody = $('tbody', table);
            let tr = $('<tr></tr>').appendTo(tbody);
            $('<td></td>').appendTo(tr).text(action);
            resultTd = $('<td></td>').appendTo(tr);
        }        
        return resultTd;
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
    function loadContract(url, callback){
        $.ajax(url,{'dataType':'json', 'cache':'false', 'data':{'t':Date.now()}}).done(callback);
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
    * Take GET parameter from current page URL
    */
    function getUrlParam(name){
        if(window.location.search == '') return null;
        let params = window.location.search.substr(1).split('&').map(function(item){return item.split("=").map(decodeURIComponent);});
        let found = params.find(function(item){return item[0] == name});
        return (typeof found == "undefined")?null:found[1];
    }

    function printError(msg){
        if(msg == null || msg == ''){
            $('#errormsg').html('');    
        }else{
            console.error(msg);
            $('#errormsg').html(msg);
        }
    }
});
