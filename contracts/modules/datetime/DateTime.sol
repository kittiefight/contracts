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

/**
 * @title Contract to track minutes, hour, daily, the weekly and monthly schedule
 * for scheduling activities within the platform. Used by contract to for time tracking,
 * accurately scheduling game events within the kittiefight sytem .
 */
contract DateTime {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;


    function getBlockchainTime()
        public view
        returns(
        uint _year, uint _month, uint _day, uint _hour,
        uint _minute, uint second)
    {
        (_year, _month, _day, _hour, _minute, second) = timestampToDateTime(now);
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
        (_year, _month, _day, _hour, _minute, second) = timestampToDateTime(timeStamp);
    }

    // from BokkyPooBahsDateTimeLibrary
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }
}