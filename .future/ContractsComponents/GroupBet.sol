pragma solidity 0.4.19;


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
