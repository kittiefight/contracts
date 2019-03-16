pragma solidity ^0.5.5;


import "../ContractManager.sol";

contract PriceDiscovery is ContractManager {

    function PriceDiscovery () public {

    }

    /**
     * Fallback function
     */
    function () public payable {
        return;
    }
}
