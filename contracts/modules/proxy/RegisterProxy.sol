pragma solidity ^0.5.5;

import '../registration/Register.sol';
import './ProxyBase.sol';

/**
 * @title RegisterProxy defines public API of Register contract
 * and redirects calls to Register instance
 */
contract RegisterProxy is ProxyBase {
    function register(/*TODO: add arguments*/) public returns(bool /*TODO: replace with actual return type*/){
        //return Register(addressOfRegister()).register(/*TODO: add arguments*/);
        return false;
    }
}
