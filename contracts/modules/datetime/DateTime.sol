/**
* @title DateTime
*
* @author @wafflemakr @hamaad
*
*/


pragma solidity >=0.5.0 <0.6.0;

import "./DateTimeAPI.sol";
import "../../interfaces/IContractManager.sol";
import "../../GameVarAndFee.sol";

contract DateTime is DateTimeAPI{
    
    IContractManager contractManager;

    /**
    * @notice creating DateTime contract using `_contractManager` as contract manager address
    * @param _contractManager the contract manager used by the game
    */
    constructor(address _contractManager) public {
        contractManager = IContractManager(_contractManager);
    }

    /**
    * @notice Uses the variable  "futureGameTime" from gameVarAndFeeManager 
    * to compare against current time and determine the countdown start of the 
    * allocated prestart time in the "gamePrestart" variable. I.e 2 min countdown 
    * @return Date and Time
    */
    function runGamePrestartTime() 
    public view 
    returns(
    uint16 _year, uint8 _month, uint8 _day, uint8 _hour, 
    uint8 _minute, uint8 second, uint8 weekday) 
    {
        GameVarAndFee gameVarAndFee = GameVarAndFee(contractManager.getContract("GameVarAndFee"));
        uint _futureGameTime = gameVarAndFee.futureGameTime();
        uint _gamePrestart = gameVarAndFee.gamePrestart();

        _DateTime dt = parseTimestamp(now + _futureGameTime - _gamePrestart);

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
        GameVarAndFee gameVarAndFee = GameVarAndFee(contractManager.getContract("GameVarAndFee"));
        uint _gameDuration = gameVarAndFee.gameDuration();

        _DateTime dt = parseTimestamp(now + _gameDuration);

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
        GameVarAndFee gameVarAndFee = GameVarAndFee(contractManager.getContract("GameVarAndFee"));
        uint _kittieHellExpiration = gameVarAndFee.kittieHellExpiration();

        _DateTime dt = parseTimestamp(_gameEndTime + _kittieHellExpiration);

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
        GameVarAndFee gameVarAndFee = GameVarAndFee(contractManager.getContract("GameVarAndFee"));
        uint _honeypotExpiration = gameVarAndFee.honeypotExpiration();

        _DateTime dt = parseTimestamp(_gameEndTime + _honeypotExpiration);

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
        GameVarAndFee gameVarAndFee = GameVarAndFee(contractManager.getContract("GameVarAndFee"));
        uint _futureGameTime = gameVarAndFee.futureGameTime();

        _DateTime dt = parseTimestamp(now + _futureGameTime);

        return (dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second, dt.weekday);

    }  
}