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

import "./EternalStorage.sol";
import "../proxy/Proxied.sol";
import "../../Proxy.sol";
import "../../libs/LinkedListLib.sol";



/**
 * @title Generic Eternal Storage Unit which can only be accessed through the proxied contracts
 * @dev This contract holds all the necessary state variables to carry out the storage of any contract.
 * @author @psychoplasma
 */
contract GenericDB is EternalStorage, Proxied {
  using LinkedListLib for LinkedListLib.LinkedList;


  function setIntStorage(
    string calldata contractName,
    bytes32 key,
    int256 value
  )
    external onlyContract(contractName) 
  {
    intStorage[keccak256(abi.encodePacked(contractName, key))] = value;
  }

  function getIntStorage(
    string memory contractName,
    bytes32 key
  )
    public view returns (int256)
  {
    return intStorage[keccak256(abi.encodePacked(contractName, key))];
  }

  function setUintStorage(
    string calldata contractName,
    bytes32 key,
    uint256 value
  )
    external onlyContract(contractName) 
  {
    uintStorage[keccak256(abi.encodePacked(contractName, key))] = value;
  }

  function getUintStorage(
    string memory contractName,
    bytes32 key
  )
    public view returns (uint256)
  {
    return uintStorage[keccak256(abi.encodePacked(contractName, key))];
  }

  function setStringStorage(
    string calldata contractName,
    bytes32 key,
    string calldata value
  )
    external onlyContract(contractName) 
  {
    stringStorage[keccak256(abi.encodePacked(contractName, key))] = value;
  }

  function getStringStorage(
    string memory contractName,
    bytes32 key
  )
    public view returns (string memory)
  {
    return stringStorage[keccak256(abi.encodePacked(contractName, key))];
  }

  function setAddressStorage(
    string calldata contractName,
    bytes32 key,
    address value
  )
    external onlyContract(contractName) 
  {
    addressStorage[keccak256(abi.encodePacked(contractName, key))] = value;
  }

  function getAddressStorage(
    string memory contractName,
    bytes32 key
  )
    public view returns (address)
  {
    return addressStorage[keccak256(abi.encodePacked(contractName, key))];
  }

  function setBytesStorage(
    string calldata contractName,
    bytes32 key,
    bytes calldata value
  )
    external onlyContract(contractName) 
  {
    bytesStorage[keccak256(abi.encodePacked(contractName, key))] = value;
  }

  function getBytesStorage(
    string memory contractName,
    bytes32 key
  )
    public view returns (bytes memory)
  {
    return bytesStorage[keccak256(abi.encodePacked(contractName, key))];
  }

  function setBoolStorage(
    string calldata contractName,
    bytes32 key,
    bool value
  )
    external onlyContract(contractName) 
  {
    boolStorage[keccak256(abi.encodePacked(contractName, key))] = value;
  }

  function getBoolStorage(
    string memory contractName,
    bytes32 key
  )
    public view returns (bool)
  {
    return boolStorage[keccak256(abi.encodePacked(contractName, key))];
  }

  function pushNodeToLinkedList(
    string calldata contractName,
    string calldata linkedListName,
    uint256 nodeId
  )
    external onlyContract(contractName) returns (bool)
  {
    if (linkedListStorage[keccak256(abi.encodePacked(contractName, linkedListName))].nodeExists(nodeId)) {
      return false;
    }

    linkedListStorage[keccak256(abi.encodePacked(contractName, linkedListName))].push(nodeId, true);
    return true;
  }

  function removeNodeFromLinkedList(
    string calldata contractName,
    string calldata linkedListName,
    uint256 nodeId
  )
    external onlyContract(contractName) returns (bool)
  {
    if (!linkedListStorage[keccak256(abi.encodePacked(contractName, linkedListName))].nodeExists(nodeId)) {
      return false;
    }
    
    linkedListStorage[keccak256(abi.encodePacked(contractName, linkedListName))].remove(nodeId);
    return true;
  }

  function getAdjacent(
    string memory contractName,
    string memory linkedListName,
    uint256 nodeId,
    bool dir
  )
    public view returns (bool, uint256)
  {
    return linkedListStorage[keccak256(abi.encodePacked(contractName, linkedListName))].getAdjacent(nodeId, dir);
  }

  function doesListExist(
    string memory contractName,
    string memory linkedListName
  )
    public view returns (bool)
  {
    return linkedListStorage[keccak256(abi.encodePacked(contractName, linkedListName))].listExists();
  }

  function doesNodeExist(
    string memory contractName,
    string memory linkedListName,
    uint256 nodeId
  )
    public view returns (bool)
  {
    return linkedListStorage[keccak256(abi.encodePacked(contractName, linkedListName))].nodeExists(nodeId);
  }

  function getLinkedListSize(
    string memory contractName,
    string memory linkedListName
  )
    public view returns (uint256)
  {
    return linkedListStorage[keccak256(abi.encodePacked(contractName, linkedListName))].sizeOf();
  }
}