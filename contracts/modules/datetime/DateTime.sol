/**
* @title DateTime
*
* @author @wafflemakr @hamaad
*
*/

pragma solidity ^0.5.5;

import "./DateTimeAPI.sol";
import "../../GameVarAndFee.sol";
import "../proxy/Proxied.sol";

/**
 * @title Contract to track minutes, hour, daily, the weekly and monthly schedule 
 * for scheduling activities within the platform. Used by contract to for time tracking,
 * accurately scheduling game events within the kittiefight sytem .
 * @dev check return variables, depending of what other contracts need.
 */
contract DateTime is Proxied, DateTimeAPI {
    
    /**
    * @notice Uses the variable  "futureGameTime" from gameVarAndFeeManager 
    * to compare against current time and determine the countdown start of the 
    * allocated prestart time in the "gamePrestart" variable. I.e 2 min countdown 
    * @return Date and Time
    * @dev gameVarAndFee will always get the updated address from contract manager if changed
    */
    function runGamePrestartTime() 
    public view 
    returns(
    uint16 _year, uint8 _month, uint8 _day, uint8 _hour, 
    uint8 _minute, uint8 second, uint8 weekday) 
    {
        GameVarAndFee gameVarAndFee = GameVarAndFee(proxy.getContract("GameVarAndFee"));
        uint _futureGameTime = gameVarAndFee.getFutureGameTime();
        uint _gamePrestart = gameVarAndFee.getGamePrestart();

        _DateTime memory dt = parseTimestamp(now + _futureGameTime - _gamePrestart);

        return (dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second, dt.weekday);
    }
    
    /**
    * @notice Uses the variable "gameDuration" to compare against current time and 
    * determine the "Time" when game should end .
    * @return Time in hour, minutes and seconds
    */
    function runGameDurationTime() 
    public view 
    returns(
    uint8 _hour, uint8 _minute, uint8 second)
    {
        GameVarAndFee gameVarAndFee = GameVarAndFee(proxy.getContract("GameVarAndFee"));
        uint _gameDuration = gameVarAndFee.getGameDuration();

        _DateTime memory dt = parseTimestamp(now + _gameDuration);

        return (dt.hour, dt.minute, dt.second);

    }

    /**
    * @notice Uses the variable "kittieHellExpiration" to compare against gameEndtime and 
    * determine  the "Time" when a CAT in kittiehell is lost forever 
    * @return Time in hour, minutes and seconds
    */
    function runKittieHellExpirationTime(uint _gameEndTime) 
    public view
    returns(
    uint8 _hour, uint8 _minute, uint8 second)
    {
        GameVarAndFee gameVarAndFee = GameVarAndFee(proxy.getContract("GameVarAndFee"));
        uint _kittieHellExpiration = gameVarAndFee.getKittieHellExpiration();

        _DateTime memory dt = parseTimestamp(_gameEndTime + _kittieHellExpiration);

        return (dt.hour, dt.minute, dt.second);

    }

    /**
    * @notice Uses the variable "honeypotExpiration" to compare against gameEndtime and 
    * determine  the "Time" when honeypot should expire and be dissolved
    * @return Time in hour, minutes and seconds
    */
    function runhoneypotExpirationTime(uint _gameEndTime) 
    public view 
    returns(
    uint8 _hour, uint8 _minute, uint8 second)
    {
        GameVarAndFee gameVarAndFee = GameVarAndFee(proxy.getContract("GameVarAndFee"));
        uint _honeypotExpiration = gameVarAndFee.getHoneypotExpiration();

        _DateTime memory dt = parseTimestamp(_gameEndTime + _honeypotExpiration);

        return (dt.hour, dt.minute, dt.second);
    } 

    /**
    * @notice Uses the variable "futureGameTime" to compare against current time "now" 
    * and determine a future start date and or time for a game
    * @return Date and Time
    */
    function runfutureGameTime() 
    public view 
    returns(
    uint16 _year, uint8 _month, uint8 _day, uint8 _hour, 
    uint8 _minute, uint8 second, uint8 weekday) 
    {
        GameVarAndFee gameVarAndFee = GameVarAndFee(proxy.getContract("GameVarAndFee"));
        uint _futureGameTime = gameVarAndFee.getFutureGameTime();

        _DateTime memory dt = parseTimestamp(now + _futureGameTime);

        return (dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second, dt.weekday);

    }  
}