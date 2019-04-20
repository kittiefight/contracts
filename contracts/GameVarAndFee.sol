/**
 * @title GameVarAndFee
 *
 * @author @wafflemakr @hamaad
 *
 */
//modifier class (DSAuth )
//Event class ( DSNote )
//
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

import "./DSNote.sol";
import "./modules/proxy/Proxied.sol";
//import "./modules/databases/GameVarAndFeeDB.sol";
import './modules/databases/GenericDB.sol';


/**
 * @title Contract that moderates the various fees, timing limits, expiry date/time, 
 * schedules, eth allocation per game, token allocation per game, kittiehell 
 * kittie expiration, time durations, distribution percentages e.t.c.
 * The note modifier will log event for each function call.
 * @dev if we implement all setters for each getter, we can run out of gas
 * current contract has 3.5k deployment cost. If needed, create a DB contract for 
 * setters and leave getters here.
 */
contract GameVarAndFee is Proxied {

  //All keys in Generic DB will be hased with this constant
  string internal constant TABLE_NAME = "GameVarAndFeeTable";

  //GenericDB type variable to be used in the contract when storing
  GenericDB public genericDB;

    
  constructor (GenericDB _genericDB) public {
    setGenericDB(_genericDB);
  }
  
  // Set generic DB deployed address when deploying this contract
  // can also be changed later by owner if its updated.
  function setGenericDB(GenericDB _genericDB) public onlyOwner{
    genericDB = _genericDB;
  }


  // --- SETTER --- 

  /// @notice Sets the time in future that a game is to be played
  /// @dev check if only one setter function can be implemented
  function setVarAndFee(string calldata keyName, uint value) 
  external onlyProxy{
    bytes32 key = keccak256(abi.encodePacked(TABLE_NAME, keyName));
    genericDB.setUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key, value);
  }


   // ----- GETTERS -------
    
  /// @notice Gets the time in future that a game is to be played
  function getFutureGameTime() 
  public view returns(uint) {
      bytes32 key = keccak256(abi.encodePacked(TABLE_NAME, "futureGameTime"));
      return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key);
  }
  
  /// @notice Gets 2 min alloted time whereby both players must initiate start or forfeit game.
  function getGamePrestart() 
  public view returns(uint) {
      bytes32 key = keccak256(abi.encodePacked(TABLE_NAME, "gamePrestart"));
      return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key);
  }
  
  /// @notice Gets Game duration, how long a game lasts
  function getGameDuration() 
  public view returns(uint) {
      bytes32 key = keccak256(abi.encodePacked("gameDuration"));
      return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key);
  }
  
  /// @notice Gets how long to wait for payment for kittie in kittiehell before kittie is lost forever 
  function getKittieHellExpiration() 
  public view returns(uint) {
      bytes32 key = keccak256(abi.encodePacked("kittieHellExpiration"));
      return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key);
  }
  
  /// @notice Gets the time at which honey pot will be dissolved,after a game is over, used by time contract at end of gameduration
  function getHoneypotExpiration() 
  public view returns(uint) {
      bytes32 key = keccak256(abi.encodePacked("honeypotExpiration"));
      return genericDB.getUintStorage(TABLE_NAME, key);
  }
  
  /// @notice Gets the farthest time in futre when a game can be schedule
  function getScheduleTimeLimits() 
  public view returns(uint) {
      bytes32 key = keccak256(abi.encodePacked("scheduleTimeLimits"));
      return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key);
  }
  
  /// @notice Gets mount of initial KTY Tokens allowed to be drawn from EndowmentFund to be allocated to game
  function getTokensPerGame() 
  public view returns(uint) {
      bytes32 key = keccak256(abi.encodePacked("tokensPerGame"));
      return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key);
  }
  
  /// @notice Gets Amount of initial ETH allowed to be drawn from EndowmentFund to be allocated to game
  function getEthPerGame() 
  public view returns(uint) {
      bytes32 key = keccak256(abi.encodePacked("ethPerGame"));
      return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key);
  }
  
  /// @notice Gets Amount of games allowed per day 
  function getDailyGameAvailability() 
  public view returns(uint) {
      bytes32 key = keccak256(abi.encodePacked("dailyGameAvailability"));
      return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key);
  }
  
  /// @notice Gets Times duration between each game per day
  function getGameTimes() 
  public view returns(uint) {
      bytes32 key = keccak256(abi.encodePacked("gameTimes"));
      return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key);
  }
  
  /// @notice Gets Games per day allowed per address "Games rate limit"
  function getGameLimit() 
  public view returns(uint) {
      bytes32 key = keccak256(abi.encodePacked("gameLimit"));
      return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key);
  }
  
  /// @notice Gets fee paid to lift the limit of the number of games allowed per day, per address
  function getGamesRateLimitFee() 
  public view returns(uint) {
      bytes32 key = keccak256(abi.encodePacked("gamesRateLimitFee"));
      return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key);
  }
  
  /// @notice Gets Distribution Rates
  function getDistributionRates() 
  public view returns(uint[] memory rates) {
      bytes32 key;
      
      key = keccak256(abi.encodePacked("winningKittie"));
      rates[0] = genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key);
      
      key = keccak256(abi.encodePacked("topBettor"));
      rates[1] = genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key);
      
      key = keccak256(abi.encodePacked("secondRunnerUp"));
      rates[2] = genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key);
      
      key = keccak256(abi.encodePacked("otherBettors"));
      rates[3] = genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key);
      
      key = keccak256(abi.encodePacked("endownment"));
      rates[4] = genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key);
  }

  /// @notice Gets ticket fee in KTY for betting participators
  function getTicketFee() 
  public view returns(uint) {
      bytes32 key = keccak256(abi.encodePacked("ticketFee"));
      return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key);
  }

  /// @notice Gets betting fee in KTY for betting participators
  function getBettingFee() 
  public view returns(uint) {
      bytes32 key = keccak256(abi.encodePacked("bettingFee"));
      return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key);
  }

  /// @notice Gets kittieHELL redemption fee in KTY for redeeming kitties
  function getKittieRedemptionFee() 
  public view returns(uint) {
      bytes32 key = keccak256(abi.encodePacked("kittieRedemptionFee"));
      return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key);
  }

  /// @notice Gets Kittie expiry time in kittieHELL 
  function getKittieExpiry() 
  public view returns(uint) {
      bytes32 key = keccak256(abi.encodePacked("kittieExpiry"));
      return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key);
  }

  /// @notice Gets honeyPot duration/expiry after game end 
  function getHoneyPotDuration() 
  public view returns(uint) {
      bytes32 key = keccak256(abi.encodePacked("honeyPotDuration"));
      return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key);
  }

}
