pragma solidity ^0.5.5;


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
