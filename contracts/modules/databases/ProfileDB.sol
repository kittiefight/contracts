// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
pragma solidity ^0.5.5;

import "../../Proxy.sol";
import "../proxy/Proxied.sol";
import "./GenericDB.sol";


/**
 * @title ProfileDB
 * @author @psychoplasma
 */
contract ProfileDB is Proxied {

  GenericDB genericDB;

  string constant TABLE_NAME = "ProfileTable";
  string constant ERROR_ALREADY_EXIST = "Profile with the given id already exists in ProfileDB";
  string constant ERROR_DOES_EXIST = "Profile with the given id does not exists in ProfileDB";


  function _setProxy(address _proxy) public onlyOwner {
    setProxy(Proxy(_proxy));
  }

  function setGenericDB(address _genericDB) public onlyOwner {
    genericDB = GenericDB(_genericDB);
  }

  function create(uint256 _id)
    external returns (bool)
  {
    // Creates a linked list with the given keys, if it does not exist
    // otherwise just returs.
    genericDB.createLinkedList(CONTRACT_NAME_PROFILE_DB, TABLE_NAME);
    // Push the new profile pointer to the list
    require(genericDB.pushNodeToLinkedList(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, _id), ERROR_ALREADY_EXIST);
    return true;
  }

  function setUintAttribute(uint256 _id, string calldata attrName, uint256 value)
    external onlyContract(CONTRACT_NAME_REGISTER) returns (bool)
  {
    require(genericDB.doesNodeExist(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, _id), ERROR_DOES_EXIST);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, attrName)), value);
    return true;
  }

  function getUintAttribute(uint256 _id, string memory attrName)
    public view returns (uint256)
  {
    require(genericDB.doesNodeExist(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, _id), ERROR_DOES_EXIST);
    return genericDB.getUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, attrName)));
  }

  function setIntAttribute(uint256 _id, string calldata attrName, int256 value)
    external onlyContract(CONTRACT_NAME_REGISTER) returns (bool)
  {
    require(genericDB.doesNodeExist(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, _id), ERROR_DOES_EXIST);
    genericDB.setIntStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, attrName)), value);
    return true;
  }

  function getIntAttribute(uint256 _id, string memory attrName)
    public view returns (int256)
  {
    require(genericDB.doesNodeExist(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, _id), ERROR_DOES_EXIST);
    return genericDB.getIntStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, attrName)));
  }

  function setAddressAttribute(uint256 _id, string calldata attrName, address value)
    external onlyContract(CONTRACT_NAME_REGISTER) returns (bool)
  {
    require(genericDB.doesNodeExist(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, _id), ERROR_DOES_EXIST);
    genericDB.setAddressStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, attrName)), value);
    return true;
  }

  function getAddressAttribute(uint256 _id, string memory attrName)
    public view returns (address)
  {
    require(genericDB.doesNodeExist(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, _id), ERROR_DOES_EXIST);
    return genericDB.getAddressStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, attrName)));
  }

  function setBoolAttribute(uint256 _id, string calldata attrName, bool value)
    external onlyContract(CONTRACT_NAME_REGISTER) returns (bool)
  {
    require(genericDB.doesNodeExist(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, _id), ERROR_DOES_EXIST);
    genericDB.setBoolStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, attrName)), value);
    return true;
  }

  function getBoolAttribute(uint256 _id, string memory attrName)
    public view returns (bool)
  {
    require(genericDB.doesNodeExist(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, _id), ERROR_DOES_EXIST);
    return genericDB.getBoolStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, attrName)));
  }

  function setStringAttribute(uint256 _id, string calldata attrName, string calldata value)
    external onlyContract(CONTRACT_NAME_REGISTER) returns (bool)
  {
    require(genericDB.doesNodeExist(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, _id), ERROR_DOES_EXIST);
    genericDB.setStringStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, attrName)), value);
    return true;
  }

  function getStringAttribute(uint256 _id, string memory attrName)
    public view returns (string memory)
  {
    require(genericDB.doesNodeExist(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, _id), ERROR_DOES_EXIST);
    return genericDB.getStringStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, attrName)));
  }

  function setBytesAttribute(uint256 _id, string calldata attrName, bytes calldata value)
    external onlyContract(CONTRACT_NAME_REGISTER) returns (bool)
  {
    require(genericDB.doesNodeExist(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, _id), ERROR_DOES_EXIST);
    genericDB.setBytesStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, attrName)), value);
    return true;
  }

  function getBytesAttribute(uint256 _id, string memory attrName)
    public view returns (bytes memory)
  {
    require(genericDB.doesNodeExist(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, _id), ERROR_DOES_EXIST);
    return genericDB.getBytesStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, attrName)));
  }
}
