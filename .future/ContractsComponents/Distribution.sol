pragma solidity 0.4.19;


import "../ContractManager.sol";

contract Distribution is ContractManager {

    function Distribution() public {

    }

    /**
     * Fallback function
     */
    function () public payable {
        return;
    }
}
