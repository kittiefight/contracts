pragma solidity >=0.5.0 <0.6.0;

import "../../interfaces/INTAllContracts.sol";
import "../../interfaces/INTContractManager.sol";



contract DateTimeAPI {


mapping(uint => uint) gameIDTimeExpiry; // game id to time expiration
mapping(bytes => uint) honeypotIDTimeExpiry; // honeypot id to time expiration
mapping(bytes => uint) kittieHellIDTimeExpiry; // kittiehell id to time expiration

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
