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
     using SafeMath for uint;
     using BokkyPooBahsDateTimeLibrary for uint;

     GenericDB public genericDB;

     uint public SIX_WORKING_DAYS = 6 * 24 * 60 * 60;
     uint public REST_DAY = 24 * 60 * 60;
     uint public SIX_HOURS = 6 * 60 * 60;

     //===================== events ===================
     event NewEpochSet(uint indexed newEpochId, uint newEpochStartTime);
     event GamingDelayAdded(
         uint indexed epoch_id,
         uint gamingDelay,
         uint newEpochEndingTime
         );

     //===================== modifiers ===================
     modifier onlyActiveEpoch(uint epoch_id) {
         require(isEpochActive(epoch_id));
         _;
     }

     //===================== setters ===================
     function initialize() external onlyOwner {
        genericDB = GenericDB(proxy.getContract(CONTRACT_NAME_GENERIC_DB));
     }

     function setTimes(uint256 sixWorking, uint256 restDay, uint256 sixHours)
     public
     onlySuperAdmin()
     {
        SIX_WORKING_DAYS = sixWorking;
        REST_DAY = restDay;
        SIX_HOURS = sixHours;
     }

    /**
     * @dev sets epoch 0
     */
    function setEpoch_0()
    external
    onlyContract(CONTRACT_NAME_WITHDRAW_POOL)
    {
        _setNewEpoch(0, now);
    }

    function setEpochTimes(uint256 epochID)
    external
    onlyContract(CONTRACT_NAME_WITHDRAW_POOL)
    {
        uint256 _startTime = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epochID.sub(1), "restDayEnd")));
        _setNewEpoch(epochID, _startTime);
    }

     //===================== getters ===================
     /**
      * @dev return the total number of epochs
      */
     function getTotalEpochs() public view returns (uint) {
         uint numberOfTotalEpochs = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked("totalNumberOfEpochs")));

         return numberOfTotalEpochs;
     }

     /**
      * @dev return the ID of the active epoch
      */
     function getActiveEpochID() public view returns (uint) {
         genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encode("activeEpoch")));
     }

     /**
      * @dev return true if the epoch with epoch_id is the active epoch
      * @param epoch_id the id of the epoch
      */
     function isEpochActive(uint epoch_id) public view returns (bool) {
         uint _sixDayStart = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "sixDayStart")));
         uint _restDayEnd = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "restDayEnd")));
         return now >= _sixDayStart && now <= _restDayEnd;
     }

     /**
      * @dev return true if game can start in the current epoch
      */
     function canStartNewGame() public view returns (bool) {
         uint epoch_id = getActiveEpochID();
         uint _sixDayStart = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "sixDayStart")));
         uint _sixDayEnd = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "restDayStart")));
         return now >= _sixDayStart && now <= _sixDayEnd.sub(SIX_HOURS);
     }

     /**
      * @dev return true if the epoch with epoch_id has started
      * @param epoch_id the id of the epoch
      */
     function hasEpochStarted(uint epoch_id) public view returns(bool) {
         uint _sixDayStart = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "sixDayStart")));
         return now >= _sixDayStart;
     }

     /**
      * @dev return true if the epoch with epoch_id has ended
      * @param epoch_id the id of the epoch
      */
     function hasEpochEnded(uint epoch_id) public view returns (bool) {
         uint _restDayStart = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "restDayStart")));
         return now > _restDayStart;
     }

     /**
      * @dev return the gaming delay time of an epoch.
      * if no gaming delay during that epoch, returns 0
      * @param epoch_id the id of the epoch
      */

     function gamingDelay(uint epoch_id) public view returns (uint) {
         uint _gamingDelay = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "gamingDelay")));
         return _gamingDelay;
     }

     /**
      * @dev return the start time (in unix time) of the epoch with epoch_id
      * @param epoch_id the id of the epoch
      */
     function _epochStartTime(uint epoch_id) public view returns (uint) {
         uint _sixDayStart = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "sixDayStart")));
         return _sixDayStart;
     }

     /**
      * @dev return the end time (in unix time) of the epoch with epoch_id
      * @param epoch_id the id of the epoch
      */
     function _epochEndTime(uint epoch_id) public view returns (uint) {
         uint _restDayEnd = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "restDayEnd")));
         return _restDayEnd;
     }

     function _newEpochStartTime() public view returns (uint) {
        uint256 epoch_id = getActiveEpochID();
        uint256 _restDayEnd = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "restDayEnd")));
        return _restDayEnd.add(REST_DAY);
     }

     /**
      * @dev return the time elapsed(in seconds) since the start of the epoch with epoch_id
      * @param epoch_id the id of the epoch
      */
     function elapsedSinceEpochStart(uint epoch_id) public view returns (uint) {
         uint _sixDayStart = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "sixDayStart")));
         require (now >= _sixDayStart, "Epoch has not started yet");
         return now.sub(_sixDayStart);
     }

     /**
      * @dev return the time remaining (in seconds) until the end of the epoch with epoch_id
      * @param epoch_id the id of the epoch
      */
     function timeUntilEpochEnd(uint epoch_id) public view returns (uint) {
         uint _restDayEnd = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "restDayEnd")));
         require(now <= _restDayEnd, "Already ended");
         return _restDayEnd.sub(now);
     }

     /**
      * @dev return the start time (in unix time) of the WorkingDays stage in the current active epoch
      */
     function workingDayStartTime()
         public
         view
         returns (uint start)
     {
         uint activeEpoch = getActiveEpochID();
         start = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(activeEpoch, "sixDayStart")));
     }

     /**
      * @dev return the end time (in unix time) of the WorkingDays stage in the current active epoch
      */
     function workingDayEndTime()
         public
         view
         returns (uint end)
     {
         uint activeEpoch = getActiveEpochID();
         end = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(activeEpoch, "restDayStart")));
     }

     /**
      * @dev return the start time (in unix time) of the RestDay stage in the current active epoch
      */
     function restDayStartTime()
         public
         view
         returns (uint start)
     {
         uint activeEpoch = getActiveEpochID();
         start = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(activeEpoch, "restDayStart")));
     }

     /**
      * @dev return the end time (in unix time) of the RestDay stage in the current active epoch
      */
     function restDayEndTime()
         public
         view
         returns (uint end)
     {
         uint activeEpoch = getActiveEpochID();
         end = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(activeEpoch, "restDayEnd")));
     }

     /**
      * @dev return true if the epoch with epoch_id is on its working days
      * @param epoch_id the id of the epoch
      */
     function isWorkingDay(uint epoch_id) public view returns (bool) {
         uint _sixDayStart = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "sixDayStart")));
         uint _restDayStart = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "restDayStart")));
         return (block.timestamp >= _sixDayStart) && (block.timestamp <= _restDayStart);
     }

     /**
      * @dev return true if the epoch with epoch_id is on its rest day
      * @param epoch_id the id of the epoch
      */
     function isRestDay(uint epoch_id) public view returns (bool) {
         uint _restDayStart = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "restDayStart")));
         uint _restDayEnd = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "restDayEnd")));
         return (block.timestamp >= _restDayStart) && (block.timestamp <= _restDayEnd);
     }

     /**
      * @dev return the entire time length (in seconds) of the epoch with epoch_id
      * @param epoch_id the id of the epoch
      */
     function epochLength(uint epoch_id) public view returns (uint) {
         uint _sixDayStart = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "sixDayStart")));
         uint _restDayEnd = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "restDayEnd")));
         require(_sixDayStart <= _restDayEnd, "Invalid start and end dates");
         return _restDayEnd.sub(_sixDayStart);
     }

     //===================== Internal Functions ===================

     /**
      * @dev creates a new epoch, the ID of which is total number of epochs - 1
      */

     function _setNewEpoch(uint _newEpochId, uint _startTime)
         internal
     {
         genericDB.setUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(_newEpochId, "sixDayStart")),
            _startTime);

         genericDB.setUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(_newEpochId, "endTimeForGames")),
            _startTime.add(SIX_WORKING_DAYS).sub(SIX_HOURS));

         genericDB.setUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encode("activeEpoch")),
            _newEpochId);

         genericDB.setUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(_newEpochId, "restDayStart")),
            _startTime.add(SIX_WORKING_DAYS));

         genericDB.setUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(_newEpochId, "restDayEnd")),
            _startTime.add(SIX_WORKING_DAYS).add(REST_DAY));

         genericDB.setUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked("totalNumberOfEpochs")),
            _newEpochId.add(1));

         emit NewEpochSet(_newEpochId, _startTime);
     }

     /**
      * @dev adds gaming delay to an epoch
      * @param _epoch_id the id of the epoch
      */
     function _addGamingDelayToEpoch(uint _epoch_id, uint restDayStart)
     external
     onlyContract(CONTRACT_NAME_WITHDRAW_POOL)
     {
         genericDB.setUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(_epoch_id, "restDayStart")),
            restDayStart);

         genericDB.setUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(_epoch_id, "restDayEnd")),
            restDayStart.add(REST_DAY));

         // emit GamingDelayAdded(_epoch_id, _gamingDelay, _restDayStart.add(_gamingDelay).add(REST_DAY));
     }

     /**
      * @dev adds gaming delay to an epoch
      * @param _epoch_id the id of the epoch
      */
     function _addDelayToRestDay(uint _epoch_id, uint restDayEnd)
     external
     onlyContract(CONTRACT_NAME_WITHDRAW_POOL)
     {
         genericDB.setUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(_epoch_id, "restDayEnd")),
            restDayEnd);
     }
 }