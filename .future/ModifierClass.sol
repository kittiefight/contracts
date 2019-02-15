pragma solidity 0.4.19;

import "./ContractManager.sol";



contract ModifierClass is ContractManager {

    function ModifierClass() public {

    }

    /**
     * Fallback function
     */
    function () public payable {
        return;
    }
}
