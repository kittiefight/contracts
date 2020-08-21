pragma solidity ^0.5.5;

import "./Staking.sol";

contract SuperDaoStaking is Staking {
    /**
     * @notice Increase locked amount by `@tokenAmount(stakingToken: address, _amount)` for user `_user` by lock manager `_lockManager`
     * @dev This function can only be used by _lockManager, because if it were used by a user, the locked amount cannot contribute to this user's pool claiming eligibility.
     * @dev A user should lock via the function lock(...) in TimeLockManager to be eligibel for pool claiming.
     * @param _user Owner of locked tokens
     * @param _lockManager The manager entity for this particular lock
     * @param _amount Amount of locked tokens increase
     */
    function lock(address _user, address _lockManager, uint256 _amount) external {
        // we are locking funds from owner account, so only owner or manager are allowed
        require(msg.sender == _lockManager, "LOCK_SENDER_NOT_ALLOWED");

        _lockUnsafe(_user, _lockManager, _amount);
    }
}