pragma solidity >=0.5.0 <0.6.0;

import "./interfaces/IDateTimeAPI.sol";

contract DateTimeAPI is IDateTimeAPI {
  struct DateTime {
    uint16 year;
    uint8 month;
    uint8 day;
    uint8 hour;
    uint8 minute;
    uint8 second;
    uint8 weekday;
  }
}
