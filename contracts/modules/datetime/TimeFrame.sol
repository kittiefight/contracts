/**
 * @title TimeFrame
 *
 * @author @ziweidream
 *
 */

pragma solidity ^0.5.5;

/**
 * @title Contract to mark weekly epochs and any possible delays
 * in the epochs in timestamps while using BokkyPooBah's DateTime Library
 * to translate such timestamps and difference between timestamps to
 * human readable outputs in year/month/day hour:minute:second.
 * Used by contracts for time tracking, accurately scheduling game events,
 * and for timeframe distinctions for financial activities regarding NFT/KETH
 * as well as staking superDao/withdrawing yields.
 */

import "../../libs/SafeMath.sol";
import "../../libs/BokkyPooBahsDateTimeLibrary.sol";
import "../proxy/Proxied.sol";
import "../../authority/Guard.sol";
import "../databases/GenericDB.sol";

contract TimeFrame is Proxied, Guard {
    using SafeMath for uint256;
    using BokkyPooBahsDateTimeLibrary for uint256;

    GenericDB public genericDB;

    uint256 public SIX_WORKING_DAYS = 6 * 24 * 60 * 60;
    uint256 public REST_DAY = 24 * 60 * 60;
    uint256 public SIX_HOURS = 6 * 60 * 60;

    //===================== events ===================
    event NewEpochSet(uint256 indexed newEpochId, uint256 newEpochStartTime);
    event GamingDelayAdded(
        uint256 indexed epoch_id,
        uint256 newEpochRestDayStartTime
    );

    //===================== modifiers ===================
    modifier onlyActiveEpoch(uint256 epoch_id) {
        require(isEpochActive(epoch_id));
        _;
    }

    //===================== setters ===================
    function initialize() external onlyOwner {
        genericDB = GenericDB(proxy.getContract(CONTRACT_NAME_GENERIC_DB));
    }

    function setTimes(
        uint256 sixWorking,
        uint256 restDay,
        uint256 sixHours
    ) public onlySuperAdmin() {
        SIX_WORKING_DAYS = sixWorking;
        REST_DAY = restDay;
        SIX_HOURS = sixHours;
    }

    /**
     * @dev sets epoch 0
     */
    function setEpoch_0() external onlyContract(CONTRACT_NAME_WITHDRAW_POOL) {
        _setNewEpoch(0, now);
    }

    function setEpochTimes(uint256 epochID)
        external
        onlyContract(CONTRACT_NAME_WITHDRAW_POOL)
    {
        uint256 _startTime = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epochID.sub(1), "restDayEnd"))
        );
        _setNewEpoch(epochID, _startTime);
    }

    //===================== getters ===================
    /**
     * @dev return the total number of epochs
     */
    function getTotalEpochs() public view returns (uint256) {
        uint256 numberOfTotalEpochs = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked("totalNumberOfEpochs"))
        );

        return numberOfTotalEpochs;
    }

    /**
     * @dev return the ID of the active epoch
     */
    function getActiveEpochID() public view returns (uint256) {
        return
            genericDB.getUintStorage(
                CONTRACT_NAME_TIMEFRAME,
                keccak256(abi.encodePacked("activeEpoch"))
            );
    }

    /**
     * @dev return true if the epoch with epoch_id is the active epoch
     * @param epoch_id the id of the epoch
     */
    function isEpochActive(uint256 epoch_id) public view returns (bool) {
        uint256 _sixDayStart = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "sixDayStart"))
        );
        uint256 _restDayEnd = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "restDayEnd"))
        );
        return now >= _sixDayStart && now <= _restDayEnd;
    }

    /**
     * @dev return true if game can start in the current epoch
     */
    function canStartNewGame() public view returns (bool) {
        uint256 epoch_id = getActiveEpochID();
        uint256 _sixDayStart = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "sixDayStart"))
        );
        uint256 _sixDayEnd = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "restDayStart"))
        );
        return now >= _sixDayStart && now <= _sixDayEnd.sub(SIX_HOURS);
    }

    /**
     * @dev return true if the epoch with epoch_id has started
     * @param epoch_id the id of the epoch
     */
    function hasEpochStarted(uint256 epoch_id) public view returns (bool) {
        uint256 _sixDayStart = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "sixDayStart"))
        );
        return now >= _sixDayStart;
    }

    /**
     * @dev return true if the epoch with epoch_id has ended
     * @param epoch_id the id of the epoch
     */
    function hasEpochEnded(uint256 epoch_id) public view returns (bool) {
        uint256 _restDayStart = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "restDayStart"))
        );
        return now > _restDayStart;
    }

    /**
     * @dev return the gaming delay time of an epoch.
     * if no gaming delay during that epoch, returns 0
     * @param epoch_id the id of the epoch
     */

    function gamingDelay(uint256 epoch_id) public view returns (uint256) {
        uint256 _gamingDelay = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "gamingDelay"))
        );
        return _gamingDelay;
    }

    /**
     * @dev return the start time (in unix time) of the epoch with epoch_id
     * @param epoch_id the id of the epoch
     */
    function _epochStartTime(uint256 epoch_id) public view returns (uint256) {
        uint256 _sixDayStart = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "sixDayStart"))
        );
        return _sixDayStart;
    }

    /**
     * @dev return the end time (in unix time) of the epoch with epoch_id
     * @param epoch_id the id of the epoch
     */
    function _epochEndTime(uint256 epoch_id) public view returns (uint256) {
        uint256 _restDayEnd = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "restDayEnd"))
        );
        return _restDayEnd;
    }

    function _newEpochStartTime() public view returns (uint256) {
        uint256 epoch_id = getActiveEpochID();
        uint256 _restDayEnd = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "restDayEnd"))
        );
        return _restDayEnd.add(REST_DAY);
    }

    /**
     * @dev return the time elapsed(in seconds) since the start of the epoch with epoch_id
     * @param epoch_id the id of the epoch
     */
    function elapsedSinceEpochStart(uint256 epoch_id)
        public
        view
        returns (uint256)
    {
        uint256 _sixDayStart = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "sixDayStart"))
        );
        require(now >= _sixDayStart, "Epoch has not started yet");
        return now.sub(_sixDayStart);
    }

    /**
     * @dev return the time remaining (in seconds) until the end of the epoch with epoch_id
     * @param epoch_id the id of the epoch
     */
    function timeUntilEpochEnd(uint256 epoch_id) public view returns (uint256) {
        uint256 _restDayEnd = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "restDayEnd"))
        );
        require(now <= _restDayEnd, "Already ended");
        return _restDayEnd.sub(now);
    }

    /**
     * @dev return the start time (in unix time) of the WorkingDays stage in the current active epoch
     */
    function workingDayStartTime() public view returns (uint256 start) {
        uint256 activeEpoch = getActiveEpochID();
        start = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(activeEpoch, "sixDayStart"))
        );
    }

    /**
     * @dev return the end time (in unix time) of the WorkingDays stage in the current active epoch
     */
    function workingDayEndTime() public view returns (uint256 end) {
        uint256 activeEpoch = getActiveEpochID();
        end = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(activeEpoch, "restDayStart"))
        );
    }

    /**
     * @dev return the start time (in unix time) of the RestDay stage in the current active epoch
     */
    function restDayStartTime() public view returns (uint256 start) {
        uint256 activeEpoch = getActiveEpochID();
        start = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(activeEpoch, "restDayStart"))
        );
    }

    /**
     * @dev return the end time (in unix time) of the RestDay stage in the current active epoch
     */
    function restDayEndTime() public view returns (uint256 end) {
        uint256 activeEpoch = getActiveEpochID();
        end = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(activeEpoch, "restDayEnd"))
        );
    }

    /**
     * @dev return true if the epoch with epoch_id is on its working days
     */
    function isWorkingDay() public view returns (bool) {
        return
            !genericDB.getBoolStorage(
                CONTRACT_NAME_WITHDRAW_POOL,
                keccak256(abi.encodePacked("rest_day"))
            );
    }

    /**
     * @dev return true if the epoch with epoch_id is on its rest day
     */
    function isRestDay() public view returns (bool) {
        return
            genericDB.getBoolStorage(
                CONTRACT_NAME_WITHDRAW_POOL,
                keccak256(abi.encodePacked("rest_day"))
            );
    }

    /**
     * @dev return the entire time length (in seconds) of the epoch with epoch_id
     * @param epoch_id the id of the epoch
     */
    function epochLength(uint256 epoch_id) public view returns (uint256) {
        uint256 _sixDayStart = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "sixDayStart"))
        );
        uint256 _restDayEnd = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "restDayEnd"))
        );
        require(_sixDayStart <= _restDayEnd, "Invalid start and end dates");
        return _restDayEnd.sub(_sixDayStart);
    }

    //===================== Internal Functions ===================

    /**
     * @dev creates a new epoch, the ID of which is total number of epochs - 1
     */

    function _setNewEpoch(uint256 _newEpochId, uint256 _startTime) internal {
        genericDB.setUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(_newEpochId, "sixDayStart")),
            _startTime
        );

        genericDB.setUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(_newEpochId, "endTimeForGames")),
            _startTime.add(SIX_WORKING_DAYS).sub(SIX_HOURS)
        );

        genericDB.setUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked("activeEpoch")),
            _newEpochId
        );

        genericDB.setUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(_newEpochId, "restDayStart")),
            _startTime.add(SIX_WORKING_DAYS)
        );

        genericDB.setUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(_newEpochId, "restDayEnd")),
            _startTime.add(SIX_WORKING_DAYS).add(REST_DAY)
        );

        genericDB.setUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked("totalNumberOfEpochs")),
            _newEpochId.add(1)
        );

        emit NewEpochSet(_newEpochId, _startTime);
    }

    /**
     * @dev adds gaming delay to an epoch
     * @param _epoch_id the id of the epoch
     */
    function _addGamingDelayToEpoch(uint256 _epoch_id, uint256 restDayStart)
        external
        onlyContract(CONTRACT_NAME_WITHDRAW_POOL)
    {
        genericDB.setUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(_epoch_id, "restDayStart")),
            restDayStart
        );

        genericDB.setUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(_epoch_id, "restDayEnd")),
            restDayStart.add(REST_DAY)
        );

        emit GamingDelayAdded(_epoch_id, restDayStart);
    }

    /**
     * @dev adds gaming delay to an epoch
     * @param _epoch_id the id of the epoch
     */
    function _addDelayToRestDay(uint256 _epoch_id, uint256 restDayEnd)
        external
        onlyContract(CONTRACT_NAME_WITHDRAW_POOL)
    {
        genericDB.setUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(_epoch_id, "restDayEnd")),
            restDayEnd
        );
    }
}
