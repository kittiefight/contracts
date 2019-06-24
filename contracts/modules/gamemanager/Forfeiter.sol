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
import "../databases/GameManagerDB.sol";
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
  GameVarAndFee public gameVarAndFee;
  ERC721 public ckc;
  address public register;

  /**
   * @notice Owner can call this function to update the needed contract for checking conditions
   * @dev contract addresses are stored in proxy
   */
  // ALTERNATIVE: call proxy.getContract in every checkGameStatus call and remove this function
  function updateContracts() external onlyOwner {
    gameManager = GameManager(proxy.getContract(CONTRACT_NAME_GAMEMANAGER));
    gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
    ckc = ERC721(proxy.getContract(CONTRACT_NAME_CRYPTOKITTIES));
    register = proxy.getContract(CONTRACT_NAME_REGISTER);
  }

  /**
   * @notice Called each time there is ANY interaction with a game instance within the gameManager
   * @dev function called only by the Game Manager contract
   * @param gameId uint256 game or fight id
   */
  function checkGameStatus(uint256 gameId)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
  {
    //TODO: Define what the GameManager sends as params (fight struct?), and get fight details
    //gameManager.gameState(gameId);

    //Mock response from GameManager
    uint kittieIdBlack = 1;
    uint kittieIdRed = 2;
    uint supportersBlack = 105;
    uint supportersRed = 98;
    uint gamePreStartTime = now + 100;
    uint gameStartTime = now + 220;
    bool blackStarted = true;
    bool redStarted = true;

    bool conditions = checkPlayersKitties(kittieIdBlack, kittieIdRed) &&
      checkAmountSupporters(supportersBlack, supportersRed, gamePreStartTime) &&
      didPlayersStartGame(blackStarted, redStarted, gameStartTime);

    //If any condition is false, call forfeitGame
    if (!(conditions)) forfeitGame(gameId);

    //TODO: Do we need to return something?
  }

  /**
   * @notice calls cancelGame on a game instance within the GamesManager
   * @dev called by "CheckStatus" if any of the required conditions are false
   *  (Not called in case of underPerformed returning true )
   * @param gameId uint256
   */
  function forfeitGame(uint256 gameId) internal {
    //gameManager.cancelGame(gameId);
  }

  /**
   * @notice checks that the register contract is owner of the kitties
   * @param kittieIdBlack uint256 kittieId of Black Corner
   * @param kittieIdRed uint256 kittieId of Red Corner
   */
  function checkPlayersKitties(uint kittieIdBlack, uint kittieIdRed)
    internal view returns (bool)
  {
    bool checkBlack = ckc.ownerOf(kittieIdBlack) == register;
    bool checkRed = ckc.ownerOf(kittieIdRed) == register;

    return (checkBlack && checkRed);
  }

  /**
   * @notice checks for correct amount of supporters in each side
   * @param supportersBlack uint256 amount of supporters in black corner
   * @param supportersRed uint256 amount of supporters in red corner
   * @param gamePreStartTime uint256 time when game starts 2 min countdown
   */
  function checkAmountSupporters(uint supportersBlack, uint supportersRed, uint gamePreStartTime)
    internal view returns (bool)
  {
    //Get minSupporters from GameVarAndFee contract
    //uint minSupporters = gameVarAndFee.getMinimumContributors();

    uint minSupporters = 100;

    return (supportersBlack > minSupporters) && (supportersRed > minSupporters) && (gamePreStartTime > now);

  }

  /**
   * @notice both players have to trigger "startGame" within 2 minutes
   * @param blackStarted bool if black player hit start
   * @param redStarted bool if red player hit start
   * @param gameStartTime uint256 time when 2 min countdown ends
   */
  function didPlayersStartGame(bool blackStarted, bool redStarted, uint gameStartTime)
    internal view returns (bool)
  {
    return (gameStartTime > now) && blackStarted && redStarted;
  }
}