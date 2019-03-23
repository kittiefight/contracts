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

import "../../libs/LinkedListLib.sol";
import "../../libs/DBSchemaLib.sol";
import "../../authority/DSGuard.sol";


/**
 * @title ProfileDB
 * @author @kittieFIGHT @psychoplasma
 */
contract ProfileDB is DSGuard {
  using LinkedListLib for LinkedListLib.LinkedList;

  /// Data table which keeps items' id in linked list for easy tracking and sorting
  LinkedListLib.LinkedList private profileTable;

  /// Data bucket where profile items are actually stored
  mapping (uint256 => DBSchemaLib.ProfileSchema) profileBucket;


  /// @dev Creates empty profile item in ProfileDB table with the given id
  /// @param _id uint256 Unique identifier for the profile to be created
  function create(uint256 _id)
    external auth returns (bool)
  {
    require(!profileTable.nodeExists(_id), "Item already exists in ProfileDB");
    require(profileTable.push(_id, true), "Cannot add item to ProfileDB");
    DBSchemaLib.ProfileSchema memory profile;
    profileBucket[_id] = profile;
    return true;
  }

  /// @dev Deletes the profile item from ProfileDB with the given id
  /// @param _id uint256 Unique identifier for the profile to be deleted
  function remove(uint256 _id) 
    external auth returns (bool) 
  {
    require(profileTable.nodeExists(_id), "Item does not exist in ProfileDB");
    require(profileTable.remove(_id) != 0, "Cannot remove item from ProfileDB");
    delete profileBucket[_id];
    return true;
  }

  /// @dev Returns the size of the DB table
  function getTableSize()
    external auth view returns (uint256) 
  {
    return profileTable.sizeOf();
  }

  function setOwnerAddress(uint256 _id, address _owner)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].owner = _owner;
    return true;
  }

  function getOwnerAddress(uint256 _id)
    external auth view returns (address)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return profileBucket[_id].owner;
  }

  function setKittieStatus(uint256 _id, bool _dead, bool _playing, uint256 _deadAt)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].kittyStatus = DBSchemaLib.KittyStatus({
      dead: _dead,
      playing: _playing,
      deadAt: _deadAt
    });
    return true;
  }

  function getKittieStatus(uint256 _id)
    external auth view returns (bool, bool, uint256)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return (
      profileBucket[_id].kittyStatus.dead,
      profileBucket[_id].kittyStatus.playing,
      profileBucket[_id].kittyStatus.deadAt
    );
  }

  function setKittieGenes(uint256 _id, uint256 _genes)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].genes = _genes;
    return true;
  }

  function getKittieGenes(uint256 _id)
    external auth view returns (uint256)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return profileBucket[_id].genes;
  }

  function setCryptokittyId(uint256 _id, uint256 _cryptokittyId)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].cryptokittyId = _cryptokittyId;
    return true;
  }

  function getCryptokittyId(uint256 _id)
    external auth view returns (uint256)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return profileBucket[_id].cryptokittyId;
  }

  function setTorMagnetsImagelinks(uint256 _id, bytes32[3] calldata _torMagnetsImagelinks)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].torMagnetsImagelinks = _torMagnetsImagelinks;
    return true;
  }

  function getTorMagnetsImagelinks(uint256 _id)
    external auth view returns (bytes32[3] memory)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return profileBucket[_id].torMagnetsImagelinks;
  }

  function setListingDate(uint256 _id, uint256 _listingStartAt, uint256 _listingEndAt)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].listingStartAt = _listingStartAt;
    profileBucket[_id].listingEndAt = _listingEndAt;
    return true;
  }

  function getListingDate(uint256 _id)
    external auth view returns (uint256, uint256)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return (
      profileBucket[_id].listingStartAt,
      profileBucket[_id].listingEndAt
    );
  }

  function setNextFight(uint256 _id, uint256 _nextFight)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].nextFight = _nextFight;
    return true;
  }

  function getNextFight(uint256 _id)
    external auth view returns (uint256)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return profileBucket[_id].nextFight;
  }

  function setLosses(uint256 _id, uint256 _losses)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].losses = _losses;
    return true;
  }

  function getLosses(uint256 _id)
    external auth view returns (uint256)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return profileBucket[_id].losses;
  }

  function setTotalFights(uint256 _id, uint256 _totalFights)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].totalFights = _totalFights;
    return true;
  }

  function getTotalFights(uint256 _id)
    external auth view returns (uint256)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return profileBucket[_id].totalFights;
  }

  function setDescription(uint256 _id, bytes32[5] calldata _description)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].description = _description;
    return true;
  }

  function getDescription(uint256 _id)
    external auth view returns (bytes32[5] memory)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return profileBucket[_id].description;
  }

// TODO: TODO: TODO: TODO:

  function setIsStakingSuperDAO(uint256 _id, bool _isStakingSuperDAO)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].isStakingSuperDAO = _isStakingSuperDAO;
    return true;
  }

  function getIsStakingSuperDAO(uint256 _id)
    external auth view returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return profileBucket[_id].isStakingSuperDAO;
  }

  function setIsFreeToPlay(uint256 _id, bool _isFreeToPlay)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].isFreeToPlay = _isFreeToPlay;
    return true;
  }

  function getIsFreeToPlay(uint256 _id)
    external auth view returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return profileBucket[_id].isFreeToPlay;
  }

  function setKittieFightTokens(uint256 _id, uint256 _kittieFightTokens)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].kittieFightTokens = _kittieFightTokens;
    return true;
  }

  function getKittieFightTokens(uint256 _id)
    external auth view returns (uint256)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return profileBucket[_id].kittieFightTokens;
  }

  function setTotalWins(uint256 _id, uint256 _totalWins)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].totalWins = _totalWins;
    return true;
  }

  function getTotalWins(uint256 _id)
    external auth view returns (uint256)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return profileBucket[_id].totalWins;
  }

  function setTotalLosses(uint256 _id, uint256 _totalLosses)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].totalLosses = _totalLosses;
    return true;
  }

  function getTotalLosses(uint256 _id)
    external auth view returns (uint256)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return profileBucket[_id].totalLosses;
  }

  function setTokensWon(uint256 _id, uint256 _tokensWon)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].tokensWon = _tokensWon;
    return true;
  }

  function getTokensWon(uint256 _id)
    external auth view returns (uint256)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return profileBucket[_id].tokensWon;
  }

  function setLastDateListing(uint256 _id, uint256 _lastDateListing)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].lastDateListing = _lastDateListing;
    return true;
  }

  function getLastDateListing(uint256 _id)
    external auth view returns (uint256)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return profileBucket[_id].lastDateListing;
  }

  function setSuperDAOTokens(uint256 _id, uint256 _superDAOTokens)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].superDAOTokens = _superDAOTokens;
    return true;
  }

  function getSuperDAOTokens(uint256 _id)
    external auth view returns (uint256)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return profileBucket[_id].superDAOTokens;
  }

  function setLastFeeDate(uint256 _id, uint256 _lastFeeDate)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].lastFeeDate = _lastFeeDate;
    return true;
  }

  function getLastFeeDate(uint256 _id)
    external auth view returns (uint256)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return profileBucket[_id].lastFeeDate;
  }

  function setFeeHistory(uint256 _id, uint256 _feeHistory)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].feeHistory = _feeHistory;
    return true;
  }

  function getFeeHistory(uint256 _id)
    external auth view returns (uint256)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return profileBucket[_id].feeHistory;
  }

  function setReferalHash(uint256 _id, bytes32 _referalHash)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].referalHash = _referalHash;
    return true;
  }

  function getReferalHash(uint256 _id)
    external auth view returns (bytes32)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return profileBucket[_id].referalHash;
  }

  function setFighterList(uint256 _id, bytes32[10] calldata _fighterList)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].fighterList = _fighterList;
    return true;
  }

  function getFighterList(uint256 _id)
    external auth view returns (bytes32[10] memory)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return profileBucket[_id].fighterList;
  }

  function setLittieHashList(uint256 _id, bytes32[10] calldata _kittieHashList)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].fighterList = _kittieHashList;
    return true;
  }

  function getKittieHashList(uint256 _id)
    external auth view returns (bytes32[10] memory)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return profileBucket[_id].kittieHashList;
  }

  function setFeePaidDate(uint256 _id, uint256 _paidDate)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].fees.paidDate = _paidDate;
    return true;
  }

  function getFeePaidDate(uint256 _id)
    external auth view returns (uint256)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return profileBucket[_id].fees.paidDate;
  }

  function setFeeType(uint256 _id, uint256 _feeType)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].fees.feeType = _feeType;
    return true;
  }

  function getFeeType(uint256 _id)
    external auth view returns (uint256)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return profileBucket[_id].fees.feeType;
  }

  function setFeeExpirationDate(uint256 _id, uint256 _expirationDate)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].fees.expirationDate = _expirationDate;
    return true;
  }

  function getFeeExpirationDate(uint256 _id)
    external auth view returns (uint256)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return profileBucket[_id].fees.expirationDate;
  }

  function setIsPaid(uint256 _id, bool _isPaid)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].fees.isPaid = _isPaid;
    return true;
  }

  function getIsPaid(uint256 _id)
    external auth view returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return profileBucket[_id].fees.isPaid;
  }

  function setFeelimits(uint256 _id, uint256 _fightFeeLimit, uint256 _resurrectionFeeLimit)
    external auth returns (bool)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    profileBucket[_id].fees.feelimits.fightFeeLimit = _fightFeeLimit;
    profileBucket[_id].fees.feelimits.resurrectionFeeLimit = _resurrectionFeeLimit;
    return true;
  }

  function getFeelimits(uint256 _id)
    external auth view returns (uint256, uint256)
  {
    require(profileTable.nodeExists(_id), "Profile with the given id does not exists in ProfileDB");
    return (
      profileBucket[_id].fees.feelimits.fightFeeLimit,
      profileBucket[_id].fees.feelimits.resurrectionFeeLimit
    );
  }
}
