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
  string internal constant ERROR_ALREADY_EXIST = "Game already exists";
  string internal constant ERROR_DOES_NOT_EXIST = "Game does not exist";
  string internal constant ERROR_PLAYER_DOES_NOT_EXIST = "Player does not exist";
  string internal constant ERROR_BETTOR_DOES_NOT_EXIST = "Bettor does not exist";

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
  function createGame(address playerRed, address playerBlack, uint256 redKittie, uint256 blackKittie)
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

    // Save players
    genericDB.setAddressStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "playerRed")), playerRed);
    genericDB.setAddressStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "playerBlack")), playerBlack);

    // Save fighting kitties
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "redKittie")), redKittie);
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "blackKittie")), blackKittie);
  }

  function updatePlayerState(uint256 gameId, address player, bool isInitiated)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(gameId)
  {

  }

  function updateGameState(uint256 gameId, string calldata state)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(gameId)
  {

  }

  /**
   * @dev Adds a bettor to the given game iff the game exists.
   * if the bettor already exists in the game, it updates her
   * total bet amount.
   */
  function addBettor(uint256 gameId, address bettor, uint256 betAmount, address supportedPlayer)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(gameId)
  {
    // Check if bettor exists
    if (!genericDB.doesNodeAddrExist(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, TABLE_NAME_BETTOR)), bettor)) {
      genericDB.pushNodeToLinkedListAddr(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, TABLE_NAME_BETTOR)), bettor);
    }
    // And update bet amount for the given player
    uint256 prevBetAmount = genericDB.getUintStorage(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(gameId, TABLE_NAME_BETTOR, "betAmount"))
    );
    genericDB.setUintStorage(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(gameId, TABLE_NAME_BETTOR, "betAmount")),
      prevBetAmount.add(betAmount)
    );
  }

  /**
   * @dev Removes a bettor and its total contribution from the given game
   * iff the game exists and the bettor exists in the game.
   * Returns the total contribution for this bettor to the caller.
   */
  function removeBettor(uint256 gameId, address bettor)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(gameId)
    returns (uint256 totalBetAmount)
  {
    // Check if bettor exists
    require(
      genericDB.doesNodeAddrExist(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, TABLE_NAME_BETTOR)), bettor),
      ERROR_BETTOR_DOES_NOT_EXIST
    );

    // Get the total contribution for the given player to return it to the caller
    totalBetAmount = genericDB.getUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, TABLE_NAME_BETTOR, "betAmount")));

    // Clear data fields related to this bettor
    genericDB.removeNodeFromLinkedListAddr(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, TABLE_NAME_BETTOR)), bettor);
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, TABLE_NAME_BETTOR, "betAmount")), 0);
  }

  function getPlayersAndKitties(uint256 gameId)
    public view
    onlyExistentGame(gameId)
    returns (address playerRed, address playerBlack, uint256 redKittie, uint256 blackKittie)
  {
    playerRed = genericDB.getAddressStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "playerRed")));
    playerBlack = genericDB.getAddressStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "playerBlack")));
    redKittie = genericDB.getUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "redKittie")));
    blackKittie = genericDB.getUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "blackKittie")));
  }

  function doesGameExist(uint256 gameId) public view returns (bool) {
    return genericDB.doesNodeExist(CONTRACT_NAME_GAMEMANAGER_DB, TABLE_KEY_GAME, gameId);
  }
}
