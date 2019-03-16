pragma solidity ^0.5.5;

import "./ContractManager.sol";



contract BurnProtocol is ContractManager {

    function BurnProtocol() public {

    }

    /**
     * Fallback function
     */
    function () public payable {
        return;
    }
}
