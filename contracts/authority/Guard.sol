pragma solidity ^0.5.5;

import "./SystemRoles.sol";
import "../modules/databases/RoleDB.sol";
import "../modules/proxy/Proxied.sol";


contract Guard is Proxied, SystemRoles {
  
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
    return RoleDB(proxy.getContract(CONTRACT_NAME_ROLE_DB)).hasRole(role, getOriginalSender());
  }

  function getOriginalSender() view internal returns(address){
    if(msg.sender != address(proxy)) return msg.sender;
    //Find out actual sender    
    uint160 sender = 0;
    for(uint256 pos = msg.data.length - 20; pos < msg.data.length; pos++){
      sender *= 256;
      sender += uint8(msg.data[pos]);
    }
    assert(sender != 0);
    return address(sender);
  }

}
