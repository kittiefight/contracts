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
import "../../libs/LinkedListLib.sol";
import "../../libs/LinkedListAddrLib.sol";


/**
 * @title EternalStorage
 * @dev This contract holds all the necessary state variables to carry out the storage of any contract.
 */
contract GenericDB is EternalStorage, Proxied {
  using LinkedListLib for LinkedListLib.LinkedList;
  using LinkedListAddrLib for LinkedListAddrLib.LinkedList;

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
    bytes32 tableKey,
    uint256 nodeId
  )
    external onlyContract(contractName) returns (bool)
  {
    if (linkedListStorage[keccak256(abi.encodePacked(contractName, tableKey))].nodeExists(nodeId)) {
      return false;
    }

    linkedListStorage[keccak256(abi.encodePacked(contractName, tableKey))].push(nodeId, true);
    return true;
  }

  function removeNodeFromLinkedList(
    string calldata contractName,
    bytes32 tableKey,
    uint256 nodeId
  )
    external onlyContract(contractName) returns (bool)
  {
    if (!linkedListStorage[keccak256(abi.encodePacked(contractName, tableKey))].nodeExists(nodeId)) {
      return false;
    }
    
    linkedListStorage[keccak256(abi.encodePacked(contractName, tableKey))].remove(nodeId);
    return true;
  }

  function insertNodeToLinkedList(
    string calldata contractName,
    bytes32 tableKey,
    uint256 nodeId,
    uint256 referenceNodeId,
    bool direction
  )
    external onlyContract(contractName) returns (bool)
  {
    return linkedListStorage[keccak256(abi.encodePacked(contractName, tableKey))].insert(referenceNodeId, nodeId, direction);
  }

  function findNextNodeInSortedLinkedList(
    string memory contractName,
    bytes32 tableKey,
    uint256 value
  )
    public view onlyContract(contractName) returns (uint256)
  {
    return linkedListStorage[keccak256(abi.encodePacked(contractName, tableKey))].getSortedSpot(0, value, true); //0 - search from HEAD, true - NEXT direction
  }

  function getAdjacent(
    string memory contractName,
    bytes32 tableKey,
    uint256 nodeId,
    bool dir
  )
    public view returns (bool, uint256)
  {
    return linkedListStorage[keccak256(abi.encodePacked(contractName, tableKey))].getAdjacent(nodeId, dir);
  }

  function getAll(
    string memory contractName,
    bytes32 key
  )
    public
    view returns (uint256[] memory nodes)
  {
    uint256 nextNode;
    uint256 i;
    uint256 len = getLinkedListSize(contractName, key);
    nodes = new uint256[](len);

    do {
      (,nextNode) = getAdjacent(contractName, key, nextNode, true);
      if (nextNode > 0) {nodes[i++] = nextNode;}
    } while (nextNode != 0 && i < len);
  }

  function doesListExist(
    string memory contractName,
    bytes32 tableKey
  )
    public view returns (bool)
  {
    return linkedListStorage[keccak256(abi.encodePacked(contractName, tableKey))].listExists();
  }

  function doesNodeExist(
    string memory contractName,
    bytes32 tableKey,
    uint256 nodeId
  )
    public view returns (bool)
  {
    return linkedListStorage[keccak256(abi.encodePacked(contractName, tableKey))].nodeExists(nodeId);
  }

  function getLinkedListSize(
    string memory contractName,
    bytes32 tableKey
  )
    public view returns (uint256)
  {
    return linkedListStorage[keccak256(abi.encodePacked(contractName, tableKey))].sizeOf();
  }

  function pushNodeToLinkedListAddr(
    string calldata contractName,
    bytes32 tableKey,
    address nodeId
  )
    external onlyContract(contractName) returns (bool)
  {
    if (linkedListAddrStorage[keccak256(abi.encodePacked(contractName, tableKey))].nodeExists(nodeId)) {
      return false;
    }

    linkedListAddrStorage[keccak256(abi.encodePacked(contractName, tableKey))].push(nodeId, true);
    return true;
  }

  function removeNodeFromLinkedListAddr(
    string calldata contractName,
    bytes32 tableKey,
    address nodeId
  )
    external onlyContract(contractName) returns (bool)
  {
    if (!linkedListAddrStorage[keccak256(abi.encodePacked(contractName, tableKey))].nodeExists(nodeId)) {
      return false;
    }
    
    linkedListAddrStorage[keccak256(abi.encodePacked(contractName, tableKey))].remove(nodeId);
    return true;
  }

  function getAdjacentAddr(
    string memory contractName,
    bytes32 tableKey,
    address nodeId,
    bool dir
  )
    public view returns (bool, address)
  {
    return linkedListAddrStorage[keccak256(abi.encodePacked(contractName, tableKey))].getAdjacent(nodeId, dir);
  }

  function getAllAddr(
    string memory contractName,
    bytes32 tableKey
  )
    public
    view returns (address[] memory nodes)
  {
    address nextNode;
    uint256 i;
    uint256 len = getLinkedListAddrSize(contractName, tableKey);
    nodes = new address[](len);

    do {
      (,nextNode) = getAdjacentAddr(contractName, tableKey, nextNode, true);
      if (nextNode != address(0)) {nodes[i++] = nextNode;}
    } while (nextNode != address(0) && i < len);
  }

  function doesListAddrExist(
    string memory contractName,
    bytes32 tableKey
  )
    public view returns (bool)
  {
    return linkedListAddrStorage[keccak256(abi.encodePacked(contractName, tableKey))].listExists();
  }

  function doesNodeAddrExist(
    string memory contractName,
    bytes32 tableKey,
    address nodeId
  )
    public view returns (bool)
  {
    return linkedListAddrStorage[keccak256(abi.encodePacked(contractName, tableKey))].nodeExists(nodeId);
  }

  function getLinkedListAddrSize(
    string memory contractName,
    bytes32 tableKey
  )
    public view returns (uint256)
  {
    return linkedListAddrStorage[keccak256(abi.encodePacked(contractName, tableKey))].sizeOf();
  }
}
