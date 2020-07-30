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


    //uint256 validClaimTime; //Valid time duration during which a staker can claim his/her dividends from a pool, after this valid time the pool will be dissolved, and unclaimed ether returned back to endowment

    uint256 totalEthPaidOut; //The total amount of Eth this contract paid to stakers.

    uint256 noOfPools; //The number of all pools created.

    uint256 noOfDissolvedPools; //The number of all pools that have been dissolved.

    uint256 noOfOpenPools; //The number of all pools yet to be dissolved.

    uint256 noOfTotalStakers; //The number of total stakers that withdrew from this contract.

    /*                                               GENERAL VARIABLES                                                */
    /*                                                      END                                                       */
    /* ============================================================================================================== */

    /*                                                 POOL VARIABLES                                                 */
    /*                                                     START                                                      */
    /* ============================================================================================================== */

    struct WithdrawalPool {
        uint256 epochID;            // epochID of the epoch asscoated with this pool
        uint256 initialETHAvailable; // How much Eth this pool initially has, which is the amount of eth distributed
                                     // to this pool when the associated honeypot dissolves
        uint256 ETHAvailable;       //How much Eth this pool contains.
        uint256 dateAvailable;      //When this pool's Eth will be available for withdrawal, in unix time
        bool initialETHadded;    // check whether initial ether is recorded in withdrawPool
        bool unlocked;              //If this is true when rest_day starts stakers will be able to claim.
        bool dissolved;             //If this is true the pool has been dissolved, otherwise has not.
        uint256 dateDissolved;      //The date this pool got dissolved in unix time.
        uint256 stakersClaimed;     //How many stakers claimed from this pool.
        address[] allClaimedStakers; //Addresses of all stakers who have claimed from this pool.
    }

    struct Staker{
        mapping(uint256 => bool) claimed; // true if this staker has already claimed from this pool
        mapping(uint256 => uint256) etherClaimed; // How many ether this staker has claimed from this pool
        uint256 totalPoolsClaimed;      //From how many pools this staker claimed funds.
        uint256 currentAvailablePools;  //From how many pools this staker hasn't yet claimed, while he is eligible.
    }

    mapping(uint256 => WithdrawalPool) public weeklyPools; //Ids for all weekly pools

    mapping(address => Staker) internal stakers; //Stake information about this address

    /*                                                 POOL VARIABLES                                                 */
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
        require(weeklyPools[pool_id].dateAvailable <= now, "This pool is not available for claiming yet");
        require(weeklyPools[pool_id].unlocked == true, "This pool is locked");
        require(weeklyPools[pool_id].dissolved == false, "This pool is already dissolved");

        address payable msgSender = address(uint160(getOriginalSender()));

        (,,,uint256 lockedAmount) = timeLockManager.getTimeInterval(msgSender, pool_id);
        // check if claimer has locked SuperDao tokens for this epoch
        require(lockedAmount > 0, "No tokens locked for this epoch");

        require(stakers[msgSender].claimed[pool_id] == false, "Already claimed from this pool");

        // record initial ether in pool in withdrawPool struct
        // only need to be called once for each pool
        if (weeklyPools[pool_id].initialETHadded == false &&
            weeklyPools[pool_id].initialETHAvailable == 0) {
                addAmountToPool(pool_id);
            }

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
        uint256 initialETHinPool = weeklyPools[pool_id].initialETHAvailable;
        return lockedByStaker.mul(initialETHinPool).div(lockedByAllStakers);
    }

    /*                                                 STAKER FUNCTIONS                                               */
    /*                                                       END                                                      */
    /* ============================================================================================================== */

    /*                                                 SETTER FUNCTIONS                                               */
    /*                                                      START                                                     */
    /* ============================================================================================================== */

    function setPool_0() public onlyOwner {
        require(noOfPools == 0, "Pool 0 already exists");
        timeFrame.setEpoch_0();
        uint256 epoch0StartTime = now;
        WithdrawalPool memory withdrawalPool;
        withdrawalPool.epochID = 0; // poolId is the same as its associated epoch
        //withdrawalPool.blockNumber = block.number;
        withdrawalPool.dateAvailable = epoch0StartTime.add(timeFrame.SIX_WORKING_DAYS());
        withdrawalPool.dateDissolved = withdrawalPool.dateAvailable.add(timeFrame.REST_DAY());
        
        weeklyPools[0] = withdrawalPool;
        earningsTrackerDB.setInvestment(0, endowmentDB.checkInvestment(0));

        noOfPools = noOfPools.add(1);

        emit Pool0Set(0, now);
    }

    /**
      * @dev adds gaming delay to a pool
      * This function should be called by GameManager when the last game
      * in an epoch runs longer than the intended sixDayEnd
      * @param pool_id the id of the pool
      * @param gamingDelay gaming delay time in seconds
      */
     function addGamingDelayToPool(uint pool_id, uint gamingDelay)
         public
         onlyActivePool(pool_id)
         onlyContract(CONTRACT_NAME_GAMEMANAGER)
     {
         _addGamingDelayToPool(pool_id, gamingDelay);
     }

     function setInterestToEarningsTracker(uint256 pool_id, uint256 total)
     external
     onlyContract(CONTRACT_NAME_GAMESTORE)
     {
        weeklyPools[pool_id].unlocked = true;
        uint256 delay;
        if(now > weeklyPools[pool_id].dateAvailable) {
            delay = now.sub(weeklyPools[pool_id].dateAvailable);
            weeklyPools[pool_id].dateAvailable = now;
            weeklyPools[pool_id].dateDissolved =
                weeklyPools[pool_id].dateAvailable.add(timeFrame.REST_DAY());
        }
        timeFrame.unlockAndAddDelay(pool_id, delay);
        earningsTrackerDB.setInterest(pool_id, total);
     }

    // /**
    //  * @dev This function is used by owner to change stakingContract's address.
    //  * @param _stakingContract The address of the new stakingContract.
    //  */
    // function setStakingContract(address _stakingContract)
    //     external
    //     onlyOwner
    // {
    //     staking = Staking(_stakingContract);
    // }

    function terminateEpochAndPoolManually()
        public
        onlySuperAdmin
    {
        timeFrame.terminateEpochManually();
        _terminatePool();
    }

    function setNewEpochAndPoolManually()
        public
        onlySuperAdmin
    {
        timeFrame.setNewEpochManually();
        uint256 _newPoolId = noOfPools;
        weeklyPools[_newPoolId].epochID = _newPoolId; // poolId is always the same as its associated epoch
       // weeklyPools[_newPoolId].blockNumber = block.number;
        weeklyPools[_newPoolId].dateAvailable = now.add(timeFrame.SIX_WORKING_DAYS());
        weeklyPools[_newPoolId].dateDissolved = weeklyPools[_newPoolId].dateAvailable.add(timeFrame.REST_DAY());

        earningsTrackerDB.setInvestment(_newPoolId, endowmentDB.checkInvestment(_newPoolId));

        noOfPools = noOfPools.add(1);

        emit NewPoolCreated(_newPoolId, now);
    }


    /*                                                 SETTER FUNCTIONS                                               */
    /*                                                       END                                                      */
    /* ============================================================================================================== */

    /*                                                 GETTER FUNCTIONS                                               */
    /*                                                      START                                                     */
    /* ============================================================================================================== */

    /**
     * @dev This function is returning the Ether that has been allocated to all pools.
     */
    function getEthPaidOut()
    external
    view
    returns(uint256)
    {
        return totalEthPaidOut;
    }

    /**
     * @dev This function is returning the total number of Pools that were created.
     */
    function getTotalNumberOfPools()
    external
    view
    returns(uint256)
    {
        return noOfPools;
    }

    /**
     * @dev This function is returning the total number of Pools that have been dissolved.
     */
    function getNumberOfDissolvedPools()
    external
    view
    returns(uint256)
    {
        return noOfDissolvedPools;
    }

    //TODO: there should always be only 1 open pool at any time, so this function is stale.
    /**
     * @dev This function is returning the total number of Pools that are still open.
     */
    function getNumberOfOpenPools()
    external
    view
    returns(uint256)
    {
        return noOfOpenPools;
    }

    /**
     * @dev This function is returning the total number of Stakers that claimed from this contract.
     */
    function getNumberOfTotalStakers()
    external
    view
    returns(uint256)
    {
        return noOfTotalStakers;
    }

    // get the pool ID of the currently active pool
    // The ID of the active pool is the same as the ID of the active epoch
    function getActivePoolID()
        public
        view
        returns (uint256)
    {
        //return timeFrame.getActiveEpochID();
        return noOfPools.sub(1);
    }

    // get the initial ether available in a pool
    function getInitialETH(uint256 _poolID)
        public
        view
        returns (uint256)
    {
        return weeklyPools[_poolID].initialETHAvailable;
    }

    // get all stakers who have received yields from a pool with _poolID
    function getAllClaimersForPool(uint256 _poolID)
        public
        view
        returns (address[] memory)
    {
        return weeklyPools[_poolID].allClaimedStakers;
    }

     /**
      * @dev return the time remaining (in seconds) until time availabe for claiming the current pool
      * only current pool can be claimed
      */
     function timeUntilClaiming() public view returns (uint256) {
         uint256 pool_id = getActivePoolID();
         require(weeklyPools[pool_id].dissolved == false, "Pool already dissolved");
         uint256 claimTime = weeklyPools[pool_id].dateAvailable;
         if (claimTime > now) {
             return claimTime.sub(now);
         } else {
             return 0;
         }

     }

     /**
      * @dev return the time remaining (in seconds) until time for dissolving the current pool
      * If the pool is already dissolved, returns 0.
      */
     function timeUntilPoolDissolve() public view returns (uint256) {
         uint256 pool_id = getActivePoolID();
         uint256 dissolveTime = weeklyPools[pool_id].dateDissolved;
         if (dissolveTime > now) {
             return dissolveTime.sub(now);
         } else {
             return 0;
         }
     }

    /*                                                 GETTER FUNCTIONS                                               */
    /*                                                       END                                                      */
    /* ============================================================================================================== */

    /*                                                INTERNAL FUNCTIONS                                              */
    /*                                                      START                                                     */
    /* ============================================================================================================== */
    /**
     * @dev This function adds initial ether allocation to a pool with pool_id
     * @dev This function is called only once when the first claimer claims from this pool
     */
    function addAmountToPool(uint256 pool_id)
        internal
        returns (bool)
    {
        uint256 totalETHtoPool = endowmentDB.getETHinPool(pool_id);
        weeklyPools[pool_id].initialETHadded = true;
        weeklyPools[pool_id].initialETHAvailable = totalETHtoPool;
        weeklyPools[pool_id].ETHAvailable = totalETHtoPool;

        emit AddETHtoPool(pool_id, totalETHtoPool);
        return true;
    }

    /**
     * @dev This function is used by cronJob to dissolve an old pool at its dissolving time
     * and create a new pool.
     * @dev Any unclaimed ethers left in the old pool is returned to endowmentFund upon the pool's dissolution
     */
    function dissolveOldCreateNew()
    public
    onlyContract(CONTRACT_NAME_GAMESTORE)
    {
        uint256 pool_id = noOfPools.sub(1);
        // dissolve the old pool
        weeklyPools[pool_id].dissolved = true;

        noOfDissolvedPools = noOfDissolvedPools.add(1);

        // create new pool
        uint256 newPoolId = pool_id.add(1);
        weeklyPools[newPoolId].epochID = newPoolId; // poolId is always the same as its associated epoch
        //weeklyPools[newPoolId].blockNumber = block.number;
        weeklyPools[newPoolId].dateAvailable = now.add(timeFrame.SIX_WORKING_DAYS());
        weeklyPools[newPoolId].dateDissolved = weeklyPools[newPoolId].dateAvailable.add(timeFrame.REST_DAY());

        earningsTrackerDB.setInvestment(newPoolId, endowmentDB.checkInvestment(newPoolId));
        noOfPools = noOfPools.add(1);

        emit PoolDissolved(pool_id, now);

        emit NewPoolCreated(newPoolId, now);
    }

    /**
     * @dev This function is used to update pool data, when a claim occurs.
     * @param pool_id The pool id.
     */
    function _updatePool(address _staker, uint256 pool_id, uint256 _yield)
    internal
    {
        weeklyPools[pool_id].ETHAvailable = weeklyPools[pool_id].ETHAvailable.sub(_yield);
        weeklyPools[pool_id].stakersClaimed = weeklyPools[pool_id].stakersClaimed.add(1);
        weeklyPools[pool_id].allClaimedStakers.push(_staker);
        totalEthPaidOut = totalEthPaidOut.add(_yield);

        emit PoolUpdated(
            pool_id,
            weeklyPools[pool_id].ETHAvailable,
            weeklyPools[pool_id].stakersClaimed,
            totalEthPaidOut
        );
    }

    /**
     * @dev This function is used to update staker's data, when a claim occurs.
     */
    function _updateStaker(address _staker, uint256 _pool_id, uint256 _yield)
    internal
    {
        stakers[_staker].claimed[_pool_id] = true;
        stakers[_staker].etherClaimed[_pool_id] = _yield;
        stakers[_staker].totalPoolsClaimed = stakers[_staker].totalPoolsClaimed.add(1);
        stakers[_staker].currentAvailablePools = stakers[_staker].currentAvailablePools > 0 ?
                                                 stakers[_staker].currentAvailablePools.sub(1) : 0;
    }

    /**
      * @dev adds gaming delay to a pool
      * @param _pool_id the id of the pool
      * @param _gamingDelay gaming delay time in seconds
      */
     function _addGamingDelayToPool(uint _pool_id, uint _gamingDelay)
         internal
     {
         require(_gamingDelay > 0, "Gaming delay must be longer than 0");
         weeklyPools[_pool_id].dateAvailable = weeklyPools[_pool_id].dateAvailable.add(_gamingDelay);
         weeklyPools[_pool_id].dateDissolved = weeklyPools[_pool_id].dateDissolved.add(_gamingDelay);
         emit GamingDelayAddedtoPool(_pool_id, _gamingDelay, weeklyPools[_pool_id].dateAvailable);
     }

    /**
      * @dev terminates a pool
      */
    function _terminatePool() internal {
        uint256 _pool_id = getActivePoolID();
        require(now <= weeklyPools[_pool_id].dateDissolved, "Pool has already dissolved");
        weeklyPools[_pool_id].dateDissolved = now.sub(1);
        weeklyPools[_pool_id].unlocked = false;
        weeklyPools[_pool_id].dissolved = true;

        emit PoolDissolved(_pool_id, now);
    }
    
    /*                                                INTERNAL FUNCTIONS                                              */
    /*                                                       END                                                      */
    /* ============================================================================================================== */
}
