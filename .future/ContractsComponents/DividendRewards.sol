pragma solidity 0.4.19;


import "../ContractManager.sol";

contract DividendRewards is ContractManager {

    function DividendRewards () public {

    }

    /**
     * Fallback function
     */
    function () public payable {
        return;
    }
}
