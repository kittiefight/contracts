pragma solidity ^0.5.5;

interface IContractManager {
  function addContract(string calldata name, address contractAddress) external;
  function removeContract(string calldata name) external;
  function updateContract(string calldata name, address contractAddress) external;
  function getContract(string calldata name) external view returns (address);
}
