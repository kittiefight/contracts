pragma solidity ^0.5.5;


import "../ContractManager.sol";

contract Staking is ContractManager {

    function Staking() public {

    }

    /**
     * Fallback function
     */
    function () public payable {
        return;
    }
}
