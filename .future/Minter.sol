pragma solidity 0.4.19;

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
