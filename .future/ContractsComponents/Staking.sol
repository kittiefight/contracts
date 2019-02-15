pragma solidity 0.4.19;


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
