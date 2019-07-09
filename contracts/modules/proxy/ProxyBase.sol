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
     function addressOfGameManager() public view returns(address)       {return getContract(CONTRACT_NAME_GAMEMANAGER);}
     function addressOfGameManagerDB() public view returns(address)     {return getContract(CONTRACT_NAME_GAMEMANAGER_DB);}
     function addressOfTimeContract() public view returns(address)      {return getContract(CONTRACT_NAME_TIMECONTRACT);}
     function addressOfCronJob() public view returns(address)           {return getContract(CONTRACT_NAME_CRONJOB);}
     function addressOfRoleDB() public view returns(address)            {return getContract(CONTRACT_NAME_ROLE_DB);}
     function addressOfHitsResolve() public view returns(address)       {return getContract(CONTRACT_NAME_HITSRESOLVE);}
}
