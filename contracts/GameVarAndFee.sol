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

pragma solidity >=0.5.0 <0.6.0;


import "./interfaces/IContractManager.sol";
import "./DSNote.sol";

/// @dev it will implement Guard/modifier class
import "./modules/proxy/Proxied.sol";



/**
 * @title moderates the various fees, timing limits, expiry date/time, 
 * schedules, eth allocation per game, token allocation per game, kittiehell 
 * kittie expiration, time durations, distribution percentages e.t.c.
 * The note modifier will log event for each function call.
 */
contract GameVarAndFee is Proxied, DSNote {

  IContractManager contractManager;

  // Variables used by DateTime contract
  /// @dev we can even lower these to uint36 (year 2106)
  uint public gamePrestart;
  uint public gameDuration;
  uint public kittieHellExpiration;
  uint public honeypotExpiration;
  uint public futureGameTime;
  uint public scheduleTimeLimits;


  /// @dev what other variables can we optimize for gas costs   
  uint public gameTimes;
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

  DistributionRates public distributionRate;

  /**
   * @notice creating GameVarAndFee contract using `_contractManager` as contract manager address
   * @param _contractManager the contract manager used by the game
   */
  constructor(address _contractManager) public {
    contractManager = IContractManager(_contractManager);
  }

  // --- DateTime Functions --- 

  /// @notice Sets the time in future that a game is to be played
  function setFutureGameTime(uint _futureGameTime) 
  public onlyProxy note {
    futureGameTime = _futureGameTime;
  }

  /// @notice Sets the 2 min alloted time whereby both players must initiate start or forfeit game.
  function setGamePrestart(uint _gamePrestart) 
  public onlyProxy note {
    gamePrestart = _gamePrestart;
  }

  /// @notice Sets Game duration, how long a game lasts 
  function setGameDuration(uint _gameDuration) 
  public onlyProxy note {
    gameDuration = _gameDuration;
  }

  /// @notice Sets how long to wait for payment for kittie in kittiehell before kittie is lost forever 
  function setKittieHellExpiration(uint _kittieHellExpiration) 
  public onlyProxy note {
    kittieHellExpiration = _kittieHellExpiration;
  }

  /// @notice Sets the time at which honey pot will be dissolved,after a game is over, used by time contract at end of gameduration
  function setHoneypotExpiration(uint _honeypotExpiration) 
  public onlyProxy note {
    honeypotExpiration = _honeypotExpiration;
  }

  /// @notice Sets the farthest time in futre when a game can be schedule
  function setScheduleTimeLimits(uint _scheduleTimeLimits) 
  public onlyProxy note {
    scheduleTimeLimits = _scheduleTimeLimits;
  }

  //---------------------------
  

  /// @notice Amount of initial KTY Tokens allowed to be drawn from EndowmentFund to be allocated to game
  function setTokensPerGame(uint _tokensPerGame) 
  public onlyProxy note {
    tokensPerGame = _tokensPerGame;
  } 
  
  /// @notice Amount of initial ETH allowed to be drawn from EndowmentFund to be allocated to game
  function setEthPerGame(uint _ethPerGame)
  public onlyProxy note {
    ethPerGame = _ethPerGame;
  }

  /// @notice Amount of games allowed per day 
  function setDailyGameAvailability(uint _dailyGameAvailability)
  public onlyProxy note {
    dailyGameAvailability = _dailyGameAvailability;
  } 

  /// @notice Times duration between each game per day
  function setGameTimes(uint _gameTimes)
  public onlyProxy note {
    gameTimes = _gameTimes;
  }

  /// @notice Games per day allowed per address "Games rate limit"
  function setGameLimit(uint _gameLimit)
  public onlyProxy note {
    gameLimit = _gameLimit;
  }

  /// @notice Set fee paid to lift the limit of the number of games allowed per day, per address
  function setGamesRateLimitFee(uint _gamesRateLimitFee)
  public onlyProxy note {
    gamesRateLimitFee = _gamesRateLimitFee;
  }

  /// @notice Distribution percentage for each participator in game
  function setDistributionRate(
    uint8 _winningKittie, uint8 _topBettor, uint8 _secondRunnerUp, 
    uint8 _otherBettors, uint8 _endownment) 
    public onlyProxy note {

        distributionRate.winningKittie = _winningKittie;
        distributionRate.topBettor =_topBettor;
        distributionRate.secondRunnerUp = _secondRunnerUp;
        distributionRate.otherBettors = _otherBettors;
        distributionRate.endownment = _endownment;
  } 

  /// @notice Get Distribution Rates
  /// @dev or should it each have a different getter?
  function getDistributionRate() 
  public  view onlyProxy 
  returns (uint8, uint8, uint8, uint8, uint8) {
    
    return (
      distributionRate.winningKittie,
      distributionRate.topBettor,
      distributionRate.secondRunnerUp,
      distributionRate.otherBettors,
      distributionRate.endownment
    );
  }

  /// @notice Set ticket fee in KTY for betting participators
  function setTicketFee(uint _ticketFee) public onlyProxy note {
        ticketFee=_ticketFee;
  } 

  /// @notice Set betting fee in KTY for betting participators
  function setBettingFee(uint _bettingFee) public onlyProxy note {
        bettingFee=_bettingFee;
  } 

  /// @notice Set kittieHELL redemption fee in KTY for redeeming kitties
  function setKittieRedemptionFee(uint _RedemptionFee) public onlyProxy note {
      kittieRedemptionFee=_RedemptionFee;
    
  }

  /// @notice Set Kittie expiry time in kittieHELL 
  function setKittieExpiry(uint _kittieExpiry) public onlyProxy note {
        kittieExpiry=_kittieExpiry;
  } 

  /// @notice Set honeyPot duration/expiry after game end 
  function setHoneyPotDuration(uint _portDuration) public onlyProxy note {
    honeyPotDuration=_portDuration; 
  } 


}
