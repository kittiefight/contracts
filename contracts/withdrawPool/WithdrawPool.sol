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
import "../interfaces/IStaking.sol";
import "../interfaces/ERC20Standard.sol";
import "../modules/databases/EndowmentDB.sol";
import "../modules/endowment/EndowmentFund.sol";
import "../modules/endowment/EarningsTracker.sol";
import "../modules/databases/EarningsTrackerDB.sol";
import "../modules/databases/GenericDB.sol";
import "../CronJob.sol";

contract WithdrawPool is Proxied, Guard {

    using SafeMath for uint256;

    /*                                               GENERAL VARIABLES                                                */
    /*                                                     START                                                      */
    /* ============================================================================================================== */

    IStaking public staking;
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

    /*                                                 POOL VARIABLES                                                 */
    /*                                                     START                                                      */
    /* ============================================================================================================== */

    struct WithdrawalPool {
        uint256 blockNumber;        //The block number of the block in which this pool was created
        uint256 stakersClaimed;     //How many stakers claimed from this pool.
        address[] allClaimedStakers; //Addresses of all stakers who have claimed from this pool.
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
        timeFrame = TimeFrame(proxy.getContract(CONTRACT_NAME_TIMEFRAME));
        staking = IStaking(_stakingContract);
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

        // the claimer must have tokens staked in the staking contract at this moment
        require(staking.totalStakedFor(msgSender) > 0, "You don't have any superDao tokens staked currently");

        // get the last time that the claimer's staked token amount has been changed
        // the tokens need to be staked before the the current epoch started
        uint256 lastModifiedBlockNumber = staking.lastStakedFor(msgSender);
        require(lastModifiedBlockNumber <= genericDB.getUintStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encodePacked(pool_id, "blockNumber"))), "You are not eligible to claim for this pool");
        require(stakers[msgSender].claimed[pool_id] == false, "You have already claimed from this pool");

        // update staker
        _updateStaker(msgSender, pool_id, lastModifiedBlockNumber);
        // calculate the amount of ether entitled to the caller
        uint256 yield = checkYield(msgSender, pool_id);
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
        // divided by 1000000000 because getPercentagePool() returns a value amplified by 1000000000
        //return getPercentageSuperDao(staker).mul(weeklyPools[pool_id].initialETHAvailable).div(1000000000);
        uint256 stakedByStaker = staking.totalStakedFor(staker);
        uint256 stakedByAllStakers = staking.totalStaked();
        uint256 initialETHinPool = genericDB.getUintStorage(
            CONTRACT_NAME_ENDOWMENT_DB,
            keccak256(abi.encodePacked(pool_id, "InitialETHinPool"))
          );
        return stakedByStaker.mul(initialETHinPool).div(stakedByAllStakers);
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

    /**
     * @dev This function is used by owner to change stakingContract's address.
     * @param _stakingContract The address of the new stakingContract.
     */
    function setStakingContract(address _stakingContract)
        external
        onlyOwner
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
     * @dev This function is returning the Ether that has been allocated to all pools.
     */
    function getEthPaidOut()
    external
    view
    returns(uint256)
    {
        return genericDB.getUintStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encode("totalEthPaidOut"))
          );
    }

    /**
     * @dev This function is returning the total number of Stakers that claimed from this contract.
     */
    function getNumberOfTotalStakers()
    external
    view
    returns(uint256)
    {
        return genericDB.getUintStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encode("noOfTotalStakers"))
          );
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
        return genericDB.getUintStorage(CONTRACT_NAME_TIMEFRAME, keccak256(abi.encode("activeEpoch")));
    }

    // get the initial ether available in a pool
    function getInitialETH(uint256 _poolID)
        public
        view
        returns (uint256)
    {
        return genericDB.getUintStorage(
            CONTRACT_NAME_ENDOWMENT_DB,
            keccak256(abi.encodePacked(_poolID, "InitialETHinPool"))
          );
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
      * @dev return the time remaining (in seconds) until time available for claiming the current pool
      * only current pool can be claimed
      */
     function timeUntilClaiming() public view returns (uint256) {
         uint256 epochID = getActivePoolID();
         uint256 claimTime = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epochID, "restDayStart")));
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
         uint256 epochID = getActivePoolID();
         uint256 dissolveTime = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epochID, "restDayEnd")));
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
     * @dev This function is used to update pool data, when a claim occurs.
     * @param pool_id The pool id.
     */
    function _updatePool(address _staker, uint256 pool_id, uint256 _yield)
    internal
    {
        weeklyPools[pool_id].stakersClaimed = weeklyPools[pool_id].stakersClaimed.add(1);
        weeklyPools[pool_id].allClaimedStakers.push(_staker);

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
            pool_id,
            endowmentDB.getETHinPool(pool_id),
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
        stakers[_staker].claimed[pool_id] = true;
        stakers[_staker].totalPoolsClaimed = stakers[_staker].totalPoolsClaimed.add(1);
        stakers[_staker].currentAvailablePools = stakers[_staker].currentAvailablePools > 0 ?
                                                 stakers[_staker].currentAvailablePools.sub(1) : 0;
    }

    function addGamingDelay(uint256 newEndTime)
    external
    //onlyContract TODO
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
            abi.encodeWithSignature("(startNewEpoch(uint256)", epochID.add(1)));

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

        genericDB.setBoolStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encodePacked(epochID.sub(1), "unlocked")),
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
            abi.encodeWithSignature("(startRestDay(uint256)", epochID));

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
