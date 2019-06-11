pragma solidity ^0.5.5;

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
