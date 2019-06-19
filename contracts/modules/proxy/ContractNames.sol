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
    string constant CONTRACT_NAME_KITTIEHELL        = "KittieHell";
    string constant CONTRACT_NAME_KITTIEHELL_DB     = "KittieHellDB";
    string constant CONTRACT_NAME_GAMEMANAGER       = "GameManager";
    string constant CONTRACT_NAME_GAMEMANAGER_DB    = "GameManagerDB";
    string constant CONTRACT_NAME_TIMECONTRACT      = "TimeContract";
    string constant CONTRACT_NAME_CRONJOB           = "CronJob";
    string constant CONTRACT_NAME_GAMEVARANDFEE     = "GameVarAndFee";
    string constant CONTRACT_NAME_ROLE_DB           = "RoleDB";
}
