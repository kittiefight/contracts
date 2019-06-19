pragma solidity ^0.5.5;

import '../../authority/Guard.sol';
import '../gamemanager/GameManager.sol';
import './ProxyBase.sol';

/**
 * @title RegisterProxy defines public API of Register contract
 * and redirects calls to Register instance
 * @author @psychoplasma
 */
contract GameManagerProxy is ProxyBase, Guard{

  function manualMatchKitties
  (
    address playerRed, address playerBlack,
    uint256 kittyRed, uint256 kittyBlack
  )
    external
    onlySuperAdmin
  {
    GameManager(addressOfGameManager()).manualMatchKitties(playerRed, playerBlack, kittyRed, kittyBlack);
  }

  function startGame(uint gameId) external onlyPlayer {
    GameManager(addressOfGameManager()).startGame(gameId);
  }
}
