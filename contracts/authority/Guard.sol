pragma solidity ^0.5.5;

import "./Owned.sol";
import "./SystemRoles.sol";
import "../modules/databases/RoleDB.sol";


contract Guard is Owned, SystemRoles {
  RoleDB public roleDB;


  constructor (RoleDB _roleDB) public {
    setRoleDB(_roleDB);
  }

  modifier onlySuperAdmin() {
    assert(msg.sender != address(0));
    require(roleDB.hasRole(SUPER_ADMIN_ROLE, msg.sender), "Only super admin");
    _;
  }

  modifier onlyAdmin() {
    assert(msg.sender != address(0));
    require(roleDB.hasRole(ADMIN_ROLE, msg.sender), "Only admin");
    _;
  }

  modifier onlyPlayer() {
    assert(msg.sender != address(0));
    require(roleDB.hasRole(PLAYER_ROLE, msg.sender), "Only player");
    _;
  }

  modifier onlyBettor() {
    assert(msg.sender != address(0));
    require(roleDB.hasRole(BETTOR_ROLE, msg.sender), "Only bettor");
    _;
  }

  function setRoleDB(RoleDB _roleDB) public onlyOwner {
    roleDB = _roleDB;
  }
}
