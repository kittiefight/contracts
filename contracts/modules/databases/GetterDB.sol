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
 * @dev Getters for game instances
 * @author @psychoplasma
 */
contract GetterDB is Proxied {

 using SafeMath for uint256;

  GenericDB public genericDB;

  bytes32 internal constant TABLE_KEY_GAME= keccak256(abi.encodePacked("GameTable"));
  string internal constant TABLE_NAME_BETTOR = "BettorTable";
  string internal constant TABLE_NAME_KITTIES = "KittieTable";
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
   * @dev Did player hit start button
   */
  function didPlayerStart(uint256 gameId, address player)
    public view
    onlyExistentGame(gameId)
    returns (bool)
  {
    return genericDB.getBoolStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, player, "startTime")));
  }

  function getHoneypotId(uint256 gameId)
    public view
    onlyExistentGame(gameId)
  {
    genericDB.getUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "honeypotId")));
  }

  /**
   * @dev get amount of supporters for given game and player
   */
  function getSupporters(uint256 gameId, address player)
    public view
    returns (uint)
  {
    return genericDB.getUintStorage(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(gameId, player, "supporters"))
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
    returns (address playerBlack, address playerRed, uint256 kittyBlack, uint256 kittyRed, uint256 totalBet, uint256 startTime)
  {
    playerBlack = genericDB.getAddressStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "playerBlack")));
    playerRed = genericDB.getAddressStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "playerRed")));
    kittyBlack = genericDB.getUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, playerRed, "kitty")));
    kittyRed = genericDB.getUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, playerBlack, "kitty")));
    totalBet = genericDB.getUintStorage(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(gameId, "totalBetAmount"))
    );
    startTime = genericDB.getUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "startTime")));
  }

 /**
   * @dev check game state, 0-4
   */
  function getGameState(uint256 gameId)
    public view
    onlyExistentGame(gameId)
    returns (uint gameState)
  {
    return genericDB.getUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "state")));
  }

  /**
   * @dev get fighting kittyId for specific game and player
   */
  function getKittieInGame(uint256 gameId, address player)
    public view
    onlyExistentGame(gameId)
    returns (uint)
  {
    return genericDB.getUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, player, "kitty")));
  }

  /**
   * @dev ?
   */
  function getStartTime(uint256 gameId)
    public view
    onlyExistentGame(gameId)
    returns (uint)
  {
    return genericDB.getUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "startTime")));
  }

  /**
   * @dev ?
   */
  function getPrestartTime(uint256 gameId)
    public view
    onlyExistentGame(gameId)
    returns (uint)
  {
    return genericDB.getUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "prestartTime")));
  }

  /**
   * @dev ?
   */
  function getEndTime(uint256 gameId)
    public view
    onlyExistentGame(gameId)
    returns (uint)
  {
    return genericDB.getUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "endTime")));
  }

   /**
   * @dev Update kittie state
   */
  function getKittieState(uint256 kittieId)
    public view
    returns (bool)
  {
    return genericDB.getBoolStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(kittieId, "inGame")));
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

  function getGames() public view returns (uint256[] memory) {
    return genericDB.getAll(
      CONTRACT_NAME_GAMEMANAGER_DB,
      TABLE_KEY_GAME
    );
  }

  /**
   * @dev get topBettor
   */
  function getTopBettor(uint256 _gameId, address _supportedPlayer)
    public view
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(_gameId)
    returns (address, uint256){
    return (
      genericDB.getAddressStorage(
        CONTRACT_NAME_GAMEMANAGER_DB,
        keccak256(abi.encodePacked(_gameId, _supportedPlayer, "TopBettor"))),
      genericDB.getUintStorage(
        CONTRACT_NAME_GAMEMANAGER_DB,
        keccak256(abi.encodePacked(_gameId, _supportedPlayer, "TopBettorAmountEth")))
      );
  }

  /**
   * @dev get secondTopBettor
   */
  function getSecondTopBettor(uint256 _gameId, address _supportedPlayer)
    public view
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(_gameId)
    returns (address, uint256){
    return (
      genericDB.getAddressStorage(
        CONTRACT_NAME_GAMEMANAGER_DB,
        keccak256(abi.encodePacked(_gameId, _supportedPlayer, "SecondTopBettor"))),
      genericDB.getUintStorage(
        CONTRACT_NAME_GAMEMANAGER_DB,
        keccak256(abi.encodePacked(_gameId, _supportedPlayer, "SecondTopBettorAmountEth")))
      );
  }

  /**
   * @dev get last bet amount (eth)
   */
  function getLastBet(uint256 _gameId)
    public view
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(_gameId)
    returns (uint256, uint256){
     return (
      genericDB.getUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(_gameId, "lastBet"))),
      genericDB.getUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(_gameId, "lastBetTimestamp")))
      );
  }

  function doesGameExist(uint256 gameId) public view returns (bool) {
    return genericDB.doesNodeExist(CONTRACT_NAME_GAMEMANAGER_DB, TABLE_KEY_GAME, gameId);
  }
}