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

  function listKittie(uint kittieId) external {
    GameManager(addressOfGameManager()).listKittie(kittieId, msg.sender);
  }

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

  function startGame(uint gameId, uint randNum) external onlyPlayer {
    GameManager(addressOfGameManager()).startGame(gameId, msg.sender, randNum);
  }

  // changed onlyBettor instead of onlyPlayer modifier
  // add fighter as a bettor so we can use onlyBettor for both roles
  function participate(uint gameId, address playerToSupport) external onlyBettor {
    GameManager(addressOfGameManager()).participate(gameId, msg.sender, playerToSupport);
  }

  function bet
  (
    uint gameId, uint amountKTY,
    address supportedPlayer, uint randomNum
  )
    external
    payable
    onlyBettor
  {
    GameManager(addressOfGameManager()).bet(gameId, msg.sender, msg.value, amountKTY, supportedPlayer, randomNum);
  }
}
