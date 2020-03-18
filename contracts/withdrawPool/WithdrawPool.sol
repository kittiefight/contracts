/* Code by Xaleee ======================================================================================= Kittiefight */
pragma solidity ^0.5.5;

import {Owned} from ".././authority/Owned.sol";
import {SafeMath} from ".././libs/SafeMath.sol";
import {IStaking} from ".././interfaces/IStaking.sol";

contract WithdrawPool is Owned {

    using SafeMath for uint256;

    /*                                               GENERAL VARIABLES                                                */
    /*                                                     START                                                      */
    /* ============================================================================================================== */

    IStaking stakingContract;

    address cronJob; //The address of the cronJob contract.

    address endowmentFund; //The address of the endowmentFund contract.

    uint256 staking_period; //Time needed a staker to stake, so as to be able to claim.

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
        uint256 ETHAvailable;       //How much Eth this pool contains.
        uint256 dateAvailable;      //When this pool's Eth will be available for withdrawal.
        bool dissolved;             //If this is true the pool has been dissolved, otherwise has not. 
        uint256 dateDissolved;      //The date this pool got dissolved.
        uint256 stakersEligible;    //How many stakers are eligible to claim from this pool.
        uint256 stakersClaimed;     //How many stakers claimed from this pool.
        address[] unclaimedStakers; //Addresses of all stakers that are yet to claim from this pool.
    }

    struct Staker{
        uint256 stakeStartDate;         //Timestamp of the date this staker started to stake.
        uint256 previousStartDate;      //Timestamp of the date this staker started to stake the previous time.
        uint256 stakeStartTime;         //
        bool staking;                   //
        uint256 totalPoolsClaimed;      //From how many pools this staker claimed funds.
        uint256 currentAvailablePools;  //From how many pools this staker hasn't yet claimed, while he is eligible.
    }

    mapping(uint256 => WithdrawalPool) public weeklyPools; //Ids for all pools contained in a week's pool

    mapping(address => Staker) stakers; //Stake information about this address

    /*                                                 POOL VARIABLES                                                 */
    /*                                                      END                                                       */
    /* ============================================================================================================== */

    /*                                                   MODIFIERS                                                    */
    /*                                                     START                                                      */
    /* ============================================================================================================== */

    modifier onlyCronJob() {
        require(msg.sender == cronJob, "WithdrawPool: Only CronJob");
        _;
    }

    modifier onlyEndowmentFund() {
        require(msg.sender == endowmentFund, "WithdrawPool: Only EndowmentFund");
        _;
    }

    /*                                                    MODIFIERS                                                   */
    /*                                                       END                                                      */
    /* ============================================================================================================== */

    /*                                                   CONSTRUCTOR                                                  */
    /*                                                      START                                                     */
    /* ============================================================================================================== */

    constructor(
        address _cronJob,
        address _stakingContract,
        address _endowmentFund
    )
    public
    {
        cronJob = cronJob;
        stakingContract = IStaking(_stakingContract);
        endowmentFund = _endowmentFund;
    }

    /*                                                   CONSTRUCTOR                                                  */
    /*                                                       END                                                      */
    /* ============================================================================================================== */

    /*                                                 STAKER FUNCTIONS                                               */
    /*                                                      START                                                     */
    /* ============================================================================================================== */

    /**
     * @dev This function is used by stakers to claim their yields.
     * @param pool_id The pool from which they would like to claim.
     * @param unstakeAmount How many tokens this staker would like to unstake from staking contract
     */
    function claimYield(uint256 pool_id, uint256 unstakeAmount)
    external
    {

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
        
    }

    /*                                                 STAKER FUNCTIONS                                               */
    /*                                                       END                                                      */
    /* ============================================================================================================== */

    /*                                                 SETTER FUNCTIONS                                               */
    /*                                                      START                                                     */
    /* ============================================================================================================== */

    /**
     * @dev This function is used by endowmentFund to add amounts to the pool.
     */
    function addAmountToPool()
    external
    payable
    onlyEndowmentFund()
    {
        //if time of previous week's pool has passed we jump to a new pool, otherwise we just increase previous pools
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
    onlyCronJob()
    {
        _returnUnclaimed(pool_id);
    }

    /**
     * @dev This function is used by owner to change cronJob's address.
     * @param _cronJob The address of the new cronJob contract.
     */
    function setCronJob(address _cronJob)
    external
    onlyOwner()
    {
        cronJob = _cronJob;
    }

    /**
     * @dev This function is used by owner to change endowmentFund's address.
     * @param _endowmentFund The address of the new endowmentFund contract.
     */
    function setEndowmentFund(address _endowmentFund)
    external
    onlyOwner()
    {
        endowmentFund = _endowmentFund;
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

    /*                                                 GETTER FUNCTIONS                                               */
    /*                                                       END                                                      */
    /* ============================================================================================================== */

    /*                                                INTERNAL FUNCTIONS                                              */
    /*                                                      START                                                     */
    /* ============================================================================================================== */

    /**
     * @dev This function is returning the unclaimed funds of a pool back to endowment.
     * @param pool_id The pool id that is going to be dissolved.
     */
    function _returnUnclaimed(uint256 pool_id)
    internal
    {

    }

    /**
     * @dev This function is used to update pool data, when a claim occurs.
     * @param pool_id The pool id.
     */
    function _updatePool(uint256 pool_id)
    internal
    {

    }

    /**
     * @dev This function is used to update staker's data, when a claim occurs.
     */
    function _updateStaker()
    internal
    {
        stakers[msg.sender].totalPoolsClaimed = stakers[msg.sender].totalPoolsClaimed.add(1);
        stakers[msg.sender].currentAvailablePools = stakers[msg.sender].currentAvailablePools.sub(1);
    }
    
    /*                                                INTERNAL FUNCTIONS                                              */
    /*                                                       END                                                      */
    /* ============================================================================================================== */
}
