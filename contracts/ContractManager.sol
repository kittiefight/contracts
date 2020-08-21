pragma solidity ^0.5.17;

import "./authority/Owned.sol";
import "./interfaces/IContractManager.sol";

contract ContractManager is Owned, IContractManager {
    mapping(bytes32 => address) private contracts;

    function addContract(string memory name, address contractAddress) public onlyOwner {
        require(contractAddress != address(0), 'Contract address can not be zero');
        bytes32 hash = keccak256(bytes(name));
        require(contracts[hash] == address(0), 'Contract with this name already added');

        contracts[hash] = contractAddress;
    }

    function removeContract(string memory name) public onlyOwner {
        bytes32 hash = keccak256(bytes(name));
        require(contracts[hash] != address(0), 'No contract with this name found');

        contracts[hash] = address(0);
    }

    function updateContract(string memory name, address contractAddress) public onlyOwner {
        bytes32 hash = keccak256(bytes(name));
        require(contracts[hash] != address(0), 'No contract with this name found');

        contracts[hash] = contractAddress;
    }

    function getContract(string memory name) public view returns (address) {
        bytes32 hash = keccak256(bytes(name));
        //require(contracts[name] != address(0), 'Contract not registered');
        if(contracts[hash] == address(0)) {
            bytes memory error = abi.encodeWithSignature('Error(string)',string(abi.encodePacked('Contract not registered: ', name)));
            assembly {
                revert(add(error,32), error)
            }
        }

        return contracts[hash];
    }

    function getContracts(bytes32[] calldata nameHashes) external view returns(address[] memory) {
        address[] memory addresses = new address[](nameHashes.length);
        for(uint256 i=0; i < nameHashes.length; i++){
            addresses[i] = contracts[nameHashes[i]];
        }
        return addresses;
    }
}
