pragma solidity 0.4.19;


import "../ContractManager.sol";

contract FightListing is ContractManager {

    function FightListing() public {

    }

    /**
     * Fallback function
     */
    function () public payable {
        return;
    }
}
