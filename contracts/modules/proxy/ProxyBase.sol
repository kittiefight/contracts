pragma solidity ^0.5.5;

import '../../ContractManager.sol';
import './ContractNames.sol';

/**
 * @title ProxyBase is a common part for all interface contracts in Proxy,
 * it allows to get addresses of proxied contracts
 */
contract ProxyBase is ContractManager, ContractNames {

    /**
     * Getters for KittyFight system contracts
     */
     function addressOfRegister() public view returns(address)          {return getContract(CONTRACT_NAME_REGISTER);}
     function addressOfProfileDB() public view returns(address)         {return getContract(CONTRACT_NAME_PROFILE_DB);}
     function addressOfKittieHell() public view returns(address)        {return getContract(CONTRACT_NAME_KITTIEHELL);}
     function addressOfKittieHellDB() public view returns(address)      {return getContract(CONTRACT_NAME_KITTIEHELL_DB);}
     function addressOfKittieHellDungeon() public view returns(address) {return getContract(CONTRACT_NAME_KITTIEHELL_DUNGEON);}
     function addressOfGameManager() public view returns(address)       {return getContract(CONTRACT_NAME_GAMEMANAGER);}
     function addressOfGameManagerHelper() public view returns(address) {return getContract(CONTRACT_NAME_GAMEMANAGER_HELPER);}
     function addressOfGMSetterDB() public view returns(address)        {return getContract(CONTRACT_NAME_GM_SETTER_DB);}
     function addressOfGMGetterDB() public view returns(address)        {return getContract(CONTRACT_NAME_GM_GETTER_DB);}
     function addressOfEndowmentDB() public view returns(address)       {return getContract(CONTRACT_NAME_ENDOWMENT_DB);}
     function addressOfTimeContract() public view returns(address)      {return getContract(CONTRACT_NAME_TIMECONTRACT);}
     function addressOfCronJob() public view returns(address)           {return getContract(CONTRACT_NAME_CRONJOB);}
     function addressOfRoleDB() public view returns(address)            {return getContract(CONTRACT_NAME_ROLE_DB);}
     function addressOfEndowmentFund() public view returns(address)     {return getContract(CONTRACT_NAME_ENDOWMENT_FUND);}
     function addressOfDistribution() public view returns(address)      {return getContract(CONTRACT_NAME_DISTRIBUTION);}
     function addressOfGameVarAndFee() public view returns(address)     {return getContract(CONTRACT_NAME_GAMEVARANDFEE);}
     function addressOfForfeiter() public view returns(address)         {return getContract(CONTRACT_NAME_FORFEITER);}
     function addressOfScheduler() public view returns(address)         {return getContract(CONTRACT_NAME_SCHEDULER);}
     function addressOfHitsResolve() public view returns(address)       {return getContract(CONTRACT_NAME_HITSRESOLVE);}
     function addressOfBetting() public view returns(address)           {return getContract(CONTRACT_NAME_BETTING);}
     function addressOfRarityCalculator() public view returns(address)  {return getContract(CONTRACT_NAME_RARITYCALCULATOR);}
     function addressOfTimeFrame() public view returns(address)         {return getContract(CONTRACT_NAME_TIMEFRAME);}
     function addressOfHoneypotAllocationAlgo() public view returns(address) {return getContract(CONTRACT_NAME_HONEYPOT_ALLOCATION_ALGO);}
     function addressOfEarningsTracker() public view returns(address)   {return getContract(CONTRACT_NAME_EARNINGS_TRACKER);}
     function addressOfEarningsTrackerDB() public view returns(address)   {return getContract(CONTRACT_NAME_EARNINGS_TRACKER_DB);}
     function addressOfWithdrawPool() public view returns(address)     {return getContract(CONTRACT_NAME_WITHDRAW_POOL);}
     function addressOfWithdrawPoolGetters() public view returns(address)     {return getContract(CONTRACT_NAME_WITHDRAW_POOL_GETTERS);}
     function addressOfWithdrawPoolYields() public view returns(address)     {return getContract(CONTRACT_NAME_WITHDRAW_POOL_YIELDS);}
     function addressOfEthieToken() public view returns(address)     {return getContract(CONTRACT_NAME_ETHIETOKEN);}
     function addressOfUniswapV2Pair() public view returns(address)     {return getContract(CONTRACT_NAME_UNISWAPV2_PAIR);}
     function addressOfUniswapV2Router() public view returns(address)     {return getContract(CONTRACT_NAME_UNISWAPV2_ROUTER);}
     function addressOfKtyWethOracle() public view returns(address)     {return getContract(CONTRACT_NAME_KTY_WETH_ORACLE);}
     function addressOfKtyUniswap() public view returns(address)     {return getContract(CONTRACT_NAME_KTY_UNISWAP);}
     function addressOfWETH() public view returns(address)     {return getContract(CONTRACT_NAME_WETH);}
     function addressOfDAI() public view returns(address)     {return getContract(CONTRACT_NAME_DAI);}
     function addressOfDaiWethPair() public view returns(address)     {return getContract(CONTRACT_NAME_DAI_WETH_PAIR);}
     function addressOfDaiWethOracle() public view returns(address)     {return getContract(CONTRACT_NAME_DAI_WETH_ORACLE);}
     function addressOfMultiSig() public view returns(address)     {return getContract(CONTRACT_NAME_MULTISIG);}
     function addressOfBusinessInsight() public view returns(address)     {return getContract(CONTRACT_NAME_BUSINESS_INSIGHT);}
     function addressOfAccountingDB() public view returns(address)     {return getContract(CONTRACT_NAME_ACCOUNTING_DB);}
     function addressOfRedeemKittie() public view returns(address)     {return getContract(CONTRACT_NAME_REDEEM_KITTIE);}
     function addressOfListKitties() public view returns(address)     {return getContract(CONTRACT_NAME_LIST_KITTIES);}
}
