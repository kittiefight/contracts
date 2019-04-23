pragma solidity ^0.5.5;

import "./SystemRoles.sol";
import "../modules/databases/RoleDB.sol";
import "../modules/proxy/ProxyBase.sol";

contract Guard is ProxyBase, SystemRoles {
  
  modifier onlySuperAdmin() {
    assert(msg.sender != address(0));
    require(checkRole(SUPER_ADMIN_ROLE), "Only super admin");
    _;
  }

  modifier onlyAdmin() {
    assert(msg.sender != address(0));
    require(checkRole(ADMIN_ROLE), "Only admin");
    _;
  }

  modifier onlyPlayer() {
    assert(msg.sender != address(0));
    require(checkRole(PLAYER_ROLE), "Only player");
    _;
  }

  modifier onlyBettor() {
    assert(msg.sender != address(0));
    require(checkRole(BETTOR_ROLE), "Only bettor");
    _;
  }

  function checkRole(string memory role) internal view returns (bool) {
    return RoleDB(addressOfRoleDB()).hasRole(role, msg.sender);
  }
}


