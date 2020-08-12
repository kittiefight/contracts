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
import "../kittieHELL/KittieHell.sol";
import "../gamemanager/Forfeiter.sol";
import "../gamemanager/GameManager.sol";
import "../gamemanager/GameCreation.sol";

/**
 * @dev Stores game instances
 * @author @psychoplasma
 * @author @psychoplasma
 * @author @psychoplasma
 */
contract GMSetterDB is Proxied {
 using SafeMath for uint256;

  GenericDB public genericDB;
  GameVarAndFee public gameVarAndFee;
  GMGetterDB public gmGetterDB;
  GameStore public gameStore;
  GameCreation public gameCreation;

  bytes32 internal constant TABLE_KEY_GAME = keccak256(abi.encodePacked("GameTable"));
  string internal constant TABLE_NAME_BETTOR = "BettorTable";

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
    gameCreation = GameCreation(proxy.getContract(CONTRACT_NAME_GAMECREATION));
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
    onlyContract(CONTRACT_NAME_GAMECREATION)
    returns (uint256 gameId)
  {
    // Get the lastest item in the linkedlist.
    // Note that 0 means the HEAD of the list always and 
    // direction(true) indicates that we are going to the end of the list.
    (,uint256 prevGameId) = genericDB.getAdjacent(CONTRACT_NAME_GM_SETTER_DB, TABLE_KEY_GAME, 0, true);
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

    setGameState(gameId);
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
    uint256 prevAmount;

    if(bettor != supportedPlayer){
      // Check if bettor does not exist in the game given, add her to the game.
      require(genericDB.doesNodeAddrExist(CONTRACT_NAME_GM_SETTER_DB,
        keccak256(abi.encodePacked(gameId, TABLE_NAME_BETTOR)), bettor));
        
      // Get the supported player for this bettor
      address _supportedPlayer = genericDB.getAddressStorage(
        CONTRACT_NAME_GM_SETTER_DB,
        keccak256(abi.encodePacked(gameId, bettor, "supportedPlayer"))
      );

      require(_supportedPlayer == supportedPlayer);

      // Update bettor's total bet amount
      prevAmount = genericDB.getUintStorage(
        CONTRACT_NAME_GM_SETTER_DB,
        keccak256(abi.encodePacked(gameId, bettor, "betAmount"))
      );
      genericDB.setUintStorage(
        CONTRACT_NAME_GM_SETTER_DB,
        keccak256(abi.encodePacked(gameId, bettor, "betAmount")),
        prevAmount.add(betAmount)
      );
    }
    else{
      prevAmount = genericDB.getUintStorage(
        CONTRACT_NAME_GM_SETTER_DB,
        keccak256(abi.encodePacked(gameId, bettor, "betAmount"))
      );

      genericDB.setUintStorage(
        CONTRACT_NAME_GM_SETTER_DB,
        keccak256(abi.encodePacked(gameId, bettor, "betAmount")),
        prevAmount.add(betAmount)
      );
    }

    // Update total bet amount in the game for a given corner
    // updateTotalBet(gameId, betAmount, supportedPlayer);
    prevAmount = genericDB.getUintStorage(
      CONTRACT_NAME_GM_SETTER_DB,
      keccak256(abi.encodePacked(gameId, supportedPlayer, "totalBetAmount"))
    );

    genericDB.setUintStorage(
      CONTRACT_NAME_GM_SETTER_DB,
      keccak256(abi.encodePacked(gameId, supportedPlayer, "totalBetAmount")),
      prevAmount.add(betAmount)
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
    only2Contracts(CONTRACT_NAME_GAMEMANAGER, CONTRACT_NAME_GAMEMANAGER_HELPER)
    onlyExistentGame(gameId)
  {
    gameCreation.scheduleJobs(gameId, state);
    genericDB.setUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "state")), state);
  }

  // ==== CRONJOBS FUNCTIONS

  function setCronJobForGame(uint256 gameId, uint256 jobId) external onlyContract(CONTRACT_NAME_GAMECREATION) {
    return genericDB.setUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "cronJobForGame")), jobId);
  }

  function updateGameStateCron(uint256 gameId)
    external
    onlyContract(CONTRACT_NAME_GAMECREATION)
    onlyExistentGame(gameId){
      gameCreation.scheduleJobs(gameId, 1);
      genericDB.setUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "state")), 1);
  }

  function setGameState(uint256 gameId)
    internal
    onlyExistentGame(gameId){
      gameCreation.scheduleJobs(gameId, 0);
      genericDB.setUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "state")), 0);
  }

  /**
   * @dev set initial ETH and initial KTY in honeypot created by Endowment
   */
  function setHoneypotInfo(uint256 gameId, uint256 _initialKTY, uint256 _initialETH)
    external
    onlyContract(CONTRACT_NAME_GAMECREATION)
    onlyExistentGame(gameId)
  {
    genericDB.setUintStorage(
      CONTRACT_NAME_GM_SETTER_DB,
      keccak256(abi.encodePacked(gameId, "initialKty")),
      _initialKTY
    );
    genericDB.setUintStorage(
      CONTRACT_NAME_GM_SETTER_DB,
      keccak256(abi.encodePacked(gameId, "initialEth")),
      _initialETH
    );
  }

  function storeHoneypotDetails(uint256 gameId)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    onlyExistentGame(gameId)
  {
    (,,,uint totalEth,,uint totalKty,) = gmGetterDB.getHoneypotInfo(gameId);
    genericDB.setUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "totalEth")), totalEth);
    genericDB.setUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "totalKty")), totalKty);
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

  // function updateTopbettors(uint256 _gameId, address _account, address _supportedPlayer)
  //   external
  //   onlyContract(CONTRACT_NAME_GAMEMANAGER)
  //   onlyExistentGame(_gameId)
  // {

  //   address topBettor = gameStore.getTopBettor(_gameId, _supportedPlayer);
  //   (uint256 bettorTotal,,,) = gmGetterDB.getSupporterInfo(_gameId, _account);
  //   (uint256 topBettorEth,,,) = gmGetterDB.getSupporterInfo(_gameId, topBettor);
    
  //   if(topBettor != _account){
  //     if (bettorTotal > topBettorEth){
  //       //If topBettor is already the account, dont update
  //       gameStore.updateTopBettor(_gameId, _supportedPlayer, _account);
  //       gameStore.updateSecondTopBettor(_gameId, _supportedPlayer, topBettor);
  //     }
  //     else {
  //       address secondTopBettor = gameStore.getSecondTopBettor(_gameId, _supportedPlayer);
  //       (uint256 secondTopBettorEth,,,) = gmGetterDB.getSupporterInfo(_gameId, secondTopBettor);
  //       if (bettorTotal > secondTopBettorEth && secondTopBettor != _account){
  //           gameStore.updateSecondTopBettor(_gameId, _supportedPlayer, _account);
  //       }
  //     }
  //   }
  // }
}
