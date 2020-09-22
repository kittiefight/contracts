/**
* @title YieldFarming
* @author @Ola, @ziweidream
* @notice This contract will track uniswap pool contract and addresses that deposit "UNISWAP pool" tokens 
*         and allow each individual address to DEPOSIT and  withdraw percentage of KTY and SDAO tokens 
*         according to number of "pool" tokens they own, relative to total pool tokens.
*         This contract contains two tokens in contract KTY and SDAO. The contract will also return 
*         certain statistics about rates, availability and timing period of the program.
*/
pragma solidity ^0.5.5;

import "../libs/SafeMath.sol";
import "../authority/Owned.sol";
import '../uniswapKTY/uniswap-v2-core/interfaces/IUniswapV2Pair.sol';
import "../interfaces/ERC20Standard.sol";
import "./YieldFarmingHelper.sol";
import "./YieldsCalculator.sol";

contract YieldFarming is Owned {
    using SafeMath for uint256;

    /*                                               GENERAL VARIABLES                                                */
    /* ============================================================================================================== */

    ERC20Standard public kittieFightToken;              // KittieFightToken contract variable
    ERC20Standard public superDaoToken;                 // SuperDaoToken contract variable
    YieldFarmingHelper public yieldFarmingHelper;       // YieldFarmingHelper contract variable
    YieldsCalculator public yieldsCalculator;           // YieldFarmingHelper contract variable

    uint256 constant public base18 = 1000000000000000000;
    uint256 constant public base6 = 1000000;

    uint256 constant public MONTH = 30 * 24 * 60 * 60;  // MONTH duration is 30 days, to keep things standard
    uint256 constant public DAY = 24 * 60 * 60; 

    uint256 public totalNumberOfPairPools;              // Total number of Uniswap V2 pair pools associated with YieldFarming

    uint256 public EARLY_MINING_BONUS;
    //uint256 public totalLockedLPinEarlyMining;
    uint256 public adjustedTotalLockedLPinEarlyMining;

    uint256 public totalDepositedLP;                    // Total Uniswap Liquidity tokens deposited
    uint256 public totalLockedLP;                       // Total Uniswap Liquidity tokens locked
    uint256 public totalRewardsKTY;                     // Total KittieFightToken rewards
    uint256 public totalRewardsSDAO;                    // Total SuperDaoToken rewards
    uint256 public lockedRewardsKTY;                    // KittieFightToken rewards to be distributed
    uint256 public lockedRewardsSDAO;                   // SuperDaoToken rewards to be distributed
    uint256 public totalRewardsKTYclaimed;              // KittieFightToken rewards already claimed
    uint256 public totalRewardsSDAOclaimed;             // SuperDaoToken rewards already claimed

    uint256 public programDuration;                     // Total time duration for Yield Farming Program
    uint256 public programStartAt;                      // Start Time of Yield Farming Program 
    uint256 public programEndAt;                        // End Time of Yield Farming Program 
    uint256[6] public monthsStartAt;                    // an array of the start time of each month.
  
    uint256[6] public KTYunlockRates;                   // Reward Unlock Rates of KittieFightToken for eahc of the 6 months for the entire program duration
    uint256[6] public SDAOunlockRates;                  // Reward Unlock Rates of KittieFightToken for eahc of the 6 months for the entire program duration

    // Properties of a Staker
    struct Staker {
        uint256[2][] totalDeposits;                      // A 2d array of total deposits [[pairCode, batchNumber], [[pairCode, batchNumber], ...]]
        uint256[][200] batchLockedLPamount;              // A 2d array showing the locked amount of Liquidity tokens in each batch of each Pair Pool
        uint256[][200] adjustedBatchLockedLPamount;      // A 2d array showing the locked amount of Liquidity tokens in each batch of each Pair Pool, adjusted to LP bubbling factor
        uint256[][200] factor;                           // A 2d array showing the LP bubbling factor in each batch of each Pair Pool
        uint256[][200] batchLockedAt;                    // A 2d array showing the locked time of each batch in each Pair Pool
        uint256[200] totalLPlockedbyPairCode;            // Total amount of Liquidity tokens locked by this stader from all pair pools
        uint256 rewardsKTYclaimed;                       // Total amount of KittieFightToken rewards already claimed by this Staker
        uint256 rewardsSDAOclaimed;                      // Total amount of SuperDaoToken rewards already claimed by this Staker
        uint256[] depositNumberForEarlyBonus;            // An array of all the deposit number eligible for early bonus for this staker
        uint256 totalDepositedLPs;
    }

    struct pairPoolInfo {
        string pairName;
        address pairPoolAddress;
        address tokenAddress;
    }

    mapping(address => Staker) public stakers;

    mapping(uint256 => pairPoolInfo) public pairPoolsInfo;

    // a mapping of every month to the deposits made during that month, adjusted to the bubbling factor
    // month => total amount of Uniswap Liquidity tokens deposted in this month, adjusted to the bubbling factor
    mapping(uint256 => uint256) public adjustedMonthlyDeposits;   

    uint256 private unlocked = 1;

    /*                                                   MODIFIERS                                                    */
    /* ============================================================================================================== */
    modifier lock() {
        require(unlocked == 1, 'Locked');
        unlocked = 0;
        _;
        unlocked = 1;
    }          

    /*                                                   INITIALIZER                                                  */
    /* ============================================================================================================== */
    function initialize
    (
        bytes32[] calldata _pairPoolNames,
        address[] calldata _pairPoolAddr,
        address[] calldata _tokenAddrs,
        ERC20Standard _kittieFightToken,
        ERC20Standard _superDaoToken,
        YieldFarmingHelper _yieldFarmingHelper,
        YieldsCalculator _yieldsCalculator,
        uint256[6] calldata _ktyUnlockRates,
        uint256[6] calldata _sdaoUnlockRates
    )
        external onlyOwner
    {
        for (uint256 i = 0; i < _pairPoolAddr.length; i++) {
            addNewPairPool(bytes32ToString(_pairPoolNames[i]), _pairPoolAddr[i], _tokenAddrs[i]);
        }

        setRewardsToken(_kittieFightToken, true);
        setRewardsToken(_superDaoToken, false);

        // setKittieFightToken(_kittieFightToken);
        // setSuperDaoToken(_superDaoToken);
        setYieldFarmingHelper(_yieldFarmingHelper);
        setYieldsCalculator(_yieldsCalculator);

        // Set total rewards in KittieFightToken and SuperDaoToken
        totalRewardsKTY = 7000000 * base18;
        totalRewardsSDAO = 7000000 * base18;

        // Set early mining bonus
        EARLY_MINING_BONUS = 700000 * base18;

        // Set reward unlock rate for the program duration
        for (uint256 j = 0; j < 6; j++) {
            setRewardUnlockRate(j, _ktyUnlockRates[j], true);
            setRewardUnlockRate(j, _sdaoUnlockRates[j], false);
        }

        // Set program duration (for a period of 6 months). Month starts at time of program deployment/initialization
        setProgramDuration(6, block.timestamp);
    }

    /*                                                      EVENTS                                                    */
    /* ============================================================================================================== */
    event Deposited(
        address indexed sender,
        uint256 indexed depositNumber,
        uint256 indexed pairCode,
        uint256 batchNumber,
        uint256 depositAmount,
        uint256 depositTime
    );

    event WithDrawn(
        address indexed sender,
        uint256 indexed pairCode,
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
     * @param _pairCode the Pair Code associated with the Pair Pool of which the Liquidity tokens are to be deposited
     * @return bool true if the deposit is successful
     * @dev    Each new deposit of a staker makes a new deposit with Deposit Number for this staker.
     *         Deposit Number for each staker starts from 0 (for the first deposit), and increment by 1 for 
     *         subsequent deposits. Each deposit with a Deposit Number is associated with a Pair Code 
     *         and a Batch Number.
     *         For each staker, each Batch Number in each Pair Pool associated with a Pair Code starts 
     *         from 0 (for the first deposit), and increment by 1 for subsequent batches each.
     */
    function deposit(uint256 _amountLP, uint256 _pairCode) external lock returns (bool) {
        require(block.timestamp <= programEndAt, "Program has ended");
        
        require(_amountLP > 0, "Cannot deposit 0 tokens");

        require(IUniswapV2Pair(pairPoolsInfo[_pairCode].pairPoolAddress).transferFrom(msg.sender, address(this), _amountLP), "Fail to deposit liquidity tokens");

        _addDeposit(msg.sender, _pairCode, _amountLP, block.timestamp);

        return true;
    }

    /**
     * @notice Withdraw Uniswap Liquidity tokens by amount specified by the staker
     * @notice Three tokens (Uniswap Liquidity Tokens, KittieFightTokens, and SuperDaoTokens) are transferred
     *         to the user upon successful withdraw
     * @param _LPamount the amount of Uniswap Liquidity tokens to be withdrawn
     * @param _pairCode the Pair Code associated with the Pair Pool of which the Liquidity tokens are to be withdrawn
     * @dev    FIFO (First in, First out) is used to allocate the _LPamount to the user's deposit batches from a Pair Pool.
     *         For example, _LPamount is allocated to batch 0 first, and if _LPamount is bigger than the amount
     *         locked in batch 0, then the rest is allocated to batch 1, and so forth. Allocation only happens to batches
     *         with the same Pair Code. 
     * @return bool true if the withdraw is successful
     */
    function withdrawByAmount(uint256 _LPamount, uint256 _pairCode) external lock returns (bool) {
        (bool _isPayDay,) = yieldFarmingHelper.isPayDay();
        require(_isPayDay == true, "Can only withdraw on pay day");
        require(_LPamount <= stakers[msg.sender].totalLPlockedbyPairCode[_pairCode], "Insuffient tokens locked");

        (
            uint256 _KTY, uint256 _SDAO, uint256 startBatchNumber, uint256 endBatchNumber
        ) = yieldsCalculator.calculateRewardsByAmount(msg.sender,  _LPamount, _pairCode);

        if (startBatchNumber == endBatchNumber) {
            _updateWithDrawByAmountCase1(msg.sender, _pairCode, startBatchNumber, _LPamount, _KTY, _SDAO);
        } else {
            _updateWithDrawByAmount(msg.sender, _pairCode, startBatchNumber, endBatchNumber, _LPamount, _KTY, _SDAO); 
        }

        _transferTokens(msg.sender, _pairCode, _LPamount, _KTY, _SDAO);

        emit WithDrawn(msg.sender, _pairCode, _KTY, _SDAO, _LPamount, startBatchNumber, endBatchNumber, block.timestamp);

        return true;
    }

    /**
     * @notice Withdraw Uniswap Liquidity tokens locked in a batch with _batchNumber specified by the staker
     * @notice Three tokens (Uniswap Liquidity Tokens, KittieFightTokens, and SuperDaoTokens) are transferred
     *         to the user upon successful withdraw
     * @param _depositNumber the deposit number of the deposit from which the user wishes to withdraw the Uniswap Liquidity tokens locked 
     * @return bool true if the withdraw is successful
     */
    function withdrawByDepositNumber(uint256 _depositNumber) external lock returns (bool) {
        (bool _isPayDay,) = yieldFarmingHelper.isPayDay();
        require(_isPayDay == true, "Can only withdraw on pay day");

        uint256 _pairCode = stakers[msg.sender].totalDeposits[_depositNumber][0];
        uint256 _batchNumber = stakers[msg.sender].totalDeposits[_depositNumber][1];

        // get the locked Liquidity token amount in this batch
        uint256 _amountLP = stakers[msg.sender].batchLockedLPamount[_pairCode][_batchNumber];
        require(_amountLP > 0, "No locked tokens in this deposit");

        (uint256 _KTY, uint256 _SDAO) = yieldsCalculator.calculateRewardsByBatchNumber(msg.sender, _batchNumber, _pairCode);

        _updateWithdrawByBatchNumber(msg.sender, _pairCode, _batchNumber, _amountLP, _KTY, _SDAO);

        _transferTokens(msg.sender, _pairCode, _amountLP, _KTY, _SDAO);

        emit WithDrawn(msg.sender, _pairCode, _KTY, _SDAO, _amountLP, _batchNumber, _batchNumber, block.timestamp);
        return true;
    }

    /*                                                 SETTER FUNCTIONS                                               */
    /* ============================================================================================================== */
    /**
     * @dev Add new pairPool
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function addNewPairPool(string memory _pairName, address _pairPoolAddr, address _tokenAddr) public onlyOwner {
        uint256 _pairCode = totalNumberOfPairPools;

        pairPoolsInfo[_pairCode].pairName = _pairName;
        pairPoolsInfo[_pairCode].pairPoolAddress = _pairPoolAddr;
        pairPoolsInfo[_pairCode].tokenAddress = _tokenAddr;

        totalNumberOfPairPools = totalNumberOfPairPools.add(1);
    }

    /**
     * @dev Set KittieFightToken contract
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setRewardsToken(ERC20Standard _rewardsToken, bool forKTY) public onlyOwner {
        if (forKTY == true) {
            kittieFightToken = _rewardsToken;
        } else if (forKTY == false) {
            superDaoToken = _rewardsToken;
        }   
    }

    /**
     * @dev Set YieldFarmingHelper contract
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setYieldFarmingHelper(YieldFarmingHelper _yieldFarmingHelper) public onlyOwner {
        yieldFarmingHelper = _yieldFarmingHelper;
    }

    /**
     * @dev Set YieldsCalculator contract
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setYieldsCalculator(YieldsCalculator _yieldsCalculator) public onlyOwner {
        yieldsCalculator = _yieldsCalculator;
    }

    /**
     * @notice This function transfers unclaimed KittieFightToken or SuperDaoToken rewards to a new address
     * @param _amount uint256 amount of rewards to be transferred
     * @param _addr uint256 account address to which the unclaimed rewards to be transferred
     * @param forKTY bool true if this transfer is for KittieFightToken, false if it is for SuperDaoToken
     * @dev This function can only be carreid out by the owner of this contract.
     */

    function transferUnclaimedRewards(uint256 _amount, address _addr, bool forKTY) external onlyOwner returns (bool) {
        require(_amount > 0, "Cannot transfer 0 tokens");
        if (forKTY == true) {
            require(kittieFightToken.transfer(_addr, _amount), "Fail to transfer KTY");
        } else if (forKTY == false) {
            require(superDaoToken.transfer(_addr, _amount), "Fail to transfer SDAO");
        }
        
        return true;
    }

    /**
     * @dev This function transfers other tokens erroneously tranferred to this contract back to their original owner
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function returnTokens(address _token, uint256 _amount, address _tokenOwner) external onlyOwner {
        uint256 balance = ERC20Standard(_token).balanceOf(address(this));
        require(_amount <= balance, "Exceeds balance");
        require(ERC20Standard(_token).transfer(_tokenOwner, balance), "Fail to transfer tokens");
    }

    /**
     * @notice Modify Reward Unlock Rate for KittieFightToken and SuperDaoToken for any month (from 0 to 5)
     *         within the program duration (a period of 6 months)
     * @param _month uint256 the month (from 0 to 5) for which the unlock rate is to be modified
     * @param _rate  uint256 the unlock rate
     * @param forKTY bool true if this modification is for KittieFightToken, false if it is for SuperDaoToken
     * @dev    This function can only be carreid out by the owner of this contract.
     */
    function setRewardUnlockRate(uint256 _month, uint256 _rate, bool forKTY) public onlyOwner {
        if (forKTY == true) {
            KTYunlockRates[_month] = _rate;
        } else {
            SDAOunlockRates[_month] = _rate;
        }
    }

    /**
     * @notice Set Yield Farming Program time duration
     * @param _totalNumberOfMonths uint256 total number of months in the entire program duration
     * @param _programStartAt uint256 time when Yield Farming Program starts
     * @dev    This function can only be carreid out by the owner of this contract.
     */
    function setProgramDuration(uint256 _totalNumberOfMonths, uint256 _programStartAt) public onlyOwner {
        programDuration = _totalNumberOfMonths.mul(MONTH);
        programStartAt = _programStartAt;
        programEndAt = programStartAt.add(MONTH.mul(6));

        monthsStartAt[0] = _programStartAt;
        for (uint256 i = 1; i < _totalNumberOfMonths; i++) {
            monthsStartAt[i] = monthsStartAt[0].add(MONTH.mul(i)); 
        }
    }

    /**
     * @notice Set total KittieFightToken rewards and total SuperDaoToken rewards for the entire program duration
     * @param _rewardsKTY uint256 total KittieFightToken rewards for the entire program duration
     * @param _rewardsSDAO uint256 total SuperDaoToken rewards for the entire program duration
     * @dev    This function can only be carreid out by the owner of this contract.
     */
    function setTotalRewards(uint256 _rewardsKTY, uint256 _rewardsSDAO) public onlyOwner {
        totalRewardsKTY = _rewardsKTY;
        totalRewardsSDAO = _rewardsSDAO;
    }

    /*                                                 GETTER FUNCTIONS                                               */
    /* ============================================================================================================== */
    function bytes32ToString(bytes32 x) internal pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
    
    /**
     * @param _pairCode uint256 Pair Code assocated with the Pair Pool 
     * @return the address of the pair pool associated with _pairCode
     */
    function getPairPool(uint256 _pairCode)
        public view
        returns (string memory, address, address)
    {
        return (pairPoolsInfo[_pairCode].pairName, pairPoolsInfo[_pairCode].pairPoolAddress, pairPoolsInfo[_pairCode].tokenAddress);
    }

    /**
     * @return uint[2][2] a 2d array containing all the deposits made by the staker in this contract,
     *         each item in the 2d array consisting of the Pair Code and the Batch Number associated this
     *         the deposit. The Deposit Number of the deposit is the same as its index in the 2d array.
     */
    function getAllDeposits(address _staker)
        external view returns (uint256[2][] memory)
    {
        return stakers[_staker].totalDeposits;
    }

    /**
     * @return the total number of deposits this _staker has made
     */
    function getNumberOfDeposits(address _staker)
        external view returns (uint256)
    {
        return stakers[_staker].totalDeposits.length;
    }

    /**
     * @param _staker address the staker who has deposited Uniswap Liquidity tokens
     * @param _depositNumber deposit number for the _staker
     * @return pair pool code and batch number associated with this _depositNumber for the _staker
     */

    function getBathcNumberAndPairCode(address _staker, uint256 _depositNumber)
        public view returns (uint256, uint256)
    {
        uint256 _pairCode = stakers[_staker].totalDeposits[_depositNumber][0];
        uint256 _batchNumber = stakers[_staker].totalDeposits[_depositNumber][1];
        return (_pairCode, _batchNumber);
    }

    /**
     * @param _staker address the staker who has deposited Uniswap Liquidity tokens
     * @param _pairCode uint256 Pair Code assocated with a Pair Pool from whichh the batches are to be shown
     * @return uint256[] an array of the amount of locked Lquidity tokens in every batch of the _staker in
     *         the _pairCode. The index of the array is the Batch Number associated with the batch, since
     *         batch for a stakder starts from batch 0, and increment by 1 for subsequent batches each.
     * @dev    Each new deposit of a staker makes a new batch in _pairCode.
     */
    function getAllBatchesPerPairPool(address _staker, uint256 _pairCode)
        external view returns (uint256[] memory)
    {
        return stakers[_staker].batchLockedLPamount[_pairCode];
    }

    function getAllDepositedLPs(address _staker)
        external view returns (uint256)
    {
        return stakers[_staker].totalDepositedLPs;
    }

    /**
     * @param _staker address the staker who has deposited Uniswap Liquidity tokens
     * @param _pairCode uint256 Pair Code assocated with a Pair Pool 
     * @param _batchNumber uint256 the batch number of which deposit the staker wishes to see the locked amount
     * @return uint256 the amount of Uniswap Liquidity tokens locked,
     *         and its adjusted amount, and the time when this batch was locked,
     *         in the batch with _batchNumber in _pairCode by the staker 
     */
    function getLPinBatch(address _staker, uint256 _pairCode, uint256 _batchNumber)
        external view returns (uint256, uint256, uint256)
    {
        uint256 _LP = stakers[_staker].batchLockedLPamount[_pairCode][_batchNumber];
        uint256 _adjustedLP = stakers[_staker].adjustedBatchLockedLPamount[_pairCode][_batchNumber];
        uint256 _lockTime = stakers[_staker].batchLockedAt[_pairCode][_batchNumber];
        
        return (_LP, _adjustedLP, _lockTime);
    }

    /**
     * @param _staker address the staker who has deposited Uniswap Liquidity tokens
     * @param _pairCode uint256 Pair Code assocated with a Pair Pool 
     * @param _batchNumber uint256 the batch number of which deposit the staker wishes to see the locked amount
     * @return uint256 the bubble factor of LP associated with this batch
     */
    function getFactorInBatch(address _staker, uint256 _pairCode, uint256 _batchNumber)
        external view returns (uint256)
    {
        return stakers[_staker].factor[_pairCode][_batchNumber];
    }

    /**
     * @return uint256 the total amount of locked liquidity tokens of a staker assocaited with _pairCode
     */
    function getLockeLPbyPairCode(address _staker, uint256 _pairCode)
        external view returns (uint256)
    {
        return stakers[_staker].totalLPlockedbyPairCode[_pairCode];
    }

    function getDepositsForEarlyBonus(address _staker) external view returns(uint256[] memory) {
        return stakers[_staker].depositNumberForEarlyBonus;
    }

    /**
     * @param _staker address the staker who has deposited Uniswap Liquidity tokens
     * @param _batchNumber uint256 the batch number of which deposit the staker wishes to see the locked amount
     * @param _pairCode uint256 Pair Code assocated with a Pair Pool 
     * @return bool true if the batch with the _batchNumber in the _pairCode of the _staker is eligible for Early Bonus, false if it is not eligible.
     * @dev    A batch needs to be locked within 7 days since contract deployment to be eligible for claiming yields.
     */
    function isBatchEligibleForEarlyBonus(address _staker, uint256 _batchNumber, uint256 _pairCode)
        public view returns (bool)
    {
        // get locked time
        uint256 lockedAt = stakers[_staker].batchLockedAt[_pairCode][_batchNumber];
        if (lockedAt > 0 && lockedAt <= programStartAt.add(DAY.mul(21))) {
            return true;
        }
        return false;
    }

    /**
     * @param _staker address the staker who has received the rewards
     * @return uint256 the total amount of KittieFightToken that have been claimed by this _staker
     * @return uint256 the total amount of SuperDaoToken that have been claimed by this _staker
     */
    function getTotalRewardsClaimedByStaker(address _staker) external view returns (uint256, uint256) {
        uint256 totalKTYclaimedByStaker = stakers[_staker].rewardsKTYclaimed;
        uint256 totalSDAOclaimedByStaker = stakers[_staker].rewardsSDAOclaimed;
        return (totalKTYclaimedByStaker, totalSDAOclaimedByStaker);
    }

    function getAdjustedTotalMonthlyDeposits(uint256 _month) external view returns (uint256) {
        return adjustedMonthlyDeposits[_month];
    }

    /**
     * @return unit256 the current month 
     * @dev    There are 6 months in this program in total, starting from month 0 to month 5.
     */
    function getCurrentMonth() public view returns (uint256) {
        uint256 currentMonth;
        for (uint256 i = 5; i >= 0; i--) {
            if (block.timestamp >= monthsStartAt[i]) {
                currentMonth = i;
                break;
            }
        }
        return currentMonth;
    }

    /**
     * @param _month uint256 the month (from 0 to 5) for which the Reward Unlock Rate is returned
     * @return uint256 the Reward Unlock Rate for KittieFightToken for the _month
     * @return uint256 the Reward Unlock Rate for SuperDaoToken for the _month
     */
    function getRewardUnlockRateByMonth(uint256 _month) external view returns (uint256, uint256) {
        uint256 _KTYunlockRate = KTYunlockRates[_month];
        uint256 _SDAOunlockRate = SDAOunlockRates[_month];
        return (_KTYunlockRate, _SDAOunlockRate);
    }

    function getMonthStartAt(uint256 month) external view returns (uint256) {
        return monthsStartAt[month];
    }

    

    /*                                                 PRIVATE FUNCTIONS                                             */
    /* ============================================================================================================== */

    /**
     * @dev    Internal functions used in function deposit()
     * @param _sender address the address of the sender
     * @param _pairCode uint256 Pair Code assocated with a Pair Pool 
     * @param _amount uint256 the amount of Uniswap Liquidity tokens to be deposited
     * @param _lockedAt uint256 the time when this depoist is made
     */
    function _addDeposit(address _sender, uint256 _pairCode, uint256 _amount, uint256 _lockedAt) private {
        uint256 _depositNumber = stakers[_sender].totalDeposits.length;
        uint256 _batchNumber = stakers[_sender].batchLockedLPamount[_pairCode].length;
        uint256 _currentMonth = getCurrentMonth();
        uint256 _factor = yieldFarmingHelper.bubbleFactor(_pairCode);

        stakers[_sender].totalDeposits.push([_pairCode, _batchNumber]);
        stakers[_sender].batchLockedLPamount[_pairCode].push(_amount);
        stakers[_sender].adjustedBatchLockedLPamount[_pairCode].push(_amount.mul(base6).div(_factor));
        stakers[_sender].factor[_pairCode].push(_factor);
        stakers[_sender].batchLockedAt[_pairCode].push(_lockedAt);
        stakers[_sender].totalLPlockedbyPairCode[_pairCode] = stakers[_sender].totalLPlockedbyPairCode[_pairCode].add(_amount);
        stakers[_sender].totalDepositedLPs = stakers[_sender].totalDepositedLPs.add(_amount);

        for (uint256 i = _currentMonth; i < 6; i++) {
            adjustedMonthlyDeposits[i] = adjustedMonthlyDeposits[i].add(_amount.mul(base6).div(_factor));
        }

        totalDepositedLP = totalDepositedLP.add(_amount);
        totalLockedLP = totalLockedLP.add(_amount);

        if (block.timestamp <= programStartAt.add(DAY.mul(21))) {
            adjustedTotalLockedLPinEarlyMining = adjustedTotalLockedLPinEarlyMining.add(_amount.mul(base6).div(_factor));
            stakers[_sender].depositNumberForEarlyBonus.push(_depositNumber);
        }

        emit Deposited(msg.sender, _depositNumber, _pairCode, _batchNumber, _amount, _lockedAt);
    }

    function _updateWithDrawByAmountCase1
    (
        address _sender, uint256 _pairCode, uint256 _startBatchNumber,
        uint256 _LP, uint256 _KTY, uint256 _SDAO
    ) 
        private
    {
        // ========= update staker info =========
        // batch info
        uint256 _adjustedLP;
        if (_LP == stakers[_sender].batchLockedLPamount[_pairCode][_startBatchNumber]) {
            _adjustedLP = stakers[_sender].adjustedBatchLockedLPamount[_pairCode][_startBatchNumber];
            stakers[_sender].batchLockedAt[_pairCode][_startBatchNumber] = 0;
        } else {
            _adjustedLP = _LP.mul(base6).div(stakers[_sender].factor[_pairCode][_startBatchNumber]);
        }
        if (block.timestamp < programEndAt && isBatchEligibleForEarlyBonus(_sender, _startBatchNumber, _pairCode)) {
            adjustedTotalLockedLPinEarlyMining = adjustedTotalLockedLPinEarlyMining
                                                 .sub(_adjustedLP);
        }
        stakers[_sender].batchLockedLPamount[_pairCode][_startBatchNumber] = stakers[_sender].batchLockedLPamount[_pairCode][_startBatchNumber]
                                                                             .sub(_LP);
        stakers[_sender].adjustedBatchLockedLPamount[_pairCode][_startBatchNumber] = stakers[_sender].adjustedBatchLockedLPamount[_pairCode][_startBatchNumber]
                                                                                     .sub(_adjustedLP);
        
        // all batches in pair code info
        stakers[_sender].totalLPlockedbyPairCode[_pairCode] = stakers[_sender].totalLPlockedbyPairCode[_pairCode].sub(_LP);
        
        // general staker info
        stakers[_sender].rewardsKTYclaimed = stakers[_sender].rewardsKTYclaimed.add(_KTY);
        stakers[_sender].rewardsSDAOclaimed = stakers[_sender].rewardsSDAOclaimed.add(_SDAO);

        // ========= update public variables =========
        totalRewardsKTYclaimed = totalRewardsKTYclaimed.add(_KTY);
        totalRewardsSDAOclaimed = totalRewardsSDAOclaimed.add(_SDAO);
        totalLockedLP = totalLockedLP.sub(_LP);

        uint256 _currentMonth = getCurrentMonth();
        if (_currentMonth < 5) {
            for (uint i = _currentMonth; i < 6; i++) {
                adjustedMonthlyDeposits[i] = adjustedMonthlyDeposits[i]
                                             .sub(_adjustedLP);
                                           
            }
        }
          
    }

    /**
     * @dev Internal functions used in function withdrawByAmount(), to deduct deposits from mapping deposits storage
     * @param _sender address the address of the sender
     * @param _pairCode uint256 Pair Code assocated with a Pair Pool 
     * @param _LP uint256 the amount of Uniswap Liquidity tokens to be deposited
     * @param _startBatchNumber uint256 the starting batch number from which the _amount of Liquidity tokens 
                                of the _sender is allocated
     * @param _endBatchNumber uint256 the ending batch number until which the _amount of Liquidity tokens 
                                of the _sender is allocated
     */
    function _updateWithDrawByAmount
    (
        address _sender, uint256 _pairCode,
        uint256 _startBatchNumber, uint256 _endBatchNumber,
        uint256 _LP, uint256 _KTY, uint256 _SDAO
    ) 
        private returns (bool)
    {
        // ========= update staker info =========
        // batch info
        uint256 withdrawAmount = 0;
        uint256 adjustedWithdrawAmount = 0;
       // all batches except the last batch
        for (uint256 i = _startBatchNumber; i < _endBatchNumber; i++) {
            // if eligible for Early Mining Bonus before program end, deduct it from totalLockedLPinEarlyMining
            if (block.timestamp < programEndAt && isBatchEligibleForEarlyBonus(_sender, i, _pairCode) == true) {
                adjustedTotalLockedLPinEarlyMining = adjustedTotalLockedLPinEarlyMining
                                                     .sub(stakers[_sender].adjustedBatchLockedLPamount[_pairCode][i]);
            }

            withdrawAmount = withdrawAmount
                             .add(stakers[_sender].batchLockedLPamount[_pairCode][i]);
            adjustedWithdrawAmount = adjustedWithdrawAmount
                             .add(stakers[_sender].adjustedBatchLockedLPamount[_pairCode][i]);
                                  
            stakers[_sender].batchLockedLPamount[_pairCode][i] = 0;
            stakers[_sender].adjustedBatchLockedLPamount[_pairCode][i] = 0;
            stakers[_sender].batchLockedAt[_pairCode][i] = 0;
        }
        // the amount left after allocating to all batches except the last batch
        uint256 leftAmountLP = _LP.sub(withdrawAmount);
        uint256 adjustedLeftAmountLP = leftAmountLP.mul(base6).div(stakers[_sender].factor[_pairCode][_endBatchNumber]);
        // last batch
        // if eligible for Early Mining Bonus before program end, deduct it from totalLockedLPinEarlyMining
        if (block.timestamp < programEndAt && isBatchEligibleForEarlyBonus(_sender, _endBatchNumber, _pairCode) == true) {
            adjustedTotalLockedLPinEarlyMining = adjustedTotalLockedLPinEarlyMining.sub(adjustedLeftAmountLP);
        }
        if (leftAmountLP >= stakers[_sender].batchLockedLPamount[_pairCode][_endBatchNumber]) {
            stakers[_sender].batchLockedLPamount[_pairCode][_endBatchNumber] = 0;
            stakers[_sender].adjustedBatchLockedLPamount[_pairCode][_endBatchNumber] = 0;
            stakers[_sender].batchLockedAt[_pairCode][_endBatchNumber] = 0;
        } else {
            stakers[_sender].batchLockedLPamount[_pairCode][_endBatchNumber] = stakers[_sender].batchLockedLPamount[_pairCode][_endBatchNumber]
                                                                   .sub(leftAmountLP);
            stakers[_sender].adjustedBatchLockedLPamount[_pairCode][_endBatchNumber] = stakers[_sender].adjustedBatchLockedLPamount[_pairCode][_endBatchNumber]
                                                                   .sub(adjustedLeftAmountLP);
        }  

        // all batches in pair code info
        stakers[_sender].totalLPlockedbyPairCode[_pairCode] = stakers[_sender].totalLPlockedbyPairCode[_pairCode].sub(_LP);
        
        // general staker info
        stakers[_sender].rewardsKTYclaimed = stakers[_sender].rewardsKTYclaimed.add(_KTY);
        stakers[_sender].rewardsSDAOclaimed = stakers[_sender].rewardsSDAOclaimed.add(_SDAO);

        // ========= update public variables =========
        totalRewardsKTYclaimed = totalRewardsKTYclaimed.add(_KTY);
        totalRewardsSDAOclaimed = totalRewardsSDAOclaimed.add(_SDAO);
        totalLockedLP = totalLockedLP.sub(_LP);

        uint256 _currentMonth = getCurrentMonth();
        if (_currentMonth < 5) {
            for (uint i = _currentMonth; i < 6; i++) {
                adjustedMonthlyDeposits[i] = adjustedMonthlyDeposits[i]
                                             .sub(adjustedWithdrawAmount)
                                             .sub(adjustedLeftAmountLP);
            }
        }
    }

    /**
     * @param _sender address the address of the sender
     * @param _pairCode uint256 Pair Code assocated with a Pair Pool 
     * @param _KTY uint256 the amount of KittieFightToken
     * @param _SDAO uint256 the amount of SuperDaoToken
     * @param _LP uint256 the amount of Uniswap Liquidity tokens
     */
    function _updateWithdrawByBatchNumber
    (
        address _sender, uint256 _pairCode, uint256 _batchNumber,
        uint256 _LP, uint256 _KTY, uint256 _SDAO
    ) 
        private
    {
        // ========= update staker info =========
        // batch info
        uint256 adjustedLP = stakers[_sender].adjustedBatchLockedLPamount[_pairCode][_batchNumber];
        stakers[_sender].batchLockedLPamount[_pairCode][_batchNumber] = 0;
        stakers[_sender].adjustedBatchLockedLPamount[_pairCode][_batchNumber] = 0;
        stakers[_sender].batchLockedAt[_pairCode][_batchNumber] = 0;

        // all batches in pair code info
        stakers[_sender].totalLPlockedbyPairCode[_pairCode] = stakers[_sender].totalLPlockedbyPairCode[_pairCode].sub(_LP);
        
        // general staker info
        stakers[_sender].rewardsKTYclaimed = stakers[_sender].rewardsKTYclaimed.add(_KTY);
        stakers[_sender].rewardsSDAOclaimed = stakers[_sender].rewardsSDAOclaimed.add(_SDAO);

        // ========= update public variables =========
        totalRewardsKTYclaimed = totalRewardsKTYclaimed.add(_KTY);
        totalRewardsSDAOclaimed = totalRewardsSDAOclaimed.add(_SDAO);
        totalLockedLP = totalLockedLP.sub(_LP);

        uint256 _currentMonth = getCurrentMonth();
        if (_currentMonth < 5) {
            for (uint i = _currentMonth; i < 6; i++) {
                adjustedMonthlyDeposits[i] = adjustedMonthlyDeposits[i]
                                             .sub(adjustedLP);
            }
        }

        // if eligible for Early Mining Bonus but unstake before program end, deduct it from totalLockedLPinEarlyMining
        if (block.timestamp < programEndAt && isBatchEligibleForEarlyBonus(_sender, _batchNumber, _pairCode) == true) {
            adjustedTotalLockedLPinEarlyMining = adjustedTotalLockedLPinEarlyMining.sub(adjustedLP);
        }
    }

    /**
     * @param _user address the address of the _user to whom the tokens are transferred
     * @param _pairCode uint256 Pair Code assocated with a Pair Pool 
     * @param _amountLP uint256 the amount of Uniswap Liquidity tokens to be transferred to the _user
     * @param _amountKTY uint256 the amount of KittieFightToken to be transferred to the _user
     * @param _amountSDAO uint256 the amount of SuperDaoToken to be transferred to the _user
     */
    function _transferTokens(address _user, uint256 _pairCode, uint256 _amountLP, uint256 _amountKTY, uint256 _amountSDAO)
        private
    {
        // transfer liquidity tokens
        require(IUniswapV2Pair(pairPoolsInfo[_pairCode].pairPoolAddress).transfer(_user, _amountLP), "Fail to transfer liquidity token");

        // transfer rewards
        require(kittieFightToken.transfer(_user, _amountKTY), "Fail to transfer KTY");
        require(superDaoToken.transfer(_user, _amountSDAO), "Fail to transfer SDAO");
    }
}