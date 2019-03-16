pragma solidity ^0.5.5;

import "./authority/Owned.sol";
import "./interfaces/IContractManager.sol";

contract ContractManager is Owned, IContractManager {
    mapping(string => address) private contracts;

    function addContract(string memory name, address contractAddress) public onlyOwner {
        require(contracts[name] == address(0));

        contracts[name] = contractAddress;
    }

    function removeContract(string memory name) public onlyOwner {
        require(contracts[name] != address(0));

        contracts[name] = address(0);
    }

    function updateContract(string memory name, address contractAddress) public onlyOwner {
        require(contracts[name] != address(0));

        contracts[name] = contractAddress;
    }

    function getContract(string memory name) public view returns (address) {
        require(contracts[name] != address(0));

        return contracts[name];
    }
}
