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
import "../../GameVarAndFee.sol";
import "../gamemanager/GameManager.sol";

/**
 * @dev Getters for game instances
 * @author @psychoplasma
 */
contract GMGetterDB is Proxied {

 using SafeMath for uint256;

  GenericDB public genericDB;
  GameVarAndFee public gameVarAndFee;
  GameManager public gameManager;

  bytes32 internal constant TABLE_KEY_GAME= keccak256(abi.encodePacked("GameTable"));
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
    gameManager = GameManager(proxy.getContract(CONTRACT_NAME_GAMEMANAGER));
  }

  function getHoneypotInfo(uint256 gameId)
    public view
    returns(uint honeypotId, uint initialEth)
  {
    honeypotId = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "honeypotId")));
    initialEth = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "initialEth")));
  }

  /**
   * @dev get amount of supporters for given game and player
   */
  function getSupporters(uint256 gameId, address player)
    public view
    returns (uint)
  {
    return genericDB.getUintStorage(
      CONTRACT_NAME_GM_SETTER_DB,
      keccak256(abi.encodePacked(gameId, player, "supporters"))
    );
  }

   /**
   * @dev Updates the total amount of bet in the given game and supported player
   */
  function getTotalBet(uint256 gameId, address supportedPlayer) public view returns(uint) {
    return genericDB.getUintStorage(
      CONTRACT_NAME_GM_SETTER_DB,
      keccak256(abi.encodePacked(gameId, supportedPlayer, "totalBetAmount"))
    );
  }

  /**
   * @dev Returns the total amount of bet of the given bettor
   * and the player supported by that bettor in the game given.
   */
  function getBettor(uint256 gameId, address bettor)
    public view
    returns (uint256 betAmount, address supportedPlayer, bool ticketFeePaid)
  {
    betAmount = genericDB.getUintStorage(
      CONTRACT_NAME_GM_SETTER_DB,
      keccak256(abi.encodePacked(gameId, bettor, "betAmount"))
    );
    supportedPlayer = genericDB.getAddressStorage(
      CONTRACT_NAME_GM_SETTER_DB,
      keccak256(abi.encodePacked(gameId, bettor, "supportedPlayer"))
    );

    ticketFeePaid = genericDB.getBoolStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, bettor, "ticketFeePaid")));
  }

  /**
   * @dev Returns the total amount of bet of the given bettor
   * and the player supported by that bettor in the game given.
   */
  function getWinner(uint256 gameId)
    public view
    returns (address)
  {
    return genericDB.getAddressStorage(
      CONTRACT_NAME_GM_SETTER_DB,
      keccak256(abi.encodePacked(gameId, "winner"))
    );
  }

  /**
   * @dev Returns players, fighter kitties' ids,
   * total amount of bet and the timestamp of creation of this game.
   */
  function getGameInfo(uint256 gameId)
    public view
    onlyExistentGame(gameId)
    returns (address[2] memory players, uint[2] memory kittieIds, uint state, uint ticketPrice, uint minSupporters,
      uint[2] memory supporters, bool[2] memory pressedStart, uint timeCreated)
  {
    players[0] = genericDB.getAddressStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "playerBlack")));
    players[1] = genericDB.getAddressStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "playerRed")));
    kittieIds[0] = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, players[0], "kitty")));
    kittieIds[1] = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, players[1], "kitty")));
    state = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "state")));
    ticketPrice = gameVarAndFee.getTicketFee();
    minSupporters = gameVarAndFee.getMinimumContributors();
    supporters[0] = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, players[0], "supporters")));
    supporters[1] = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, players[1], "supporters")));
    (,pressedStart[0],) = gameManager.players(players[0], gameId);
    (,pressedStart[1],) = gameManager.players(players[1], gameId);
    timeCreated = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "createdTime")));
  }

  function getGamePlayers(uint256 gameId)
    public view
    onlyExistentGame(gameId)
    returns (address playerBlack, address playerRed, uint256 kittyBlack, uint256 kittyRed)
  {
    playerBlack = genericDB.getAddressStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "playerBlack")));
    playerRed = genericDB.getAddressStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "playerRed")));
    kittyBlack = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, playerRed, "kitty")));
    kittyRed = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, playerBlack, "kitty")));
  
  }

 /**
   * @dev check game state, 0-4
   */
  function getGameState(uint256 gameId)
    public view
    onlyExistentGame(gameId)
    returns (uint gameState)
  {
    return genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "state")));
  }

  /**
   * @dev get fighting kittyId for specific game and player
   */
  function getKittieInGame(uint256 gameId, address player)
    public view
    onlyExistentGame(gameId)
    returns (uint)
  {
    return genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, player, "kitty")));
  }

  /**
   * @dev ?
   */
  function getGameTimes(uint256 gameId)
    public view
    onlyExistentGame(gameId)
    returns (uint startTime, uint preStartTime, uint endTime)
  {
    startTime = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "startTime")));
    preStartTime = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "prestartTime")));
    endTime = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "endTime")));
  }

  // /**
  //  * @dev ?
  //  */
  // function getPrestartTime(uint256 gameId)
  //   public view
  //   onlyExistentGame(gameId)
  //   returns (uint)
  // {
  //   return genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "prestartTime")));
  // }

  // /**
  //  * @dev ?
  //  */
  // function getEndTime(uint256 gameId)
  //   public view
  //   onlyExistentGame(gameId)
  //   returns (uint)
  // {
  //   return genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "endTime")));
  // }

   /**
   * @dev Update kittie state
   */
  function getKittieState(uint256 kittieId)
    public view
    returns (bool)
  {
    return genericDB.getBoolStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(kittieId, "inGame")));
  }
  
  /**
   * @dev Checks whether the given player is playing in the given game.
   */
  function isPlayer(uint256 gameId, address player) public view returns (bool) {
    address playerRed = genericDB.getAddressStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "playerRed")));
    if (player == playerRed) {
      return true;
    }

    address playerBlack = genericDB.getAddressStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "playerBlack")));
    if (player == playerBlack) {
      return true;
    }

    return false;
  }

  function getGames() public view returns (uint256[] memory) {
    return genericDB.getAll(
      CONTRACT_NAME_GM_SETTER_DB,
      TABLE_KEY_GAME
    );
  }

  /**
   * @dev get all bettors for a given game id
   */
  function getBettors(uint gameId) public view returns (address[] memory) {
    return genericDB.getAllAddr(
      CONTRACT_NAME_GM_SETTER_DB,
      keccak256(abi.encodePacked(gameId, TABLE_NAME_BETTOR))
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
        CONTRACT_NAME_GM_SETTER_DB,
        keccak256(abi.encodePacked(_gameId, _supportedPlayer, "TopBettor"))),
      genericDB.getUintStorage(
        CONTRACT_NAME_GM_SETTER_DB,
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
        CONTRACT_NAME_GM_SETTER_DB,
        keccak256(abi.encodePacked(_gameId, _supportedPlayer, "SecondTopBettor"))),
      genericDB.getUintStorage(
        CONTRACT_NAME_GM_SETTER_DB,
        keccak256(abi.encodePacked(_gameId, _supportedPlayer, "SecondTopBettorAmountEth")))
      );
  }

  // /**
  //  * @dev get last bet amount (eth)
  //  */
  // function getLastBet(uint256 _gameId, address _supportedPlayer)
  //   public view
  //   onlyContract(CONTRACT_NAME_GAMEMANAGER)
  //   onlyExistentGame(_gameId)
  //   returns (uint256, uint256){
  //    return (
  //     genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(_gameId, _supportedPlayer, "lastBet"))),
  //     genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(_gameId, _supportedPlayer, "lastBetTimestamp")))
  //     );
  // }

  function doesGameExist(uint256 gameId) public view returns (bool) {
    return genericDB.doesNodeExist(CONTRACT_NAME_GM_SETTER_DB, TABLE_KEY_GAME, gameId);
  }


  // /**
  //  * @dev Get both player's hitStart status
  //  */
  // function getPlayerStartStatus(uint256 gameId)
  //   public view
  //   returns(bool redStarted, bool blackStarted){
  //     address playerRed = genericDB.getAddressStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "playerRed")));
  //     address playerBlack = genericDB.getAddressStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "playerBlack")));

  //     return (
  //       genericDB.getBoolStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, playerRed, "hitStart"))),
  //       genericDB.getBoolStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, playerBlack, "hitStart")))
  //       );
  // }

  // /**
  //  * @dev Get players current Defense Level
  //  */
  // function getDefenseLevel(uint256 gameId, address player) public view returns(uint){
  //   return genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, player, "defenseLevel")));
  // }

  // /**
  //  * @dev Get players current random number (start button)
  //  */
  // function getRandomNum(uint256 gameId, address player) public view returns(uint){
  //   return genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, player, "randomNum")));
  // }

  // function getAttackValues(uint256 gameId) public view
  //   returns
  //   (uint256 lowPunch, uint256 lowKick, uint256 lowThunder,
  //     uint256 hardPunch, uint256 hardKick, uint256 hardThunder, uint256 slash)
  // {
  //   lowPunch = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "lowPunch")));
  //   lowKick = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "lowKick")));
  //   lowThunder = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "lowThunder")));
  //   hardPunch = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "hardPunch")));
  //   hardKick = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "hardKick")));
  //   hardThunder = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "hardThunder")));
  //   slash = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "slash")));
  // }

}