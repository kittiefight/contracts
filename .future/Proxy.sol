pragma solidity ^0.5.5;

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
