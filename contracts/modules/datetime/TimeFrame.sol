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
     public
     onlyContract(CONTRACT_NAME_WITHDRAW_POOL)
     {
         _setNewEpoch(0, now);
     }

     /**
      * @dev creates a new epoch, the ID of which is total number of epochs - 1
      * This function should be called by GameManager when the last game
      * in an epoch ends in order to set new epoch
      */
     function setNewEpoch()
         public
         onlyContract(CONTRACT_NAME_GAMESTORE)
     {
         uint newEpochId = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked("totalNumberOfEpochs")));

         uint prevEpochId = newEpochId.sub(1);

         uint prevEpochEnd = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(prevEpochId, "restDayEnd")));

         _setNewEpoch(newEpochId, prevEpochEnd);
     }

     /**
      * @dev adds gaming delay to an epoch
      * This function should be called by GameManager when the last game
      * in an epoch runs longer than the intended sixDayEnd
      * @param epoch_id the id of the epoch
      * @param gamingDelay gaming delay time in seconds
      */
     function unlockAndAddDelay(uint epoch_id, uint gamingDelay)
         public
         onlyContract(CONTRACT_NAME_WITHDRAW_POOL)
     {
         genericDB.setBoolStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "unlocked")),
            true);
         if(gamingDelay > 0)
             _addGamingDelayToEpoch(epoch_id, gamingDelay);
     }

    function terminateEpochManually()
        public
        onlyContract(CONTRACT_NAME_WITHDRAW_POOL)
    {
        uint epoch_id = getActiveEpochID();
        _terminateEpoch(epoch_id);
    }

    function setNewEpochManually()
        public
        onlyContract(CONTRACT_NAME_WITHDRAW_POOL)
    {
        uint newEpochId = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked("totalNumberOfEpochs")));

        _setNewEpoch(newEpochId, now);

        emit NewEpochSet(newEpochId, now);
    }

     //===================== public functions ===================

     /**
      * @dev converts date and time in human-readable format to unix timestamp
      */
     function timestampFromDateTime
     (
         uint year,
         uint month,
         uint day,
         uint hour,
         uint minute,
         uint second
     ) public pure returns (uint timestamp)
     {
        return BokkyPooBahsDateTimeLibrary.timestampFromDateTime(year, month, day, hour, minute, second);
    }

    /**
     * @dev converts unix timestamp to date and time in human-readable format
     */
     function timestampToDateTime(uint timestamp)
         public
         pure
         returns (uint year, uint month, uint day, uint hour, uint minute, uint second)
    {
        (year, month, day, hour, minute, second) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(timestamp);
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
         uint numberOfEpochs = getTotalEpochs();

         if (numberOfEpochs < 2) {
             return 0;
         }

         return numberOfEpochs.sub(1);
     }

     /**
      * @dev return the last epoch ID
      */
     function getLastEpochID() public view returns (uint) {
         uint numberOfEpochs = getTotalEpochs();
         return numberOfEpochs.sub(1);
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
            keccak256(abi.encodePacked(epoch_id, "sixDayEnd")));
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
         uint _sixDayEnd = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "sixDayEnd")));
         return now > _sixDayEnd;
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
      * @dev return the start time (in human-readable format) of the epoch with epoch_id
      * @param epoch_id the id of the epoch
      */
     function epochStartTime(uint epoch_id)
         public view
         returns (
             uint year,
             uint month,
             uint day,
             uint hour,
             uint minute,
             uint second
         )
     {
         uint timestamp = _epochStartTime(epoch_id);
         (year, month, day, hour, minute, second) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(timestamp);
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

     /**
      * @dev return the end time (in human-readable format) of the epoch with epoch_id
      * @param epoch_id the id of the epoch
      */
     function epochEndTime(uint epoch_id)
         public view
         returns (
             uint year,
             uint month,
             uint day,
             uint hour,
             uint minute,
             uint second
         )
     {
         uint timestamp = _epochEndTime(epoch_id);
         (year, month, day, hour, minute, second) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(timestamp);
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
            keccak256(abi.encodePacked(activeEpoch, "sixDayEnd")));
     }

     function checkBurn()
     external
     view
     returns(bool)
     {
        uint activeEpoch = getActiveEpochID();
        bool unlocked = genericDB.getBoolStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(activeEpoch, "unlocked")));
        uint _sixDayEnd = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(activeEpoch, "sixDayEnd")));
        if(unlocked && now > _sixDayEnd)
            return true;
        return false;
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
         uint _sixDayEnd = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "sixDayEnd")));
         return (block.timestamp >= _sixDayStart) && (block.timestamp <= _sixDayEnd);
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
            keccak256(abi.encodePacked(_newEpochId, "sixDayEnd")),
            _startTime.add(SIX_WORKING_DAYS));

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
      * @param _gamingDelay gaming delay time in seconds
      */
     function _addGamingDelayToEpoch(uint _epoch_id, uint _gamingDelay)
         internal
     {
         require(_gamingDelay > 0);

         uint _prevGamingDelay = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(_epoch_id, "gamingDelay")));

         genericDB.setUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(_epoch_id, "gamingDelay")),
            _prevGamingDelay.add(_gamingDelay));

         uint _sixDayEnd = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(_epoch_id, "sixDayEnd")));

         genericDB.setUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(_epoch_id, "sixDayEnd")),
            _sixDayEnd.add(_gamingDelay));

         genericDB.setUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(_epoch_id, "restDayStart")),
            _sixDayEnd.add(_gamingDelay));

         genericDB.setUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(_epoch_id, "restDayEnd")),
            _sixDayEnd.add(_gamingDelay).add(REST_DAY));

         emit GamingDelayAdded(_epoch_id, _gamingDelay, _sixDayEnd.add(_gamingDelay).add(REST_DAY));
     }

     /**
      * @dev terminates an epoch
      * @param epoch_id the id of the epoch
      */
     function _terminateEpoch(uint epoch_id) internal {
         uint _restDayEnd = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "restDayEnd")));
         require(now <= _restDayEnd, "Epoch has already ended");
         genericDB.setUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epoch_id, "restDayEnd")),
            now.sub(1));
     }
 }