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
import "../databases/GMGetterDB.sol";
import "./GameStore.sol";
import "./GameManager.sol";
import "../../GameVarAndFee.sol";
import "../../interfaces/ERC721.sol";
import '../kittieHELL/KittieHell.sol';
import '../kittieHELL/KittieHellDungeon.sol';
import "./GameManagerHelper.sol";

/**
 * @title Forfeiter
 * @notice This contracts safeguards any game instances against any unintended outcomes
 * @author wafflemakr
 */
contract Forfeiter is Proxied {

  GameStore public gameStore;
  GameManager public gameManager;
  GMGetterDB public gmGetterDB;
  GameVarAndFee public gameVarAndFee;
  ERC721 public ckc;
  KittieHell public kittieHELL;
  KittieHellDungeon public kittieHellDungeon;
  GameManagerHelper public gameManagerHelper;

  uint256 public constant UNDERSUPPORTED = 0;
  uint256 public constant KITTIE_LEFT = 1;
  uint256 public constant NOT_HIT_START = 2;

  event GameCancelled(uint gameId, string reason);

  /**
   * @notice Owner can call this function to update the needed contracts for checking conditions
   * @dev contract addresses are stored in proxy
   */
  function initialize() external onlyOwner {
    gameManager = GameManager(proxy.getContract(CONTRACT_NAME_GAMEMANAGER));
    gameStore = GameStore(proxy.getContract(CONTRACT_NAME_GAMESTORE));
    gmGetterDB = GMGetterDB(proxy.getContract(CONTRACT_NAME_GM_GETTER_DB));
    gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
    ckc = ERC721(proxy.getContract(CONTRACT_NAME_CRYPTOKITTIES));
    kittieHELL = KittieHell(proxy.getContract(CONTRACT_NAME_KITTIEHELL));
    kittieHellDungeon = KittieHellDungeon(proxy.getContract(CONTRACT_NAME_KITTIEHELL_DUNGEON));
    gameManagerHelper = GameManagerHelper(proxy.getContract(CONTRACT_NAME_GAMEMANAGER_HELPER));
  }

  /**
   * @notice Called each time there is ANY interaction with a game instance within the gameManager
   * @dev function called only by the Game Manager contract
   * @param gameId uint256 game or fight id
   */
  function checkStatus(uint256 gameId, uint gameState)
    internal
  {
    (address playerBlack, address playerRed, uint256 kittyBlack,
      uint256 kittyRed) = gmGetterDB.getGamePlayers(gameId);

    // GAME_CREATED
    if (gameState == 0) {
      (,uint256 gamePreStartTime,) = gmGetterDB.getGameTimes(gameId);
      uint supportersBlack = gmGetterDB.getSupporters(gameId, playerBlack);
      uint supportersRed = gmGetterDB.getSupporters(gameId, playerRed);

      bool check = checkPlayersKitties(gameId, kittyBlack, kittyRed, playerBlack, playerRed);
      //if previous check passes, check players start
       if(check) checkAmountSupporters(gameId, supportersBlack, supportersRed, gamePreStartTime);
    }

    // GAME_PRESTART
    if (gameState == 1) {
      (uint256 gameStartTime,,) = gmGetterDB.getGameTimes(gameId);
      bool redStarted = gameManagerHelper.didHitStart(gameId, playerRed);
      bool blackStarted = gameManagerHelper.didHitStart(gameId, playerBlack);

      bool check = checkPlayersKitties(gameId, kittyBlack, kittyRed, playerBlack, playerRed); // TODO check why it fails here
      //if previous check passes, check players start
      if(check) didPlayersStartGame(gameId, blackStarted, redStarted, gameStartTime);
    }
  }

  /**
   * @notice calls cancelGame on a game instance within the GamesManager
   * @dev called by "CheckStatus" if any of the required conditions are false
   *  (Not called in case of underPerformed returning true )
   * @param gameId uint256
   */
  function forfeitGame(uint256 gameId, string memory reason) internal {
    (/*address playerBlack*/, /*address playerRed*/, uint256 kittyBlack,
      uint256 kittyRed) = gmGetterDB.getGamePlayers(gameId);
    if(ckc.ownerOf(kittyBlack) == address(kittieHellDungeon)) kittieHELL.releaseKittyGameManager(kittyBlack);
    if(ckc.ownerOf(kittyRed) == address(kittieHellDungeon)) kittieHELL.releaseKittyGameManager(kittyRed);
    gameManager.cancelGame(gameId);
    emit GameCancelled(gameId, reason);
  }

  function forfeitCron(uint256 gameId, string calldata reason)
    external
    onlyContract(CONTRACT_NAME_GAMECREATION)
  {
    forfeitGame(gameId, reason);
  }

  function checkGameStatusCron(uint256 gameId, uint state)
    external
    onlyContract(CONTRACT_NAME_GAMECREATION)
  {
    checkStatus(gameId, state);
  }

  function checkGameStatus(uint256 gameId, uint state)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
  {
    checkStatus(gameId, state);
  }

  /**
   * @notice checks that the each player still own listed kittie
   * @dev it can also be owned by kittie hell
   * @param kittieIdBlack uint256 kittieId of Black Corner
   * @param kittieIdRed uint256 kittieId of Red Corner
   * @param playerBlack address of Black Player
   * @param playerRed address of Red Player
   */
  function checkPlayersKitties
  (
    uint gameId, uint kittieIdBlack, uint kittieIdRed,
    address playerBlack, address playerRed
  )
    internal
    returns(bool)
  {
    bool checkBlack;
    bool checkRed;

    //When one player hits start, that kittie is owned by kittieHELL
    if (ckc.ownerOf(kittieIdBlack) == address(kittieHellDungeon)) checkBlack = true;
    else if(ckc.ownerOf(kittieIdBlack) == playerBlack) checkBlack = true;
    else checkBlack = false;

    if(ckc.ownerOf(kittieIdRed) == address(kittieHellDungeon)) checkRed = true;
    else if(ckc.ownerOf(kittieIdRed) == playerRed) checkRed = true;
    else checkRed = false;

    if (!(checkBlack && checkRed)) {
      forfeitGame(gameId, 'Kittie Left');
      return false;
    }

    return true;
  }

  /**
   * @notice checks for correct amount of supporters in each side when prestart time is reached
   * @param supportersBlack uint256 amount of supporters in black corner
   * @param supportersRed uint256 amount of supporters in red corner
   * @param gamePreStartTime uint256 time when game starts 2 min countdown
   */
  function checkAmountSupporters(uint gameId, uint supportersBlack, uint supportersRed, uint gamePreStartTime)
    internal
    returns(bool)
  {
    if (gamePreStartTime <= now) {
      uint minSupporters = gameManagerHelper.getMinimumContributors(gameId); //TODO: should call getterDB as vars and fees are locked
      if(supportersBlack < minSupporters || supportersRed < minSupporters){
        forfeitGame(gameId, "Undersupported");
        return false;
      }
    }

    return true;
  }

  /**
   * @notice Check if any of players did not hit start when game start time is reached
   * @param blackStarted bool if black player hit start
   * @param redStarted bool if red player hit start
   * @param gameStartTime uint256 time when 2 min countdown ends
   */
  function didPlayersStartGame(uint gameId, bool blackStarted, bool redStarted, uint gameStartTime)
    internal
  {
    if (gameStartTime <= now){
      if(!blackStarted || !redStarted) forfeitGame(gameId, "Did not hit start");
    }
  }
}
