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

import "../proxy/Proxied.sol";
import "./GenericDB.sol";
import "../../libs/SafeMath.sol";

/**
 * @title ProfileDB
 * @author @kittieFIGHT @psychoplasma
 */
contract ProfileDB is Proxied {
  using SafeMath for uint256;

  GenericDB public genericDB;

  string internal constant TABLE_NAME = "ProfileTable";
  string internal constant ERROR_ALREADY_EXIST = "Profile already exists";
  string internal constant ERROR_DOES_NOT_EXIST = "Profile not exists";

  constructor(GenericDB _genericDB) public {
    setGenericDB(_genericDB);
  }

  function setGenericDB(GenericDB _genericDB) public onlyOwner {
    genericDB = _genericDB;
  }

  function create(address account)
    external onlyContract(CONTRACT_NAME_REGISTER)
  {
    // Creates a linked list with the given keys, if it does not exist
    // And push the new profile pointer to the list
    require(genericDB.pushNodeToLinkedListAddr(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, account), ERROR_ALREADY_EXIST);
  }

  function setKittieAttributes(
    address account,
    uint256 kittieId,
    uint256 deadAt,
    string calldata kittieStatus
  )
    external onlyContract(CONTRACT_NAME_REGISTER)
  {
    require(genericDB.doesNodeAddrExist(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, account), ERROR_DOES_NOT_EXIST);
    // Check if kittie exists under this account
    require(kittieId == genericDB.getUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "kittieId"))));
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, kittieId, "deadAt")), deadAt);
    genericDB.setStringStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, kittieId, "kittieStatus")), kittieStatus);
  }

  function addKittie(
    address account,
    uint256 kittieId,
    uint256 deadAt,
    string calldata kittieStatus
  )
    external onlyContract(CONTRACT_NAME_REGISTER)
  {
    require(genericDB.doesNodeAddrExist(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, account), ERROR_DOES_NOT_EXIST);
    // Do not allow to add the same kittie again
    require(kittieId != genericDB.getUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "kittieId"))));
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "kittieId")), kittieId);
    // Increment the number of kitties for this account by one
    uint256 numOfKitties = genericDB.getUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "numOfKitties")));
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "numOfKitties")), numOfKitties.add(1));
    // Set that kittie's attributes
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, kittieId, "deadAt")), deadAt);
    genericDB.setStringStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, kittieId, "kittieStatus")), kittieStatus);
  }

  function removeKittie(
    address account,
    uint256 kittieId
  )
    external onlyContract(CONTRACT_NAME_REGISTER)
  {
    require(genericDB.doesNodeAddrExist(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, account), ERROR_DOES_NOT_EXIST);
    // Check if kittie exists under this account
    require(kittieId == genericDB.getUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "kittieId"))));
    // Decrement the number of kitties for this account by one
    uint256 numOfKitties = genericDB.getUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "numOfKitties")));
    // Number of kitties should never be zero, if the above require conditions pass, therefore it will never be negative. 
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "numOfKitties")), numOfKitties.sub(1));
  }

  function setGamingAttributes(
    address account,
    uint256 totalWins,
    uint256 totalLosses,
    uint256 tokensWon,
    uint256 lastFeeDate,
    uint256 feeHistory,
    bool isFreeToPlay
  )
    external onlyContract(CONTRACT_NAME_REGISTER)
  {
    require(genericDB.doesNodeAddrExist(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, account), ERROR_DOES_NOT_EXIST);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "totalWins")), totalWins);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "totalLosses")), totalLosses);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "tokensWon")), tokensWon);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "lastFeeDate")), lastFeeDate);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "feeHistory")), feeHistory);
    genericDB.setBoolStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "isFreeToPlay")), isFreeToPlay);
  }

  function setFightingAttributes(
    address account,
    uint256 totalFights,
    uint256 nextFight,
    uint256 listingStart,
    uint256 listingEnd
  )
    external onlyContract(CONTRACT_NAME_REGISTER)
  {
    require(genericDB.doesNodeAddrExist(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, account), ERROR_DOES_NOT_EXIST);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "totalFights")), totalFights);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "nextFight")), nextFight);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "listingStart")), listingStart);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "listingEnd")), listingEnd);
  }

  function setFeeAttributes(
    address account,
    uint256 feeType,
    uint256 paidDate,
    uint256 expirationDate,
    bool isPaid
  )
    external onlyContract(CONTRACT_NAME_REGISTER)
  {
    require(genericDB.doesNodeAddrExist(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, account), ERROR_DOES_NOT_EXIST);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "feeType")), feeType);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "paidDate")), paidDate);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "expirationDate")), expirationDate);
    genericDB.setBoolStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "isPaid")), isPaid);
  }

  function setTokenEconomyAttributes(
    address account,
    uint256 kittieFightTokens,
    uint256 superDAOTokens,
    bool isStakingSuperDAO
  )
    external onlyContract(CONTRACT_NAME_REGISTER)
  {
    require(genericDB.doesNodeAddrExist(CONTRACT_NAME_PROFILE_DB, TABLE_NAME, account), ERROR_DOES_NOT_EXIST);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "kittieFightTokens")), kittieFightTokens);
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "superDAOTokens")), superDAOTokens);
    genericDB.setBoolStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "isStakingSuperDAO")), isStakingSuperDAO);
  }
}
