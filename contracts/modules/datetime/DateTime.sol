/**
* @title DateTime
*
* @author @wafflemakr @hamaad
*
*/

// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday

pragma solidity ^0.5.5;


import "../../GameVarAndFee.sol";
import "../proxy/Proxied.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";


/**
 * @title Contract to track minutes, hour, daily, the weekly and monthly schedule
 * for scheduling activities within the platform. Used by contract to for time tracking,
 * accurately scheduling game events within the kittiefight sytem .
 * @dev check return variables, depending of what other contracts need.
 */
contract DateTime is Proxied {

    using BokkyPooBahsDateTimeLibrary for uint;

    GameVarAndFee public gameVarAndFee;

    /**
    * @notice initialize the gameVarAndFee contract
    */
    function initialize() external onlyOwner {
        gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
    }

    /**
    * @notice generic timestamp parser
    */
    function convertTimeStamp(uint timeStamp)
        public pure
        returns(
        uint _year, uint _month, uint _day, uint _hour,
        uint _minute, uint second)
    {
        (_year, _month, _day, _hour, _minute, second) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(timeStamp);
    }

    
    /**
    * @notice Uses the variable "gameDuration" to compare against current time and
    * determine the "Time" when game should end .
    * @return Time in hour, minutes and seconds
    */
    function runGameDurationTime()
        public view
        returns(
        uint _year, uint _month, uint _day, uint _hour,
        uint _minute, uint second)
    {
        uint _gameDuration = gameVarAndFee.getGameDuration();
        (_year, _month, _day, _hour, _minute, second) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(now + _gameDuration);

    }

    /**
    * @notice Uses the variable "kittieHellExpiration" to compare against gameEndtime and
    * determine  the "Time" when a CAT in kittiehell is lost forever
    * @return Time in hour, minutes and seconds
    */
    function runKittieHellExpirationTime(uint _gameEndTime)
    public view
        returns(
        uint _year, uint _month, uint _day, uint _hour,
        uint _minute, uint second)
    {
        uint _kittieHellExpiration = gameVarAndFee.getKittieHellExpiration();
        (_year, _month, _day, _hour, _minute, second) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(_gameEndTime + _kittieHellExpiration);
    }

    /**
    * @notice Uses the variable "honeypotExpiration" to compare against gameEndtime and
    * determine  the "Time" when honeypot should expire and be dissolved
    * @return Time in hour, minutes and seconds
    */
    function runhoneypotExpirationTime(uint _gameEndTime)
    public view
    returns(
        uint _year, uint _month, uint _day, uint _hour,
        uint _minute, uint second)
    {
        uint _honeypotExpiration = gameVarAndFee.getHoneypotExpiration();
        (_year, _month, _day, _hour, _minute, second) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(_gameEndTime + _honeypotExpiration);
    }

    /**
    * @notice Uses the variable "futureGameTime" to compare against current time "now"
    * and determine a future start date and or time for a game
    * @return Date and Time
    */
    function runfutureGameTime()
        public view
        returns(
        uint _year, uint _month, uint _day, uint _hour,
        uint _minute, uint second)
    {
        uint _futureGameTime = gameVarAndFee.getFutureGameTime();
        (_year, _month, _day, _hour, _minute, second) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(now + _futureGameTime);
    }
}