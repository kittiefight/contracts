pragma solidity ^0.5.5;


import "../ContractManager.sol";

contract WinAlgo is ContractManager {

    function WinAlgo() public {

    }

    /**
     * Fallback function
     */
    function () public payable {
        return;
    }
}
