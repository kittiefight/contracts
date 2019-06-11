pragma solidity ^0.5.5;

import "./ContractManager.sol";



contract Minter is ContractManager {

    function Minter() public {

    }

    /**
     * Fallback function
     */
    function () public payable {
        return;
    }
}
