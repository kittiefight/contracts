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
import "../kittieHELL/KittieHellDungeon.sol";
import "../kittieHELL/KittieHellStruct.sol";
/**
 * @title KittieHellDB
 * @author @kittieFIGHT @ziweidream
 */

contract KittieHellDB is Proxied, Guard, KittieHellStruct {
    using SafeMath for uint256;

    GenericDB public genericDB;
    KittieHell public kittieHELL;
    KittieHellDungeon public kittieHellDungeon;
    ERC721 public cryptoKitties;

    bytes32 internal constant TABLE_KEY_KITTIEHELL = keccak256(abi.encodePacked("KittieHellTable"));
    string internal constant ERROR_ALREADY_EXIST = "Ghost already exists in Hell";
    string internal constant ERROR_DOES_NOT_EXIST = "Ghost not exists";

    constructor(GenericDB _genericDB) public {
      setGenericDB(_genericDB);
    }

    function setGenericDB(GenericDB _genericDB) public onlyOwner {
      genericDB = GenericDB(_genericDB);
   }

    function initialize() public onlyOwner {
      kittieHELL = KittieHell(proxy.getContract(CONTRACT_NAME_KITTIEHELL));
      kittieHellDungeon = KittieHellDungeon(proxy.getContract(CONTRACT_NAME_KITTIEHELL_DUNGEON));
      cryptoKitties = ERC721(proxy.getContract(CONTRACT_NAME_CRYPTOKITTIES));
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
   * @dev Add the node _id to GhostsList
   * @param _id the node id
   */
  function fallToHell(uint256 _id)
    internal
  {
    require(genericDB.pushNodeToLinkedList(CONTRACT_NAME_KITTIEHELL_DB, TABLE_KEY_KITTIEHELL, _id), ERROR_ALREADY_EXIST);
  }

  /**
   * @author @ziweidream
   * @dev This function can only be carried out via kittieHELL contract
   * @dev Add the node _id of a loser kittie to GhostsList
   * @param _kittieID the kittieID of the loser kittie who lost a game
   * @param _owner the owner of the loser kittie
   */
  function loserKittieToHell
  (
    uint256 _kittieID,
    address _owner
  )
    public
    onlyContract(CONTRACT_NAME_KITTIEHELL)
  {
    require(ERC721(proxy.getContract(CONTRACT_NAME_CRYPTOKITTIES)).ownerOf(_kittieID) == address(this));
    uint256 _id = getLastGhostId().add(1);
    fallToHell(_id);
    genericDB.setUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "kittieId")), _kittieID);
    genericDB.setAddressStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "owner")), _owner);
    genericDB.setBoolStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "sacrificeKittie")), false);
    genericDB.setUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "sacrificeFor")), 0);
    genericDB.setUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_kittieID, "ghostID")), _id);
    uint256 totalNumberOfKitties = genericDB.getUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked("totalNumberOfKitties")));
    genericDB.setUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked("totalNumberOfKitties")), totalNumberOfKitties.add(1));

    emit AddedToKittieHellDB(_kittieID, _owner, _id);
  }

  /**
   * @author @ziweidream
   * @param _id the node id of the ghost
   * @return its kittyID, its original owner, whether it is a replacement kittie,
   *         the loser kitty for which it is a replacement kittie(0 if this ghost is a loser kittie itself)
   */
  function getGhostAttributes(uint256 _id) public view returns (uint256, address, bool, uint256) {
    uint256 _kittyID = genericDB.getUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "kittieId")));
    address _owner = genericDB.getAddressStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "owner")));
    bool _isSacrificeKittie = genericDB.getBoolStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "sacrificeKittie")));
    uint256 _sacrificeFor = genericDB.getUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "sacrificeFor")));

    return (_kittyID, _owner, _isSacrificeKittie, _sacrificeFor);
  }

  /**
   * @author @ziweidream
   * @return the node id of the last node
   */
  function getLastGhostId() public view returns(uint256){
        (/*bool found*/, uint256 id) = genericDB.getAdjacent(CONTRACT_NAME_KITTIEHELL_DB, TABLE_KEY_KITTIEHELL, 0, true);
        return id;
  }

  /**
   * @author @ziweidream
   * @dev This function can only be carried out via proxy
   * @dev Add the node _id of a sacrificing kittie to GhostsList
   * @param _kittieID the kittieID of the loser kittie who lost a game
   * @param _owner the owner of the loser kittie
   * @param _sacrificeKittie the kittieID of the sacrificing kittie for redeeming the loser kittie
   */
  function sacrificeKittieToHell(uint256 _kittieID, address _owner, uint256 _sacrificeKittie)
      public
      onlyContract(CONTRACT_NAME_REDEEM_KITTIE)
  {
    require(cryptoKitties.ownerOf(_sacrificeKittie) == _owner, "Not the owner of this kittie");
    kittieHellDungeon.transferFrom(_owner, _sacrificeKittie);
    require(cryptoKitties.ownerOf(_sacrificeKittie) == address(kittieHellDungeon), "Kittie not in dungeon");
    uint256 _id = getLastGhostId().add(1);
    fallToHell(_id);
    genericDB.setUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "kittieId")), _sacrificeKittie);
    genericDB.setAddressStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "owner")), _owner);
    genericDB.setBoolStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "sacrificeKittie")), true);
    genericDB.setUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_id, "sacrificeFor")), _kittieID);
    genericDB.setUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_sacrificeKittie, "ghostID")), _id);
    uint256 numberOfSacrificeKitties = genericDB.getUintStorage(
      CONTRACT_NAME_KITTIEHELL_DB,
      keccak256(abi.encodePacked(_kittieID, "numberOfSacrificeKitties"))).add(1);
    genericDB.setUintStorage(
      CONTRACT_NAME_KITTIEHELL_DB,
      keccak256(abi.encodePacked(_kittieID, "numberOfSacrificeKitties")),
      numberOfSacrificeKitties);
    uint256 totalNumberOfKitties = genericDB.getUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked("totalNumberOfKitties")));
    genericDB.setUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked("totalNumberOfKitties")), totalNumberOfKitties.add(1));
    emit AddedToKittieHellDB(_sacrificeKittie, _owner, _id);
  }

  /**
   * @author @ziweidream
   * @param _kittieID the kittieID of the loser kittie
   * @return the number of sacrificing kitties already in HELL for this loser kittie
   */
  function getNumberOfSacrificeKitties(uint256 _kittieID) public view returns(uint256) {
    return genericDB.getUintStorage(
      CONTRACT_NAME_KITTIEHELL_DB,
      keccak256(abi.encodePacked(_kittieID, "numberOfSacrificeKitties")));
  }

  /**
   * @author @ziweidream
   * @dev This function can only be carried out via kittieHELL contract
   * @dev record the KTY amount locked in kittieHELL contract
   * @param _kittieID the kittieID of the loser kittie who lost a game
   * @param _kty_amount the redemption fee locked in kittieHELL contract
   *                    for redeeming the loser kittie
   */
  function lockKTYsInKittieHell(uint256 _kittieID, uint256 _kty_amount)
      public
      onlyContract(CONTRACT_NAME_REDEEM_KITTIE)
  {
    genericDB.setUintStorage(
      CONTRACT_NAME_KITTIEHELL_DB,
      keccak256(abi.encodePacked(_kittieID, "redemptionFeeKTY")),
      _kty_amount
    );
    uint totalKTYsLockedInKittieHell = genericDB.getUintStorage(
      CONTRACT_NAME_KITTIEHELL_DB,
      keccak256(abi.encodePacked("totalKTYsLockedInKittieHell"))
    ).add(_kty_amount);
    genericDB.setUintStorage(
      CONTRACT_NAME_KITTIEHELL_DB,
      keccak256(abi.encodePacked("totalKTYsLockedInKittieHell")),
      totalKTYsLockedInKittieHell
    );
  }

  /**
   * @author @ziweidream
   * @return the total amount of KTYs locked in kittieHELL contract
   */
  function getTotalKTYsLockedInKittieHell() public view returns(uint256) {
    return genericDB.getUintStorage(
      CONTRACT_NAME_KITTIEHELL_DB,
      keccak256(abi.encodePacked("totalKTYsLockedInKittieHell"))
    );
  }

  /**
   * @author @ziweidream
   * @return the total number of kittie ghosts permanently locked in HELL
   */
  function getTotalNumberOfGhostsInHell() public view returns(uint256) {
    return genericDB.getUintStorage(
      CONTRACT_NAME_KITTIEHELL_DB,
      keccak256(abi.encodePacked("totalNumberOfKitties"))
    );
  }

  /**
   * @author @ziweidream
   * @param _kittieID the kittieID of the kittie
   * @return node id of the kittie (if the kittie is not a ghost, it returns 0)
   */
  function getGhostIdForKittie(uint256 _kittieID) public view returns(uint256) {
    return genericDB.getUintStorage(
      CONTRACT_NAME_KITTIEHELL_DB,
      keccak256(abi.encodePacked(_kittieID, "ghostID")));
  }

  /**
   * @author @ziweidream
   * @param _kittieID the kittieID of the kittie
   * @return true if the kittie is a permanent ghost, false if the kittie is not permanently dead
   */
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

  /**
   * @author @pash7ka
   * @notice Returns Id of scheduled cron job, which will make kittie a ghost
   * @param _kittieID the kittieID of the kittie
   * @return Id of scheduled cron job, which will make kittie a ghost
   */
  function getGhostifyJob(uint256 _kittieID) public view returns(uint256) {
    return genericDB.getUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_kittieID, "ghostifyJob")));  
  }

  /**
   * @author @pash7ka
   * @notice Sets Id of scheduled cron job, which will make kittie a ghost
   * @param _kittieID the kittieID of the kittie
   */
  function setGhostifyJob(uint256 _kittieID, uint256 job) public onlyContract(CONTRACT_NAME_KITTIEHELL) {
    genericDB.setUintStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_kittieID, "ghostifyJob")), job);  
  }

  function getKittieStatus(uint256 _kittieID) public view returns(bytes memory){
    return genericDB.getBytesStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_kittieID, "kittieStatus")));  
  }

  function setKittieStatus(uint256 _kittieID, bytes calldata encodedStatus) external onlyContract(CONTRACT_NAME_KITTIEHELL) {
    genericDB.setBytesStorage(CONTRACT_NAME_KITTIEHELL_DB, keccak256(abi.encodePacked(_kittieID, "kittieStatus")), encodedStatus);  
  }

  /**
   * @author @ziweidream
   * @param _kittyID The kittie to release
   * @return the previous kitty owner, the kitty dead status, the kitty playing status, the kitty ghost status, and the kitty death time   
   */
  function kittyStatus(uint256 _kittyID) public view returns (address _owner, bool _dead, bool _playing, bool _ghost, uint _deadAt) {
      KittyStatus memory ks = decodeKittieStatus(getKittieStatus(_kittyID));
      _owner = ks.owner;
      _dead = ks.dead;
      _playing = ks.playing;
      _ghost = ks.ghost;
      _deadAt = ks.deadAt;
  }

  /**
   * @dev This will be used for upgrading kittieHellDungeon only,
   *      if kittieHellDungeon ever needs to be upgraded
   */
  function moveKittiesManually(uint256[] calldata _kittyIDs, address newKittieHellDungeon)
      external onlySuperAdmin
  {
      for(uint256 i = 0; i < _kittyIDs.length; i++) {
          kittieHellDungeon.transfer(newKittieHellDungeon, _kittyIDs[i]);
      }
  }


  event AddedToKittieHellDB(uint256 indexed kittyID, address _owner, uint256 indexed _id);
}

