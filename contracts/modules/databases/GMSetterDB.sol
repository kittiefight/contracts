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
import "./GMGetterDB.sol";
import "../../libs/SafeMath.sol";
import "../../GameVarAndFee.sol";
import "../gamemanager/GameStore.sol";

/**
 * @dev Stores game instances
 * @author @psychoplasma
 */
contract GMSetterDB is Proxied {
 using SafeMath for uint256;

  GenericDB public genericDB;
  GameVarAndFee public gameVarAndFee;
  GMGetterDB public gmGetterDB;
  GameStore public gameStore;

  bytes32 internal constant TABLE_KEY_GAME= keccak256(abi.encodePacked("GameTable"));
  string internal constant TABLE_NAME_BETTOR = "BettorTable";
  string internal constant TABLE_NAME_KITTIES = "KittieTable";

  modifier onlyExistentGame(uint256 gameId) {
    require(doesGameExist(gameId));
    _;
  }
  
  constructor(GenericDB _genericDB) public {
    setGenericDB(_genericDB);
  }

  function setGenericDB(GenericDB _genericDB) public onlyOwner {
    genericDB = _genericDB;
  }

  function initialize() external onlyOwner {
    gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
    gmGetterDB = GMGetterDB(proxy.getContract(CONTRACT_NAME_GM_GETTER_DB));
    gameStore = GameStore(proxy.getContract(CONTRACT_NAME_GAMESTORE));
  }

 /**
   * @dev Creates a new game item on game table
   */
  function createGame
  (
    address playerRed, address playerBlack,
    uint256 kittyRed, uint256 kittyBlack,
    uint256 gameStartTime
  )
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    returns (uint256 gameId)
  {
    // Get the lastest item in the linkedlist.
    // Note that 0 means the HEAD of the list always and direction(false)
    //  indicates that we are going to the end of the list.
    (,uint256 prevGameId) = genericDB.getAdjacent(CONTRACT_NAME_GM_SETTER_DB, TABLE_KEY_GAME, 0, false);
    // And create new item with an incremental id.
    // Note that we don't need to check any existance here, because
    // exsistance of the previous item in the list already self-verifies.
    gameId = prevGameId.add(1);
    genericDB.pushNodeToLinkedList(CONTRACT_NAME_GM_SETTER_DB, TABLE_KEY_GAME, gameId);

    uint256 gamePrestartTime = gameStartTime.sub(gameVarAndFee.getGamePrestart());
    uint256 gameEndTime = gameStartTime.add(gameVarAndFee.getGameDuration());

    // Save players for the created game
    genericDB.setAddressStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "playerRed")), playerRed);
    genericDB.setAddressStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "playerBlack")), playerBlack);

    // Set kitties for the given players
    genericDB.setUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, playerRed, "kitty")), kittyRed);
    genericDB.setUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, playerBlack, "kitty")), kittyBlack);

    // solium-disable-next-line security/no-block-members
    genericDB.setUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "createdTime")), now);
    genericDB.setUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "startTime")), gameStartTime);
    genericDB.setUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "prestartTime")), gamePrestartTime);
    genericDB.setUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "endTime")), gameEndTime);

    genericDB.setUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "state")), 0);

    // Set kittieIds to true, so we know that there are in a match
    genericDB.setUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(kittyRed, "playingGame")), gameId);
    genericDB.setUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(kittyBlack, "playingGame")), gameId);
    
    return gameId;
  }
  

  /**
   * @dev Adds a bettor to the given game iff the game exists.
   * If the bettor already exists in the game, updates her bet.
   */
  function addBettor(uint256 gameId, address bettor, address supportedPlayer)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(gameId)
    returns(bool)
  {
    // If bettor does not exist in the game given, add bettor to the game.
    if (!genericDB.doesNodeAddrExist(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, TABLE_NAME_BETTOR)), bettor)) {
      // Add the bettor to the bettor table.
      genericDB.pushNodeToLinkedListAddr(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, TABLE_NAME_BETTOR)), bettor);
      // Save the supported player for this bettor
      genericDB.setAddressStorage(
        CONTRACT_NAME_GM_SETTER_DB,
        keccak256(abi.encodePacked(gameId, bettor, "supportedPlayer")),
        supportedPlayer
      );

      //Set payed fee to true
      genericDB.setBoolStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, bettor, "ticketFeePaid")), true);
      
      // And increase the number of supporters for that player
      incrementSupporters(gameId, supportedPlayer);

      return true;
    }

    return false;
  }

  /**
   * @dev Increments the number of supporters for the given player
   */
  function incrementSupporters(uint256 gameId, address player) internal {
    // Increment number of supporters by one
    uint256 supporters = genericDB.getUintStorage(
      CONTRACT_NAME_GM_SETTER_DB,
      keccak256(abi.encodePacked(gameId, player, "supporters"))
    );
    genericDB.setUintStorage(
      CONTRACT_NAME_GM_SETTER_DB,
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
    require(genericDB.doesNodeAddrExist(CONTRACT_NAME_GM_SETTER_DB,
      keccak256(abi.encodePacked(gameId, TABLE_NAME_BETTOR)), bettor),
      "Bettor does not exist. Call participate first");

    // Get the supported player for this bettor
    address _supportedPlayer = genericDB.getAddressStorage(
      CONTRACT_NAME_GM_SETTER_DB,
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
   //DONE IN ENDOWMENTDB
  function updateBet(uint256 gameId, address bettor, uint256 amount) internal {
    uint256 prevAmount = genericDB.getUintStorage(
      CONTRACT_NAME_GM_SETTER_DB,
      keccak256(abi.encodePacked(gameId, bettor, "betAmount"))
    );
    genericDB.setUintStorage(
      CONTRACT_NAME_GM_SETTER_DB,
      keccak256(abi.encodePacked(gameId, bettor, "betAmount")),
      prevAmount.add(amount)
    );
  }

  /**
   * @dev Updates the total amount of bet in the given game and supported player
   */
  function updateTotalBet(uint256 gameId, uint256 amount, address supportedPlayer) internal {
    uint256 prevAmount = genericDB.getUintStorage(
      CONTRACT_NAME_GM_SETTER_DB,
      keccak256(abi.encodePacked(gameId, supportedPlayer, "totalBetAmount"))
    );

    genericDB.setUintStorage(
      CONTRACT_NAME_GM_SETTER_DB,
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
    genericDB.setUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "endTime")), newTime);
  }

  /**
   * @dev Update game to one of 5 states
   */
  function updateGameState(uint256 gameId, uint256 state)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(gameId)
  {
    genericDB.setUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "state")), state);
  }

  /**
   * @dev Update kittie state
   */
  function removeKittiesInGame(uint256 gameId)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
  {
    ( , ,uint256 kittyBlack, uint256 kittyRed) = gmGetterDB.getGamePlayers(gameId);
    genericDB.setUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(kittyBlack, "playingGame")), 0);
    genericDB.setUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(kittyRed, "playingGame")), 0);
  }

  /**
   * @dev set HoneyPotId and initial ETH in jackpot created by Endowment
   */
  function setHoneypotInfo(uint256 gameId, uint256 honeypotId, uint256 initialEth)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(gameId)
  {
    genericDB.setUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "honeypotId")), honeypotId);
    genericDB.setUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "initialEth")), initialEth);
  }  

  function doesGameExist(uint256 gameId) public view returns (bool) {
    return genericDB.doesNodeExist(CONTRACT_NAME_GM_SETTER_DB, TABLE_KEY_GAME, gameId);
  }

  /**
   * @dev set winner for each game
   */
  function setWinners(uint256 gameId, address winner, address topBettor, address secondTopBettor)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(gameId)
  {
    genericDB.setAddressStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "winner")), winner);
    genericDB.setAddressStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "topBettor")), topBettor);
    genericDB.setAddressStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "secondTopBettor")), secondTopBettor);
  }

  function updateTopbettors(uint256 _gameId, address _account, address _supportedPlayer)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(_gameId)
  {

        address topBettor = gameStore.getTopBettor(_gameId, _supportedPlayer);
        (uint256 bettorTotal, ,) = gmGetterDB.getSupporterInfo(_gameId, _account);
        (uint256 topBettorEth, ,) = gmGetterDB.getSupporterInfo(_gameId, topBettor);

        if (bettorTotal > topBettorEth){
            gameStore.updateTopBettor(_gameId, _supportedPlayer, _account);
            gameStore.updateSecondTopBettor(_gameId, _supportedPlayer, topBettor);
        } else {
            address secondTopBettor = gameStore.getSecondTopBettor(_gameId, _supportedPlayer);
            (uint256 secondTopBettorEth,,) = gmGetterDB.getSupporterInfo(_gameId, secondTopBettor);
            if (bettorTotal > secondTopBettorEth){
                gameStore.updateSecondTopBettor(_gameId, _supportedPlayer, _account);
    }   }   }
}
