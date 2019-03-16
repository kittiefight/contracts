pragma solidity ^0.5.5;


import "../ContractManager.sol";

contract GroupBet is ContractManager {

    function GroupBet () public {

    }

    /**
     * Fallback function
     */
    function () public payable {
        return;
    }
}
