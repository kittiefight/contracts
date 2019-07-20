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
    string constant CONTRACT_NAME_REGISTER          = "Register";
    string constant CONTRACT_NAME_PROFILE_DB        = "ProfileDB";
    string constant CONTRACT_NAME_KITTIEFIGHTOKEN   = "KittieFightToken";
    string constant CONTRACT_NAME_KITTIEHELL        = "KittieHell";
    string constant CONTRACT_NAME_KITTIEHELL_DB     = "KittieHellDB";
    string constant CONTRACT_NAME_GAMEMANAGER       = "GameManager";
    string constant CONTRACT_NAME_GM_SETTER_DB      = "GMSetterDB";
    string constant CONTRACT_NAME_GM_GETTER_DB      = "GMGetterDB";
    string constant CONTRACT_NAME_ENDOWMENT_FUND    = "EndowmentFund";
    string constant CONTRACT_NAME_ENDOWMENT_DB      = "EndowmentDB";
    string constant CONTRACT_NAME_TIMECONTRACT      = "TimeContract";
    string constant CONTRACT_NAME_CRONJOB           = "CronJob";
    string constant CONTRACT_NAME_GAMEVARANDFEE     = "GameVarAndFee";
    string constant CONTRACT_NAME_ROLE_DB           = "RoleDB";
    string constant CONTRACT_NAME_DISTRIBUTION      = "Distribution";
    string constant CONTRACT_NAME_FORFEITER         = "Forfeiter";
    string constant CONTRACT_NAME_SCHEDULER         = "Scheduler";
    string constant CONTRACT_NAME_BETTING           = "Betting";
    string constant CONTRACT_NAME_HITSRESOLVE       = "HitsResolve";
    string constant CONTRACT_NAME_RARITYCALCULATOR  = "RarityCalculator";
    string constant CONTRACT_NAME_CRYPTOKITTIES     = "CryptoKitties";
    string constant CONTRACT_NAME_ESCROW            = "Escrow";

}
