pragma solidity ^0.5.5;

import "../libs/openzeppelin_upgradable_v2_5_0/ownership/Ownable.sol";
import "../libs/SafeMath.sol";
import './YieldFarming.sol';
import './YieldFarmingHelper.sol';

contract YieldsCalculator is Ownable {
    using SafeMath for uint256;

    /*                                               GENERAL VARIABLES                                                */
    /* ============================================================================================================== */

    YieldFarming public yieldFarming;
    YieldFarmingHelper public yieldFarmingHelper;

    uint256 constant public base18 = 1000000000000000000;
    uint256 constant public base6 = 1000000;

    uint256 constant public MONTH = 24 * 60 * 60;// 30 * 24 * 60 * 60;  // MONTH duration is 30 days, to keep things standard
    uint256 constant public DAY = 48 * 60;// 24 * 60 * 60;
    uint256 constant DAILY_PORTION_IN_MONTH = 33333;

    // proportionate a month into 30 parts, each part is 0.033333 * 1000000 = 33333
    uint256 constant public monthDays = MONTH / DAY;

    // total amount of KTY sold
    uint256 internal tokensSold;

    /*                                                   INITIALIZER                                                  */
    /* ============================================================================================================== */

    function initialize
    (
        uint256 _tokensSold,
        YieldFarming _yieldFarming,
        YieldFarmingHelper _yieldFarmingHelper
    ) 
        public initializer
    {
        Ownable.initialize(_msgSender());
        tokensSold = _tokensSold;
        setYieldFarming(_yieldFarming);
        setYieldFarmingHelper(_yieldFarmingHelper);
    }

    /*                                                 SETTER FUNCTIONS                                               */
    /* ============================================================================================================== */

    /**
     * @dev Set Uniswap KTY-Weth Pair contract
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setYieldFarming(YieldFarming _yieldFarming) public onlyOwner {
        yieldFarming = _yieldFarming;
    }

    /**
     * @dev Set Uniswap KTY-Weth Pair contract
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setYieldFarmingHelper(YieldFarmingHelper _yieldFarmingHelper) public onlyOwner {
        yieldFarmingHelper = _yieldFarmingHelper;
    }

    function setTokensSold(uint256 _tokensSold) public onlyOwner {
        tokensSold = _tokensSold;
    }

    /*                                                 GETTER FUNCTIONS                                               */
    /* ============================================================================================================== */

    /**
     * @notice Allocate a sepcific amount of Uniswap Liquidity tokens locked by a staker to batches
     * @param _staker address the address of the staker for whom the rewards are calculated
     * @param _amountLP the amount of Uniswap Liquidity tokens locked
     * @param _pairCode uint256 Pair Code assocated with a Pair Pool 
     * @return unit256 the Batch Number of the starting batch to which LP is allocated
     * @return unit256 the Batch Number of the end batch to which LP is allocated
     * @return bool true if all the LP locked in the end batch is allocated, false if there is residual
               amount left in the end batch after allocation
     * @dev    FIFO (First In, First Out) is used to allocate the amount of liquidity tokens to the batches of deposits of this staker
     */
    function allocateLP(address _staker, uint256 _amountLP, uint256 _pairCode)
        public view returns (uint256, uint256, uint256)
    {
        uint256 startBatchNumber;
        uint256 endBatchNumber;
        uint256[] memory allBatches = yieldFarming.getAllBatchesPerPairPool(_staker, _pairCode);
        uint256 residual;

        for (uint256 m = 0; m < allBatches.length; m++) {
            if (allBatches[m] > 0) {
                startBatchNumber = m;
                break;
            }
        }
        
        for (uint256 i = startBatchNumber; i < allBatches.length; i++) {
            if (_amountLP <= allBatches[i]) {
                if (_amountLP == allBatches[i]) {
                    residual = 0;
                } else {
                    residual = allBatches[i].sub(_amountLP);
                }
                endBatchNumber = i;
                break;
            } else {
                _amountLP = _amountLP.sub(allBatches[i]);
            }
        }

        return (startBatchNumber, endBatchNumber, residual);
    }

    /**
     * @param _time uint256 The time point for which the month number is enquired
     * @return uint256 the month in which the time point _time is
     */
    function getMonth(uint256 _time) public view returns (uint256) {
        uint256 month;
        uint256 monthStartTime;

        for (uint256 i = 5; i >= 0; i--) {
            monthStartTime = yieldFarming.getMonthStartAt(i);
            if (_time >= monthStartTime) {
                month = i;
                break;
            }
        }
        return month;
    }

    /**
     * @param _time uint256 The time point for which the day number is enquired
     * @return uint256 the day in which the time point _time is
     */
    function getDay(uint256 _time) public view returns (uint256) {
        uint256 _programStartAt = yieldFarming.programStartAt();
        if (_time <= _programStartAt) {
            return 0;
        }
        uint256 elapsedTime = _time.sub(_programStartAt);
        return elapsedTime.div(DAY);
    }

    /**
     * @dev Get the starting month, ending month, and days in starting month during which the locked Liquidity
     *      tokens in _staker's _batchNumber associated with _pairCode are locked and eligible for rewards.
     * @dev The ending month is the month preceding the current month.
     */
    function getLockedPeriod(address _staker, uint256 _batchNumber, uint256 _pairCode)
        public view
        returns (
            uint256 _startingMonth,
            uint256 _endingMonth,
            uint256 _daysInStartMonth
        )
    {
        uint256 _currentMonth = yieldFarming.getCurrentMonth();
        (,,,uint256 _lockedAt) = yieldFarming.getLPinBatch(_staker, _pairCode, _batchNumber);
        uint256 _startingDay = getDay(_lockedAt);
        uint256 _programEndAt = yieldFarming.programEndAt();

        _startingMonth = getMonth(_lockedAt); 
        _endingMonth = _currentMonth == 0 ? 0 : block.timestamp > _programEndAt ? 5 : _currentMonth.sub(1);
        _daysInStartMonth = 30 - getElapsedDaysInMonth(_startingDay, _startingMonth);
    }

    /**
     * @return unit256 the current day
     * @dev    There are 180 days in this program in total, starting from day 0 to day 179.
     */
    function getCurrentDay() public view returns (uint256) {
        uint256 programStartTime = yieldFarming.programStartAt();
        if (block.timestamp <= programStartTime) {
            return 0;
        }
        uint256 elapsedTime = block.timestamp.sub(programStartTime);
        uint256 currentDay = elapsedTime.div(DAY);
        return currentDay;
    }

    /**
     * @param _days uint256 which day since this program starts
     * @param _month uint256 which month since this program starts
     * @return unit256 the number of days that have elapsed in this _month
     */
    function getElapsedDaysInMonth(uint256 _days, uint256 _month) public view returns (uint256) {
        // In the first month
        if (_month == 0) {
            return _days;
        }

        // In the other months
        // Get the unix time for _days
        uint256 month0StartTime = yieldFarming.getMonthStartAt(0);
        uint256 dayInUnix = _days.mul(DAY).add(month0StartTime);
        // If _days are before the start of _month, then no day has been elapsed
        uint256 monthStartTime = yieldFarming.getMonthStartAt(_month);
        if (dayInUnix <= monthStartTime) {
            return 0;
        }
        // get time elapsed in seconds
        uint256 timeElapsed = dayInUnix.sub(monthStartTime);
        return timeElapsed.div(DAY);
    }

     /**
     * @return unit256 time in seconds until the current month ends
     */
    function timeUntilCurrentMonthEnd() public view returns (uint) {
        uint256 nextMonth = yieldFarming.getCurrentMonth().add(1);
        if (nextMonth > 5) {
            if (block.timestamp >= yieldFarming.getMonthStartAt(5).add(MONTH)) {
                return 0;
            }
            return MONTH.sub(block.timestamp.sub(yieldFarming.getMonthStartAt(5)));
        }
        return yieldFarming.getMonthStartAt(nextMonth).sub(block.timestamp);
    }

    function calculateYields2(address _staker, uint256 _pairCode, uint256 startBatchNumber, uint256 lockedLP, uint256 startingLP)
        internal view
        returns (uint256 yieldsKTY, uint256 yieldsSDAO) {
        (uint256 _startingMonth, uint256 _endingMonth,) = getLockedPeriod(_staker, startBatchNumber, _pairCode);
        return calculateYields(_startingMonth, _endingMonth, lockedLP, startingLP);
    }

    function calculateYields(uint256 startMonth, uint256 endMonth, uint256 lockedLP, uint256 startingLP)
        internal view
        returns (uint256 yieldsKTY, uint256 yieldsSDAO)
    {
        (uint256 yields_part_1_KTY, uint256 yields_part_1_SDAO) = calculateYields_part_1(startMonth, startingLP);
        uint256 yields_part_2_KTY;
        uint256 yields_part_2_SDAO;
        if (endMonth > startMonth) {
            (yields_part_2_KTY, yields_part_2_SDAO) = calculateYields_part_2(startMonth, endMonth, lockedLP);
        }        
        return (yields_part_1_KTY.add(yields_part_2_KTY), yields_part_1_SDAO.add(yields_part_2_SDAO));
    }

    function calculateYields_part_1(uint256 startMonth, uint256 startingLP)
        internal view
        returns (uint256 yields_part_1_KTY, uint256 yields_part_1_SDAO)
    {
        // yields KTY in startMonth
        uint256 rewardsKTYstartMonth = getTotalKTYRewardsByMonth(startMonth);
        uint256 rewardsSDAOstartMonth = getTotalSDAORewardsByMonth(startMonth);
        uint256 adjustedMonthlyDeposit = yieldFarming.getAdjustedTotalMonthlyDeposits(startMonth);

        yields_part_1_KTY = rewardsKTYstartMonth.mul(startingLP).div(adjustedMonthlyDeposit);
        yields_part_1_SDAO = rewardsSDAOstartMonth.mul(startingLP).div(adjustedMonthlyDeposit);
    }

    function calculateYields_part_2(uint256 startMonth, uint256 endMonth, uint256 lockedLP)
        internal view
        returns (uint256 yields_part_2_KTY, uint256 yields_part_2_SDAO)
    {
        uint256 adjustedMonthlyDeposit;
        // yields KTY in endMonth and other month between startMonth and endMonth
        for (uint256 i = startMonth.add(1); i <= endMonth; i++) {
            uint256 monthlyRewardsKTY = getTotalKTYRewardsByMonth(i);
            uint256 monthlyRewardsSDAO = getTotalSDAORewardsByMonth(i);
            adjustedMonthlyDeposit = yieldFarming.getAdjustedTotalMonthlyDeposits(i);
            yields_part_2_KTY = yields_part_2_KTY.add(monthlyRewardsKTY.mul(lockedLP).div(adjustedMonthlyDeposit));
            yields_part_2_SDAO = yields_part_2_SDAO.add(monthlyRewardsSDAO.mul(lockedLP).div(adjustedMonthlyDeposit));
        }
         
    }

    /**
     * @notice Calculate the rewards (KittieFightToken and SuperDaoToken) by the batch number of deposits
     *         made by a staker
     * @param _staker address the address of the staker for whom the rewards are calculated
     * @param _batchNumber the deposit number of the deposits made by _staker
     * @param _pairCode uint256 Pair Code assocated with a Pair Pool 
     * @return unit256 the amount of KittieFightToken rewards associated with the _batchNumber of this _staker
     * @return unit256 the amount of SuperDaoToken rewards associated with the _batchNumber of this _staker
     */
    function calculateRewardsByBatchNumber(address _staker, uint256 _batchNumber, uint256 _pairCode)
        public view
        returns (uint256, uint256)
    {
        uint256 rewardKTY;
        uint256 rewardSDAO;

        // If the batch is locked less than 30 days, rewards are 0.
        if (!isBatchEligibleForRewards(_staker, _batchNumber, _pairCode)) {
            return(0, 0);
        }

        (,uint256 adjustedLockedLP, uint256 adjustedStartingLP,) = yieldFarming.getLPinBatch(_staker, _pairCode, _batchNumber);

        // calculate KittieFightToken rewards
        (rewardKTY, rewardSDAO) = calculateYields2(_staker, _pairCode, _batchNumber, adjustedLockedLP, adjustedStartingLP);

        // If the program ends
        if (block.timestamp >= yieldFarming.programEndAt()) {
            // if eligible for Early Mining Bonus, add the rewards for early bonus
            if (yieldFarming.isBatchEligibleForEarlyBonus(_staker, _batchNumber, _pairCode)) {
                uint256 _earlyBonus = getEarlyBonus(adjustedLockedLP);
                rewardKTY = rewardKTY.add(_earlyBonus);
                rewardSDAO = rewardSDAO.add(_earlyBonus);
            }
        }

        return (rewardKTY, rewardSDAO);
    }

    function calculateRewardsByAmountCase1
    (address _staker, uint256 _pairCode, uint256 _amountLP,
     uint256 startBatchNumber)
        internal view
        returns (uint256 rewardKTY, uint256 rewardSDAO)
    {
        uint256 earlyBonus;
        uint256 adjustedLockedLP;
        uint256 adjustedStartingLP;

        // // allocate _amountLP per FIFO
        // (startBatchNumber, endBatchNumber, residual) = allocateLP(_staker, _amountLP, _pairCode);
        if (!isBatchEligibleForRewards(_staker, startBatchNumber, _pairCode)) {
            rewardKTY = 0;
            rewardSDAO = 0;
        } else {
            (,adjustedLockedLP, adjustedStartingLP,) = yieldFarming.getLPinBatch(_staker, _pairCode, startBatchNumber);

            uint256 _adjustedStartingLP = _amountLP.mul(adjustedStartingLP).div(adjustedLockedLP);

            (rewardKTY, rewardSDAO) = calculateYields2(_staker, _pairCode, startBatchNumber, _amountLP, _adjustedStartingLP);

            // check if early mining bonus applies here
            if (block.timestamp >= yieldFarming.programEndAt() && yieldFarming.isBatchEligibleForEarlyBonus(_staker,startBatchNumber, _pairCode)) {
                earlyBonus = getEarlyBonus(adjustedLockedLP);
                rewardKTY = rewardKTY.add(earlyBonus);
                rewardSDAO = rewardKTY.add(earlyBonus);
            }
        }
    }

    function calculateRewardsByAmountCase2
    (address _staker, uint256 _pairCode,
     uint256 startBatchNumber, uint256 endBatchNumber)
        internal view
        returns (uint256 rewardKTY, uint256 rewardSDAO)
    {
        uint256 earlyBonus;
        uint256 adjustedLockedLP;
        uint256 adjustedStartingLP;

        for (uint256 i = startBatchNumber; i <= endBatchNumber; i++) {
            // if this batch is eligible for claiming rewards, we calculate its rewards and add to total rewards for this staker
            if(isBatchEligibleForRewards(_staker, i, _pairCode)) {
                // lockedLP = stakers[_staker].batchLockedLPamount[_pairCode][i];
                (,adjustedLockedLP, adjustedStartingLP,) = yieldFarming.getLPinBatch(_staker, _pairCode, i);

                (rewardKTY, rewardSDAO) = calculateYields2(_staker, _pairCode, i, adjustedLockedLP, adjustedStartingLP);

                // if eligible for early bonus, the rewards for early bonus is added for this batch
                if (block.timestamp >= yieldFarming.programEndAt() && yieldFarming.isBatchEligibleForEarlyBonus(_staker, i, _pairCode)) {
                    earlyBonus = getEarlyBonus(adjustedLockedLP);
                    rewardKTY = rewardKTY.add(earlyBonus);
                    rewardSDAO = rewardSDAO.add(earlyBonus);
                } 
            } 
        }
        
    }
    
    /**
     * @notice Calculate the rewards (KittieFightToken and SuperDaoToken) by the amount of Uniswap Liquidity tokens 
     *         locked by a staker
     * @param _staker address the address of the staker for whom the rewards are calculated
     * @param _pairCode uint256 Pair Code assocated with a Pair Pool 
     * @return unit256 the amount of KittieFightToken rewards associated with the _amountLP lockec by this _staker
     * @return unit256 the amount of SuperDaoToken rewards associated with the _amountLP lockec by this _staker
     * @return uint256 the starting batch number of deposit from which the amount of Uniswap Liquidity tokens are allocated
     * @return uint256 the ending batch number of deposit from which the amount of Uniswap Liquidity tokens are allocated
     * @dev    FIFO (First In, First Out) is used to allocate the amount of liquidity tokens to the batches of deposits of this staker
     */
    function calculateRewardsByAmountResidual
    (address _staker, uint256 _pairCode, uint256 endBatchNumber, uint256 residual)
        internal view
        returns (uint256 rewardKTY, uint256 rewardSDAO)
    {
        uint256 earlyBonus;

        // add rewards for end Batch from which only part of the locked amount is to be withdrawn
        if(isBatchEligibleForRewards(_staker, endBatchNumber, _pairCode)) {
            uint256 factor = yieldFarming.getFactorInBatch(_staker, _pairCode, endBatchNumber);
            uint256 adjustedLockedLP = residual.mul(base6).div(factor);

            (,, uint256 adjustedStartingLP,) = yieldFarming.getLPinBatch(_staker, _pairCode, endBatchNumber);
    
            (rewardKTY, rewardSDAO) = calculateYields2(_staker, _pairCode, endBatchNumber, adjustedLockedLP, adjustedStartingLP);

            if (block.timestamp >= yieldFarming.programEndAt() && yieldFarming.isBatchEligibleForEarlyBonus(_staker, endBatchNumber, _pairCode)) {
                earlyBonus = getEarlyBonus(adjustedLockedLP);
                rewardKTY = rewardKTY.add(earlyBonus);
                rewardSDAO = rewardSDAO.add(earlyBonus);
            }
        }    
    }

    /**
     * @param _staker address the staker who has deposited Uniswap Liquidity tokens
     * @param _batchNumber uint256 the batch number of which deposit the staker wishes to see the locked amount
     * @param _pairCode uint256 Pair Code assocated with a Pair Pool 
     * @return bool true if the batch with the _batchNumber in the _pairCode of the _staker is eligible for claiming yields, false if it is not eligible.
     * @dev    A batch needs to be locked for at least 30 days to be eligible for claiming yields.
     * @dev    A batch locked for less than 30 days has 0 rewards, although the locked Liquidity tokens can be withdrawn at any time.
     */
    function isBatchEligibleForRewards(address _staker, uint256 _batchNumber, uint256 _pairCode)
        public view returns (bool)
    {
        // get locked time
        (,,,uint256 lockedAt) = yieldFarming.getLPinBatch(_staker, _pairCode, _batchNumber);
      
        if (lockedAt == 0) {
            return false;
        }
        // get total locked duration
        uint256 lockedPeriod = block.timestamp.sub(lockedAt);
        // a minimum of 30 days of staking is required to be eligible for claiming rewards
        if (lockedPeriod >= MONTH) {
            return true;
        }
        return false;
    }

    function getTotalRewards()
        external view
       returns (uint256[6] memory ktyRewards, uint256[6] memory sdaoRewards)
    {
        uint256 _ktyReward;
        uint256 _sdaoReward;
        for (uint256 i = 0; i < 6; i++) {
            _ktyReward = getTotalKTYRewardsByMonth(i);
            _sdaoReward = getTotalSDAORewardsByMonth(i);
            ktyRewards[i] = _ktyReward;
            sdaoRewards[i] = _sdaoReward;
        }
    }

    /**
     * @param _month uint256 the month (from 0 to 5) for which the Reward Unlock Rate is returned
     * @return uint256 the amount of total Rewards for KittieFightToken for the _month
     * @return uint256 the amount of total Rewards for SuperDaoToken for the _month
     */
    function getTotalKTYRewardsByMonth(uint256 _month)
        public view 
        returns (uint256)
    {
        uint256 _totalRewardsKTY = yieldFarming.totalRewardsKTY();
        (uint256 _KTYunlockRate,) = yieldFarming.getRewardUnlockRateByMonth(_month);
        uint256 _earlyBonus = yieldFarming.EARLY_MINING_BONUS();
        return (_totalRewardsKTY.sub(_earlyBonus)).mul(_KTYunlockRate).div(base6);
    }

    function getTotalSDAORewardsByMonth(uint256 _month)
        public view 
        returns (uint256)
    {
        uint256 _totalRewardsSDAO = yieldFarming.totalRewardsSDAO();
        (,uint256 _SDAOunlockRate) = yieldFarming.getRewardUnlockRateByMonth(_month);
        uint256 _earlyBonus = yieldFarming.EARLY_MINING_BONUS();
        return (_totalRewardsSDAO.sub(_earlyBonus)).mul(_SDAOunlockRate).div(base6);
    }

    /**
     * @param _amountLP the amount of locked Liquidity token eligible for claiming early bonus
     * @return uint256 the amount of early bonus for this _staker. Since the amount of early bonus is the same
     *         for KittieFightToken and SuperDaoToken, only one number is returned.
     */
    function getEarlyBonus(uint256 _amountLP)
        public view returns (uint256)
    {
        uint256 _earlyBonus = yieldFarming.EARLY_MINING_BONUS();
        uint256 _adjustedTotalLockedLPinEarlyMining = yieldFarming.adjustedTotalLockedLPinEarlyMining();
    
        return _amountLP.mul(_earlyBonus).div(_adjustedTotalLockedLPinEarlyMining);
    }

    function calculateRewardsByDepositNumber(address _staker, uint256 _depositNumber)
        external view
        returns (uint256, uint256)
    {
        (uint256 _pairCode, uint256 _batchNumber) = yieldFarming.getBatchNumberAndPairCode(_staker, _depositNumber); 
        (uint256 _rewardKTY, uint256 _rewardSDAO) = calculateRewardsByBatchNumber(_staker, _batchNumber, _pairCode);
        return (_rewardKTY, _rewardSDAO);
    }

    function calculateRewardsByAmount(address _staker, uint256 _LPamount, uint256 _pairCode)
        public view
        returns (uint256, uint256, uint256, uint256)
    {
        // allocate _amountLP per FIFO
        (uint256 startBatchNumber, uint256 endBatchNumber, uint256 residual) = allocateLP(_staker, _LPamount, _pairCode);
        uint256 _KTY;
        uint256 _SDAO;

        if (startBatchNumber == endBatchNumber) {
            (_KTY, _SDAO) = calculateRewardsByAmountCase1(_staker, _pairCode, _LPamount, startBatchNumber);
          
        } else if (startBatchNumber < endBatchNumber && residual == 0) {
            (_KTY, _SDAO) = calculateRewardsByAmountCase2(_staker, _pairCode, startBatchNumber, endBatchNumber);
           
        } else if (startBatchNumber < endBatchNumber && residual > 0) {
            (_KTY, _SDAO) = calculateRewardsByAmountCase2(_staker, _pairCode, startBatchNumber, endBatchNumber.sub(1));
            (uint256 _KTYresidual, uint256 _SDAOresidual) = calculateRewardsByAmountResidual(_staker, _pairCode, endBatchNumber, residual);
            _KTY = _KTY.add(_KTYresidual);
            _SDAO = _SDAO.add(_SDAOresidual);
           
        }
        return (_KTY, _SDAO, startBatchNumber, endBatchNumber);
    }

    function getTotalLPsLocked(address _staker) public view returns (uint256) {
        uint256 _totalPools = yieldFarming.totalNumberOfPairPools();
        uint256 _totalLPs;
        uint256 _LP;
        for (uint256 i = 0; i < _totalPools; i++) {
            _LP = yieldFarming.getLockedLPbyPairCode(_staker, i);
            _totalLPs = _totalLPs.add(_LP);
        }
        return _totalLPs;
    }

    /**
     * This should actually take users address as parameter to check total LP tokens locked.
       Then it should calculate possible APY, proportional to lp tokens locked, over the 6 month 
       program duration. Proportional meaning, total personal amount of LP tokens LOCKED relative
       and what total percentage of the 7000,000 KTY and SDAO tokens to be earned over the next 6 months.
     * @return uint256 APY amplified 1000000 times to avoid float imprecision
     */
    function getAPY(address _staker) external view returns (uint256) {
        uint256 totalRewards = yieldFarming.totalRewardsKTY();
        // get total number of LPs deposited
        uint256 totalLPs = getTotalLPsLocked(_staker);

        if (totalLPs == 0) {
            return 0;
        }
        // return APY calculated
        return totalLPs.mul(base6).mul(totalRewards).div(tokensSold).div(base18);
    }

    /**
     * This should actually take users address as parameter to check total LP tokens locked.
       Its same as apy for individual but in number form, i.e Total tokens allocated in the duration
       of the yield farming program, divided by estimated personal allocation based on How much the
       total personal lp tokens locked
     * @return uint256 the Reward Multiplier for KittieFightToken, amplified 1000000 times to avoid float imprecision
     * @return uint256 the Reward Multiplier for SuperDaoFightToken, amplified 1000000 times to avoid float imprecision
     */
    function getRewardMultipliers(address _staker) external view returns (uint256, uint256) {
        uint256 totalLPs = getTotalLPsLocked(_staker);
        if (totalLPs == 0) {
            return (0, 0);
        }
        uint256 totalRewards = yieldFarming.totalRewardsKTY();
        (uint256 rewardsKTY, uint256 rewardsSDAO) = getRewardsToClaim(_staker);
        uint256 rewardMultiplierKTY = rewardsKTY.mul(base6).mul(totalRewards).div(tokensSold).div(totalLPs);
        uint256 rewardMultiplierSDAO = rewardsSDAO.mul(base6).mul(totalRewards).div(tokensSold).div(totalLPs);
        return (rewardMultiplierKTY, rewardMultiplierSDAO);
    }

    /**
     * @notice This function returns already earned tokens by the _staker
     * @return uint256 the accrued KittieFightToken rewards
     * @return uint256 the accrued SuperDaoFightToken rewards
     */
    function getAccruedRewards(address _staker) public view returns (uint256, uint256) {
        // get rewards already claimed
        (uint256 _claimedKTY, uint256 _claimedSDAO) = yieldFarming.getTotalRewardsClaimedByStaker(_staker);

        // get rewards earned but yet to be claimed
        (uint256 _KTYtoClaim, uint256 _SDAOtoClaim) = getRewardsToClaim(_staker);

        return (_claimedKTY.add(_KTYtoClaim), _claimedSDAO.add(_SDAOtoClaim));  
    }

    function getRewardsToClaim(address _staker) internal view returns (uint256, uint256) {
        uint256 _KTY = 0;
        uint256 _SDAO = 0;
       
        // get rewards earned but yet to be claimed
        uint256 _totalPools = yieldFarming.totalNumberOfPairPools();
        uint256 _ktyRewards;
        uint256 _sdaoRewards;
        uint256 _LP;
        for (uint256 i = 0; i < _totalPools; i++) {
            _LP = yieldFarming.getLockedLPbyPairCode(_staker, i);
            if (_LP > 0) {
                (_ktyRewards, _sdaoRewards,,) = calculateRewardsByAmount(_staker, _LP, i);
                _KTY = _KTY.add(_ktyRewards);
                _SDAO = _SDAO.add(_sdaoRewards);
            }
        }

        return (_KTY, _SDAO);  
    }

    function getFirstMonthAmount(
        uint256 startDay,
        uint256 startMonth,
        uint256 adjustedMonthlyDeposit,
        uint256 _LP
    )
    public view returns(uint256)
    {        
        uint256 monthlyProportion = getElapsedDaysInMonth(startDay, startMonth);
        return adjustedMonthlyDeposit
            .mul(_LP.mul(monthDays.sub(monthlyProportion)))
            .div(adjustedMonthlyDeposit.add(monthlyProportion.mul(_LP).div(monthDays)))
            .div(monthDays);
    }

    function estimateRewards(uint256 _LP, uint256 _pairCode) external view returns (uint256, uint256) {
        uint256 startMonth = yieldFarming.getCurrentMonth();
        uint256 startDay = getDay(block.timestamp);
        uint256 factor = yieldFarmingHelper.bubbleFactor(_pairCode);
        uint256 adjustedLP = _LP.mul(base6).div(factor);
        
        uint256 adjustedMonthlyDeposit = yieldFarming.getAdjustedTotalMonthlyDeposits(startMonth);

        uint256 currentDepositedAmount = getFirstMonthAmount(startDay, startMonth, adjustedMonthlyDeposit, adjustedLP);

        (uint256 _KTY, uint256 _SDAO) = estimateYields(startMonth, 5, adjustedLP, currentDepositedAmount, adjustedMonthlyDeposit);

        // if eligible for Early Mining Bonus, add the rewards for early bonus
        uint256 startTime = yieldFarming.programStartAt();
        if (block.timestamp <= startTime.add(DAY.mul(21))){
            uint256 _earlyBonus = estimateEarlyBonus(adjustedLP);
            _KTY = _KTY.add(_earlyBonus);
            _SDAO = _SDAO.add(_earlyBonus);
        }

        return (_KTY, _SDAO);
    }

    // These internal functions are for estimating rewards only
    function estimateYields(uint256 startMonth, uint256 endMonth, uint256 lockedLP, uint256 startingLP, uint256 adjustedMonthlyDeposit)
        internal view
        returns (uint256, uint256)
    {
        (uint256 yields_part_1_KTY, uint256 yields_part_1_SDAO)= estimateYields_part_1(startMonth, startingLP, adjustedMonthlyDeposit);
        uint256 yields_part_2_KTY;
        uint256 yields_part_2_SDAO;
        if (endMonth > startMonth) {
            (yields_part_2_KTY, yields_part_2_SDAO) = estimateYields_part_2(startMonth, endMonth, lockedLP, adjustedMonthlyDeposit);
        }
        return (yields_part_1_KTY.add(yields_part_2_KTY), yields_part_1_SDAO.add(yields_part_2_SDAO));
    }

    function estimateYields_part_1(uint256 startMonth, uint256 startingLP, uint256 adjustedMonthlyDeposit)
        internal view
        returns (uint256 yieldsKTY_part_1, uint256 yieldsSDAO_part_1)
    {
        uint256 rewardsKTYstartMonth = getTotalKTYRewardsByMonth(startMonth);
        uint256 rewardsSDAOstartMonth = getTotalSDAORewardsByMonth(startMonth);
        adjustedMonthlyDeposit = adjustedMonthlyDeposit.add(startingLP);

        yieldsKTY_part_1 = rewardsKTYstartMonth.mul(startingLP).div(adjustedMonthlyDeposit);
        yieldsSDAO_part_1 = rewardsSDAOstartMonth.mul(startingLP).div(adjustedMonthlyDeposit);
    }

    function estimateYields_part_2(uint256 startMonth, uint256 endMonth, uint256 lockedLP, uint256 adjustedMonthlyDeposit)
        internal view
        returns (uint256 yieldsKTY_part_2, uint256 yieldsSDAO_part_2)
    {
        for (uint256 i = startMonth.add(1); i <= endMonth; i++) {
            uint256 monthlyRewardsKTY = getTotalKTYRewardsByMonth(i);
            uint256 monthlyRewardsSDAO = getTotalSDAORewardsByMonth(i);
            yieldsKTY_part_2 = yieldsKTY_part_2
                .add(monthlyRewardsKTY.mul(lockedLP).div(adjustedMonthlyDeposit));
            yieldsSDAO_part_2 = yieldsSDAO_part_2
                .add(monthlyRewardsSDAO.mul(lockedLP).div(adjustedMonthlyDeposit));
        }
         
    }

    function estimateEarlyBonus(uint256 _amountLP)
        public view returns (uint256)
    {
        uint256 _earlyBonus = yieldFarming.EARLY_MINING_BONUS();
        uint256 _adjustedTotalLockedLPinEarlyMining = yieldFarming.adjustedTotalLockedLPinEarlyMining();
        if (_adjustedTotalLockedLPinEarlyMining == 0) {
            _adjustedTotalLockedLPinEarlyMining = _amountLP;
        } else {
            _adjustedTotalLockedLPinEarlyMining = _adjustedTotalLockedLPinEarlyMining.add(_amountLP);
        }
        return _amountLP.mul(_earlyBonus).div(_adjustedTotalLockedLPinEarlyMining);
    }
}
