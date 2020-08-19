/**
* @title YieldFarming
*
* @author @ziweidream
*
*/
pragma solidity ^0.5.5;

import "../libs/SafeMath.sol";
import "../authority/Owned.sol";
import "../uniswapKTY/uniswap-v2-core/interfaces/IUniswapV2ERC20.sol";
import "../interfaces/ERC20Standard.sol";

contract YieldFarming is Owned {
    using SafeMath for uint256;

    /*                                               GENERAL VARIABLES                                                */
    /* ============================================================================================================== */
 
    IUniswapV2ERC20 public LP;   // Uniswap Liquidity token contract
    ERC20Standard public kittieFightToken;
    ERC20Standard public superDaoToken;

    
    uint256 totalDepositedLP;
    uint256 totalLockedLP;
    uint256 totalRewardsKTY;
    uint256 totalRewardsSDAO;
    uint256 lockedRewardsKTY;
    uint256 lockedRewardsSDAO;
    uint256 totalRewardsKTYclaimed;
    uint256 totalRewardsSDAOclaimed;

    uint256 programDuration;

    uint256[6] KTYunlockRates;
    uint256[6] SDAOunlockRates;

    struct Deposit {
        uint256 amountLP;
        uint256 lockedAt;
    }

    struct Staker {
        uint256 totalDepositTimes;
        uint256 totalLPLocked;
        uint256 rewardsKTYclaimed;
        uint256 rewardsSDAOclaimed;
        uint256[] allBatches;
    }

    mapping(address => mapping(uint256 => Deposit)) public deposits;
    mapping(address => Staker) public stakers;
    
    /*                                                   CONSTRUCTOR                                                  */
    /* ============================================================================================================== */
    constructor(address _liquidityToken, address _kittieFightToken, address _superDaoToken) public {
        // Set token contracts
        LP = IUniswapV2ERC20(_liquidityToken);
        kittieFightToken = ERC20Standard(_kittieFightToken);
        superDaoToken = ERC20Standard(_superDaoToken);

        // Set reward unlock rate for KittieFightToken for the program duration
        KTYunlockRates[0] = 300000;
        KTYunlockRates[1] = 250000;
        KTYunlockRates[2] = 150000;
        KTYunlockRates[3] = 100000;
        KTYunlockRates[4] = 100000;
        KTYunlockRates[5] = 100000;

        // Set reward unlock rate for SuperDaoToken for the program duration
        SDAOunlockRates[0] = 100000;
        SDAOunlockRates[1] = 100000;
        SDAOunlockRates[2] = 100000;
        SDAOunlockRates[3] = 150000;
        SDAOunlockRates[4] = 250000;
        SDAOunlockRates[5] = 300000;

        // Set program duration (for a period of 6 months)
        uint256 duration = 180 * 24 * 60 * 60; // to do
        setProgramDuration(duration);
    }

    /*                                                      EVENTS                                                    */
    /* ============================================================================================================== */
    event Deposited(address indexed sender, uint256 indexed batchNumber, uint256 depositAmount, uint256 depositTime);

    event WithDrawn(
        address indexed sender,
        uint256 KTYamount,
        uint256 SDAOamount,
        uint256 LPamount,
        uint256 startBatchNumber,
        uint256 endBatchNumber, 
        uint256 withdrawTime
    );

    /*                                                 YIELD FARMING FUNCTIONS                                        */
    /* ============================================================================================================== */

    /**
     * @notice Deposit Uniswap Liquidity tokens
     * @param _amountLP the amount of Uniswap Liquidity tokens to be deposited
     * @return bool true if the deposit is successful
     * @dev    Each new deposit of a staker makes a new batch for this staker
     */
    function deposit(uint256 _amountLP) public returns (bool) {
         
        require(LP.transferFrom(msg.sender, address(this), _amountLP), "Fail to deposit liquidity tokens");

        _addDeposit(msg.sender, _amountLP, block.timestamp);

        return true;
    }

    /**
     * @notice Withdraw Uniswap Liquidity tokens deposited previously
     * @notice Three tokens (Uniswap Liquidity Tokens, KittieFightTokens, and SuperDaoTokens) are transferred
     *         to the user upon successful withdraw
     * @param _LPamount the amount of Uniswap Liquidity tokens to be withdrawn
     * @dev    FIFO (First in, First out) is used to allocate the _LPamount to the user's deposit batches.
     *         For example, _LPamount is allocated to batch 0 first, and if _LPamount is bigger than the amount
     *         locked in batch 0, then the rest is allocated to batch 1, and so forth.
     * @dev    Batch Number for each staker starts from 0, and increment by 1 for subsequent batches each.
     * @return true if the withdraw is successful
     */
    function withdrawByAmount(uint256 _LPamount) public returns (bool) {
        require(_LPamount <= stakers[msg.sender].totalLPLocked, "Insuffient liquidity tokens locked");

        (uint256 _KTY, uint256 _SDAO, uint256 _startBatchNumber, uint256 _endBatchNumber) = calculateRewardsByAmount(msg.sender, _LPamount);
        require(_KTY > 0 && _SDAO > 0, "Rewards cannot be 0");

        // deduct _LP from mapping deposits storage
        _deductDeposits(msg.sender, _LPamount, _startBatchNumber, _endBatchNumber);

        _withdraw (msg.sender, _LPamount, _KTY, _SDAO);

        emit WithDrawn(msg.sender, _KTY, _SDAO, _LPamount, _startBatchNumber, _endBatchNumber, block.timestamp);
        return true;
    }

    /**
     * @notice Withdraw Uniswap Liquidity tokens
     * @notice Three tokens (Uniswap Liquidity Tokens, KittieFightTokens, and SuperDaoTokens) are transferred
     *         to the user upon successful withdraw
     * @param _batchNumber the batch number of which deposit the user wishes to withdraw the Uniswap Liquidity tokens locked in it
     * @return bool true if the withdraw is successful
     */
    function withdrawByBatchNumber(uint256 _batchNumber) public returns (bool) {
        uint256 _amountLP = deposits[msg.sender][_batchNumber].amountLP;
        require(_amountLP > 0, "This batch number doesn't havey any liquidity token locked");

        (uint256 _KTY, uint256 _SDAO) = calculateRewardsByBatchNumber(msg.sender, _batchNumber);
        deposits[msg.sender][_batchNumber].amountLP = 0;
        deposits[msg.sender][_batchNumber].lockedAt = 0;

        _withdraw (msg.sender, _amountLP, _KTY, _SDAO);

        emit WithDrawn(msg.sender, _KTY, _SDAO, _amountLP, _batchNumber, _batchNumber, block.timestamp);
        return true;
    }

    /*                                                 SETTER FUNCTIONS                                               */
    /* ============================================================================================================== */
    /**
     * @notice Modify Reward Unlock Rate for KittieFightToken and SuperDaoToken for any month (from 0 to 5)
     *         within the program duration (a period of 6 months)
     * @param _month uint256 the month (from 0 to 5) for which the unlock rate is to be modified
     * @param _rate  uint256 the unlock rate
     * @param forKTY bool true if this modification is for KittieFightToken, false if it is for SuperDaoToken
     * @dev    This function can only be carreid out by the owner of this contract.
     */
    function modifyRewardUnlockRate(uint256 _month, uint256 _rate, bool forKTY) public onlyOwner {
        if (forKTY) {
            KTYunlockRates[_month] = _rate;
        } else {
            SDAOunlockRates[_month] = _rate;
        }
    }

    /**
     * @notice Set yield farming program time duration (for a period of 6 months)
     * @param _time uint256 the time duration of the program
     * @dev    This function can only be carreid out by the owner of this contract.
     */
    function setProgramDuration(uint256 _time) public onlyOwner {
        programDuration = _time;
    }

    /*                                                 GETTER FUNCTIONS                                               */
    /* ============================================================================================================== */

    /**
     * @param _staker address the staker who has deposited Uniswap Liquidity tokens
     * @return uint256 the amount of Uniswap Liquidity tokens locked by the staker in this contract
     */
    function getLiquidityTokenLocked(address _staker) public view returns (uint256) {
        return stakers[_staker].totalLPLocked;
    }

    /**
     * @param _staker address the staker who has deposited Uniswap Liquidity tokens
     * @return uint256[] an array of the amount of locked Lquidity tokens in every batch of the _staker. 
     *         The index of the array is the batch number associated, since batch for a stakder
     *         starts from batch 0, and increment by 1 for subsequent batches each.
     * @dev    Each new deposit of a staker makes a new batch.
     */
    function getAllBatches(address _staker)
        public view returns (uint256[] memory)
    {
        return stakers[_staker].allBatches;
    }

    /**
     * @param _staker address the staker who has deposited Uniswap Liquidity tokens
     * @return uint256 the batch number of the last batch of the _staker. 
     *         The batch number of the first batch of a staker is always 0, and increments by 1 for 
     *         subsequent batches each.
     */
    function getLastBatchNumber(address _staker)
        public view returns (uint)
    {
        return stakers[_staker].totalDepositTimes.sub(1);
    }

    /**
     * @param _staker address the staker who has deposited Uniswap Liquidity tokens
     * @param _batchNumber uint256 the batch number of which deposit the staker wishes to see the locked amount
     * @return uint256 the amount of Uniswap Liquidity tokens locked in the batch with _batchNumber by the staker 
     */
    function getLiquidityTokenLockedPerBatch(address _staker, uint256 _batchNumber)
        public view returns (uint256)
    {
        return deposits[_staker][_batchNumber].amountLP;
    }

    /**
     * @param _staker address the staker who has deposited Uniswap Liquidity tokens
     * @param _batchNumber uint256 the batch number of which deposit the staker wishes to see the locked amount
     * @return bool true if the batch with the _batchNumber of the _staker is a valid batch, false if it is non-valid.
     * @dev    A valid batch is a batch which has locked Liquidity tokens in it. 
     * @dev    A non-valid batch is an empty batch which has no Liquidity tokens in it.
     */
    function isBatchValid(address _staker, uint256 _batchNumber)
        public view returns (bool)
    {
        return deposits[_staker][_batchNumber].amountLP > 0;
    }

    /**
     * @notice Calculate the rewards (KittieFightToken and SuperDaoToken) by the amount of Uniswap Liquidity tokens 
     *         locked by a staker
     * @param _staker address the address of the staker for whom the rewards are calculated
     * @param _amountLP the amount of Uniswap Liquidity tokens locked
     * @return unit256 the amount of KittieFightToken rewards associated with the _amountLP lockec by this _staker
     * @return unit256 the amount of SuperDaoToken rewards associated with the _amountLP lockec by this _staker
     * @return uint256 the starting batch number of deposit from which the amount of Uniswap Liquidity tokens are allocated
     * @return uint256 the ending batch number of deposit from which the amount of Uniswap Liquidity tokens are allocated
     * @dev    FIFO (First In, First Out) is used to allocate the amount of liquidity tokens to the batches of deposits of this staker
     */
    function calculateRewardsByAmount(address _staker, uint256 _amountLP)
        public view
        returns (uint256 rewardKTY, uint256 rewardSDAO, uint256 startBatchNumber, uint256 endBatchNumber)
    {
        // to do
    }

    /**
     * @notice Calculate the rewards (KittieFightToken and SuperDaoToken) by the batch number of deposits
     *         made by a staker
     * @param _staker address the address of the staker for whom the rewards are calculated
     * @param _batchNumber the batch number of the deposits made by _staker
     * @return unit256 the amount of KittieFightToken rewards associated with the _batchNumber of this _staker
     * @return unit256 the amount of SuperDaoToken rewards associated with the _batchNumber of this _staker
     */
    function calculateRewardsByBatchNumber(address _staker, uint256 _batchNumber)
        public view
        returns (uint256 rewardKTY, uint256 rewardSDAO)
    {
        // to do
    }

    /**
     * @return uint256 the total amount of Uniswap Liquidity tokens locked in this contract
     */
    function getTotalLiquidityTokenLocked() public view returns (uint256) {
        return totalLockedLP;
    }

    /**
     * @return uint256 the total amount of KittieFightToken that have been claimed
     * @return uint256 the total amount of SuperDaoToken that have been claimed
     */
    function getTotalRewardsClaimed() public view returns (uint256, uint256) {
        uint256 totalKTYclaimed = totalRewardsKTYclaimed;
        uint256 totalSDAOclaimed = totalRewardsSDAOclaimed;
        return (totalKTYclaimed, totalSDAOclaimed);
    }

    /**
     * @return uint256 
     */
    function getAPY() public view returns (uint256) {
        // to do
    }

    /**
     * @return uint256 the Reward Multiplier for KittieFightToken
     * @return uint256 the Reward Multiplier for SuperDaoFightToken
     */
    function getRewardMultipliers() public view returns (uint256, uint256) {
        // to do
    }

    /**
     * @return uint256 the accrued KittieFightToken rewards
     * @return uint256 the accrued SuperDaoFightToken rewards
     */
    function getAccruedRewards() public view returns (uint256, uint256) {
        // to do
    }

    /**
     * @return uint256 the total amount of KittieFightToken rewards
     * @return uint256 the total amount of SuperDaoFightToken rewards
     */
    function getTotalRewards() public view returns (uint256, uint256) {
        return (totalRewardsKTY, totalRewardsSDAO);
    }

    /**
     * @return uint256 the total amount of Uniswap Liquidity tokens deposited
     *         including both locked tokens and withdrawn tokens
     */
    function getTotalDeposits() public view returns (uint256) {
        return totalDepositedLP;
    }

    /**
     * @return uint256 the total amount of KittieFightToken rewards yet to be distributed
     * @return uint256 the total amount of SuperDaoFightToken rewards yet to be distributed
     */
    function getLockedRewards() public view returns (uint256, uint256) {
        return (lockedRewardsKTY, lockedRewardsSDAO);
    }

    /**
     * @return uint256 the total amount of KittieFightToken rewards already distributed
     * @return uint256 the total amount of SuperDaoFightToken rewards already distributed
     */
    function getUnlockedRewards() public view returns (uint256, uint256) {
        uint256 unlockedKTY = totalRewardsKTY.sub(lockedRewardsKTY);
        uint256 unlockedSDAO = totalRewardsSDAO.sub(lockedRewardsSDAO);
        return (unlockedKTY, unlockedSDAO);
    }

    /**
     * @return uint256 the entire param duration
     * @return uint256 the entire param duration in Months
     * @return uint256 the param duration elapsed in Months
     */
    function getProgramDuration() public view returns (uint256, uint256, uint256) {
        // to do
    }

    /**
     * @param _month uint256 the month (from 0 to 5) for which the Reward Unlock Rate is returned
     * @return uint256 the Reward Unlock Rate for KittieFightToken for the _month
     * @return uint256 the Reward Unlock Rate for SuperDaoToken for the _month
     */
    function getRewardUnlockRate(uint256 _month) public view returns (uint256, uint256) {
        uint256 _KTYunlockRate = KTYunlockRates[_month];
        uint256 _SDAOunlockRate = SDAOunlockRates[_month];
        return (_KTYunlockRate, _SDAOunlockRate);
    }

    /*                                                 INTERNAL FUNCTIONS                                             */
    /* ============================================================================================================== */

    /**
     * @dev    Internal functions used in function deposit()
     * @param _sender address the address of the sender
     * @param _amount uint256 the amount of Uniswap Liquidity tokens to be deposited
     * @param _lockedAt uint256 the time when this depoist is made
     */
    function _addDeposit(address _sender, uint256 _amount, uint256 _lockedAt) internal {
        // get total deposit times for msgSender
        uint256 depositTimes = stakers[_sender].totalDepositTimes.add(1);
        stakers[_sender].totalDepositTimes = depositTimes;
        stakers[_sender].totalLPLocked = stakers[_sender].totalLPLocked.add(_amount);
        stakers[_sender].allBatches.push(_amount);

        uint256 batchNumber = depositTimes.sub(1);
        deposits[_sender][batchNumber].amountLP = _amount;
        deposits[_sender][batchNumber].lockedAt = block.timestamp;

        totalDepositedLP = totalDepositedLP.add(_amount);
        totalLockedLP = totalLockedLP.add(_amount);

        emit Deposited(msg.sender, batchNumber, _amount, _lockedAt);
    }

    /**
     * @dev Internal functions used in function withdrawByAmount(), to deduct deposits from mapping deposits storage
     * @param _sender address the address of the sender
     * @param _amount uint256 the amount of Uniswap Liquidity tokens to be deposited
     * @param _startBatchNumber uint256 the starting batch number from which the _amount of Liquidity tokens 
                                of the _sender is allocated
     * @param _endBatchNumber uint256 the ending batch number until which the _amount of Liquidity tokens 
                                of the _sender is allocated
     */
    function _deductDeposits
    (
        address _sender,
        uint256 _amount,
        uint256 _startBatchNumber,
        uint256 _endBatchNumber
    ) 
        internal 
    {
        uint256 withdrawAmount = 0;
        for (uint256 i = _startBatchNumber; i < _endBatchNumber; i++) {
            withdrawAmount = withdrawAmount.add(deposits[_sender][i].amountLP);
            deposits[_sender][i].amountLP = 0;
            deposits[_sender][i].lockedAt = 0;
            stakers[_sender].allBatches[i] = 0;
        }
        uint256 leftAmountLP = _amount.sub(withdrawAmount);
        if (leftAmountLP >= deposits[_sender][_endBatchNumber].amountLP) {
            deposits[_sender][_endBatchNumber].amountLP = 0;
            deposits[_sender][_endBatchNumber].lockedAt = 0;
            stakers[_sender].allBatches[_endBatchNumber] = 0;
        } else {
            deposits[_sender][_endBatchNumber].amountLP = deposits[_sender][_endBatchNumber].amountLP.sub(leftAmountLP);
            stakers[_sender].allBatches[_endBatchNumber] = deposits[_sender][_endBatchNumber].amountLP;
        }  
    }

    /**
     * @param _sender address the address of the _sender to whom the tokens are transferred
     * @param _amountLP uint256 the amount of Uniswap Liquidity tokens to be transferred to the _user
     * @param _amountKTY uint256 the amount of KittieFightToken to be transferred to the _user
     * @param _amountSDAO uint256 the amount of SuperDaoToken to be transferred to the _user
     */
    function _withdraw (address _sender, uint256 _amountLP, uint256 _amountKTY, uint256 _amountSDAO)
        internal
    {
        _updateWithdraw(_sender, _amountLP, _amountKTY, _amountSDAO);
        _transferTokens(_sender, _amountLP, _amountKTY, _amountSDAO);
    }

    /**
     * @param _sender address the address of the sender
     * @param _KTY uint256 the amount of KittieFightToken
     * @param _SDAO uint256 the amount of SuperDaoToken
     * @param _LP uint256 the amount of Uniswap Liquidity tokens
     */
    function _updateWithdraw (address _sender, uint256 _LP, uint256 _KTY, uint256 _SDAO) internal {
        // update staker info
        stakers[_sender].totalLPLocked = stakers[_sender].totalLPLocked.sub(_LP);
        stakers[_sender].rewardsKTYclaimed = stakers[msg.sender].rewardsKTYclaimed.add(_KTY);
        stakers[_sender].rewardsSDAOclaimed = stakers[_sender].rewardsSDAOclaimed.add(_SDAO);
        // update public variables
        totalRewardsKTYclaimed = totalRewardsKTYclaimed.add(_KTY);
        totalRewardsSDAOclaimed = totalRewardsSDAOclaimed.add(_SDAO);
        totalLockedLP = totalLockedLP.sub(_LP);
    }

    /**
     * @param _user address the address of the _user to whom the tokens are transferred
     * @param _amountLP uint256 the amount of Uniswap Liquidity tokens to be transferred to the _user
     * @param _amountKTY uint256 the amount of KittieFightToken to be transferred to the _user
     * @param _amountSDAO uint256 the amount of SuperDaoToken to be transferred to the _user
     */
    function _transferTokens(address _user, uint256 _amountLP, uint256 _amountKTY, uint256 _amountSDAO)
        internal
    {
        // transfer liquidity tokens, KTY and SDAO to the staker
        require(LP.transfer(_user, _amountLP), "Fail to transfer liquidity token");
        require(kittieFightToken.transfer(_user, _amountKTY), "Fail to transfer KTY");
        require(superDaoToken.transfer(_user, _amountSDAO), "Fail to transfer SDAO");
    }

}