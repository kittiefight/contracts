/* Code by Xaleee ======================================================================================= Kittiefight */
pragma solidity ^0.5.5;

import "../modules/proxy/Proxied.sol";
import "../authority/Guard.sol";
//import {Owned} from ".././authority/Owned.sol";
import "../libs/SafeMath.sol";
import {IStaking} from ".././interfaces/IStaking.sol";
import "../interfaces/ERC20Standard.sol";
import "../modules/databases/EndowmentDB.sol";
import "../modules/endowment/EndowmentFund.sol";

contract WithdrawPool is Proxied, Guard {

    using SafeMath for uint256;

    /*                                               GENERAL VARIABLES                                                */
    /*                                                     START                                                      */
    /* ============================================================================================================== */

    IStaking stakingContract;

    ERC20Standard public superDaoToken;

    CronJob public cronJob;

    EndowmentDB public endowmentDB;

    EndowmentFund public endowmentFund;

    //address cronJob; //The address of the cronJob contract.

    //address endowmentFund; //The address of the endowmentFund contract.

    uint256 staking_period; //Time needed a staker to stake, so as to be able to claim.

    uint256 validClaimTime; //Valid time duration during which a staker can claim his/her dividends from a pool, after this valid time the pool will be dissolved, and unclaimed ether returned back to endowment

    uint256 totalEthPaidOut; //The total amount of Eth this contract paid to stakers.

    uint256 noOfPools; //The number of all pools created.

    uint256 noOfDissolvedPools; //The number of all pools that have been dissolved.

    uint256 noOfOpenPools; //The number of all pools yet to be dissolved.

    uint256 noOfTotalStakers; //The number of total stakers that withdrew from this contract.

    uint256 noOfTokensStaked; //The number of tokens that we know for sure are staked right now.

    /*                                               GENERAL VARIABLES                                                */
    /*                                                      END                                                       */
    /* ============================================================================================================== */

    /*                                                 POOL VARIABLES                                                 */
    /*                                                     START                                                      */
    /* ============================================================================================================== */

    struct WithdrawalPool {
        uint256 blockNumber;        //The block number of the block in which this pool was created
        uint256 ETHAvailable;       //How much Eth this pool contains.
        uint256 dateAvailable;      //When this pool's Eth will be available for withdrawal.
        bool eligibilityChecked;    // Check every activeLockId to make sure that the tokens locked were not unlocked
                                    // only need to be called/checked once
        bool dissolved;             //If this is true the pool has been dissolved, otherwise has not. 
        uint256 dateDissolved;      //The date this pool got dissolved.
        uint256 stakersEligible;    //How many stakers are eligible to claim from this pool.
        uint256 stakersClaimed;     //How many stakers claimed from this pool.
        address[] unclaimedStakers; //Addresses of all stakers that are yet to claim from this pool.
        address[] eligibleStakers; //Addresses of all stakers that are eligible to claim from this pool.
    }

    struct Staker{
        uint256 stakeStartDate;         //Timestamp of the date this staker started to stake.
        uint256 previousStartDate;      //Timestamp of the date this staker started to stake the previous time.
        uint256 stakeStartTime;    //Timestamp of the date this staker started to lock superDao.
        bool staking;                   //
        uint256 totalPoolsClaimed;      //From how many pools this staker claimed funds.
        uint256 currentAvailablePools;  //From how many pools this staker hasn't yet claimed, while he is eligible.
    }

    mapping(uint256 => WithdrawalPool) public weeklyPools; //Ids for all weekly pools

    mapping(address => Staker) internal stakers; //Stake information about this address

    address[] internal potentialStakers; //SuperDao holders who stake their tokens, may not eligible for claiming yields if not meeting staking period requirement

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

    /*                                                    MODIFIERS                                                   */
    /*                                                       END                                                      */
    /* ============================================================================================================== */

    /*                                                   CONSTRUCTOR                                                  */
    /*                                                      START                                                     */
    /* ============================================================================================================== */

    function initialize(address _stakingContract, address _superDaoToken)
        external onlyOwner 
    {
        cronJob = CronJob(proxy.getContract(CONTRACT_NAME_CRONJOB));
        stakingContract = IStaking(_stakingContract);
        endowmentFund = EndowmentFund(proxy.getContract(CONTRACT_NAME_ENDOWMENT_FUND));
        superDaoToken = ERC20Standard(_superDaoToken);
        endowmentDB = EndowmentDB(proxy.getContract(CONTRACT_NAME_ENDOWMENT_DB));
    }

    /*                                                   CONSTRUCTOR                                                  */
    /*                                                       END                                                      */
    /* ============================================================================================================== */

    // events
    event AddETHtoPool(uint256 indexed pool_id, uint256 amountETH);
    event CheckStakersEligibility(uint256 indexed pool_id, uint256 numberOfStakersEligible, uint256 checkingTime);
    event PoolUpdated(
        uint256 indexed pool_id,
        uint256 ETHAvailableInPool,
        uint256 stakersClaimedForPool,
        uint256 totalEthPaidOut
    );
    event ClaimYield(uint256 indexed pool_id, address indexed account, uint256 yield);
    event ReturnUnclaimedETHtoEscrow(uint256 indexed pool_id, uint256 unclaimedETH, address receiver);
    event PoolDissolved(uint256 indexed pool_id, uint256 dissolveTime);
    event NewPoolCreated(uint256 indexed newPoolId, uint256 newPoolCreationTime);

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
        // if eligibility of the stakers for the pool is not checked, check it here. 
        // only need to check once
        if (weeklyPools[pool_id].eligibilityChecked == false) {
            checkEligibility(pool_id);
        }
        // check caller's eligibiliy for the specific pool with pool_id
        require(isUnclaimed(msg.sender, pool_id) == true, "You have already claimed or you are not eligible to claim this pool");
        // calculate the amount of ether entitled to the caller
        uint256 yield = getPercentagePool(msg.sender, pool_id).mul(weeklyPools[pool_id].ETHAvailable).div(1000000000); // divided by 1000000000 because getPercentagePool() returns a value amplified by 1000000000
        // update pool data
        _updatePool(msg.sender, pool_id, yield);
        // update staker
        _updateStaker();
        // pay dividend to the caller
        require(endowmentFund.transferETHfromEscrowWithdrawalPool(msg.sender, yield));
        emit ClaimYield(pool_id, msg.sender, yield);
        return true;
    }

    /**
     * @dev This function is used, so as to check how much Eth a staker can withdraw from a specific pool.
     * @param pool_id The pool from which they would like to claim.
     * @param staker The address of the staker we would like to check.
     */
    function checkYield(address staker, uint256 pool_id)
    external
    view
    returns(uint256)
    {
        return getPercentagePool(staker, pool_id).mul(weeklyPools[pool_id].ETHAvailable).div(1000000000); // divided by 1000000000 because getPercentagePool() returns a value amplified by 1000000000
    }

    /*                                                 STAKER FUNCTIONS                                               */
    /*                                                       END                                                      */
    /* ============================================================================================================== */

    /*                                                 SETTER FUNCTIONS                                               */
    /*                                                      START                                                     */
    /* ============================================================================================================== */

    /**
     * @dev This function is used by endowmentDB to add amounts to the pool.
     * @dev When a honeypot dissolves, this funciton is carried out to add the 7% share 
     *      to the pool. Each honeypot is associated with a pool with pool_id
     */
    function addAmountToPool(uint256 pool_id, uint256 amountETH)
        external
        payable
        onlyContract(CONTRACT_NAME_ENDOWMENT_DB)
        returns (bool)
    {
        //if time of previous week's pool has passed we jump to a new pool, otherwise we just increase previous pools
        
        require(weeklyPools[pool_id].dissolved == false, "This pool is dissolved");
        endowmentDB.updateEndowmentFund(0, amountETH, true);
        weeklyPools[pool_id].ETHAvailable.add(amountETH);
        emit AddETHtoPool(pool_id, amountETH);
        return true;
    }

    /**
     * @dev This function is used by owner to update to a new contract.
     * @param _newPool The address of the new contract.
     */
    function upgradeContractPool(address _newPool)
    external
    onlyOwner()
    {

    }

    /**
     * @dev This function is used by cronJob to return all unclaimed funds of a pool back to endowment.
     * @param pool_id The pool id that is going to be dissolved.
     */
    function dissolvePool(uint256 pool_id)
    external
    onlyContract(CONTRACT_NAME_CRONJOB)
    returns (bool)
    {
        _returnUnclaimed(pool_id);
        weeklyPools[pool_id].dateDissolved = now;
        weeklyPools[pool_id].dissolved = true;

        uint256 newPoolId = _createPool();

        noOfDissolvedPools.add(1);
        noOfPools.add(1);

        emit PoolDissolved(pool_id, now);
        emit NewPoolCreated(newPoolId, now);

        return true;
    }

    /**
     * @dev This function is used by owner to change stakingContract's address.
     * @param _stakingContract The address of the new stakingContract.
     */
    function setStakingContract(address _stakingContract)
    external
    onlyOwner()
    {
        stakingContract = IStaking(_stakingContract);
    }
    
    /*                                                 SETTER FUNCTIONS                                               */
    /*                                                       END                                                      */
    /* ============================================================================================================== */

    /*                                                 GETTER FUNCTIONS                                               */
    /*                                                      START                                                     */
    /* ============================================================================================================== */

    // TODO: this contract should not hold any ether, this function shouldn't exist
    /**
     * @dev This function is returning the Ether that is available in this contract.
     */
    function getEthAvailable()
    external
    view
    returns(uint256)
    {
        return address(this).balance;
    }

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
        return noOfTokensStaked;
    }

    // return true if the staker is eligible but hasn't claimed 
    // from this pool with pool_id
    function isUnclaimed(address account, uint256 pool_id)
        internal
        view
        returns(bool)
    {
        address[] memory unclaimed = weeklyPools[pool_id].unclaimedStakers;
        for (uint256 i=0; i<unclaimed.length-1; i++) {
            if (account == unclaimed[i]) {
                return true;
            }
        }
        return false;
    }

    // calculate the percentage of a staker's token staked in the total SuperDao tokens minted

    function getPercentageSuperDao(address account)
        internal
        view
        returns (uint256)
    {
        require(stakers[account].staking == true, "This account is not currently staking SuperDao tokens");
        uint256 total = superDaoToken.totalSupply(); // TODO: total minted
        uint256 stakedAmount = stakingContract.totalStakedForAt(account, stakers[account].stakeStartDate);
        uint256 percentagePool = stakedAmount.mul(1000000000).div(total); // multiply 1000000000 to ensure it is always an integer
        return percentagePool;
    }

    // The sum of the percentages of each individual staker's token staked in the total SuperDao tokens minted

    function getSumOfPercentagePool(uint256 pool_id)
        internal
        view
        returns (uint256)
    {
        uint256 sum;
        address[] memory allEligibleStakers = weeklyPools[pool_id].eligibleStakers;
        for (uint256 i=0; i<allEligibleStakers.length; i++) {
            sum = sum.add(getPercentageSuperDao(allEligibleStakers[i]));
        }
        return sum;
    }

    // calculate the share of a staker in a pool

    function getPercentagePool(address account, uint256 pool_id)
        internal
        view
        returns (uint256)
    {
        return getPercentageSuperDao(account).div(getSumOfPercentagePool(pool_id));
    }


    /*                                                 GETTER FUNCTIONS                                               */
    /*                                                       END                                                      */
    /* ============================================================================================================== */

    /*                                                INTERNAL FUNCTIONS                                              */
    /*                                                      START                                                     */
    /* ============================================================================================================== */

    function _createPool()
        internal
        returns (uint256)
    {
        uint256 newPoolId = noOfPools;
        WithdrawalPool memory withdrawalPool;
        uint256 WORKING_DAYS = 6 * 24 * 3600;
        withdrawalPool.blockNumber = block.number;
        withdrawalPool.dateAvailable = now.add(WORKING_DAYS);
        
        weeklyPools[newPoolId] = withdrawalPool;

        noOfPools.add(1);

        return newPoolId;
    }
    /**
     * @dev This function is returning the unclaimed funds of a pool back to endowment.
     * @param pool_id The pool id that is going to be dissolved.
     */
    function _returnUnclaimed(uint256 pool_id)
        internal
        returns(bool)
    {
        uint256 unclaimedETH = weeklyPools[pool_id].ETHAvailable;
        require(unclaimedETH > 0, "No ether left in the pool to return");

        weeklyPools[pool_id].ETHAvailable = 0;

        endowmentDB.updateEndowmentFund(0, unclaimedETH, false);

        emit ReturnUnclaimedETHtoEscrow(pool_id, unclaimedETH, proxy.getContract(CONTRACT_NAME_ENDOWMENT_FUND));

        return true;
    }

    /**
     * @dev This function is used to update pool data, when a claim occurs.
     * @param pool_id The pool id.
     */
    function _updatePool(address _account, uint256 pool_id, uint256 _yield)
    internal
    {
        weeklyPools[pool_id].ETHAvailable.sub(_yield);
        weeklyPools[pool_id].stakersClaimed.add(1);
        _removeFromUnclaimed(_account, pool_id);
        totalEthPaidOut.add(_yield);

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
    function _updateStaker()
    internal
    {
        stakers[msg.sender].totalPoolsClaimed = stakers[msg.sender].totalPoolsClaimed.add(1);
        stakers[msg.sender].currentAvailablePools = stakers[msg.sender].currentAvailablePools > 0 ? stakers[msg.sender].currentAvailablePools.sub(1) : 0;
    }

    // remove a staker from a pool's list of unclaimedStakers
    function _removeFromUnclaimed(address _account, uint256 pool_id)
        internal
    {
        uint256 len = weeklyPools[pool_id].unclaimedStakers.length;
        for (uint256 i=0; i<len-1; i++) {
            if (_account == weeklyPools[pool_id].unclaimedStakers[i]) {
                weeklyPools[pool_id].unclaimedStakers[i] = weeklyPools[pool_id].unclaimedStakers[len-1];
            }
        }
        weeklyPools[pool_id].unclaimedStakers.length.sub(1);
    }

    // check all stakers activeLockIds and select those who didn't unlock as eligibleStakers
    // only need to be called once for a pool(by the first claimer for the current pool)
    function checkEligibility(uint256 pool_id) internal {
        for (uint256 i = 0; i < potentialStakers.length; i++) {
            uint256 lastModifiedBlockNumber = stakingContract.lastStakedFor(potentialStakers[i]);
            if (lastModifiedBlockNumber <= weeklyPools[pool_id].blockNumber) {
                weeklyPools[pool_id].eligibleStakers.push(potentialStakers[i]);
                weeklyPools[pool_id].unclaimedStakers.push(potentialStakers[i]);
                stakers[potentialStakers[i]].currentAvailablePools.add(1);
                stakers[potentialStakers[i]].stakeStartDate = lastModifiedBlockNumber;
            }
        }

        weeklyPools[pool_id].stakersEligible = weeklyPools[pool_id].eligibleStakers.length;
        weeklyPools[pool_id].eligibilityChecked = true;

        emit CheckStakersEligibility(pool_id, weeklyPools[pool_id].stakersEligible, now);
    }
    
    /*                                                INTERNAL FUNCTIONS                                              */
    /*                                                       END                                                      */
    /* ============================================================================================================== */
}
