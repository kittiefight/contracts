/**
* @title WithdrawPool
*
* @author @ziweidream @Xaleee
*
*/
pragma solidity ^0.5.5;

import "../modules/proxy/Proxied.sol";
import "../authority/Guard.sol";
import "../modules/datetime/TimeFrame.sol";
import "../libs/SafeMath.sol";
import "../modules/databases/EndowmentDB.sol";
import "../modules/endowment/EndowmentFund.sol";
import "../modules/endowment/EarningsTracker.sol";
import "../modules/databases/EarningsTrackerDB.sol";
import "../modules/databases/GenericDB.sol";
import "../CronJob.sol";

contract WithdrawPool is Proxied, Guard {

    using SafeMath for uint256;

    uint public HALF_HOUR = 1800;

    /*                                               GENERAL VARIABLES                                                */
    /*                                                     START                                                      */
    /* ============================================================================================================== */

    TimeFrame public timeFrame;
    EndowmentDB public endowmentDB;
    EndowmentFund public endowmentFund;
    EarningsTracker public earningsTracker;
    EarningsTrackerDB public earningsTrackerDB;
    GenericDB public genericDB;
    CronJob public cronJob;

    /*                                               GENERAL VARIABLES                                                */
    /*                                                      END                                                       */
    /* ============================================================================================================== */

    /*                                                   MODIFIERS                                                    */
    /*                                                     START                                                      */
    /* ============================================================================================================== */

    modifier onlyActivePool(uint pool_id) {
         require(pool_id == getActivePoolID());
         _;
     }

    /*                                                    MODIFIERS                                                   */
    /*                                                       END                                                      */
    /* ============================================================================================================== */

    /*                                                   CONSTRUCTOR                                                  */
    /*                                                      START                                                     */
    /* ============================================================================================================== */

    function initialize()
        external
        onlyOwner
    {
        timeFrame = TimeFrame(proxy.getContract(CONTRACT_NAME_TIMEFRAME));
        endowmentFund = EndowmentFund(proxy.getContract(CONTRACT_NAME_ENDOWMENT_FUND));
        endowmentDB = EndowmentDB(proxy.getContract(CONTRACT_NAME_ENDOWMENT_DB));
        earningsTracker = EarningsTracker(proxy.getContract(CONTRACT_NAME_EARNINGS_TRACKER));
        earningsTrackerDB = EarningsTrackerDB(proxy.getContract(CONTRACT_NAME_EARNINGS_TRACKER_DB));
        genericDB = GenericDB(proxy.getContract(CONTRACT_NAME_GENERIC_DB));
        cronJob = CronJob(proxy.getContract(CONTRACT_NAME_CRONJOB));
    }

    /*                                                   CONSTRUCTOR                                                  */
    /*                                                       END                                                      */
    /* ============================================================================================================== */

    // events
    event Pool0Set(uint256 pool_id, uint256 createTime);
    event AddETHtoPool(uint256 indexed pool_id, uint256 amountETH);
    //event PoolDissolveScheduled(uint256 indexed scheduledJob, uint256 dissolveTime, uint256 indexed pool_id);
    event ReturnUnclaimedETHtoEscrow(uint256 indexed pool_id, uint256 unclaimedETH, address receiver);
    event PoolDissolved(uint256 indexed pool_id, uint256 dissolveTime);
    event NewPoolCreated(uint256 indexed newPoolId, uint256 newPoolCreationTime);
    event GamingDelayAddedtoPool(
        uint256 indexed _pool_id,
        uint256 _gamingDelay,
        uint256 newAvailableTimeForClaiming
    );
    /*                                                 SETTER FUNCTIONS                                               */
    /*                                                      START                                                     */
    /* ============================================================================================================== */

    function setPool_0() public onlyOwner {
        uint256 blockNumber = genericDB.getUintStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encodePacked("0", "blockNumber")));

        require(blockNumber == 0, "Pool 0 already exists");

        timeFrame.setEpoch_0();

        _startNewEpoch(0);

        emit Pool0Set(0, now);
    }

    /*                                                 SETTER FUNCTIONS                                               */
    /*                                                       END                                                      */
    /* ============================================================================================================== */

    /*                                                 GETTER FUNCTIONS                                               */
    /*                                                      START                                                     */
    /* ============================================================================================================== */
    // get the pool ID of the currently active pool
    // The ID of the active pool is the same as the ID of the active epoch
    function getActivePoolID()
        public
        view
        returns (uint256)
    {
        return genericDB.getUintStorage(CONTRACT_NAME_TIMEFRAME, keccak256(abi.encode("activeEpoch")));
    }

    /*                                                 GETTER FUNCTIONS                                               */
    /*                                                       END                                                      */
    /* ============================================================================================================== */

    
    /*                                                INTERNAL FUNCTIONS                                              */
    /*                                                      START                                                     */
    /* ============================================================================================================== */

    function addGamingDelay(uint256 newEndTime)
    external
    onlyContract(CONTRACT_NAME_GAMECREATION)
    {
        uint256 epochID = getActivePoolID();
        uint256 jobID = genericDB.getUintStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encodePacked(epochID, "jobID"))
        );

        uint256 scheduledJob = cronJob.rescheduleCronJob(
            CONTRACT_NAME_WITHDRAW_POOL,
            jobID,
            newEndTime);

        genericDB.setUintStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encodePacked(epochID, "jobID")),
            scheduledJob
        );

        timeFrame._addGamingDelayToEpoch(epochID, newEndTime);
    }

    function _addInvestmentDelay() 
    internal
    {
        uint256 epochID = getActivePoolID();
        uint256 jobID = genericDB.getUintStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encodePacked(epochID, "jobID"))
        );

        uint256 newTime = now.add(timeFrame.REST_DAY());

        uint256 scheduledJob = cronJob.rescheduleCronJob(
            CONTRACT_NAME_WITHDRAW_POOL,
            jobID,
            newTime);

        genericDB.setUintStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encodePacked(epochID, "jobID")),
            scheduledJob
        );

        timeFrame._addDelayToRestDay(epochID, newTime);
    }

    function startRestDay(uint256 epochID)
    external
    onlyContract(CONTRACT_NAME_CRONJOB)
    {
        (,uint256 gameId) = genericDB.getAdjacent(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked("GameTable")), 0, true);

        if(genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "state"))) < 3) {
            uint256 newTime = block.timestamp.add(HALF_HOUR);

            uint256 scheduledJob = cronJob.addCronJob(
                CONTRACT_NAME_WITHDRAW_POOL,
                newTime,
                abi.encodeWithSignature("startRestDay(uint256)", epochID));

            genericDB.setUintStorage(
                CONTRACT_NAME_WITHDRAW_POOL,
                keccak256(abi.encodePacked(epochID, "jobID")),
                scheduledJob
            );

            timeFrame._addGamingDelayToEpoch(epochID, newTime);
        }
        else
            _startRestDay(epochID);
    }

    function startNewEpoch(uint256 epochID)
    external
    onlyContract(CONTRACT_NAME_CRONJOB)
    {
        timeFrame.setEpochTimes(epochID);

        genericDB.setBoolStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encodePacked(epochID.sub(1), "unlocked")),
            false);

        _startNewEpoch(epochID);

        emit PoolDissolved(epochID.sub(1), now);
    }

    function _startRestDay(uint256 epochID)
    internal
    {
        genericDB.setBoolStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encodePacked(epochID, "unlocked")),
            true);

        genericDB.setBoolStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encode("rest_day")),
            true);

        (uint256 interest,) = endowmentDB.getTotalForEpoch(epochID);
        earningsTrackerDB.setInterest(epochID, interest);

        uint256 newEpochStart = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epochID, "restDayEnd")));

        uint256 scheduledJob = cronJob.addCronJob(
            CONTRACT_NAME_WITHDRAW_POOL,
            newEpochStart,
            abi.encodeWithSignature("startNewEpoch(uint256)", epochID.add(1)));

        genericDB.setUintStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encodePacked(epochID, "jobID")),
            scheduledJob
        );
    }

    function _startNewEpoch(uint256 epochID)
    internal
    {
        uint256 investment = endowmentDB.checkInvestment(epochID);
        if(investment == 0) {
            _addInvestmentDelay();
            return;
        }

        genericDB.setBoolStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encode("rest_day")),
            false);

        earningsTrackerDB.setInvestment(epochID, investment);

        genericDB.setUintStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encodePacked(epochID, "blockNumber")),
            block.number);

        uint256 restDayStart = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epochID, "restDayStart")));

        uint256 scheduledJob = cronJob.addCronJob(
            CONTRACT_NAME_WITHDRAW_POOL,
            restDayStart,
            abi.encodeWithSignature("startRestDay(uint256)", epochID));

        genericDB.setUintStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encodePacked(epochID, "jobID")),
            scheduledJob
        );

        emit NewPoolCreated(epochID, now);
    }
    
    /*                                                INTERNAL FUNCTIONS                                              */
    /*                                                       END                                                      */
    /* ============================================================================================================== */
}
