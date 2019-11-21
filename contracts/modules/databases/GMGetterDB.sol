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
import "../gamemanager/GameStore.sol";
import "./EndowmentDB.sol";
import "./ProfileDB.sol";
import "../registration/Register.sol";
import "../kittieHELL/KittieHell.sol";
import "../endowment/EndowmentFund.sol";

/**
 * @dev Getters for game instances
 * @author @psychoplasma
 */
contract GMGetterDB is Proxied {

 using SafeMath for uint256;

  GenericDB public genericDB;
  GameStore public gameStore;
  EndowmentDB public endowmentDB;

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
    gameStore = GameStore(proxy.getContract(CONTRACT_NAME_GAMESTORE));
    endowmentDB = EndowmentDB(proxy.getContract(CONTRACT_NAME_ENDOWMENT_DB));
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

  function getGamePlayers(uint256 gameId)
    public view
    onlyExistentGame(gameId)
    returns (address playerBlack, address playerRed, uint256 kittyBlack, uint256 kittyRed)
  {
    playerBlack = genericDB.getAddressStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "playerBlack")));
    playerRed = genericDB.getAddressStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "playerRed")));
    kittyBlack = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, playerBlack, "kitty")));
    kittyRed = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, playerRed, "kitty")));
  
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

  function doesGameExist(uint256 gameId) public view returns (bool) {
    return genericDB.doesNodeExist(CONTRACT_NAME_GM_SETTER_DB, TABLE_KEY_GAME, gameId);
  }

  function getGameOfKittie(uint kittieId) public view returns(uint){
    return genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(kittieId, "playingGame")));
  }

  // temporarily hardcode totalEth and totalKty for truffle testing of GameStore-kittieRedemptionFee.test.js
  // otherwise the entire gaming process has to be run throughly to get totalEth and totalKty
  // please remove hardcoding once test is done and uncomment line 172 and line 173
  function getFinalHoneypot(uint256 gameId)
    public view
    returns(uint totalEth, uint totalKty )
  {
    totalEth = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "totalEth")));
    totalKty = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "totalKty")));
  }

  function getPlayerBet(uint gameId, address player)
  public view
  returns(uint playerBet)
  {
    playerBet = genericDB.getUintStorage(
      CONTRACT_NAME_GM_SETTER_DB,
      keccak256(abi.encodePacked(gameId, player, "betAmount"))
    );
  }

  // === FRONTEND GETTERS ===
  function getFighterByKittieID(uint256 kittieId)
    public view
    returns (address owner, bool isDead, uint deathTime, uint kittieHellExp, bool isGhost, bool isPlaying, uint gameId)
  {
    (owner, isDead,, isGhost, deathTime) = KittieHell(proxy.getContract(CONTRACT_NAME_KITTIEHELL)).getKittyStatus(kittieId);
    gameId = getGameOfKittie(kittieId);
    //If gameId is 0 is not playing, otherwise, it is.
    isPlaying = (gameId != 0);
    if(isDead) kittieHellExp = deathTime.add(gameStore.getKittieExpirationTime(gameId));
  }

  /**
   * @dev Returns the total amount of bet of the given bettor
   * and the player supported by that bettor in the game given.
   */
  function getSupporterInfo(uint256 gameId, address bettor)
    public view
    returns (uint256 betAmount, address supportedPlayer, bool ticketFeePaid, bool hasClaimed)
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
    hasClaimed = EndowmentFund(proxy.getContract(CONTRACT_NAME_ENDOWMENT_FUND)).getWithdrawalState(gameId, bettor);
  }

  /**
   * @dev Returns players, fighter kitties' ids,
   * total amount of bet and the timestamp of creation of this game.
   */
  function getGameInfo(uint256 gameId)
    public view
    onlyExistentGame(gameId)
    returns (address[2] memory players, uint[2] memory kittieIds, uint state,
      uint[2] memory supporters, bool[2] memory pressedStart, uint timeCreated, address winner)
  {
    (players[0], players[1], kittieIds[0], kittieIds[1]) = getGamePlayers(gameId);
    state = getGameState(gameId);
    supporters[0] = getSupporters(gameId, players[0]);
    supporters[1] = getSupporters(gameId, players[1]);
    pressedStart[0] = gameStore.didHitStart(gameId, players[0]);
    pressedStart[1] = gameStore.didHitStart(gameId, players[1]);
    timeCreated = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "createdTime")));
    winner = genericDB.getAddressStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "winner")));
  }

  function getHoneypotInfo(uint256 gameId)
    public view
    returns(uint honeypotId, uint status, uint initialEth, uint ethTotal, uint[2] memory ethByCorner, uint ktyTotal, uint expTime)
  {
    (address playerBlack, address playerRed,,) = getGamePlayers(gameId);
    honeypotId = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "honeypotId")));
    initialEth = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "initialEth")));
    (ktyTotal, ethTotal) = endowmentDB.getHoneyPotBalance(gameId);
    ethByCorner[0] = getTotalBet(gameId, playerBlack);
    ethByCorner[1] = getTotalBet(gameId, playerRed);
    (status, expTime) = endowmentDB.getHoneypotState(gameId);
  }

  function getMyInfo(uint256 gameId, address sender)
    public view
    returns(bool isSupporter, uint supportedCorner, bool isPlayerInGame, uint corner)
  {
    isSupporter = genericDB.doesNodeAddrExist(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, TABLE_NAME_BETTOR)), sender);
    address supportedPlayer = genericDB.getAddressStorage(
      CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, sender, "supportedPlayer")));
    supportedCorner = gameStore.getCorner(gameId, supportedPlayer);
    isPlayerInGame = isPlayer(gameId, sender);
    corner = gameStore.getCorner(gameId, sender);
  }

  function getPlayer(uint gameId, address player)
    public view
    returns(uint kittieId, uint corner, uint betsTotalEth)
  {
    kittieId = getKittieInGame(gameId, player);
    corner = gameStore.getCorner(gameId, player);
    betsTotalEth = getTotalBet(gameId, player);
  }

  function getWinners(uint256 gameId)
    public view
    returns (address winner, address topBettor, address secondTopBettor)
  {
    winner = genericDB.getAddressStorage(CONTRACT_NAME_GM_SETTER_DB,keccak256(abi.encodePacked(gameId, "winner")));
    topBettor = genericDB.getAddressStorage(CONTRACT_NAME_GM_SETTER_DB,keccak256(abi.encodePacked(gameId, "topBettor")));
    secondTopBettor = genericDB.getAddressStorage(CONTRACT_NAME_GM_SETTER_DB,keccak256(abi.encodePacked(gameId, "secondTopBettor")));
  }

  function getAccountInfo(address account)
    public view
    returns(bool isRegistered, bool isVerified)
  {
    isRegistered = Register(proxy.getContract(CONTRACT_NAME_REGISTER)).isRegistered(account);
    uint civicId = ProfileDB(proxy.getContract(CONTRACT_NAME_PROFILE_DB)).getCivicId(account);
    isVerified = civicId > 0;
  }

}
