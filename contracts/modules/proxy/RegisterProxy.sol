pragma solidity ^0.5.5;

import '../../authority/Guard.sol';
import '../registration/Register.sol';
import './ProxyBase.sol';
import "../proxy/Proxied.sol";

/**
 * @title RegisterProxy defines public API of Register contract
 * and redirects calls to Register instance
 * @author @psychoplasma
 */
contract RegisterProxy is ProxyBase, Guard {

  function register() external {
    Register(addressOfRegister()).register(msg.sender);
  }

  function lockKittie(uint256 kittieId)
    external
    onlyBettor // Or player, but players have already got also bettor role when they registered. Therefore it's safe to assume that only bettor role can lock kittie
  {
    Register(addressOfRegister()).lockKittie(msg.sender, kittieId);
  }

  function releaseKittie(uint256 kittieId)
    external
    onlyPlayer
  {
    Register(addressOfRegister()).releaseKittie(msg.sender, kittieId);
  }

  function sendTokensTo(address to, uint256 amount)
    external
    onlyBettor
  {
    Register(addressOfRegister()).sendTokensTo(msg.sender, to, amount);
  }

  function exchangeTokensForEth(uint256 amount)
    external
    onlyBettor
  {
    Register(addressOfRegister()).exchangeTokensForEth(msg.sender, amount);
  }

  function stakeSuperDAO(uint256 amount)
    external
    onlyBettor
  {
    Register(addressOfRegister()).stakeSuperDAO(msg.sender, amount);
  }

  function payFees(uint256 amount)
    external
    onlyBettor
  {
    Register(addressOfRegister()).payFees(msg.sender, amount);
  }

  function lockTokens(uint256 amount)
    external
    onlyBettor
  {
    Register(addressOfRegister()).lockTokens(msg.sender, amount);
  }

  function releaseTokens(uint256 amount)
    external
    onlyBettor
  {
    Register(addressOfRegister()).releaseTokens(msg.sender, amount);
  }
}
