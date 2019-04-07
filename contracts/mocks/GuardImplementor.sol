pragma solidity ^0.5.5;

import "../authority/Guard.sol";


contract GuardImplementor is Guard {
  uint256 data;

  constructor (RoleDB _roleDB) Guard(_roleDB) public {
  }

  function canCalledByOnlySuperAdmin() public onlySuperAdmin {
    data += 1;
  }

  function canCalledByOnlyAdmin() public onlyAdmin {
    data += 1;
  }

  function canCalledByOnlyPlayer() public onlyPlayer {
    data += 1;
  }

  function canCalledByOnlyBettor() public onlyBettor {
    data += 1;
  }
}
