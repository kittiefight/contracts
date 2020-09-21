pragma solidity ^0.5.5;

import "../authority/Owned.sol";
import '../libs/SafeMath.sol';
import './YieldFarming.sol';
import './YieldFarmingHelper.sol';

contract YieldsCalculator is Owned {
    using SafeMath for uint256;

    YieldFarming public yieldFarming;
    YieldFarmingHelper public yieldFarmingHelper;

   

    uint256 constant public base18 = 1000000000000000000;
    uint256 constant public base6 = 1000000;

    uint256 constant public MONTH = 30 * 24 * 60 * 60; // MONTH duration is 30 days, to keep things standard
    uint256 constant public DAY = 24 * 60 * 60;

    // proportionate a month into 30 parts, each part is 0.033333 * 1000000 = 33333
    uint256 constant public DAILY_PORTION_IN_MONTH = 33333;

    function initialize
    (
        YieldFarming _yieldFarming,
        YieldFarmingHelper _yieldFarmingHelper
    ) 
        public onlyOwner
    {
        setYieldFarming(_yieldFarming);
        setYieldFarmingHelper(_yieldFarmingHelper);
    }

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
        (,,uint256 _lockedAt) = yieldFarming.getLPinBatch(_staker, _pairCode, _batchNumber);
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

    function calculateYieldsKTY(uint256 startMonth, uint256 endMonth, uint256 daysInStartMonth, uint256 lockedLP)
        public view
        returns (uint256 yieldsKTY)
    {
        uint256 yieldsKTY_part_1 = calculateYieldsKTY_part_1(startMonth, daysInStartMonth, lockedLP);
        uint256 yieldsKTY_part_2 = 0;
        if (endMonth > startMonth) {
            yieldsKTY_part_2 = calculateYieldsKTY_part_2(startMonth, endMonth, lockedLP);
        }
        
        yieldsKTY = yieldsKTY_part_2 == 0 ? yieldsKTY_part_1 : yieldsKTY_part_1.add(yieldsKTY_part_2);
    }

    function calculateYieldsKTY_part_1(uint256 startMonth, uint256 daysInStartMonth, uint256 lockedLP)
        internal view
        returns (uint256 yieldsKTY_part_1)
    {
        // yields KTY in startMonth
        uint256 rewardsKTYstartMonth = yieldFarming.getTotalKTYRewardsByMonth(startMonth);
        yieldsKTY_part_1 = rewardsKTYstartMonth.mul(lockedLP).div(yieldFarming.getAdjustedTotalMonthlyDeposits(startMonth))
                    .mul(daysInStartMonth).mul(DAILY_PORTION_IN_MONTH).div(base6);
       
    }

    function calculateYieldsKTY_part_2(uint256 startMonth, uint256 endMonth, uint256 lockedLP)
        internal view
        returns (uint256 yieldsKTY_part_2)
    {
        uint256 monthlyRewardsKTY;
        uint256 adjustedMonthlyDeposit;
        // yields KTY in endMonth and other month between startMonth and endMonth
        for (uint256 i = startMonth.add(1); i <= endMonth; i++) {
            monthlyRewardsKTY = yieldFarming.getTotalKTYRewardsByMonth(i);
            adjustedMonthlyDeposit = yieldFarming.getAdjustedTotalMonthlyDeposits(i);
            yieldsKTY_part_2 = yieldsKTY_part_2
                .add(monthlyRewardsKTY.mul(lockedLP).div(adjustedMonthlyDeposit));
        }
         
    }

    function calculateYieldsSDAO(uint256 startMonth, uint256 endMonth, uint256 daysInStartMonth, uint256 lockedLP)
        public view
        returns (uint256 yieldsSDAO)
    {
        uint256 yieldsSDAO_part_1 = calculateYieldsSDAO_part_1(startMonth, daysInStartMonth, lockedLP);
        uint256 yieldsSDAO_part_2 = 0;
        if (endMonth > startMonth) {
            yieldsSDAO_part_2 = calculateYieldsSDAO_part_2(startMonth, endMonth, lockedLP);
        }
        yieldsSDAO = yieldsSDAO_part_2 == 0 ? yieldsSDAO_part_1 : yieldsSDAO_part_1.add(yieldsSDAO_part_2);
    }

    function calculateYieldsSDAO_part_1(uint256 startMonth, uint256 daysInStartMonth, uint256 lockedLP)
        internal view
        returns (uint256 yieldsSDAO_part_1)
    {
        // yields SDAO in startMonth
        uint256 rewardsSDAOstartMonth = yieldFarming.getTotalSDAORewardsByMonth(startMonth);
        yieldsSDAO_part_1 = rewardsSDAOstartMonth.mul(lockedLP).div(yieldFarming.getAdjustedTotalMonthlyDeposits(startMonth))
                .mul(daysInStartMonth).mul(DAILY_PORTION_IN_MONTH).div(base6);
    }

    function calculateYieldsSDAO_part_2(uint256 startMonth, uint256 endMonth, uint256 lockedLP)
        internal view
        returns (uint256 yieldsSDAO_part_2)
    {
        uint256 monthlyRewardsSDAO;
        uint256 adjustedMonthlyDeposit;
        // yields SDAO in endMonth and in other months (between startMonth and endMonth)
        for (uint256 i = startMonth.add(1); i <= endMonth; i++) {
            monthlyRewardsSDAO = yieldFarming.getTotalSDAORewardsByMonth(i);
            adjustedMonthlyDeposit = yieldFarming.getAdjustedTotalMonthlyDeposits(i);
            yieldsSDAO_part_2 = yieldsSDAO_part_2
                .add(monthlyRewardsSDAO.mul(lockedLP).div(adjustedMonthlyDeposit));
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

        (
            uint256 _startingMonth,
            uint256 _endingMonth,
            uint256 _daysInStartMonth
        ) = getLockedPeriod(_staker, _batchNumber, _pairCode);

        (,uint256 adjustedLockedLP,) = yieldFarming.getLPinBatch(_staker, _pairCode, _batchNumber);

        // calculate KittieFightToken rewards
        rewardKTY = calculateYieldsKTY(_startingMonth, _endingMonth, _daysInStartMonth, adjustedLockedLP);
        rewardSDAO = calculateYieldsSDAO(_startingMonth, _endingMonth, _daysInStartMonth, adjustedLockedLP);

        // If the program ends
        if (block.timestamp >= yieldFarming.programEndAt()) {
            // if eligible for Early Mining Bonus, add the rewards for early bonus
            if (yieldFarming.isBatchEligibleForEarlyBonus(_staker, _batchNumber, _pairCode)) {
                uint256 _earlyBonus = yieldFarming.getEarlyBonus(adjustedLockedLP);
                rewardKTY = rewardKTY.add(_earlyBonus);
                rewardSDAO = rewardSDAO.add(_earlyBonus);
            }
        }

        return (rewardKTY, rewardSDAO);
    }

    function calculateRewardsByAmountCase1
    (address _staker, uint256 _pairCode, uint256 _amountLP,
     uint256 startBatchNumber)
        public view
        returns (uint256 rewardKTY, uint256 rewardSDAO)
    {
        
        uint256 _startingMonth;
        uint256 _endingMonth;
        uint256 _daysInStartMonth;
        uint256 earlyBonus;
        uint256 adjustedLockedLP;

        // // allocate _amountLP per FIFO
        // (startBatchNumber, endBatchNumber, residual) = allocateLP(_staker, _amountLP, _pairCode);
        if (!isBatchEligibleForRewards(_staker, startBatchNumber, _pairCode)) {
            rewardKTY = 0;
            rewardSDAO = 0;
        } else {
            uint256 factor = yieldFarming.getFactorInBatch(_staker, _pairCode, startBatchNumber); 
            adjustedLockedLP = _amountLP.mul(1000000).div(factor);
            (_startingMonth, _endingMonth, _daysInStartMonth) = getLockedPeriod(_staker, startBatchNumber, _pairCode);
            rewardKTY = calculateYieldsKTY(_startingMonth, _endingMonth, _daysInStartMonth, adjustedLockedLP);
            rewardSDAO = calculateYieldsSDAO(_startingMonth, _endingMonth, _daysInStartMonth, adjustedLockedLP);

            // check if early mining bonus applies here
            if (block.timestamp >= yieldFarming.programEndAt() && yieldFarming.isBatchEligibleForEarlyBonus(_staker,startBatchNumber, _pairCode)) {
                earlyBonus = yieldFarming.getEarlyBonus(adjustedLockedLP);
                rewardKTY = rewardKTY.add(earlyBonus);
                rewardSDAO = rewardKTY.add(earlyBonus);
            }
        }
    }

    function calculateRewardsByAmountCase2
    (address _staker, uint256 _pairCode,
     uint256 startBatchNumber, uint256 endBatchNumber)
        public view
        returns (uint256 rewardKTY, uint256 rewardSDAO)
    {
        
        uint256 _startingMonth;
        uint256 _endingMonth;
        uint256 _daysInStartMonth;
        uint256 earlyBonus;
        uint256 adjustedLockedLP;

        for (uint256 i = startBatchNumber; i <= endBatchNumber; i++) {
            // if this batch is eligible for claiming rewards, we calculate its rewards and add to total rewards for this staker
            if(isBatchEligibleForRewards(_staker, i, _pairCode)) {
                // lockedLP = stakers[_staker].batchLockedLPamount[_pairCode][i];
                (,adjustedLockedLP,) = yieldFarming.getLPinBatch(_staker, _pairCode, i);

                (_startingMonth, _endingMonth, _daysInStartMonth) = getLockedPeriod(_staker, i, _pairCode);
                rewardKTY = rewardKTY.add(calculateYieldsKTY(_startingMonth, _endingMonth, _daysInStartMonth, adjustedLockedLP));
                rewardSDAO = rewardSDAO.add(calculateYieldsSDAO(_startingMonth, _endingMonth, _daysInStartMonth, adjustedLockedLP));

                // if eligible for early bonus, the rewards for early bonus is added for this batch
                if (block.timestamp >= yieldFarming.programEndAt() && yieldFarming.isBatchEligibleForEarlyBonus(_staker, i, _pairCode)) {
                    earlyBonus = yieldFarming.getEarlyBonus(adjustedLockedLP);
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
        public view
        returns (uint256 rewardKTY, uint256 rewardSDAO)
    {
        
        uint256 _startingMonth;
        uint256 _endingMonth;
        uint256 _daysInStartMonth;
        uint256 earlyBonus;

        // add rewards for end Batch from which only part of the locked amount is to be withdrawn
        if(isBatchEligibleForRewards(_staker, endBatchNumber, _pairCode)) {
            uint256 factor = yieldFarming.getFactorInBatch(_staker, _pairCode, endBatchNumber);
            uint256 adjustedLockedLP = residual.mul(1000000).div(factor);
    
            (_startingMonth, _endingMonth, _daysInStartMonth) = getLockedPeriod(_staker, endBatchNumber, _pairCode);

            rewardKTY = calculateYieldsKTY(_startingMonth, _endingMonth, _daysInStartMonth, adjustedLockedLP);
            rewardSDAO = calculateYieldsSDAO(_startingMonth, _endingMonth, _daysInStartMonth, adjustedLockedLP);

            if (block.timestamp >= yieldFarming.programEndAt() && yieldFarming.isBatchEligibleForEarlyBonus(_staker, endBatchNumber, _pairCode)) {
                earlyBonus = yieldFarming.getEarlyBonus(adjustedLockedLP);
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
        (,,uint256 lockedAt) = yieldFarming.getLPinBatch(_staker, _pairCode, _batchNumber);
      
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

    



}