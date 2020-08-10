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
import "../interfaces/ERC20Standard.sol";
import "../modules/databases/EndowmentDB.sol";
import "../modules/endowment/EndowmentFund.sol";
import "../modules/endowment/EarningsTracker.sol";
import "../modules/databases/EarningsTrackerDB.sol";
import "../modules/databases/GenericDB.sol";
import "../CronJob.sol";
import "../stakingAragon/TimeLockManager.sol";

contract WithdrawPool is Proxied, Guard {

    using SafeMath for uint256;

    /*                                               GENERAL VARIABLES                                                */
    /*                                                     START                                                      */
    /* ============================================================================================================== */

    TimeLockManager public timeLockManager;
    ERC20Standard public superDaoToken;
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

    function initialize(address _timeLockManager, address _superDaoToken)
        external
        onlyOwner
    {
        timeFrame = TimeFrame(proxy.getContract(CONTRACT_NAME_TIMEFRAME));
        timeLockManager = TimeLockManager(_timeLockManager);
        endowmentFund = EndowmentFund(proxy.getContract(CONTRACT_NAME_ENDOWMENT_FUND));
        superDaoToken = ERC20Standard(_superDaoToken);
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
    event CheckStakersEligibility(uint256 indexed pool_id, uint256 numberOfStakersEligible, uint256 checkingTime);
    event PoolUpdated(
        uint256 indexed pool_id,
        uint256 ETHAvailableInPool,
        uint256 stakersClaimedForPool,
        uint256 totalEthPaidOut
    );
    event ClaimYield(uint256 indexed pool_id, address indexed account, uint256 yield);
    //event PoolDissolveScheduled(uint256 indexed scheduledJob, uint256 dissolveTime, uint256 indexed pool_id);
    event ReturnUnclaimedETHtoEscrow(uint256 indexed pool_id, uint256 unclaimedETH, address receiver);
    event PoolDissolved(uint256 indexed pool_id, uint256 dissolveTime);
    event NewPoolCreated(uint256 indexed newPoolId, uint256 newPoolCreationTime);
    event GamingDelayAddedtoPool(
        uint256 indexed _pool_id,
        uint256 _gamingDelay,
        uint256 newAvailableTimeForClaiming
    );

    /*                                                 STAKER FUNCTIONS                                               */
    /*                                                      START                                                     */
    /* ============================================================================================================== */

    /**
     * @dev This function is used by stakers to claim their yields.
     * @param pool_id The pool from which they would like to claim.
     */
    function claimYield(uint256 pool_id)
    external onlyProxy returns(bool)
    {
        require(genericDB.getBoolStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encodePacked(pool_id, "unlocked"))), "Pool is not claimable");

        address payable msgSender = address(uint160(getOriginalSender()));

        // check claimer's eligibility for claiming pool from this epoch
        require(timeLockManager.isEligible(msgSender, pool_id), "No tokens locked for this epoch");

        bool claimed = genericDB.getBoolStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encodePacked(pool_id, msgSender, "claimed")));

        require(claimed == false, "Already claimed from this pool");

        // calculate the amount of ether entitled to the caller
        uint256 yield = checkYield(msgSender, pool_id);

        // update staker
        _updateStaker(msgSender, pool_id, yield);

        // update pool data
        _updatePool(msgSender, pool_id, yield);
        // pay dividend to the caller
        require(endowmentFund.transferETHfromEscrowWithdrawalPool(msgSender, yield, pool_id));

        emit ClaimYield(pool_id, msgSender, yield);
        return true;
    }

    /**
     * @dev This function is used, so as to check how much Eth a staker can withdraw from a specific pool.
     * @param pool_id The pool from which they would like to claim.
     * @param staker The address of the staker we would like to check.
     */
    function checkYield(address staker, uint256 pool_id)
        public
        view
    returns(uint256)
    {
        (,,,uint256 lockedByStaker) = timeLockManager.getTimeInterval(staker, pool_id);
        uint256 lockedByAllStakers = timeLockManager.getTotalLockedForEpoch(pool_id);
        uint256 initialETHinPool = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB,keccak256(abi.encodePacked(pool_id, "InitialETHinPool")));
        return lockedByStaker.mul(initialETHinPool).div(lockedByAllStakers);
    }

    /*                                                 STAKER FUNCTIONS                                               */
    /*                                                       END                                                      */
    /* ============================================================================================================== */

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

    /**
     * @dev This function is used to update pool data, when a claim occurs.
     * @param _pool_id The pool id.
     */
    function _updatePool(address _staker, uint256 _pool_id, uint256 _yield)
    internal
    {
        uint256 totalStakersClaimed = genericDB.getUintStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encodePacked(_pool_id, "totalStakersClaimed"))
        ).add(1);

        genericDB.setUintStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encodePacked(_pool_id, "totalStakersClaimed")),
            totalStakersClaimed
        );

        uint256 totalEthPaidOut = _yield.add(genericDB.getUintStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encode("totalEthPaidOut"))
          ));

        genericDB.setUintStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encode("totalEthPaidOut")),
            totalEthPaidOut
          );

        emit PoolUpdated(
            _pool_id,
            endowmentDB.getETHinPool(_pool_id),
            totalStakersClaimed,
            totalEthPaidOut
        );
    }

    /**
     * @dev This function is used to update staker's data, when a claim occurs.
     */
    function _updateStaker(address _staker, uint256 _pool_id, uint256 _yield)
    internal
    {
        genericDB.setBoolStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encodePacked(_pool_id, _staker, "claimed")),
            true
        );

        genericDB.setUintStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encodePacked(_pool_id, _staker, "etherClaimed")),
            _yield
        );

        uint256 prevEthersClaimed = genericDB.getUintStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encodePacked(_pool_id, _staker, "totalEthersClaimed"))
        );

        genericDB.setUintStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encodePacked(_pool_id, _staker, "totalEthersClaimed")),
            prevEthersClaimed.add(_yield)
        );

        uint256 prevPoolsClaimed = genericDB.getUintStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encodePacked(_pool_id, _staker, "totalPoolsClaimed"))
        );

        genericDB.setUintStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encodePacked(_pool_id, _staker, "totalPoolsClaimed")),
            prevPoolsClaimed.add(1)
        );
    }

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

        (uint256 interest, uint256 fundsForPool) = endowmentDB.getTotalForEpoch(epochID);
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
