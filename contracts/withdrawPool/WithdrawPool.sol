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
import "../CronJob.sol";
import "../interfaces/IStaking.sol";
import "../interfaces/ERC20Standard.sol";
import "../modules/databases/EndowmentDB.sol";
import "../modules/endowment/EndowmentFund.sol";
import "../modules/endowment/EarningsTracker.sol";

contract WithdrawPool is Proxied, Guard {

    using SafeMath for uint256;

    /*                                               GENERAL VARIABLES                                                */
    /*                                                     START                                                      */
    /* ============================================================================================================== */

    IStaking public staking;

    ERC20Standard public superDaoToken;

    CronJob public cronJob;

    TimeFrame public timeFrame;

    EndowmentDB public endowmentDB;

    EndowmentFund public endowmentFund;

    EarningsTracker public earningsTracker;


    uint256 staking_period; //Time needed a staker to stake, so as to be able to claim.

    //uint256 validClaimTime; //Valid time duration during which a staker can claim his/her dividends from a pool, after this valid time the pool will be dissolved, and unclaimed ether returned back to endowment

    uint256 totalEthPaidOut; //The total amount of Eth this contract paid to stakers.

    uint256 noOfPools; //The number of all pools created.

    uint256 noOfDissolvedPools; //The number of all pools that have been dissolved.

    uint256 noOfOpenPools; //The number of all pools yet to be dissolved.

    uint256 noOfTotalStakers; //The number of total stakers that withdrew from this contract.

    //uint256 noOfTokensStaked; //The number of tokens that we know for sure are staked right now.

    /*                                               GENERAL VARIABLES                                                */
    /*                                                      END                                                       */
    /* ============================================================================================================== */

    /*                                                 POOL VARIABLES                                                 */
    /*                                                     START                                                      */
    /* ============================================================================================================== */

    struct WithdrawalPool {
        uint256 epochID;            // epochID of the epoch asscoated with this pool
        uint256 blockNumber;        //The block number of the block in which this pool was created
        uint256 initialETHAvailable; // How much Eth this pool initially has, which is the amount of eth distributed
                                     // to this pool when the associated honeypot dissolves
        uint256 ETHAvailable;       //How much Eth this pool contains.
        uint256 dateAvailable;      //When this pool's Eth will be available for withdrawal, in unix time
        bool initialETHadded;    // check whether initial ether is recorded in withdrawPool
        bool dissolved;             //If this is true the pool has been dissolved, otherwise has not.
        uint256 dateDissolved;      //The date this pool got dissolved in unix time.
        //uint256 stakersEligible;    //How many stakers are eligible to claim from this pool.
        uint256 stakersClaimed;     //How many stakers claimed from this pool.
        address[] allClaimedStakers; //Addresses of all stakers who have claimed from this pool.
        //address[] eligibleStakers; //Addresses of all stakers that are eligible to claim from this pool.
    }

    struct Staker{
        //uint256 stakeStartDate;        //Timestamp of the date this staker started to stake.
        uint256 previousStartTime;      //Block Number of the block in which this staker started to stake the previous time.
        uint256 stakeStartTime;         //Block Number of the block in which this staker started to lock superDao.
        mapping(uint256 => bool) staking;                   //
        mapping(uint256 => bool) claimed; // true if this staker has already claimed from this pool
        uint256 totalPoolsClaimed;      //From how many pools this staker claimed funds.
        uint256 currentAvailablePools;  //From how many pools this staker hasn't yet claimed, while he is eligible.
    }

    mapping(uint256 => WithdrawalPool) public weeklyPools; //Ids for all weekly pools

    mapping(address => Staker) internal stakers; //Stake information about this address

    // mapping(uint256 => bool) internal dissolveScheduled; //True if a pool is already scheduled for dissolve
    // uint256 public scheduledJob;                 //Current cronJob ID of the cronJob scheduled for pool dissolving
    // mapping (uint => uint) public scheduledJobs; // Mapping pool_id to cronJob ID which schdules dissolving this pool

    //address[] internal potentialStakers; // A list of the addresses of SuperDao holders who stake their tokens,
                                         // may not eligible for claiming yields
                                         //if not meeting staking period requirement

    /*                                                 POOL VARIABLES                                                 */
    /*                                                      END                                                       */
    /* ============================================================================================================== */

    /*                                                   MODIFIERS                                                    */
    /*                                                     START                                                      */
    /* ============================================================================================================== */

    //modifier onlyCronJob() {
      //  require(msg.sender == cronJob, "WithdrawPool: Only CronJob");
        //_;
    //}

    //modifier onlyEndowmentFund() {
      //  require(msg.sender == endowmentFund, "WithdrawPool: Only EndowmentFund");
        //_;
    //}

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

    function initialize(address _stakingContract, address _superDaoToken)
        external
        onlyOwner
    {
        cronJob = CronJob(proxy.getContract(CONTRACT_NAME_CRONJOB));
        timeFrame = TimeFrame(proxy.getContract(CONTRACT_NAME_TIMEFRAME));
        staking = IStaking(_stakingContract);
        endowmentFund = EndowmentFund(proxy.getContract(CONTRACT_NAME_ENDOWMENT_FUND));
        superDaoToken = ERC20Standard(_superDaoToken);
        endowmentDB = EndowmentDB(proxy.getContract(CONTRACT_NAME_ENDOWMENT_DB));
        earningsTracker = EarningsTracker(proxy.getContract(CONTRACT_NAME_EARNINGS_TRACKER));
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
    external returns(bool)
    {
        // must be the open pool
        require(weeklyPools[pool_id].dateAvailable <= now, "This pool is not available for claiming yet");
        require(weeklyPools[pool_id].dissolved == false, "This pool is already dissolved");

        // get the last time that the claimer's staked token amount has been changed
        // the tokens need to be staked before the the current epoch started
        uint256 lastModifiedBlockNumber = staking.lastStakedFor(msg.sender);
        require(lastModifiedBlockNumber <= weeklyPools[pool_id].blockNumber, "You are not eligible to claim for this pool");
        require(stakers[msg.sender].claimed[pool_id] == false, "You have already claimed from this pool");

        // // schedule dissolving this pool if its dissolving has not been scheduled yet
        // if (dissolveScheduled[pool_id] == false) {
        //     //scheduleDissolvePool(pool_id);
        //     scheduleDissolveOldCreateNew(pool_id);
        //     dissolveScheduled[pool_id] = true;
        // }
        // record initial ether in pool in withdrawPool struct
        // only need to be called once for each pool
        if (weeklyPools[pool_id].initialETHadded == false &&
            weeklyPools[pool_id].initialETHAvailable == 0) {
                addAmountToPool(pool_id);
            }

        // update staker
        _updateStaker(msg.sender, pool_id, lastModifiedBlockNumber);
        // calculate the amount of ether entitled to the caller
        uint256 yield = checkYield(msg.sender, pool_id);
        // update pool data
        _updatePool(msg.sender, pool_id, yield);
        // pay dividend to the caller
        require(endowmentFund.transferETHfromEscrowWithdrawalPool(msg.sender, yield, pool_id));

        emit ClaimYield(pool_id, msg.sender, yield);
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
        // divided by 1000000000 because getPercentagePool() returns a value amplified by 1000000000
        //return getPercentageSuperDao(staker).mul(weeklyPools[pool_id].initialETHAvailable).div(1000000000);
        uint256 stakedByStaker = staking.totalStakedFor(staker);
        uint256 stakedByAllStakers = staking.totalStaked();
        uint256 initialETHinPool = weeklyPools[pool_id].initialETHAvailable;
        return stakedByStaker.mul(initialETHinPool).div(stakedByAllStakers);
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
        withdrawalPool.blockNumber = block.number;
        withdrawalPool.dateAvailable = epoch0StartTime.add(timeFrame.SIX_WORKING_DAYS());
        withdrawalPool.dateDissolved = epoch0StartTime.add(timeFrame.SIX_WORKING_DAYS()).add(timeFrame.REST_DAY());
        
        weeklyPools[0] = withdrawalPool;
        earningsTracker.setInvestment(0, endowmentDB.checkInvestment(0));

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
        earningsTracker.setInterest(pool_id, total);
     }

    /**
     * @dev This function is used by owner to change stakingContract's address.
     * @param _stakingContract The address of the new stakingContract.
     */
    function setStakingContract(address _stakingContract)
    external
    onlyOwner()
    {
        staking = IStaking(_stakingContract);
    }

    /*                                                 SETTER FUNCTIONS                                               */
    /*                                                       END                                                      */
    /* ============================================================================================================== */

    /*                                                 GETTER FUNCTIONS                                               */
    /*                                                      START                                                     */
    /* ============================================================================================================== */

    /**
     * @dev This function is returning the Ether that has been claimed by this contract till now.
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

    /**
     * @dev This function is returning the total number of Tokens that are staked.
     */
    function getNumberOfTokensStaked()
    external
    view
    returns(uint256)
    {
        return staking.totalStaked();
    }

    // return true if the staker has already claimed
    // from this pool with pool_id
    //function hasClaimed(address account, uint256 pool_id)
      //  internal
       // view
        //returns(bool)
    //{
      //  address[] memory unclaimed = weeklyPools[pool_id].unclaimedStakers;
        //for (uint256 i=0; i<unclaimed.length-1; i++) {
          //  if (account == unclaimed[i]) {
            //    return true;
            //}
        //}
        //return false;
    //}

    // calculate the percentage of a staker's token staked in the total SuperDao tokens minted
    function getPercentageSuperDao(address account)
        //internal
        public
        view
        returns (uint256)
    {
        uint256 total = superDaoToken.totalSupply(); // TODO: total minted
        uint256 stakedAmount = staking.totalStakedFor(account);
        uint256 percentagePool = stakedAmount.mul(1000000000).div(total); // multiply 1000000000 to ensure it is always an integer
        return percentagePool;
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
      * @dev return the time remaining (in seconds) until time availabe for claiming the pool with pool_id
      * @param pool_id the id of the pool
      */
     function timeUntilClaiming(uint256 pool_id) public view returns (uint256) {
         require(weeklyPools[pool_id].dissolved == false, "Pool already dissolved");
         return weeklyPools[pool_id].dateAvailable.sub(now);
     }

     /**
      * @dev return the time remaining (in seconds) until time for dissolving the pool with pool_id
      * @param pool_id the id of the pool
      */
     function timeUntilPoolDissolve(uint256 pool_id) public view returns (uint256) {
         require(weeklyPools[pool_id].dissolved == false, "Pool already dissolved");
         return weeklyPools[pool_id].dateDissolved.sub(now);
     }


    // This function is dangersou if there are too many takers - problem: looping over a long list
    // The sum of the percentages of each individual staker's token staked in the total SuperDao tokens minted
    //function getSumOfPercentagePool(uint256 pool_id)
      //  internal
        //view
        //returns (uint256)
    //{
      //  uint256 sum;
       // address[] memory allEligibleStakers = weeklyPools[pool_id].eligibleStakers;
       // for (uint256 i=0; i<allEligibleStakers.length; i++) {
         //   sum = sum.add(getPercentageSuperDao(allEligibleStakers[i]));
        //}
        //return sum;
   // }

    // calculate the share of a staker in a pool

    //function getPercentagePool(address account, uint256 pool_id)
      //  internal
        //view
        //returns (uint256)
    //{
      //  return getPercentageSuperDao(account).div(getSumOfPercentagePool(pool_id));
    //}


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
        weeklyPools[newPoolId].blockNumber = block.number;
        weeklyPools[newPoolId].dateAvailable = now.add(6 * 24 * 60 * 60);//now.add(timeFrame.SIX_WORKING_DAYS());
        weeklyPools[newPoolId].dateDissolved = weeklyPools[newPoolId].dateAvailable.add(24 * 60 * 60);//now.add(timeFrame.SIX_WORKING_DAYS()).add(timeFrame.REST_DAY());

        earningsTracker.setInvestment(newPoolId, endowmentDB.checkInvestment(newPoolId));
        noOfPools = noOfPools.add(1);

        emit PoolDissolved(pool_id, now);

        emit NewPoolCreated(newPoolId, now);
    }

    // *
    //  * @dev This function schedules dissolving an old pool at its dissolving time
    //  * and create a new pool by the cronJob.
    //  * @dev This function is called only once, when the first claimer claims from this pool
    //  * @param _pool_id The pool id of the pool for which dissolving is scheduled
    //  * @return True if the cronJob is scheduled
     

    // function scheduleDissolveOldCreateNew(uint256 _pool_id)
    //     internal
    //     returns (bool)
    // {
    //     uint256 _time = weeklyPools[_pool_id].dateDissolved;
    //     scheduledJob = cronJob.addCronJob(
    //         CONTRACT_NAME_WITHDRAW_POOL,
    //         _time,
    //         abi.encodeWithSignature("dissolveOldCreateNew(uint256)", _pool_id)
    //     );
    //     scheduledJobs[_pool_id] = scheduledJob;

    //     emit PoolDissolveScheduled(scheduledJob, _time, _pool_id);
    //     return true;
    // }

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
    function _updateStaker(address _staker, uint256 pool_id, uint256 _stakeStartTime)
    internal
    {
        stakers[_staker].previousStartTime = stakers[_staker].stakeStartTime;
        stakers[_staker].stakeStartTime = _stakeStartTime;
        //stakers[_staker].staking[pool_id] = true;
        stakers[_staker].claimed[pool_id] = true;
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


    // This function is too dangerous if there are too many stakers - problem :looping over a long list
    // remove a staker from a pool's list of unclaimedStakers
   // function _removeFromUnclaimed(address _account, uint256 pool_id)
     //   internal
    //{
      //  uint256 len = weeklyPools[pool_id].unclaimedStakers.length;
        //for (uint256 i=0; i<len-1; i++) {
          //  if (_account == weeklyPools[pool_id].unclaimedStakers[i]) {
            //    weeklyPools[pool_id].unclaimedStakers[i] = weeklyPools[pool_id].unclaimedStakers[len-1];
            //}
        //}
        //weeklyPools[pool_id].unclaimedStakers.length.sub(1);
    //}

    // this function is too dangerous if there are many stakers - looping over a long list is dangerous
    //function checkEligibility(uint256 pool_id) internal {
      //  for (uint256 i = 0; i < potentialStakers.length; i++) {
        //    uint256 lastModifiedBlockNumber = stakingContract.lastStakedFor(potentialStakers[i]);
          //  if (lastModifiedBlockNumber <= weeklyPools[pool_id].blockNumber) {
            //    weeklyPools[pool_id].eligibleStakers.push(potentialStakers[i]);
              //  weeklyPools[pool_id].unclaimedStakers.push(potentialStakers[i]);
                //stakers[potentialStakers[i]].currentAvailablePools.add(1);
                //stakers[potentialStakers[i]].stakeStartDate = lastModifiedBlockNumber;
            //}
        //}

        //weeklyPools[pool_id].stakersEligible = weeklyPools[pool_id].eligibleStakers.length;
        //weeklyPools[pool_id].eligibilityChecked = true;

        //emit CheckStakersEligibility(pool_id, weeklyPools[pool_id].stakersEligible, now);
    //}
    
    /*                                                INTERNAL FUNCTIONS                                              */
    /*                                                       END                                                      */
    /* ============================================================================================================== */
}
