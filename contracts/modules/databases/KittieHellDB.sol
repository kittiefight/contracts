/**
 * @title kittiehellDB
 *
 * @author @kittieFIGHT @ola
 *
 */
//modifier class (DSAuth )
//Event class ( DSNote )
//
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
import "../../authority/Guard.sol";
import "./GenericDB.sol";
import "../../libs/SafeMath.sol";
import "../../interfaces/ERC721.sol";
import "../kittieHELL/KittieHell.sol";

/**
 * @title KittieHellDB
 * @author @kittieFIGHT @ziweidream
 */

contract KittieHellDB is Proxied, Guard {
    using SafeMath for uint256;

    GenericDB public genericDB;
    KittieHell public kittieHELL;

    bytes32 internal constant TABLE_KEY_KITTIEHELL = keccak256(abi.encodePacked("KittieHellTable"));
    string internal constant ERROR_ALREADY_EXIST = "Ghost already exists in Hell";
    string internal constant ERROR_DOES_NOT_EXIST = "Ghost not exists";

    constructor(GenericDB _genericDB) public {
      setGenericDB(_genericDB);
    }

    function setGenericDB(GenericDB _genericDB) public onlyOwner {
      genericDB = GenericDB(_genericDB);
   }

    function setKittieHELL() public onlyOwner {
      kittieHELL = KittieHell(proxy.getContract(CONTRACT_NAME_KITTIEHELL));
    }

  /**
   * @author @ziweidream
   * @param _id the node id 
   * @return true if the node _id exists     
   */
  function doesGhostExist(uint256 _id) public view returns (bool) {
    return genericDB.doesNodeExist(CONTRACT_NAME_KITTIEHELL_DB, TABLE_KEY_KITTIEHELL, _id);
  }
  
  /**
   * @author @ziweidream   
   * @return the size of GhostsList    
   */
  function getGhostsListSize() public view returns (uint256) {
      return genericDB.getLinkedListSize(CONTRACT_NAME_KITTIEHELL_DB, TABLE_KEY_KITTIEHELL);
  }

  /**
   * @author @ziweidream
   * @dev This function can only be carried out via proxy
   * @dev Add the node _id to GhostsList 
   * @param _id the node id        
   */

  function fallToHell(uint256 _id)
    internal
  {
    require(genericDB.pushNodeToLinkedList(CONTRACT_NAME_KITTIEHELL_DB, TABLE_KEY_KITTIEHELL, _id), ERROR_ALREADY_EXIST);
  }

  function loserKittieToHell
  (
    uint256 _id,
    uint256 _kittieID,
    address _owner
  )
    public
    onlyContract(CONTRACT_NAME_KITTIEHELL)
  {
    fallToHell(_id);
    genericDB.setUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "kittieId")), _kittieID);
    genericDB.setAddressStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "owner")), _owner);
    genericDB.setBoolStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "replacementKittie")), false);
    genericDB.setUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "replacemetFor")), 0);
    genericDB.setUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_kittieID, "ghostID")), _id);
    uint256 totalNumberOfKitties = genericDB.getUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked("totalNumberOfKitties")));
    genericDB.setUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked("totalNumberOfKitties")), totalNumberOfKitties.add(1));
  }


  /**
   * @author @ziweidream
   * @param _id the node id
   * @return the kitty, its ghost status, and its death time
   */
  function getKittieAttributes(uint256 _id) public view returns (uint256, address, bool, uint256) {
    uint256 _kittyID = genericDB.getUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "kittieId")));
    address _owner = genericDB.getAddressStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "owner")));
    bool _isReplacementKittie = genericDB.getBoolStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "replacementKittie")));
    uint256 _replacementFor = genericDB.getUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "replacemetFor")));

    return (_kittyID, _owner, _isReplacementKittie, _replacementFor);
  }
  
  /**
   * @author @ziweidream
   * @dev Add the node _id to GhostsList
   * @param _id the node id
   * @return the direction which is default as false, and the node id of the ajacent node
   */
  function getAdjacentGhost(uint256 _id) public view returns (bool, uint256) {
    return genericDB.getAdjacent(CONTRACT_NAME_KITTIEHELL_DB, TABLE_KEY_KITTIEHELL, _id, false);
  }

  function getLastGhostId() public view returns(uint256){
        (/*bool found*/, uint256 id) = genericDB.getAdjacent(CONTRACT_NAME_KITTIEHELL_DB, TABLE_KEY_KITTIEHELL, 0, false);
        // 0 means HEAD, false means tail of the list
        return id;
    }

  function kittieReplacementToHell(uint256 _kittieID, address _owner, uint256 _kittieReplacement)
      public
      onlyProxy
      returns(bool, uint256 _id)
  {
    require(ERC721(proxy.getContract(CONTRACT_NAME_CRYPTOKITTIES)).ownerOf(_kittieReplacement) == _owner);
    ERC721(proxy.getContract(CONTRACT_NAME_CRYPTOKITTIES)).transferFrom(_owner, address(this), _kittieReplacement);
    assert(ERC721(proxy.getContract(CONTRACT_NAME_CRYPTOKITTIES)).ownerOf(_kittieReplacement) == address(this));
    _id = getLastGhostId().add(1);
    fallToHell(_id);
    genericDB.setUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "kittieId")), _kittieReplacement);
    genericDB.setAddressStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "owner")), _owner);
    genericDB.setBoolStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "replacementKittie")), true);
    genericDB.setUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "replacemetFor")), _kittieID);
    genericDB.setUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_kittieReplacement, "ghostID")), _id);
    uint256 numberOfReplacementKitties = genericDB.getUintStorage(
      CONTRACT_NAME_KITTIEHELL_DB,
      keccak256(abi.encodePacked(_kittieID, "numberOfReplacementKitties"))).add(1);
    genericDB.setUintStorage(
      CONTRACT_NAME_KITTIEHELL_DB,
      keccak256(abi.encodePacked(_kittieID, "numberOfReplacementKitties")),
      numberOfReplacementKitties);
    uint256 totalNumberOfKitties = genericDB.getUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked("totalNumberOfKitties")));
    genericDB.setUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked("totalNumberOfKitties")), totalNumberOfKitties.add(1));
    emit AddedToKittieHellDB(_kittieReplacement, _owner, _id);
    return (true, _id);
  }

  function getNumberOfReplacementKitties(uint256 _kittieID) public view returns(uint256) {
    return genericDB.getUintStorage(
      CONTRACT_NAME_KITTIEHELL_DB,
      keccak256(abi.encodePacked(_kittieID, "numberOfReplacementKitties")));
  }

  function lockKTYsInKittieHell(uint256 _kittieID, uint256 _kty_amount)
      public
      onlyContract(CONTRACT_NAME_KITTIEHELL)
  {
    genericDB.setUintStorage(
      CONTRACT_NAME_KITTIEHELL_DB,
      keccak256(abi.encodePacked(_kittieID, "redemptionFeeKTY")),
      _kty_amount
    );
    uint totalKTYsLockedInKittieHell = genericDB.getUintStorage(
      CONTRACT_NAME_KITTIEHELL_DB,
      keccak256(abi.encodePacked("totalKTYsLockedInKittieHell"))
    ) + _kty_amount;
    genericDB.setUintStorage(
      CONTRACT_NAME_KITTIEHELL_DB,
      keccak256(abi.encodePacked("totalKTYsLockedInKittieHell")),
      totalKTYsLockedInKittieHell
    );
  }

  function getTotalKTYsLockedInKittieHell() public view returns(uint256) {
    return genericDB.getUintStorage(
      CONTRACT_NAME_KITTIEHELL_DB,
      keccak256(abi.encodePacked("totalKTYsLockedInKittieHell"))
    );
  }

  function getTotalNumberOfGhostsInHell() public view returns(uint256) {
    return genericDB.getUintStorage(
      CONTRACT_NAME_KITTIEHELL_DB,
      keccak256(abi.encodePacked("totalNumberOfKitties"))
    );
  }

  function getGhostIdForKittie(uint256 _kittieID) public view returns(uint256) {
    return genericDB.getUintStorage(
      CONTRACT_NAME_KITTIEHELL_DB,
      keccak256(abi.encodePacked(_kittieID, "ghostID")));
  }

  function isKittieGhost(uint256 _kittieID) public view returns(bool) {
    uint256 _id = getGhostIdForKittie(_kittieID);
    if (_id == 0) {
      return false;
    }
    if(doesGhostExist(_id)) {
      return true;
    }
    return false;
  }

  // this function should not exist since no kitty can be released from the hell once the deadline
  // for ressurection has been passed without proper action (pay for ressrrection) being taken
  /**
   * @author @ziweidream
   * @dev This function can only be carried out via CronJob.sol contract
   * @dev Removes the node _id from GhostsList
   * @param _id the node id
   * @return true if the node is removed from GhostsList
   */
  //function removeGhostFromHell(uint256 _id)
   //public
   //onlyContract(CONTRACT_NAME_CRONJOB)
   //returns (bool) {
    //return genericDB.removeNodeFromLinkedList(CONTRACT_NAME_KITTIEHELL_DB, TABLE_NAME_GHOST, _id);
  //}

  event AddedToKittieHellDB(uint256 indexed kittyID, address _owner, uint256 indexed _id);

}

