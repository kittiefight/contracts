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

 contract TimeFrame is Proxied {
     using SafeMath for uint;
     using BokkyPooBahsDateTimeLibrary for uint;

     uint constant public SIX_WORKING_DAYS = 6 * 24 * 60 * 60;
     uint constant public REST_DAY = 24 * 60 * 60;
     uint constant public SIX_HOURS = 6 * 60 * 60;

     /// @dev total number of epochs
     uint public numberOfEpochs;

     struct Epoch {
         /// @dev Unix time of the start of an epoch
         uint sixDayStart;
         /// @dev Unix time of the end of an epoch (should be greater than start)
         uint sixDayEnd;
         /// @dev Delay time duration in seconds
         uint gamingDelay;
         /// @dev Unix time of the start of a rest day (sixDayEnd or gamingDelay+now)
         uint restDAYStart;
         /// @dev Unix time of the end of a rest day (restDAYStart+24hours)
         uint restDAYEnd;
     }

     /// @dev a list of all epochs throughout lifetime of system
     mapping (uint => Epoch) public lifeTimeEpochs;

     //===================== events ===================
     event Epoch0Set(uint indexed epoch_0_id, uint epoch_0_startTime);
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
     /**
      * @dev sets epoch 0
      * @param start the start time (in unix time) of epoch 0
      */
     function setEpoch_0(uint start) public onlyOwner {
         lifeTimeEpochs[0].sixDayStart = start;
         lifeTimeEpochs[0].sixDayEnd = start.add(SIX_WORKING_DAYS);
         lifeTimeEpochs[0].restDAYStart = start.add(SIX_WORKING_DAYS);
         lifeTimeEpochs[0].restDAYEnd = start.add(SIX_WORKING_DAYS).add(REST_DAY);
         numberOfEpochs = numberOfEpochs.add(1);

         emit Epoch0Set(0, start);
     }

     /**
      * @dev creates a new epoch, the ID of which is total number of epochs - 1
      * This function should be called by GameManager when the last game
      * in an epoch ends in order to set new epoch
      */
     function setNewEpoch()
         public
         //temporarily comment out onlyContract for testing purpose only: TimeFrame.test.js
         onlyContract(CONTRACT_NAME_GAMESTORE)
     {
         _setNewEpoch();
     }

     /**
      * @dev adds gaming delay to an epoch
      * This function should be called by GameManager when the last game
      * in an epoch runs longer than the intended sixDayEnd
      * @param epoch_id the id of the epoch
      * @param gamingDelay gaming delay time in seconds
      */
     function addGamingDelayToEpoch(uint epoch_id, uint gamingDelay)
         public
         onlyActiveEpoch(epoch_id)
         //temporarily comment out onlyContract for testing purpose only: TimeFrame.test.js
         onlyContract(CONTRACT_NAME_GAMEMANAGER)
     {
         _addGamingDelayToEpoch(epoch_id, gamingDelay);
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
      * @dev return the ID of the active epoch
      * either the last epoch or the epoch before the last epoch can be
      * the current epoch, since new epoch is created at the time of sixDayEnd
      * of the previous epoch
      */
     function getActiveEpochID() public view returns (uint) {
         if (numberOfEpochs < 2) {
             return 0;
         }
         if (now <= lifeTimeEpochs[numberOfEpochs.sub(1)].sixDayStart) {
             return numberOfEpochs.sub(2);
         }
         return numberOfEpochs.sub(1);
     }

     /**
      * @dev return the last epoch ID
      * the last epoch may or may not be the active epoch, since a new epoch is created
      * 1 hour before its start time
      */
     function getLastEpochID() public view returns (uint) {
         return numberOfEpochs.sub(1);
     }

     /**
      * @dev return true if the epoch with epoch_id is the active epoch
      * @param epoch_id the id of the epoch
      */
     function isEpochActive(uint epoch_id) public view returns (bool) {
         return now >= lifeTimeEpochs[epoch_id].sixDayStart && now <= lifeTimeEpochs[epoch_id].restDAYEnd;
     }

     /**
      * @dev return true if game can start in the the epoch with epoch_id
      * @param epoch_id the id of the epoch
      */
     function canStartNewGame(uint epoch_id) public view returns (bool) {
         return now >= lifeTimeEpochs[epoch_id].sixDayStart && now <= lifeTimeEpochs[epoch_id].sixDayEnd.sub(SIX_HOURS);
     }

     /**
      * @dev return true if the epoch with epoch_id has started
      * @param epoch_id the id of the epoch
      */
     function hasEpochStarted(uint epoch_id) public view returns(bool) {
         return now >= lifeTimeEpochs[epoch_id].sixDayStart;
     }

     /**
      * @dev return true if the epoch with epoch_id has ended
      * @param epoch_id the id of the epoch
      */
     function hasEpochEnded(uint epoch_id) public view returns (bool) {
         return now > lifeTimeEpochs[epoch_id].sixDayEnd;
     }

     /**
      * @dev return the gaming delay time of an epoch.
      * if no gaming delay during that epoch, returns 0
      * @param epoch_id the id of the epoch
      */

     function gamingDelay(uint epoch_id) public view returns (uint) {
         return lifeTimeEpochs[epoch_id].gamingDelay;
     }

     /**
      * @dev return the start time (in unix time) of the epoch with epoch_id
      * @param epoch_id the id of the epoch
      */
     function _epochStartTime(uint epoch_id) public view returns (uint) {
         return lifeTimeEpochs[epoch_id].sixDayStart;
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
         return lifeTimeEpochs[epoch_id].restDAYEnd;
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
         require (now >= lifeTimeEpochs[epoch_id].sixDayStart, "Epoch has not started yet");
         return now.sub(lifeTimeEpochs[epoch_id].sixDayStart);
     }

     /**
      * @dev return the time remaining (in seconds) until the end of the epoch with epoch_id
      * @param epoch_id the id of the epoch
      */
     function timeUntilEpochEnd(uint epoch_id) public view returns (uint) {
         require(now <= lifeTimeEpochs[epoch_id].restDAYEnd, "Already ended");
         return lifeTimeEpochs[epoch_id].restDAYEnd.sub(now);
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
         start = lifeTimeEpochs[activeEpoch].sixDayStart;
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
         end = lifeTimeEpochs[activeEpoch].sixDayEnd;
     }

     /**
      * @dev return the start time (in unix time) of the RestDay stage in the current active epoch
      */
     function restDayStartTime()
         public
         view
         returns (uint end)
     {
         uint activeEpoch = getActiveEpochID();
         end = lifeTimeEpochs[activeEpoch].restDAYStart;
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
         end = lifeTimeEpochs[activeEpoch].restDAYEnd;
     }

     /**
      * @dev return true if the epoch with epoch_id is on its working days
      * @param epoch_id the id of the epoch
      */
     function isWorkingDay(uint epoch_id) public view returns (bool) {
         return (block.timestamp >= lifeTimeEpochs[epoch_id].sixDayStart) && (block.timestamp <= lifeTimeEpochs[epoch_id].sixDayEnd);
     }

     /**
      * @dev return true if the epoch with epoch_id is on its rest day
      * @param epoch_id the id of the epoch
      */
     function isRestDay(uint epoch_id) public view returns (bool) {
         return (block.timestamp >= lifeTimeEpochs[epoch_id].restDAYStart) && (block.timestamp <= lifeTimeEpochs[epoch_id].restDAYEnd);
     }

     /**
      * @dev return the entire time length (in seconds) of the epoch with epoch_id
      * @param epoch_id the id of the epoch
      */
     function epochLength(uint epoch_id) public view returns (uint) {
         require(lifeTimeEpochs[epoch_id].sixDayStart <= lifeTimeEpochs[epoch_id].restDAYEnd, "Invalid start and end dates");
         return lifeTimeEpochs[epoch_id].restDAYEnd.sub(lifeTimeEpochs[epoch_id].sixDayStart);
     }

     //===================== Internal Functions ===================

     /**
      * @dev creates a new epoch, the ID of which is total number of epochs - 1
      */

     function _setNewEpoch()
         internal
     {
         uint prevEpochId = numberOfEpochs.sub(1);
         uint newEpochId = numberOfEpochs;
         Epoch memory epoch;

         uint prevEpochEnd = lifeTimeEpochs[prevEpochId].restDAYEnd;

         epoch.sixDayStart = prevEpochEnd;
         epoch.sixDayEnd = prevEpochEnd.add(SIX_WORKING_DAYS);
         epoch.restDAYStart = prevEpochEnd.add(SIX_WORKING_DAYS);
         epoch.restDAYEnd = prevEpochEnd.add(SIX_WORKING_DAYS).add(REST_DAY);

         lifeTimeEpochs[newEpochId] = epoch;
         numberOfEpochs = numberOfEpochs.add(1);
         emit NewEpochSet(newEpochId, lifeTimeEpochs[newEpochId].sixDayStart);
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
         lifeTimeEpochs[_epoch_id].gamingDelay = lifeTimeEpochs[_epoch_id].gamingDelay.add(_gamingDelay);
         lifeTimeEpochs[_epoch_id].sixDayEnd = lifeTimeEpochs[_epoch_id].sixDayEnd.add(_gamingDelay);
         lifeTimeEpochs[_epoch_id].restDAYStart = lifeTimeEpochs[_epoch_id].restDAYStart.add(_gamingDelay);
         lifeTimeEpochs[_epoch_id].restDAYEnd = lifeTimeEpochs[_epoch_id].restDAYEnd.add(_gamingDelay);
         emit GamingDelayAdded(_epoch_id, _gamingDelay, lifeTimeEpochs[_epoch_id].restDAYEnd);
     }

     /**
      * @dev terminates an epoch
      * @param epoch_id the id of the epoch
      */
     function terminateEpoch(uint epoch_id) internal onlyOwner {
         require(now <= lifeTimeEpochs[epoch_id].restDAYEnd, "Epoch has already ended");
         lifeTimeEpochs[epoch_id].restDAYEnd = now.sub(1);
     }
 }