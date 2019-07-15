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
import "./GenericDB.sol";
import "../../libs/SafeMath.sol";
import "../kittieHELL/KittieHELL.sol";

contract KittieHellDB is Proxied {
    using SafeMath for uint256;

    GenericDB public genericDB;
    KittieHELL public kittieHELL;

    bytes32 internal constant TABLE_NAME = "GhostsList";
    string internal constant ERROR_ALREADY_EXIST = "Ghost already exists in Hell";
    string internal constant ERROR_DOES_NOT_EXIST = "Ghost not exists";

    constructor(GenericDB _genericDB) public {
      setGenericDB(_genericDB);
    }

    function setGenericDB(GenericDB _genericDB) public onlyOwner {
      genericDB = _genericDB;
   }

    function setKittieHELL(KittieHELL _kittieHELL) public onlyOwner {
      kittieHELL = KittieHELL(proxy.getContract(CONTRACT_NAME_KITTIEHELL));
    }

    /**
   * @author @ziweidream
   * @return true if the database GhostsList exists     
   */
    function doesGhostsListExist() public view returns (bool) {
      return genericDB.doesListExist(CONTRACT_NAME_KITTIEHELL_DB, TABLE_NAME);
    }

  /**
   * @author @ziweidream
   * @param _id the node id 
   * @return true if the node _id exists     
   */
  function doesGhostExist(uint256 _id) public view returns (bool) {
    return genericDB.doesNodeExist(CONTRACT_NAME_KITTIEHELL_DB, TABLE_NAME, _id);
  }
  
  /**
   * @author @ziweidream   
   * @return the size of GhostsList    
   */
  function getGhostsListSize() public view returns (uint256) {
      return genericDB.getLinkedListSize(CONTRACT_NAME_KITTIEHELL_DB, TABLE_NAME);
  }

  /**
   * @author @ziweidream
   * @dev This function can only be carried out via proxy
   * @dev Add the node _id to GhostsList 
   * @param _id the node id        
   */
  function fallToHell(uint256 _id)
    public 
    onlyProxy
  { 
    require(genericDB.pushNodeToLinkedList(CONTRACT_NAME_KITTIEHELL_DB, TABLE_NAME, _id), ERROR_ALREADY_EXIST);
  }

  /**
   * @author @ziweidream   
   * @dev Get the previous status of a kitty from KittieHel.sol contract
   * @param _kittyId the kitty whose status are to be obtained    
   * @return the previous kitty owner, the kitty dead status, the kitty playing status, the kitty ghost status, and the kitty death time   
   */
  function getKittieStatus (uint256 _kittyId) internal view returns (address, bool, bool, bool, uint) {
      (address _owner, bool _dead, bool _playing, bool _ghost, uint _deadAt) = kittieHELL.getKittyStatus(_kittyId);
      return (_owner, _dead, _playing, _ghost, _deadAt);      
  }

  /**
   * @author @ziweidream
   * @dev This function can only be carried out via proxy
   * @dev Set the attributes of a kitty ghost
   * @param _id the node id  
   * @param kittieId the kitty whose attributes are set into this node      
   */
  function setKittieAttributes(
    uint256 _id,
    uint256 kittieId      
  )
    public
    onlyProxy
  {
    require(genericDB.doesNodeExist(CONTRACT_NAME_KITTIEHELL_DB, TABLE_NAME, _id), ERROR_DOES_NOT_EXIST);

    (address owner, bool dead, bool playing, bool ghost, uint deadAt) = getKittieStatus(kittieId);
   
    uint256 numberOfKitties = genericDB.getUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "kittieLength")));
    genericDB.setUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "kittieLength")), numberOfKitties.add(1));
    genericDB.setUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "kittieId")), kittieId);
    genericDB.setAddressStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "owner")), owner);
    genericDB.setBoolStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "dead")), dead);
    genericDB.setBoolStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "playing")), playing);
    genericDB.setBoolStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "ghost")), ghost);
    genericDB.setUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "deadAt")), deadAt); 
    
  }

  /**
   * @author @ziweidream    
   * @param _id the node id    
   * @return the kitty, its ghost status, and its death time    
   */
  function getKittieAttributes(uint256 _id) public view returns (uint256, bool, uint256) {
    uint256 _kittyID = genericDB.getUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "kittieId")));
    bool _ghost = genericDB.getBoolStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "ghost")));
    uint256 _deadAt = genericDB.getUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "deadAt")));

    return (_kittyID, _ghost, _deadAt);
  }
  
  /**
   * @author @ziweidream  
   * @dev Add the node _id to GhostsList 
   * @param _id the node id 
   * @return the direction which is default as false, and the node id of the ajacent node       
   */
  function getAdjacentGhost(uint256 _id) public view returns (bool, uint256) {
    return genericDB.getAdjacent(CONTRACT_NAME_KITTIEHELL_DB, TABLE_NAME, _id, false);
  }

}

