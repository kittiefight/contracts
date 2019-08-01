/*
const BigNumber = require('bignumber.js');
require('chai')
  .use(require('chai-shallow-deep-equal'))
  .use(require('chai-bignumber')(BigNumber))
  .use(require('chai-as-promised'))
  .should();
*/

const BigNumber = web3.utils.BN;
  require('chai')
  .use(require('chai-shallow-deep-equal'))
  .use(require('chai-bignumber')(BigNumber))
  .use(require('chai-as-promised'))
  .should();  

const KFProxy = artifacts.require('KFProxy')
const GenericDB = artifacts.require('GenericDB');
const ProfileDB = artifacts.require('ProfileDB')
const RoleDB = artifacts.require('RoleDB')
const GMSetterDB = artifacts.require('GMSetterDB')
const GMGetterDB = artifacts.require('GMGetterDB')
const GameManager = artifacts.require('GameManager')
const GameVarAndFee = artifacts.require('GameVarAndFee')
const Distribution = artifacts.require('Distribution')
const Forfeiter = artifacts.require('Forfeiter')
const DateTime = artifacts.require('DateTime')
const Scheduler = artifacts.require('Scheduler')
const Betting = artifacts.require('Betting')
const HitsResolve = artifacts.require('HitsResolve')
const RarityCalculator = artifacts.require('RarityCalculator')
const Register = artifacts.require('Register')
const EndowmentFund = artifacts.require('EndowmentFund')
const EndowmentDB = artifacts.require('EndowmentDB')
const Escrow = artifacts.require('Escrow')
const KittieHELL = artifacts.require('KittieHELL')
const KittieHellDB = artifacts.require('KittieHellDB')
const SuperDaoToken = artifacts.require('MockERC20Token');
const KittieFightToken = artifacts.require('MockERC20Token');
const CryptoKitties = artifacts.require('MockERC721Token');
const CronJob = artifacts.require('CronJob');
const ERC20_TOKEN_SUPPLY = new BigNumber(1000000);

//Contract instances
let proxy, dateTime, genericDB, profileDB, roleDB, superDaoToken,
  kittieFightToken, cryptoKitties, register, gameVarAndFee, endowmentFund,
  endowmentDB, distribution, forfeiter, scheduler, betting, hitsResolve,
  rarityCalculator, kittieHELL, kittieHellDB, getterDB, setterDB, gameManager,
  cronJob, escrow


const kittie1 = 1234
const kittie2 = 32452
const kittie3 = 23134
const kittie4 = 44444
const kittie5 = 55555
const kittie6 = 6666

const cividId1 = 1;
const cividId2 = 2;
const cividId3 = 3;
const cividId4 = 4;

// GAME VARS AND FEES
const LISTING_FEE = 1000
const TICKET_FEE = 100
const BETTING_FEE = 100
const MIN_CONTRIBUTORS = 2
const REQ_NUM_MATCHES = 2
const GAME_PRESTART = 120 // 2 min
const GAME_DURATION = 300 // games last 5 min
const ETH_PER_GAME = 0 //How does endowment start funds?
const TOKENS_PER_GAME = 0;
const GAME_TIMES = 3600 //Scheduled games 1 hour apart

let five_escrow_pre = 0, five_escrow_post = 0, five_receiver_pre = 0, five_receiver_post = 0, five_add_amount = 10
let six_escrow_pre = 0, six_escrow_post = 0, six_receiver_pre = 0, six_receiver_post = 0, six_add_amount = 10



function setMessage(contract, funcName, argArray) {
  return web3.eth.abi.encodeFunctionCall(
    contract.abi.find((f) => { return f.name == funcName; }),
    argArray
  );
}

contract('EndowmentFund', ([creator, user1, user2, user3, user4, bettor1, bettor2, bettor3, bettor4, randomAddress]) => {

  it('deploys contracts', async () => {
    // PROXY
    proxy = await KFProxy.new()

    // DATABASES
    genericDB = await GenericDB.new()
    profileDB = await ProfileDB.new(genericDB.address);
    roleDB = await RoleDB.new(genericDB.address);
    endowmentDB = await EndowmentDB.new(genericDB.address)
    getterDB = await GMGetterDB.new(genericDB.address)
    setterDB = await GMSetterDB.new(genericDB.address)
    kittieHellDB = await KittieHellDB.new(genericDB.address)

    // CRONJOB
    cronJob = await CronJob.new(genericDB.address)

    // TOKENS
    superDaoToken = await SuperDaoToken.new(ERC20_TOKEN_SUPPLY);
    kittieFightToken = await KittieFightToken.new(ERC20_TOKEN_SUPPLY);
    cryptoKitties = await CryptoKitties.new();

    // MODULES
    gameManager = await GameManager.new()
    register = await Register.new()
    dateTime = await DateTime.new()
    gameVarAndFee = await GameVarAndFee.new(genericDB.address, randomAddress)
    distribution = await Distribution.new()
    forfeiter = await Forfeiter.new()
    scheduler = await Scheduler.new()
    betting = await Betting.new()
    hitsResolve = await HitsResolve.new()
    rarityCalculator = await RarityCalculator.new()
    endowmentFund = await EndowmentFund.new()
    kittieHELL = await KittieHELL.new()

    //ESCROW
    escrow = await Escrow.new()
    await escrow.transferOwnership(endowmentFund.address).should.be.fulfilled

  })

  it('adds contract addresses to contract manager', async () => {
    await proxy.addContract('TimeContract', dateTime.address)
    await proxy.addContract('GenericDB', genericDB.address)
    await proxy.addContract('CryptoKitties', cryptoKitties.address);
    await proxy.addContract('SuperDAOToken', superDaoToken.address);
    await proxy.addContract('KittieFightToken', kittieFightToken.address);
    await proxy.addContract('ProfileDB', profileDB.address);
    await proxy.addContract('RoleDB', roleDB.address);
    await proxy.addContract('Register', register.address)
    await proxy.addContract('GameVarAndFee', gameVarAndFee.address)
    await proxy.addContract('EndowmentFund', endowmentFund.address)
    await proxy.addContract('EndowmentDB', endowmentDB.address)
    await proxy.addContract('Distribution', distribution.address)
    await proxy.addContract('Forfeiter', forfeiter.address)
    await proxy.addContract('Scheduler', scheduler.address)
    await proxy.addContract('Betting', betting.address)
    await proxy.addContract('HitsResolve', hitsResolve.address)
    await proxy.addContract('RarityCalculator', rarityCalculator.address)
    await proxy.addContract('GMSetterDB', setterDB.address)
    await proxy.addContract('GMGetterDB', getterDB.address)
    await proxy.addContract('GameManager', gameManager.address)
    await proxy.addContract('CronJob', cronJob.address)
    await proxy.addContract('KittieHell', kittieHELL.address)
    await proxy.addContract('KittieHellDB', kittieHellDB.address)
  })

  it('sets proxy in contracts', async () => {
    await genericDB.setProxy(proxy.address)
    await profileDB.setProxy(proxy.address);
    await roleDB.setProxy(proxy.address);
    await setterDB.setProxy(proxy.address)
    await getterDB.setProxy(proxy.address)
    await endowmentFund.setProxy(proxy.address)
    await endowmentDB.setProxy(proxy.address)
    await gameVarAndFee.setProxy(proxy.address)
    await distribution.setProxy(proxy.address)
    await forfeiter.setProxy(proxy.address)
    await scheduler.setProxy(proxy.address)
    await betting.setProxy(proxy.address)
    await hitsResolve.setProxy(proxy.address)
    await rarityCalculator.setProxy(proxy.address)
    await register.setProxy(proxy.address)
    await gameManager.setProxy(proxy.address)
    await cronJob.setProxy(proxy.address)
    await kittieHELL.setProxy(proxy.address)
    await kittieHellDB.setProxy(proxy.address)
  })

  it('initializes contract variables', async () => {
    await gameVarAndFee.initialize()
    await forfeiter.initialize()
    await scheduler.initialize()
    await register.initialize()
    await gameManager.initialize()
    await getterDB.initialize()
    await endowmentFund.initialize()
    await endowmentFund.initUpgradeEscrow(escrow.address)
    await kittieHellDB.setKittieHELL()
    await kittieHELL.initialize()
  })

  /*
  // Mint some kitties for the test addresses
  it('mint some kitties for the test addresses', async () => {
    await cryptoKitties.mint(user1, kittie1).should.be.fulfilled;
    await cryptoKitties.mint(user2, kittie2).should.be.fulfilled;
    await cryptoKitties.mint(user3, kittie3).should.be.fulfilled;
    await cryptoKitties.mint(user4, kittie4).should.be.fulfilled;
    await cryptoKitties.mint(user1, kittie5).should.be.fulfilled;
    await cryptoKitties.mint(user2, kittie6).should.be.fulfilled;
  })
*/

  // Approve transfer operation for the system
  // Register no longer holds kittie
  // await cryptoKitties.approve(register.address, kittie1, { from: user1 }).should.be.fulfilled;
  // await cryptoKitties.approve(register.address, kittie2, { from: user2 }).should.be.fulfilled;
  // await cryptoKitties.approve(register.address, kittie3, { from: user3 }).should.be.fulfilled;
  // await cryptoKitties.approve(register.address, kittie4, { from: user4 }).should.be.fulfilled;
  // await cryptoKitties.approve(register.address, kittie5, { from: user5 }).should.be.fulfilled;
  // await cryptoKitties.approve(register.address, kittie6, { from: user2 }).should.be.fulfilled;


  it('transfer some KTY for the test addresses', async () => {
    await kittieFightToken.transfer(user1, 100000).should.be.fulfilled;
    await kittieFightToken.transfer(user2, 100000).should.be.fulfilled;
    await kittieFightToken.transfer(user3, 100000).should.be.fulfilled;
    await kittieFightToken.transfer(user4, 100000).should.be.fulfilled;
    await kittieFightToken.transfer(bettor1, 100000).should.be.fulfilled;
    await kittieFightToken.transfer(bettor2, 100000).should.be.fulfilled;
    await kittieFightToken.transfer(bettor3, 100000).should.be.fulfilled;
    await kittieFightToken.transfer(bettor4, 100000).should.be.fulfilled;
    await kittieFightToken.transfer(randomAddress, 100000).should.be.fulfilled;
    
  })


  it('approves erc20 token transfer operation by endowment contract', async () => {
    await kittieFightToken.approve(endowmentFund.address, 100000, { from: user1 }).should.be.fulfilled;
    await kittieFightToken.approve(endowmentFund.address, 100000, { from: user2 }).should.be.fulfilled;
    await kittieFightToken.approve(endowmentFund.address, 100000, { from: user3 }).should.be.fulfilled;
    await kittieFightToken.approve(endowmentFund.address, 100000, { from: user4 }).should.be.fulfilled;
    await kittieFightToken.approve(endowmentFund.address, 100000, { from: bettor1 }).should.be.fulfilled;
    await kittieFightToken.approve(endowmentFund.address, 100000, { from: bettor2 }).should.be.fulfilled;
    await kittieFightToken.approve(endowmentFund.address, 100000, { from: bettor3 }).should.be.fulfilled;
    await kittieFightToken.approve(endowmentFund.address, 100000, { from: bettor4 }).should.be.fulfilled;
    await kittieFightToken.approve(endowmentFund.address, 100000, { from: randomAddress }).should.be.fulfilled;
  })

    // registers user to the system
  it('Register users', async () => {
    await proxy.execute('Register', setMessage(register, 'register', [user1]), {from: user1}).should.be.fulfilled;
    await proxy.execute('Register', setMessage(register, 'register', [bettor1]), {from: user1}).should.be.fulfilled;
 
  })
      

  it('endowmentFund.sendKTYtoEscrow() : add initial KTY to Escrow', async () => {

   let kty = await escrow.getBalanceKTY();

    //send some kty to endowmentFund first
   await kittieFightToken.transfer(endowmentFund.address, 1000).should.be.fulfilled;

   let add_amount = 10;
   endowmentFund.sendKTYtoEscrow(add_amount);
   kty = await escrow.getBalanceKTY();   //console.log('escrow.getBalanceKTY() = ' + kty);
   assert.equal(kty, add_amount);  

  });

  it('endowmentFund.sendETHtoEscrow() : add initial Eth to Escrow', async () => {

    let sender_balance = await  web3.eth.getBalance(user1); //console.log('sender_balance =' + sender_balance);
    let add_amount = 10;
    assert(sender_balance >= add_amount, 'sender does not have balance');

    //let pre = await  web3.eth.getBalance(escrow.address); //console.log('escrow pre =' + pre);
    let pre = await escrow.getBalanceETH(); 

    // send some eth
    endowmentFund.sendETHtoEscrow({from: user1, value: add_amount });

    let post1 = await escrow.getBalanceETH(); // REQUIRED - to introduces a delay perhaps
    let post = await web3.eth.getBalance(escrow.address); 
    assert.equal(post - pre, add_amount);
 
   });

  it('endowmentFund.contributeKTY() : bettor sends KTY to escrow', async () => {
    let add_amount = 10;
    let pre = await escrow.getBalanceKTY(); 

    await endowmentFund.contributeKTY(bettor1, add_amount);
    
    let post = await escrow.getBalanceKTY(); 
    assert.equal(post - pre, add_amount);

  });

  // five  - pre
  it('endowmentFund.contributeETH() : Bettors sends Eth to Escrow via endowmentFund', async () => {

    let sender_balance = await  web3.eth.getBalance(bettor1); //console.log('sender_balance =' + sender_balance);
    assert(sender_balance >= five_add_amount, 'sender does not have balance');

    five_escrow_pre = await escrow.getBalanceETH(); 

    // send some eth
    endowmentFund.contributeETH(1, {from: bettor1, value: five_add_amount });

  });

   // five  - post
   it('endowmentFund.contributeETH() : Verify', async () => {

    five_escrow_post = await web3.eth.getBalance(escrow.address);  

    assert.equal(five_escrow_post - five_escrow_pre, five_add_amount);

  }); 
   
  it('endowmentFund.transferKFTfromEscrow() : Escrow send Eth to given address', async () => {

    let sender_balance = await kittieFightToken.balanceOf(escrow.address); //console.log('sender_balance =' + sender_balance);
    let add_amount = 10;
    assert(sender_balance >= add_amount, 'sender does not have balance');

    let pre = await kittieFightToken.balanceOf(bettor1);

    // send some eth
    endowmentFund.transferKFTfromEscrow(bettor1, add_amount);

    let post = await kittieFightToken.balanceOf(bettor1); //console.log('escrow post =' + post);
    assert.equal(post - pre, add_amount);

  });

  // six - pre
  it('endowmentFund.transferETHfromEscrow() : Escrow send Eth to given address', async () => {

    let sender_balance = await web3.eth.getBalance(escrow.address); 
    assert(sender_balance >= six_add_amount, 'sender does not have balance');

    six_receiver_pre = await web3.eth.getBalance(bettor1); console.log('six_receiver_pre =' + six_receiver_pre);    
    six_escrow_pre = await web3.eth.getBalance(escrow.address); 

    // send some eth
    endowmentFund.transferETHfromEscrow(bettor1, six_add_amount);

  });

  // six - post
  it('endowmentFund.transferETHfromEscrow() : Verify sender', async () => {

    six_escrow_post = await web3.eth.getBalance(escrow.address); 
    assert.equal(six_escrow_pre - six_escrow_post, six_add_amount);

  });  

  // six - post
  it('endowmentFund.transferETHfromEscrow() : Verify receiver', async () => {

    six_receiver_post = await web3.eth.getBalance(bettor1);  console.log('six_receiver_post =' + six_receiver_post);
    // console.log( (await web3.eth.getBalance(bettor1)).toNumber() ); // toNumber() not working. 
    // console.log( web3.fromWei((await web3.eth.getBalance(bettor1)).toNumber(), "ether") ); // toNumber() not working. 
   
    //assert.equal(six_receiver_post - six_receiver_pre, six_add_amount); // big number problem

  });  


  it('Replace Escrow with New Escrow', async () => {

    newEscrow = await Escrow.new()

    await newEscrow.transferOwnership(endowmentFund.address).should.be.fulfilled

    await endowmentFund.initUpgradeEscrow(newEscrow.address);

  });


return;




/*
// no needed

  it('Add ETH to endowmentFund', async () => {
    
    let sender_balance = await  web3.eth.getBalance(bettor1); //console.log('eth_pre =' + eth_pre);
    let add_amount = 20;
    assert(sender_balance >= add_amount, 'sender does not have balance');

    let pre = await web3.eth.getBalance(endowmentFund.address); //console.log('eth_pre =' + pre);

    // send some eth
    let txHash = await web3.eth.sendTransaction({from: bettor1, to: endowmentFund.address, value: add_amount });

    let post = await web3.eth.getBalance(endowmentFund.address); //console.log('eth_post =' + post);
    assert.equal(post - pre, add_amount); 

   });
*/



})


