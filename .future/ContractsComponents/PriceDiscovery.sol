pragma solidity 0.4.19;


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
