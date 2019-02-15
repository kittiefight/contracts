pragma solidity >=0.5.0 <0.6.0;

import "./authority/Owned.sol";


contract ContractManager is Owned {
    mapping(string => address) private contracts;

    function addContract(string name, address contractAddress) public onlyOwner {
        require(contracts[name] == 0);

        contracts[name] = contractAddress;
    }

    function removeContract(string name) public onlyOwner {
        require(contracts[name] != 0);

        contracts[name] = 0;
    }

    function updateContract(string name, address contractAddress) public onlyOwner {
        require(contracts[name] != 0);

        contracts[name] = contractAddress;
    }

    function getContract(string name) public view returns (address) {
        require(contracts[name] != 0);

        return contracts[name];
    }
}
