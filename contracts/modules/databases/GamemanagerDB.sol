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

  uint256 public constant PLAYER_STATUS_INITIATED = 1;
  uint256 public constant PLAYER_STATUS_PLAYING = 2;
  uint256 public constant GAME_STATE_CREATED = 0;
  uint256 public constant GAME_STATE_STARTED = 1;
  uint256 public constant GAME_STATE_CANCELLED = 2;
  uint256 public constant GAME_STATE_FINISHED = 3;

  bytes32 internal constant TABLE_KEY_GAME= keccak256(abi.encodePacked("GameTable"));
  string internal constant TABLE_NAME_BET = "BetTable";
  string internal constant ERROR_ALREADY_EXIST = "Game already exists";
  string internal constant ERROR_DOES_NOT_EXIST = "Game does not exist";
  string internal constant ERROR_PLAYER_DOES_NOT_EXIST = "Player does not exist";
  string internal constant ERROR_BET_DOES_NOT_EXIST = "Bet does not exist";

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

    // Save players. Note that this is not really necessary
    // but provides a convenience when querying players by team.
    genericDB.setAddressStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "playerRed")), playerRed);
    genericDB.setAddressStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "playerBlack")), playerBlack);

    // Set kitties for the given players
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, playerRed, "kitty")), kittyRed);
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, playerBlack, "kitty")), kittyBlack);
  }

  function updatePlayerStatus(uint256 gameId, address player, uint256 status)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(gameId)
  {

    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, player, "status")), status);
  }

  function updateGameState(uint256 gameId, uint256 state)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(gameId)
  {
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "state")), state);
  }

  function updateBetStatus(uint256 gameId, uint256 betId, uint256 status)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(gameId)
  {
    require(
      genericDB.doesNodeExist(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, TABLE_NAME_BET)), betId),
      ERROR_BET_DOES_NOT_EXIST
    );
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, betId, "status")), status);
  }

  /**
   * @dev Adds a bet to the given game iff the game exists.
   */
  function addBet(uint256 gameId, uint256 betAmount, address supportedPlayer)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(gameId)
    returns (uint256 betId)
  {
    // Get the lastest item in the linkedlist.
    // Note that 0 means the HEAD of the list always and direction(false)
    // indicates that we are going to the end of the list.
    (,uint256 prevBetId) = genericDB.getAdjacent(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(gameId, TABLE_NAME_BET)),
      0,
      false
    );
    // And create new item with an incremental id.
    // Note that we don't need to check any existance here, because
    // exsistance of the previous item in the list already self-verifies.
    betId = prevBetId.add(1);
    genericDB.pushNodeToLinkedList(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, TABLE_NAME_BET)), betId);

    // Save bet amount
    genericDB.setUintStorage(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(gameId, betId, "betAmount")),
      betAmount
    );

    // Save the supported player
    genericDB.setAddressStorage(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(gameId, betId, "supportedPlayer")),
      supportedPlayer
    );

    // Bet attribute:isClaimed is 0:false by default,
    // and we don't set it expilicitly to save some gas.
    // Set attribute:isClaimed to 1:true when updating it.
  }

  /**
   * @dev Removes a bet from the given game and returns the removed amount.
   */
  function removeBet(uint256 gameId, uint256 betId)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(gameId)
    returns (uint256 totalBetAmount)
  {
    // Check whether the bet exists
    require(
      genericDB.doesNodeExist(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, TABLE_NAME_BET)), betId),
      ERROR_BET_DOES_NOT_EXIST
    );

    // Get the total contribution for the given player and return it to the caller
    totalBetAmount = genericDB.getUintStorage(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(gameId, betId, "betAmount"))
    );

    // Clear data fields related to this bettor
    genericDB.setUintStorage(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(gameId, betId, "betAmount")),
      0
    );

    genericDB.setAddressStorage(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(gameId, betId, "supportedPlayer")),
      address(0)
    );
  }

  function getPlayer(uint256 gameId, address player)
    public view
    onlyExistentGame(gameId)
    returns (uint256 kittieId, uint256 status)
  {
    kittieId = genericDB.getUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, player, "kittie")));
    status = genericDB.getUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, player, "status")));
  }

  function doesGameExist(uint256 gameId) public view returns (bool) {
    return genericDB.doesNodeExist(CONTRACT_NAME_GAMEMANAGER_DB, TABLE_KEY_GAME, gameId);
  }
}
