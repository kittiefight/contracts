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
import "./GenericDB.sol";
import "../../libs/SafeMath.sol";


/**
 * @dev Stores game instances
 * @author @psychoplasma
 */
contract GameManagerDB is Proxied {
  using SafeMath for uint256;

  GenericDB public genericDB;

  bytes32 internal constant TABLE_KEY_GAME= keccak256(abi.encodePacked("GameTable"));
  string internal constant TABLE_NAME_BETTOR = "BettorTable";
  string internal constant ERROR_DOES_NOT_EXIST = "Game does not exist";
  string internal constant ERROR_CANNOT_SUPPORT_BOTH = "Cannot support both players";
  string internal constant ERROR_INVALID_CURRENCY = "Invalid currency for bet";

  modifier onlyExistentGame(uint256 gameId) {
    require(doesGameExist(gameId), ERROR_DOES_NOT_EXIST);
    _;
  }

  constructor(GenericDB _genericDB) public {
    setGenericDB(_genericDB);
  }

  function setGenericDB(GenericDB _genericDB) public onlyOwner {
    genericDB = _genericDB;
  }

  /**
   * @dev Creates a new game item on game table
   */
  function createGame(address playerRed, address playerBlack, uint256 kittyRed, uint256 kittyBlack)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    returns (uint256 gameId)
  {
    // Get the lastest item in the linkedlist.
    // Note that 0 means the HEAD of the list always and direction(false)
    //  indicates that we are going to the end of the list.
    (,uint256 prevGameId) = genericDB.getAdjacent(CONTRACT_NAME_GAMEMANAGER_DB, TABLE_KEY_GAME, 0, false);
    // And create new item with an incremental id.
    // Note that we don't need to check any existance here, because
    // exsistance of the previous item in the list already self-verifies.
    gameId = prevGameId.add(1);
    genericDB.pushNodeToLinkedList(CONTRACT_NAME_GAMEMANAGER_DB, TABLE_KEY_GAME, gameId);

    // Save players for the created game
    genericDB.setAddressStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "playerRed")), playerRed);
    genericDB.setAddressStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "playerBlack")), playerBlack);

    // Set kitties for the given players
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, playerRed, "kitty")), kittyRed);
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, playerBlack, "kitty")), kittyBlack);

    // solium-disable-next-line security/no-block-members
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "createdAt")), block.timestamp);
  }

  /**
   * @dev Adds a bettor to the given game iff the game exists.
   * If the bettor already exists in the game, updates her bet.
   */
  function addBettor(uint256 gameId, address bettor, uint256 betAmount, address supportedPlayer)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(gameId)
  {
    // If bettor does not exist in the game given, add her to the game.
    if (!genericDB.doesNodeAddrExist(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, TABLE_NAME_BETTOR)), bettor)) {
      // Add the bettor to the bettor table.
      genericDB.pushNodeToLinkedListAddr(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, TABLE_NAME_BETTOR)), bettor);
      // Save the supported player for this bettor
      genericDB.setAddressStorage(
        CONTRACT_NAME_GAMEMANAGER_DB,
        keccak256(abi.encodePacked(gameId, bettor, "supportedPlayer")),
        supportedPlayer
      );
      // And increase the number of supporters for that player
      incrementSupporters(gameId, supportedPlayer);
    }

    // Get the supported player for this bettor
    address _supportedPlayer = genericDB.getAddressStorage(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(gameId, bettor, "supportedPlayer"))
    );

    // Check if the supported player is same in case of additional bet
    require(_supportedPlayer != supportedPlayer, ERROR_CANNOT_SUPPORT_BOTH);

    // Update bettor's total bet amount
    updateBet(gameId, bettor, betAmount);

    // Update total bet amount in the game
    updateTotalBet(gameId, betAmount);
  }

  /**
   * @dev Updates the amount of bet for the given bettor in the given game by the given amount.
   */
  function updateBet(uint256 gameId, address bettor, uint256 amount) internal {
    uint256 prevAmount = genericDB.getUintStorage(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(gameId, bettor, "betAmount"))
    );
    genericDB.setUintStorage(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(gameId, bettor, "betAmount")),
      prevAmount.add(amount)
    );
  }

  /**
   * @dev Updates the total amount of bet in the given game by the given amount.
   */
  function updateTotalBet(uint256 gameId, uint256 amount) internal {
    uint256 prevAmount = genericDB.getUintStorage(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(gameId, "totalBetAmount"))
    );

    genericDB.setUintStorage(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(gameId, "totalBetAmount")),
      prevAmount.add(amount)
    );
  }

  /**
   * @dev Increments the number of supporters for the given player
   */
  function incrementSupporters(uint256 gameId, address player) internal {
    // Increment number of supporters by one
    uint256 supporters = genericDB.getUintStorage(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(gameId, player, "supporters"))
    );
    genericDB.setUintStorage(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(gameId, player, "supporters")),
      supporters.add(1)
    );
  }

  /**
   * @dev Returns the total amount of bet of the given bettor
   * and the player supported by that bettor in the game given.
   */
  function getBettor(uint256 gameId, address bettor)
    public view
    returns (uint256 betAmount, address supportedPlayer)
  {
    betAmount = genericDB.getUintStorage(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(gameId, bettor, "betAmount"))
    );
    supportedPlayer = genericDB.getAddressStorage(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(gameId, bettor, "supportedPlayer"))
    );
  }

  /**
   * @dev Returns players, fighter kitties' ids,
   * total amount of bet and the timestamp of creation of this game.
   */
  function getGame(uint256 gameId)
    public view
    onlyExistentGame(gameId)
    returns (address playerBlack, address playerRed, uint256 kittyBlack, uint256 kittyRed, uint256 totalBet, uint256 createdAt)
  {
    playerBlack = genericDB.getAddressStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "playerBlack")));
    playerRed = genericDB.getAddressStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "playerRed")));
    kittyBlack = genericDB.getUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, playerRed, "kitty")));
    kittyRed = genericDB.getUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, playerBlack, "kitty")));
    totalBet = genericDB.getUintStorage(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(gameId, "totalBetAmount"))
    );
    createdAt = genericDB.getUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "createdAt")));
  }

  /**
   * @dev Checks whether the given player is playing in the given game.
   */
  function isPlayer(uint256 gameId, address player) public view returns (bool) {
    address playerRed = genericDB.getAddressStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "playerRed")));
    if (player == playerRed) {
      return true;
    }

    address playerBlack = genericDB.getAddressStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "playerBlack")));
    if (player == playerBlack) {
      return true;
    }

    return false;
  }

  function doesGameExist(uint256 gameId) public view returns (bool) {
    return genericDB.doesNodeExist(CONTRACT_NAME_GAMEMANAGER_DB, TABLE_KEY_GAME, gameId);
  }
}
