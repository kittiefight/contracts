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
   * @dev Creates a new game item on game table
   */
  function createGame
  (
    address playerRed, address playerBlack,
    uint256 kittyRed, uint256 kittyBlack,
    uint256 gameStartTime, uint256 gamePrestartTime,
    uint256 gameEndTime
  )
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
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "startTime")), gameStartTime);
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "prestartTime")), gamePrestartTime);
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "endTime")), gameEndTime);

    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "state")), 0);

    // Set kittieIds to true, so we know that there are in a match
    genericDB.setBoolStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(kittyRed, "inGame")), true);
    genericDB.setBoolStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(kittyBlack, "inGame")), true);
  }

  /**
   * @dev Adds a bettor to the given game iff the game exists.
   * If the bettor already exists in the game, updates her bet.
   */
  function addBettor(uint256 gameId, address bettor, address supportedPlayer)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(gameId)
  {
    // TODO: check if bettor is the same as one of the players

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
   * @dev *
   */
  function updateBettor(uint256 gameId, address bettor, uint256 betAmount, address supportedPlayer)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(gameId)
  {
    // TODO: check if bettor is the same as one of the players

    // Check if bettor does not exist in the game given, add her to the game.
    require(genericDB.doesNodeAddrExist(CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(gameId, TABLE_NAME_BETTOR)), bettor),
      "Bettor does not exist. Call participate first");

    // Get the supported player for this bettor
    address _supportedPlayer = genericDB.getAddressStorage(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(gameId, bettor, "supportedPlayer"))
    );

    require(_supportedPlayer == supportedPlayer, "You cannot bet for the opposite player");

    if (betAmount > 0) {
      // Update bettor's total bet amount
      updateBet(gameId, bettor, betAmount);

      // Update total bet amount in the game for a given corner
      updateTotalBet(gameId, betAmount, supportedPlayer);
    }
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
   * @dev Updates the total amount of bet in the given game and supported player
   */
  function updateTotalBet(uint256 gameId, uint256 amount, address supportedPlayer) internal {
    uint256 prevAmount = genericDB.getUintStorage(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(gameId, supportedPlayer, "totalBetAmount"))
    );

    genericDB.setUintStorage(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(gameId, supportedPlayer, "totalBetAmount")),
      prevAmount.add(amount)
    );
  }

  /**
   * @dev Adds 1 minute to the game end time
   */
  function updateEndTime(uint256 gameId, uint newTime)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(gameId)
  {
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "endTime")), newTime);
  }

   /**
   * @dev Update different game vars for every bet function call
   */
  function updateGameVars(uint256 gameId, uint256 lastBet, uint lastBetTimestamp, address topBettor, address secondTopBettor)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(gameId)
  {
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "lastBet")), lastBet);
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "lastBetTimestamp")), lastBetTimestamp);
    genericDB.setAddressStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "topBettor")), topBettor);
    genericDB.setAddressStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "secondTopBettor")), secondTopBettor);
  }

  /**
   * @dev set topBettor
   */
  function setTopBettor(uint256 _gameId, address _bettor, address _supportedPlayer, uint256 _amountEth)
    public
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(_gameId) {
    genericDB.setAddressStorage(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(_gameId, _supportedPlayer, "TopBettor")), _bettor);
    genericDB.setUintStorage(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(_gameId, _supportedPlayer, "TopBettorAmountEth")), _amountEth);
  }

  /**
   * @dev set secondTopBettor
   */
  function setSecondTopBettor(uint256 _gameId, address _bettor, address _supportedPlayer, uint256 _amountEth)
    public
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(_gameId) {
    genericDB.setAddressStorage(
      CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(_gameId,
      _supportedPlayer, "SecondTopBettor")), _bettor);
    genericDB.setUintStorage(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(_gameId, _supportedPlayer, "SecondTopBettorAmountEth")), _amountEth);
  }

  /**
   * @dev set last bet amount (eth)
   */
  function setLastBet(uint256 _gameId, uint256 _amountEth, uint256 _lastBetTimestamp, address _supportedPlayer)
    public
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(_gameId) {
    genericDB.setUintStorage(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(_gameId, _supportedPlayer, "lastBet")), _amountEth);
    genericDB.setUintStorage(
      CONTRACT_NAME_GAMEMANAGER_DB,
      keccak256(abi.encodePacked(_gameId, _supportedPlayer, "lastBetTimestamp")), _lastBetTimestamp);
  }

  /**
   * @dev Update game to one of 5 states
   */
  function updateGameState(uint256 gameId, uint256 state)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(gameId)
  {
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "state")), state);
  }

  /**
   * @dev Update kittie state
   */
  function updateKittieState(uint256 kittieId, bool state)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
  {
    genericDB.setBoolStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(kittieId, "inGame")), state);
  }

  /**
   * @dev ?
   */
  function startGameVars(uint256 gameId, address player, uint defenseLevel, uint randomNum)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(gameId)
  {

    //Defense Level
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, player, "defenseLevel")), defenseLevel);

    // Set random seed send by player in startGame function
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, player, "randomNum")), randomNum);

  }

  /**
   * @dev ?
   */
  function updateDefenseLevel(uint256 gameId, address player, uint defenseLevel)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(gameId)
  {
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, player, "defenseLevel")), defenseLevel);

  }

  /**
   * @dev Pressed start button
   */
  function setHitStart(uint256 gameId, address player)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
  {
    genericDB.setBoolStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, player, "hitStart")), true);
  }

  /**
   * @dev TODO: Set the fight map sent by betting algo
   */
  function setFightMap(uint256 gameId)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(gameId)
  {
    //TODO: How to store the fight map, what input variable types
  }

  /**
   * @dev TODO: Set the attack values returned by HitResolver when game ends
   */
  function setAttackValues
  (
    uint256 gameId, uint256 lowPunch, uint256 lowKick, uint256 lowThunder,
    uint256 hardPunch, uint256 hardKick, uint256 hardThunder, uint256 slash)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(gameId)
  {
    //TODO: How to store the attack values
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "lowPunch")), lowPunch);
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "lowKick")), lowKick);
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "lowThunder")), lowThunder);
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "hardPunch")), hardPunch);
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "hardKick")), hardKick);
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "hardThunder")), hardThunder);
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "slash")), slash);
  }

  /**
   * @dev set HoneyPotId and initial ETH in jackpot created by Endowment
   */
  function setHoneypotInfo(uint256 gameId, uint256 honeypotId, uint256 initialEth)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(gameId)
  {
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "honeypotId")), honeypotId);
    genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_DB, keccak256(abi.encodePacked(gameId, "initialEth")), initialEth);
  }  

  function doesGameExist(uint256 gameId) public view returns (bool) {
    return genericDB.doesNodeExist(CONTRACT_NAME_GAMEMANAGER_DB, TABLE_KEY_GAME, gameId);
  }
}