pragma solidity 0.4.19;

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
