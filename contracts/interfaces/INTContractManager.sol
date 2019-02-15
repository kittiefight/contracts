pragma solidity 0.4.21;

/**
 * @title INTContractManager
 * @dev Contract manager interface
 */
interface INTContractManager {
    function addContract(string name, address contractAddress) public;
    function removeContract(string name) public;
    function updateContract(string name, address contractAddress) public;
    function getContract(string name) public view returns (address);
}
