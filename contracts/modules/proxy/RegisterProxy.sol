pragma solidity ^0.5.5;

import '../../authority/Guard.sol';
import '../registration/Register.sol';
import './ProxyBase.sol';

/**
 * @title RegisterProxy defines public API of Register contract
 * and redirects calls to Register instance
 * @author @psychoplasma
 */
contract RegisterProxy is ProxyBase, Guard {
  function register(address account) external {
    Register(addressOfRegister()).register(account);
  }
}
