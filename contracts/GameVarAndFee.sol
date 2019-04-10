/**
 * @title GameVarAndFee
 *
 * @author @kittieFIGHT @ola
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

pragma solidity >=0.5.0 <0.6.0;


import "./interfaces/IContractManager.sol";
import "./modules/proxy/Proxied.sol";


/**
 * @title moderates the various fees, timing limits, expiry date/time, 
 * schedules, eth allocation per game, token allocation per game, kittiehell 
 * kittie expiration, time durations, distribution percentages e.t.c
 */
contract GameVarAndFee is Proxied {

  IContractManager contractManager;

  // Variables used by dateandtime contract
  uint48 public gamePrestart;
  uint48 public gameDuration;
  uint48 public kittieHellExpiration;
  uint48 public honeypotExpiration;
  uint48 public futureGameTime;
  uint48 public scheduleTimeLimits;

  // ---  
  uint48 public gameTimes;
  uint public ethPerGame;
  uint public dailyGameAvailability;  
  uint public gameLimit;
  uint public gamesRateLimitFee;  
  uint public kittieExpiry;
  uint public honeyPotDuration;
  
  //---expressed in KTY tokens 
  uint public tokensPerGame;
  uint public ticketFee;
  uint public bettingFee;
  uint public kittieRedemptionFee;

 

   /// @notice Distribution percentage for each participator in game
  struct DistributionRates {
    uint8 winningKittie;    // Winning kittie fighter (i.e 35% of honeypot/Jackpot )
    uint8 topBettor;        // top bettor ( i.e  25% of honeypot/Jackpot  )
    uint8 secondRunnerUp;   // second runner-up ( i.e 10% of honeypot/Jackpot) 
    uint8 otherBettors;     // Every other bettor ( i.e  share 15% equally ).
    uint8 endownment;       // Endowment, ( 15% is sent back to Endowment fund,later it will be split between endowment fund and DAO stakeholders) .
  }

  /**
   * @notice creating GameVarAndFee contract using `_contractManager` as contract manager address
   * @param _contractManager the contract manager used by the game
   */
  constructor(address _contractManager) public {
    contractManager = IContractManager(_contractManager);
  }

  // DateTime Functions   

  /// @notice Sets the time in future that a game is to be played
  function setFutureGameTime(uint48 _futureGameTime) 
  public 
  onlyProxy 
  returns(uint48) {
    futureGameTime = _futureGameTime;
    return futureGameTime;
  }

  /// @notice Sets the 2 min alloted time whereby both players must initiate start or forfeit game.
  function setGamePrestart(uint48 _gamePrestart) 
  public onlyProxy 
  returns (uint48) {
    gamePrestart = _gamePrestart;
    return gamePrestart;
  }

  /// @notice Sets Game duration, how long a game lasts 
  function setGameDuration(uint48 _gameDuration) 
  public onlyProxy 
  returns (uint48) {
    gameDuration = _gameDuration;
    return gameDuration;
  }

  /// @notice Sets how long to wait for payment for kittie in kittiehell before kittie is lost forever 
  function setKittieHellExpiration(uint48 _kittieHellExpiration) 
  public onlyProxy 
  returns (uint48) {
    kittieHellExpiration = _kittieHellExpiration;
    return kittieHellExpiration;
  }

  /// @notice Sets the time at which honey pot will be dissolved,after a game is over, used by time contract at end of gameduration
  function setHoneypotExpiration(uint48 _honeypotExpiration) 
  public onlyProxy 
  returns (uint48) {
    honeypotExpiration = _honeypotExpiration;
    return honeypotExpiration;
  }

  /// @notice Sets the farthest time in futre when a game can be schedule
  function setScheduleTimeLimits(uint48 _scheduleTimeLimits) 
  public onlyProxy 
  returns (uint48) {
    scheduleTimeLimits = _scheduleTimeLimits;
    return scheduleTimeLimits;
  }

  //---------------------------
  

  /// @notice Amount of initial KTY Tokens allowed to be drawn from EndowmentFund to be allocated to game
  function setTokensPerGame(uint _tokensPerGame) 
  public onlyProxy 
  returns (uint) {
    tokensPerGame = _tokensPerGame;
    return tokensPerGame;
  } 
  
  /// @notice Amount of initial ETH allowed to be drawn from EndowmentFund to be allocated to game
  function setEthPerGame(uint _ethPerGame)
  public onlyProxy 
  returns (uint) {
    ethPerGame = _ethPerGame;
    return ethPerGame;
  }

  /// @notice Amount of games allowed per day 
  function setDailyGameAvailability(uint _dailyGameAvailability)
  public onlyProxy 
  returns (uint) {
    dailyGameAvailability = _dailyGameAvailability;
    return dailyGameAvailability;
  } 

  /// @notice Times duration between each game per day
  function setGameTimes(uint48 _gameTimes)
  public onlyProxy 
  returns (uint48) {
    gameTimes = _gameTimes;
    return gameTimes;
  }

  /// @notice Games per day allowed per address "Games rate limit"
  function setGameLimit(uint _gameLimit)
  public onlyProxy 
  returns (uint) {
    gameLimit = _gameLimit;
    return gameLimit;
  }

  /// @notice Set fee paid to lift the limit of the number of games allowed per day, per address
  function setGamesRateLimitFee(uint _gamesRateLimitFee)
  public onlyProxy 
  returns (uint) {
    gamesRateLimitFee = _gamesRateLimitFee;
    return gamesRateLimitFee;
  }

    /// @notice Distribution percentage for each participator in game
  function setDistributionRate() public onlyProxy {

  } 

  /// @notice Get Distribution Rates
  function getDistributionRate() public onlyProxy {
  }

  /// @notice Set ticket fee in KTY for betting participators
  function setTicketFee() public onlyProxy {

  } 

  /// @notice Set betting fee in KTY for betting participators
  function setBettingFee() public onlyProxy {

  } 

  /// @notice Set kittieHELL redemption fee in KTY for redeeming kitties
  function setKittieRedemptionFee() public onlyProxy {

  }

  /// @notice Set Kittie expiry time in kittieHELL 
  function setKittieExpiry() public onlyProxy {

  } 

  /// @notice Set honeyPot duration/expiry after game end 
  function setHoneyPotDuration() public onlyProxy {
    
  } 

  /* function getters or public variables : write public getters or public variables 
  to access variable values important to other contracts dependent on them...*/


}
