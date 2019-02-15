pragma solidity 0.4.19;


import "../ContractManager.sol";

contract UserProfile is ContractManager {

    function UserProfile () public {

    }

    /**
     * Fallback function
     */
    function () public payable {
        return;
    }
}
