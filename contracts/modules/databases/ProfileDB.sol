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
 * @author @psychoplasma
 */
contract ProfileDB is Proxied {
  using SafeMath for uint256;

  GenericDB public genericDB;

  bytes32 internal constant TABLE_KEY_PROFILE = keccak256(abi.encodePacked("ProfileTable"));
  string internal constant TABLE_NAME_KITTIE = "KittieTable";
  string internal constant ERROR_ALREADY_EXIST = "Profile already exists";
  string internal constant ERROR_DOES_NOT_EXIST = "Profile not exists";

  modifier onlyExistentProfile(address account) {
    require(doesProfileExist(account), ERROR_DOES_NOT_EXIST);
    _;
  }

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
    require(genericDB.pushNodeToLinkedListAddr(CONTRACT_NAME_PROFILE_DB, TABLE_KEY_PROFILE, account), ERROR_ALREADY_EXIST);
  }

  function setCivicId(address account, uint256 civicId)
    external
    onlyContract(CONTRACT_NAME_REGISTER)
    onlyExistentProfile(account)
  {
    // Check if the provided civic id is registered under another account
    require(
      genericDB.getAddressStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked("civicIdTable", civicId))) == address(0),
      "Civic id already in use"
    );
    // Save the civic id with the given account in a table
    genericDB.setAddressStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked("civicIdTable", civicId)), account);
    // Save the civic id under the given account as well
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "civicId")), civicId);
  }

  // // FIXME: Stale function
  // function setKittieAttributes(
  //   address account,
  //   uint256 kittieId,
  //   uint256 deadAt,
  //   uint256 gene,
  //   string calldata kittieStatus
  // )
  //   external
  //   onlyContract(CONTRACT_NAME_REGISTER)
  //   onlyExistentProfile(account)
  // {
  //   // Check if kittie exists under this account
  //   require(genericDB.doesNodeExist(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, TABLE_NAME_KITTIE)), kittieId));
  //   genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, kittieId, "gene")), gene);
  //   genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, kittieId, "deadAt")), deadAt);
  //   genericDB.setStringStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, kittieId, "kittieStatus")), kittieStatus);
  // }

  // // FIXME: Stale function
  // function addKittie(
  //   address account,
  //   uint256 kittieId,
  //   uint256 deadAt,
  //   uint256 gene,
  //   string calldata kittieStatus
  // )
  //   external
  //   onlyContract(CONTRACT_NAME_REGISTER)
  //   onlyExistentProfile(account)
  // {
  //   // Check if kittie exists or not under this account
  //   // If it does not, add it to kittie table under this account
  //   require(genericDB.pushNodeToLinkedList(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, TABLE_NAME_KITTIE)), kittieId));
  //   // Set that kittie's attributes
  //   genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, kittieId, "gene")), gene);
  //   genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, kittieId, "deadAt")), deadAt);
  //   genericDB.setStringStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, kittieId, "kittieStatus")), kittieStatus);
  // }

  // // FIXME: Stale function
  // function removeKittie(
  //   address account,
  //   uint256 kittieId
  // )
  //   external
  //   onlyContract(CONTRACT_NAME_REGISTER)
  //   onlyExistentProfile(account)
  // {
  //   // Check if kittie exists under this account
  //   // If it exists, remove the kittie from kittie table under this account
  //   require(genericDB.removeNodeFromLinkedList(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, TABLE_NAME_KITTIE)), kittieId));
  // }

  // // FIXME: Stale function
  // function setGamingAttributes(
  //   address account,
  //   uint256 totalWins,
  //   uint256 totalLosses,
  //   uint256 tokensWon,
  //   uint256 lastFeeDate,
  //   uint256 feeHistory,
  //   bool isFreeToPlay
  // )
  //   external
  //   onlyContract(CONTRACT_NAME_REGISTER)
  //   onlyExistentProfile(account)
  // {
  //   genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "totalWins")), totalWins);
  //   genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "totalLosses")), totalLosses);
  //   genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "tokensWon")), tokensWon);
  //   genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "lastFeeDate")), lastFeeDate);
  //   genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "feeHistory")), feeHistory);
  //   genericDB.setBoolStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "isFreeToPlay")), isFreeToPlay);
  // }

  // // FIXME: Stale function
  // function setFightingAttributes(
  //   address account,
  //   uint256 totalFights,
  //   uint256 nextFight,
  //   uint256 listingStart,
  //   uint256 listingEnd
  // )
  //   external
  //   onlyContract(CONTRACT_NAME_REGISTER)
  //   onlyExistentProfile(account)
  // {
  //   genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "totalFights")), totalFights);
  //   genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "nextFight")), nextFight);
  //   genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "listingStart")), listingStart);
  //   genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "listingEnd")), listingEnd);
  // }

  // // FIXME: Stale function
  // function setFeeAttributes(
  //   address account,
  //   uint256 feeType,
  //   uint256 paidDate,
  //   uint256 expirationDate,
  //   bool isPaid
  // )
  //   external
  //   onlyContract(CONTRACT_NAME_REGISTER)
  //   onlyExistentProfile(account)
  // {
  //   genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "feeType")), feeType);
  //   genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "paidDate")), paidDate);
  //   genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "expirationDate")), expirationDate);
  //   genericDB.setBoolStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "isPaid")), isPaid);
  // }

  function setSuperDAOTokens(
    address account,
    uint256 superDAOTokens,
    bool isStakingSuperDAO
  )
    external
    onlyContract(CONTRACT_NAME_REGISTER)
    onlyExistentProfile(account)
  {
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "superDAOTokens")), superDAOTokens);
    genericDB.setBoolStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "isStakingSuperDAO")), isStakingSuperDAO);
  }

  function setKittieFightTokens(
    address account,
    uint256 kittieFightTokens
  )
    external
    onlyContract(CONTRACT_NAME_REGISTER)
    onlyExistentProfile(account)
  {
    genericDB.setUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "kittieFightTokens")), kittieFightTokens);
  }

  function getKittieAttributes(address account, uint256 kittieId)
    public view
    onlyContract(CONTRACT_NAME_REGISTER)
    onlyExistentProfile(account)
    returns (uint256 gene, uint256 deadAt, string memory status)
  {
    require(genericDB.doesNodeExist(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, TABLE_NAME_KITTIE)), kittieId));
    gene = genericDB.getUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, kittieId, "gene")));
    deadAt = genericDB.getUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, kittieId, "deadAt")));
    status = genericDB.getStringStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, kittieId, "kittieStatus")));
  }


  function getCivicId(address account)
    public view
    returns (uint256)
  {
    return genericDB.getUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "civicId")));
  }

  function getKittieFightTokens(address account)
    public
    onlyExistentProfile(account)
    view returns (uint256 amount)
  {
    amount = genericDB.getUintStorage(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, "kittieFightTokens")));
  }

  function doesProfileExist(address account) public view returns (bool) {
    return genericDB.doesNodeAddrExist(CONTRACT_NAME_PROFILE_DB, TABLE_KEY_PROFILE, account);
  }

  // function getKitties(address account) public view returns (uint256[] memory) {
  //   return genericDB.getAll(
  //     CONTRACT_NAME_PROFILE_DB,
  //     keccak256(abi.encodePacked(account, TABLE_NAME_KITTIE))
  //   );
  // }

  function getKittieCount(address account) public view returns (uint256) {
    return genericDB.getLinkedListSize(
      CONTRACT_NAME_PROFILE_DB,
      keccak256(abi.encodePacked(account, TABLE_NAME_KITTIE))
    );
  }

  function doesKittieExist(address account, uint256 kittieId) public view returns (bool) {
    return genericDB.doesNodeExist(CONTRACT_NAME_PROFILE_DB, keccak256(abi.encodePacked(account, TABLE_NAME_KITTIE)), kittieId);
  }
}
