pragma solidity ^0.5.5;

import "./GenericDB.sol";
import "../proxy/Proxied.sol";


contract RoleDB is Proxied, GenericDB {
  GenericDB public genericDB;

  event RoleAdded(address indexed account, string role);
  event RoleRemoved(address indexed account, string role);

  constructor (GenericDB _genericDB) public {
    setGenericDB(_genericDB);
  }

  function setGenericDB(GenericDB _genericDB) public onlyOwner {
    genericDB = _genericDB;
  }

  function addRole(
    string calldata contractName,
    string calldata role,
    address account
  ) 
    external onlyContract(contractName)
  {
    require(account != address(0), "0x0 address!");
    require(!hasRole(role, account), "Existent role!");
    genericDB.setBoolStorage(CONTRACT_NAME_ROLE_DB, keccak256(abi.encodePacked(role, account)), true);
    emit RoleAdded(account, role);
  }

  function removeRole(
    string calldata contractName,
    string calldata role,
    address account
  )
    external onlyContract(contractName)
  {
    require(hasRole(role, account), "Non-existent role!");
    genericDB.setBoolStorage(CONTRACT_NAME_ROLE_DB, keccak256(abi.encodePacked(role, account)), false);
    emit RoleRemoved(account, role);
  }

  function hasRole(
    string memory role,
    address account
  )
    public view returns (bool)
  {
    return genericDB.getBoolStorage(CONTRACT_NAME_ROLE_DB, keccak256(abi.encodePacked(role, account)));
  }
}
