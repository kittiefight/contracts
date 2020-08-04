pragma solidity ^0.5.5;

import "./interface/ILockManager.sol";
import "./interface/IStakingLocking.sol";
import "./common/TimeHelpers.sol";
import "./common/ScriptHelpers.sol";
import "../libs/SafeMath.sol";
import "../modules/datetime/TimeFrame.sol";
import "../authority/Owned.sol";

/**
 * Time based lock manager for Staking contract
 * Allows to set a time interval, either in blocks or seconds, during which the funds are locked.
 * Outside that window the owner can unlock them.
 */
contract TimeLockManager is ILockManager, TimeHelpers, Owned {
    using ScriptHelpers for bytes;
    using SafeMath for uint256;

    IStakingLocking public staking;
    TimeFrame public timeFrame;

    string private constant ERROR_ALREADY_LOCKED = "TLM_ALREADY_LOCKED";
    string private constant ERROR_WRONG_INTERVAL = "TLM_WRONG_INTERVAL";
    string private constant ERROR_ZERO_LOCK_AMOUNT = "TLM_ERROR_ZERO_LOCK_AMOUNT";

    enum TimeUnit { Blocks, Seconds }

    struct TimeInterval {
        uint256 unit;
        uint256 start;
        uint256 end;
        uint256 amount;
    }

    mapping (address => mapping (uint256 => TimeInterval)) internal timeIntervals;

    mapping (uint256 => uint256) internal totalLockedPerEpoch;

    event LogLockCallback(uint256 amount, uint256 allowance, bytes data);
    event SuperDaoTokensLocked(address indexed user, uint256 indexed nextEpochId, uint256 amount, uint256 totalAmount);

    function initialize(address _staking, address _timeFrame) public onlyOwner {
        timeFrame = TimeFrame(_timeFrame);
        staking = IStakingLocking(_staking);
    }

    /**
     * @notice Set a locked amount for next epoch to be eligible for next pool claiming
     * @dev Each epoch has one pool. Epoch 0 has pool 0, epoch 1 has pool 1... and epoch n has pool n.
     * @dev Locked amount for an epoch cannot be unlocked until the end of this epoch.
     * @dev A user can lock for next epoch at any time during current epoch.
     * @param _amount The amount to be locked for next epoch
     */
    function lock(uint256 _amount) external {
        require(_amount > 0, ERROR_ZERO_LOCK_AMOUNT);

        // A user can lock at any time, and the locked amount is for the next epoch, which will
        // remain locked until the end of next epoch. This user's yields she can claim from next pool
        // is based upon the proportion of this locked amount to the total amount locked for next epoch

        // Get next epoch id
        uint256 _currentEpochId = timeFrame.getActiveEpochID();
        uint256 _nextEpochId;
        if (timeFrame._epochEndTime(0) == 0) {
            _nextEpochId = 0;  // If locking time is before epoch 0 is set, then this amount is locked for epoch 0
        } else {
            _nextEpochId = _currentEpochId.add(1);
        }

        // Each user can only lock for an epoch once.
        require(timeIntervals[msg.sender][_nextEpochId].end == 0, ERROR_ALREADY_LOCKED);

        // Get how long till the end of current epoch
        uint256 currentEpochEnd = timeFrame._epochEndTime(_currentEpochId);
        uint256 _extraTime = currentEpochEnd > now ? currentEpochEnd.sub(now) : 0;

        // If there are still some time till the end of current epoch, this time is added to the lock time
        // so that the lock ending time is the same for every user locking tokens for the next epoch
        uint256 _start = now;
        uint256 _end = _start.add(_extraTime).add(7 * 24 * 60 * 60);

        // Records the TimeInterval for this user for next epoch
        // we only use seconds, which is 1 from enum TimeUnit { Blocks, Seconds }
        timeIntervals[msg.sender][_nextEpochId] = TimeInterval(1, _start, _end, _amount);

        // Lock the _amount for this user using function lock(...) in staking contract
        staking.lock(msg.sender, address(this), _amount);

        // Add this user's locked amount to the total amount for next epoch
        totalLockedPerEpoch[_nextEpochId] = totalLockedPerEpoch[_nextEpochId].add(_amount);

        emit SuperDaoTokensLocked(msg.sender, _nextEpochId, _amount, totalLockedPerEpoch[_nextEpochId]);
    }

    /**
     * @notice Callback called from Staking when a new lock manager instance of this contract is allowed
     * @param _amount The amount of tokens to be locked
     * @param _allowance Amount of tokens that the manager can lock
     * @param _data Data to parametrize logic for the lock to be enforced by the manager
     */
    function receiveLock(uint256 _amount, uint256 _allowance, bytes calldata _data) external returns (bool) {
        emit LogLockCallback(_amount, _allowance, _data);
        return true;
    }

    /**
     * @notice Check if the owner can unlock the funds, i.e., if current timestamp is outside the lock interval
     * @param _owner Owner of the locked funds
     * @param _amount Amount of locked tokens to unlock.
     * @return True if current timestamp is outside the lock interval
     */
    function canUnlock(address _owner, uint256 _amount) external view returns (bool) {

        // Get current epoch Id
        // Get next epoch Id
        uint256 currentEpoch = timeFrame.getActiveEpochID();
        uint256 nextEpoch = currentEpoch.add(1);
        // Get TimeInterval
        TimeInterval storage currentTimeInterval = timeIntervals[_owner][currentEpoch];
        TimeInterval storage nextTimeInterval = timeIntervals[_owner][nextEpoch];

        // Any amount locked for epochs preceding current epoch can be unlocked at any time
        if (currentTimeInterval.amount == 0 && nextTimeInterval.amount == 0) {
            return true;
        }

        // Get total locked amount by this user via TimeLockManager
        (uint256 totalAmount,) = staking.getLock(_owner, address(this));
        // Get the sum of the locked amount for current epoch and for next epoch
        uint256 amountCurrentNext = currentTimeInterval.amount.add(nextTimeInterval.amount);

        // Locked amount for an epoch cannot be unlocked until the end of this epoch
        // Since at the time of query, current epoch is not at the end yet (otherwise next epoch will be current epoch),
        // neither locked amount for current epoch nor locked amount for next epoch can be unlocked at this time.
        // However, the amount locked for epochs preceding current epoch can be unlocked
        if (currentTimeInterval.amount > 0 || nextTimeInterval.amount > 0) {
            return _amount <= totalAmount.sub(amountCurrentNext);
        }

        return false;
    }

    function getTimeInterval(address _owner, uint256 _epoch) external view returns (uint256 unit, uint256 start, uint256 end, uint256 amount) {
        TimeInterval storage timeInterval = timeIntervals[_owner][_epoch];

        return (timeInterval.unit, timeInterval.start, timeInterval.end, timeInterval.amount);
    }

    function getTotalLockedForEpoch(uint256 _epoch) external view returns (uint256) {
        return totalLockedPerEpoch[_epoch];
    }

    /**
     * @notice Check if the owner is eligible for claiming from a pool associated with _epoch
     * @dev Only eligibility for current epoch or next epoch is relevant, because pools in past epochs cannot be claimed.
     * @param _owner Owner of the locked funds
     * @param _epoch Epoch ID associated with the locked amount, only current or next epoch is relevant
     * @return True if _owner is eligible for claiming for a pool associated with _epoch
     */
    function isEligible(address _owner, uint256 _epoch) external view returns (bool) {
        uint256 currentEpoch = timeFrame.getActiveEpochID();
        // Eligiblity is only relevant for current epoch or next epoch.
        require(_epoch >= currentEpoch, "TimeLockManager: cannot claim pools in past epochs");
        // At time of query, if total amount locked via TimeLockManager by _owner is 0, this means either the _owner
        // never locks for any epoch, or has unlocked all SuperDao tokens in each epoch including current
        // epoch and next epoch.
        (uint256 totalLocked,) = staking.getLock(_owner, address(this));
        if( totalLocked > 0 && timeIntervals[_owner][_epoch].amount > 0) {
            return true;
        }
        return false;
    }
}
