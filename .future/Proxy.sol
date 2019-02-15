pragma solidity 0.4.19;

import "./ContractManager.sol";



contract Proxy is ContractManager {

    function Proxy() public {

    }

    /**
     * Fallback function
     */
    function () public payable {
        return;
    }
}
