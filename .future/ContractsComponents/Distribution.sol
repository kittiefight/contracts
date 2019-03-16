pragma solidity ^0.5.5;


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
