pragma solidity ^0.5.5;


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
