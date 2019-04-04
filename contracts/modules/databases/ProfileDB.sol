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
import "../../libs/SafeMath.sol";


/**
 * @title ProfileDB
 * @author @psychoplasma
 */
contract ProfileDB is Proxied {
  using SafeMath for uint256;

  GenericDB public genericDB;

  string internal constant TABLE_NAME = "ProfileTable";
  string internal constant ERROR_ALREADY_EXIST = "Profile already exists";
  string internal constant ERROR_DOES_NOT_EXIST = "Profile not exists";


  function _setProxy(address _proxy) public onlyOwner {
    setProxy(Proxy(_proxy));
  }

  function setGenericDB(address _genericDB) public onlyOwner {
    genericDB = GenericDB(_genericDB);
  }

  function create(uint256 _id)
    external onlyContract(CONTRACT_NAME_REGISTER)
  {
    // Creates a linked list with the given keys, if it does not exist
    // otherwise just returs.
    genericDB.createLinkedList(CONTRACT_NAME_PROFILE_DB, TABLE_NAME);
    // Push the new profile pointer to the list
    require(genericDB.pushNodeToLinkedList(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, _id), ERROR_ALREADY_EXIST);
  }

  function setAccountAttributes(
    uint256 _id,
    address owner,
    bytes calldata genes,
    bytes calldata description
  )
    external onlyContract(CONTRACT_NAME_REGISTER)
  {
    require(genericDB.doesNodeExist(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, _id), ERROR_DOES_NOT_EXIST);
    genericDB.setAddressStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "ownerAddress")), owner);
    genericDB.setBytesStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "description")), description);
    genericDB.setBytesStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "genes")), genes);
  }

  function setLoginStatus(uint256 _id, bool isLoggedIn)
    external onlyContract(CONTRACT_NAME_REGISTER)
  {
    require(genericDB.doesNodeExist(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, _id), ERROR_DOES_NOT_EXIST);
    genericDB.setBoolStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "isLoggedIn")), isLoggedIn);
  }

  function setKittieAttributes(
    uint256 _id,
    uint256 kittieId,
    uint256 kittieHash,
    uint256 deadAt,
    string calldata kittieReferalHash,
    string calldata kittieStatus
  )
    external onlyContract(CONTRACT_NAME_REGISTER)
  {
    require(genericDB.doesNodeExist(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, _id), ERROR_DOES_NOT_EXIST);
    uint256 numberOfKitties = genericDB.getUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "kittieLength")));
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "kittieLength")), numberOfKitties.add(1));
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "kittieId")), kittieId);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "kittieHash")), kittieHash);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "deadAt")), deadAt);
    genericDB.setStringStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "kittieReferalHash")), kittieReferalHash);
    genericDB.setStringStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "kittieStatus")), kittieStatus);
  }

  function setGamingAttributes(
    uint256 _id,
    uint256 totalWins,
    uint256 totalLosses,
    uint256 tokensWon,
    uint256 lastFeeDate,
    uint256 feeHistory,
    bool isFreeToPlay
  )
    external onlyContract(CONTRACT_NAME_REGISTER)
  {
    require(genericDB.doesNodeExist(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, _id), ERROR_DOES_NOT_EXIST);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "totalWins")), totalWins);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "totalLosses")), totalLosses);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "tokensWon")), tokensWon);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "lastFeeDate")), lastFeeDate);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "feeHistory")), feeHistory);
    genericDB.setBoolStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "isFreeToPlay")), isFreeToPlay);
  }

  function setFightingAttributes(
    uint256 _id,
    uint256 totalFights,
    uint256 nextFight,
    uint256 listingStart,
    uint256 listingEnd
  )
    external onlyContract(CONTRACT_NAME_REGISTER)
  {
    require(genericDB.doesNodeExist(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, _id), ERROR_DOES_NOT_EXIST);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "totalFights")), totalFights);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "nextFight")), nextFight);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "listingStart")), listingStart);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "listingEnd")), listingEnd);
  }

  function setFeeAttributes(
    uint256 _id,
    uint256 feeType,
    uint256 paidDate,
    uint256 expirationDate,
    bool isPaid
  )
    external onlyContract(CONTRACT_NAME_REGISTER)
  {
    require(genericDB.doesNodeExist(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, _id), ERROR_DOES_NOT_EXIST);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "feeType")), feeType);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "paidDate")), paidDate);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "expirationDate")), expirationDate);
    genericDB.setBoolStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "isPaid")), isPaid);
  }

  function setTokenEconomyAttributes(
    uint256 _id,
    uint256 kittieFightTokens,
    uint256 superDAOTokens,
    bool isStakingSuperDAO
  )
    external onlyContract(CONTRACT_NAME_REGISTER)
  {
    require(genericDB.doesNodeExist(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, _id), ERROR_DOES_NOT_EXIST);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "kittieFightTokens")), kittieFightTokens);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "superDAOTokens")), superDAOTokens);
    genericDB.setBoolStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(_id, "isStakingSuperDAO")), isStakingSuperDAO);
  }
}
