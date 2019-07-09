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
    address sender;
    assembly {
        let ptr := sub(calldatasize, 20)  // Find out start position of the sender's address
        mstore(0x20, 0)                   // Fill 32 bytes with 0
        calldatacopy(0x2C, ptr, 20)       // Load 20 bytes of address to the end of cleared memory 
        sender := mload(0x20)             // Store address to solidity variable
    }
    assert(sender != address(0));
    return sender;
  }

}
