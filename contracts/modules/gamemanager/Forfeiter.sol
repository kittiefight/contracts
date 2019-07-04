// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
pragma solidity ^0.5.5;

import "../proxy/Proxied.sol";
import "../databases/GetterDB.sol";
import "./GameManager.sol";
import "../../GameVarAndFee.sol";
import "../../interfaces/ERC721.sol";


/**
 * @title Forfeiter
 * @notice This contracts safeguards any game instances against any unintended outcomes
 * @author wafflemakr
 */
 // TODO: check GameManager implementation, update API calls, and figure out how to test.
contract Forfeiter is Proxied {

  GameManager public gameManager;
  GetterDB public getterDB;
  GameVarAndFee public gameVarAndFee;
  ERC721 public ckc;

  /**
   * @notice Owner can call this function to update the needed contracts for checking conditions
   * @dev contract addresses are stored in proxy
   */
  function updateContracts() external onlyOwner {
    gameManager = GameManager(proxy.getContract(CONTRACT_NAME_GAMEMANAGER));
    getterDB = GetterDB(proxy.getContract(CONTRACT_NAME_GETTER_DB));
    gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
    ckc = ERC721(proxy.getContract(CONTRACT_NAME_CRYPTOKITTIES));
  }

  /**
   * @notice Called each time there is ANY interaction with a game instance within the gameManager
   * @dev function called only by the Game Manager contract
   * @param gameId uint256 game or fight id
   */
  function checkGameStatus(uint256 gameId, uint gameState)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    returns (bool conditions)
  {
    (address playerBlack, address playerRed, uint256 kittyBlack,
      uint256 kittyRed, ,) = getterDB.getGame(gameId);

    // GAME_CREATED
    if (gameState == 0) {
      uint256 gamePreStartTime = getterDB.getPrestartTime(gameId);
      uint supportersBlack = getterDB.getSupporters(gameId, playerBlack);
      uint supportersRed = getterDB.getSupporters(gameId, playerRed);

      conditions = checkPlayersKitties(kittyBlack, kittyRed, playerBlack, playerRed) &&
        checkAmountSupporters(supportersBlack, supportersRed, gamePreStartTime);
    }

    // GAME_PRESTART
    if (gameState == 1) {
      uint256 gameStartTime = getterDB.getStartTime(gameId);
      bool blackStarted = getterDB.didPlayerStart(gameId, playerBlack);
      bool redStarted = getterDB.didPlayerStart(gameId, playerRed);

      conditions = checkPlayersKitties(kittyBlack, kittyRed, playerBlack, playerRed) &&
        didPlayersStartGame(blackStarted, redStarted, gameStartTime);
    }
    

    //If any condition is false, call forfeitGame
    if (!conditions) forfeitGame(gameId);

    return conditions;
  }

  /**
   * @notice calls cancelGame on a game instance within the GamesManager
   * @dev called by "CheckStatus" if any of the required conditions are false
   *  (Not called in case of underPerformed returning true )
   * @param gameId uint256
   */
  function forfeitGame(uint256 gameId) internal {
    gameManager.cancelGame(gameId);
  }

  /**
   * @notice checks that the each player still own listed kittie
   * @param kittieIdBlack uint256 kittieId of Black Corner
   * @param kittieIdRed uint256 kittieId of Red Corner
   * @param playerBlack address of Black Player
   * @param playerRed address of Red Player
   */
  function checkPlayersKitties
  (
    uint kittieIdBlack, uint kittieIdRed,
    address playerBlack, address playerRed
  )
    internal view returns (bool)
  {
    bool checkBlack = ckc.ownerOf(kittieIdBlack) == playerBlack;
    bool checkRed = ckc.ownerOf(kittieIdRed) == playerRed;

    return (checkBlack && checkRed);
  }

  /**
   * @notice checks for correct amount of supporters in each side when prestart time is reached
   * @param supportersBlack uint256 amount of supporters in black corner
   * @param supportersRed uint256 amount of supporters in red corner
   * @param gamePreStartTime uint256 time when game starts 2 min countdown
   */
  function checkAmountSupporters(uint supportersBlack, uint supportersRed, uint gamePreStartTime)
    internal view returns (bool)
  { 
    if (gamePreStartTime <= now) {
      uint minSupporters = gameVarAndFee.getMinimumContributors();
      return (supportersBlack > minSupporters) && (supportersRed > minSupporters);
    }
    
    return true;
  }

  /**
   * @notice Check if any of players did not hit start when game start time is reached
   * @param blackStarted bool if black player hit start
   * @param redStarted bool if red player hit start
   * @param gameStartTime uint256 time when 2 min countdown ends
   */
  function didPlayersStartGame(bool blackStarted, bool redStarted, uint gameStartTime)
    internal view returns (bool)
  {
    if (gameStartTime <= now) return blackStarted && redStarted;
    return true;
  }
}