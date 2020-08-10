pragma solidity ^0.5.5;

/**
 * @title ContractNames defines Names of KittyFight system contracts, 
 * used to load/store their deployed addresses in ContractManager
 */
contract ContractNames {

    /**
     * Names of KittyFight system contracts, used to load/store their deployed
     * addresses in ContractManager
     */
    string constant CONTRACT_NAME_GENERIC_DB        = "GenericDB";
    string constant CONTRACT_NAME_REGISTER          = "Register";
    string constant CONTRACT_NAME_PROFILE_DB        = "ProfileDB";
    string constant CONTRACT_NAME_KITTIEFIGHTOKEN   = "KittieFightToken";
    string constant CONTRACT_NAME_KITTIEHELL        = "KittieHell";
    string constant CONTRACT_NAME_KITTIEHELL_DB     = "KittieHellDB";
    string constant CONTRACT_NAME_KITTIEHELL_DUNGEON     = "KittieHellDungeon";
    string constant CONTRACT_NAME_GAMEMANAGER       = "GameManager";
    string constant CONTRACT_NAME_GAMESTORE         = "GameStore";
    string constant CONTRACT_NAME_GAMECREATION      = "GameCreation";
    string constant CONTRACT_NAME_GM_SETTER_DB      = "GMSetterDB";
    string constant CONTRACT_NAME_GM_GETTER_DB      = "GMGetterDB";
    string constant CONTRACT_NAME_ENDOWMENT_FUND    = "EndowmentFund";
    string constant CONTRACT_NAME_ENDOWMENT_DB      = "EndowmentDB";
    string constant CONTRACT_NAME_TIMECONTRACT      = "TimeContract";
    string constant CONTRACT_NAME_CRONJOB           = "CronJob";
    string constant CONTRACT_NAME_GAMEVARANDFEE     = "GameVarAndFee";
    string constant CONTRACT_NAME_ROLE_DB           = "RoleDB";
    string constant CONTRACT_NAME_FREEZE_INFO       = "FreezeInfo";
    string constant CONTRACT_NAME_DISTRIBUTION      = "Distribution";
    string constant CONTRACT_NAME_FORFEITER         = "Forfeiter";
    string constant CONTRACT_NAME_SCHEDULER         = "Scheduler";
    string constant CONTRACT_NAME_BETTING           = "Betting";
    string constant CONTRACT_NAME_HITSRESOLVE       = "HitsResolve";
    string constant CONTRACT_NAME_RARITYCALCULATOR  = "RarityCalculator";
    string constant CONTRACT_NAME_CRYPTOKITTIES     = "CryptoKitties";
    string constant CONTRACT_NAME_TIMEFRAME         = "TimeFrame";
    string constant CONTRACT_NAME_HONEYPOT_ALLOCATION_ALGO = "HoneypotAllocationAlgo";
    string constant CONTRACT_NAME_EARNINGS_TRACKER  = "EarningsTracker";
    string constant CONTRACT_NAME_EARNINGS_TRACKER_DB  = "EarningsTrackerDB";
    string constant CONTRACT_NAME_WITHDRAW_POOL   = "WithdrawPool";
    string constant CONTRACT_NAME_WITHDRAW_POOL_GETTERS   = "WithdrawPoolGetters";
    string constant CONTRACT_NAME_ETHIETOKEN   = "EthieToken";
    string constant CONTRACT_NAME_UNISWAPV2_PAIR   = "UniswapV2Pair";
    string constant CONTRACT_NAME_UNISWAPV2_ROUTER   = "UniswapV2Router01";
    string constant CONTRACT_NAME_KTY_WETH_ORACLE   = "KtyWethOracle";
    string constant CONTRACT_NAME_KTY_UNISWAP   = "KtyUniswap";
    string constant CONTRACT_NAME_WETH = "WETH9";
    string constant CONTRACT_NAME_DAI = "Dai";
    string constant CONTRACT_NAME_DAI_WETH_PAIR = "IDaiWethPair";
    string constant CONTRACT_NAME_DAI_WETH_ORACLE   = "DaiWethOracle";
    string constant CONTRACT_NAME_MULTISIG = "Multisig5of12";
    string constant CONTRACT_NAME_BUSINESS_INSIGHT = "BusinessInsight";
}
