pragma solidity ^0.5.5;

import "./libs/zos-lib/Initializable.sol";
import "./modules/proxy/ProxyBase.sol";
//import "./modules/proxy/KittieHellProxy.sol";
// import "./modules/proxy/GameVarAndFeeProxy.sol";
//Generates inheritance conflict, need to create interface
import "./modules/proxy/RegisterProxy.sol";
import "./modules/proxy/GameManagerProxy.sol";

/**
 * @title Proxy contract is a main entry point for KittyFight contract system
 * @author @pash7ka
 */
contract KFProxy is
    Initializable,          //Allows to use ZeppelinOS Proxy
    ProxyBase,
    //List of public interfaces this proxy supports
    // GameVarAndFeeProxy,
    //KittieHellProxy
    RegisterProxy,
    GameManagerProxy
{

    /**
     * This function should be run instead of constructor
     * See https://docs.zeppelinos.org/docs/pattern.html#the-constructor-caveat
     */
    function initialize() initializer public {
        //TODO: Initialize contract addressses here or in separate function
    }




}
