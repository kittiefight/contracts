pragma solidity ^0.5.5;

import "./ContractManager.sol";



contract EventClass is ContractManager {

    function EventClass() public {

    }

    /**
     * Fallback function
     */
    function () public payable {
        return;
    }
}
