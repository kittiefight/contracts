// ABI interface for all contracts
// all major interactive contract interfaces are compiled into this file for modularity and ease of maintainance
// reduces clutter in number of imports of dependent contract system
//  interfaces are instanciated through address derived from contract manager


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

contract ChroneJobListINT {

}

contract DSAuthINT {

}

contract DSNoteINT {

}


contract ContractManagerINT {

}


contract RegisterINT {

}


contract TimeContractINT {

}


contract GameVarAndFeeManagerINT {

}


contract ForfeiterINT {

}


contract SchedulerINT {

}


contract GamesManagerINT {

}


contract DistributionINT {

}


contract EndowmentFundINT {

}


contract MinterINT {

}


contract KittieHellINT {

}


contract ProfileDBINT {

}


contract SchedulerDBINT {

}


contract GamemanagerDBINT {

}


contract KittieHellDBINT {

}


contract HitsResolveAlgoINT {

}


contract BettingINT {

}


contract RarityCalculatorINT {

}


contract KtyINT {

}

contract CryptoKittiesINT {

}
