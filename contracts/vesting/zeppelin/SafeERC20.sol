pragma solidity ^0.5.5;

import "../../interfaces/ERC20Basic.sol";
import "../../interfaces/ERC20Standard.sol";


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 * Source: OpenZeppelin library
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20Standard token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20Standard token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}
