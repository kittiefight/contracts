pragma solidity ^0.5.5;

import "../ContractManager.sol";

// https://github.com/pipermerriam/ethereum-datetime

contract DateTimeAPI {
        /*
         *  Abstract contract for interfacing with the DateTime contract.
         *
         */
        function isLeapYear(uint16 year) constant returns (bool);
        function getYear(uint timestamp) constant returns (uint16);
        function getMonth(uint timestamp) constant returns (uint8);
        function getDay(uint timestamp) constant returns (uint8);
        function getHour(uint timestamp) constant returns (uint8);
        function getMinute(uint timestamp) constant returns (uint8);
        function getSecond(uint timestamp) constant returns (uint8);
        function getWeekday(uint timestamp) constant returns (uint8);
        function toTimestamp(uint16 year, uint8 month, uint8 day) constant returns (uint timestamp);
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) constant returns (uint timestamp);
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) constant returns (uint timestamp);
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) constant returns (uint timestamp);
}


contract TimerContract is ContractManager {

    DateTimeAPI dateTime;
    function TimerContract () public {
      dateTime = DateTimeAPI(x1a6184CD4C5Bea62B0116de7962EE7315B7bcBce);

    }

    /**
     * Fallback function
     */
    function () public payable {
        return;
    }


}
