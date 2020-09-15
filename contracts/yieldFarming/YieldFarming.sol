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
import "../uniswapKTY/uniswap-v2-core/interfaces/IUniswapV2ERC20.sol";
import "../interfaces/ERC20Standard.sol";
import "./KtyUniswapOracle.sol";

contract YieldFarming is Owned {
    using SafeMath for uint256;

    /*                                               GENERAL VARIABLES                                                */
    /* ============================================================================================================== */

    ERC20Standard public kittieFightToken;      // KittieFightToken contract variable
    ERC20Standard public superDaoToken;         // SuperDaoToken contract variable
    KtyUniswapOracle public ktyUniswapOracle;   // KtyUniswapOracle contract variable

    uint256 constant MONTH = 30 * 24 * 60 * 60; // MONTH duration is 30 days, to keep things standard
    uint256 constant DAY = 24 * 60 * 60; 

    // proportionate a month into 30 parts, each part is 0.033333 * 1000000 = 33333
    uint256 constant DAILY_PORTION_IN_MONTH = 33333;

    // Uniswap pair contract code
    uint256 constant public KTY_WETH = 0;
    uint256 constant public KTY_ANT = 1;
    uint256 constant public KTY_YDAI = 2;
    uint256 constant public KTY_YYFI = 3;
    uint256 constant public KTY_YYCRV = 4;
    uint256 constant public KTY_YALINK = 5;
    uint256 constant public KTY_ALEND = 6;
    uint256 constant public KTY_ASNX = 7;
    uint256 constant public KTY_GNO = 8;
    uint256 constant public KTY_2KEY = 9;
    uint256 constant public KTY_YETH = 10;
    uint256 constant public KTY_AYFI = 11;

    address[12] public pairPools;                       // An array of the address of each Pair Pool, indexed by its pairCode

    uint256 public EARLY_MINING_BONUS;
    uint256 public totalLockedLPinEarlyMining;

    uint256 public totalDepositedLP;            // Total Uniswap Liquidity tokens deposited
    uint256 public totalLockedLP;               // Total Uniswap Liquidity tokens locked
    uint256 public totalRewardsKTY;             // Total KittieFightToken rewards
    uint256 public totalRewardsSDAO;            // Total SuperDaoToken rewards
    uint256 public lockedRewardsKTY;            // KittieFightToken rewards to be distributed
    uint256 public lockedRewardsSDAO;           // SuperDaoToken rewards to be distributed
    uint256 public totalRewardsKTYclaimed;      // KittieFightToken rewards already claimed
    uint256 public totalRewardsSDAOclaimed;     // SuperDaoToken rewards already claimed

    uint256 programDuration;                    // Total time duration for Yield Farming Program
    uint256 programStartAt;                     // Start Time of Yield Farming Program 
    uint256 programEndAt;                       // End Time of Yield Farming Program 
    uint256[6] public monthsStartAt;            // an array of the start time of each month.
  
    uint256[6] KTYunlockRates;                  // Reward Unlock Rates of KittieFightToken for eahc of the 6 months for the entire program duration
    uint256[6] SDAOunlockRates;                 // Reward Unlock Rates of KittieFightToken for eahc of the 6 months for the entire program duration

    enum Months { FirstMonth, SecondMonth, ThirdMonth, FourthMonth, FifthMonth, SixthMonth }

    // Properties of a Staker
    struct Staker {
        uint256[2][] totalDeposits;                     // A 2d array of total deposits [[pairCode, batchNumber], [[pairCode, batchNumber], ...]]
        uint256[][12] batchLockedLPamount;               // A 2d array showing the locked amount of Liquidity tokens in each batch of each Pair Pool
        uint256[][12] batchLockedAt;                     // A 2d array showing the locked time of each batch in each Pair Pool
        uint256[12] totalLPlockedbyPairCode;             // Total amount of Liquidity tokens locked by this stader from all pair pools
        uint256 totalLPlocked;                          // Total Uniswap Liquidity tokens locked by this staker
        uint256 rewardsKTYclaimed;                      // Total amount of KittieFightToken rewards already claimed by this Staker
        uint256 rewardsSDAOclaimed;                     // Total amount of SuperDaoToken rewards already claimed by this Staker
    }

    mapping(address => Staker) public stakers;

    // a mapping of every month to the deposits made during that month: 
    // month => total amount of Uniswap Liquidity tokens deposted in this month
    mapping(uint256 => uint256) public monthlyDeposits;

    // Total Uniswap Liquidity tokens locked from each uniswap pair pool
    // pair code => total locked LP from the pair pool with this pair code
    mapping(uint256 => uint256) public totalLockedLPbyPairCode;   

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
    // We can use constructor in place of function initialize(...) here. However, in local test, it's hard to get
    // the address of the _liquidityToken (which is the KtyWeth pair address created from factory), although there
    // would be no problem in Rinkeby or Mainnet. Therefore, function initialzie(...) can be replaced by a constructor
    // in Rinkeby or Mainnet deployment (but will consume more gas in deployment).
    function initialize
    (
        address[12] calldata _pairPoolAddr,
        ERC20Standard _kittieFightToken,
        ERC20Standard _superDaoToken,
        KtyUniswapOracle _ktyUniswapOracle,
        uint256 _totalKTYrewards,
        uint256 _totalSDAOrewards,
        uint256[6] calldata _ktyUnlockRates,
        uint256[6] calldata _sdaoUnlockRates
    )
        external onlyOwner
    {
        for (uint256 i = 0; i < 12; i++) {
            setPairPoolAddress(i, _pairPoolAddr[i]);
        }

        setKittieFightToken(_kittieFightToken);
        setSuperDaoToken(_superDaoToken);
        setKtyUniswapOracle(_ktyUniswapOracle);

        // Set total rewards in KittieFightToken and SuperDaoToken
        setTotalRewards(_totalKTYrewards, _totalSDAOrewards);

        // Set early mining bonus
        EARLY_MINING_BONUS = 700000*(10**18);

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

        require(IUniswapV2ERC20(pairPools[_pairCode]).transferFrom(msg.sender, address(this), _amountLP), "Fail to deposit liquidity tokens");

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
        require(_LPamount <= stakers[msg.sender].totalLPlockedbyPairCode[_pairCode], "Insuffient tokens locked");

        (uint256 _KTY, uint256 _SDAO, uint256 _startBatchNumber, uint256 _endBatchNumber) = calculateRewardsByAmount(msg.sender, _pairCode, _LPamount);

        _updateWithDrawByAmount(msg.sender, _pairCode, _startBatchNumber, _endBatchNumber, _LPamount, _KTY, _SDAO); 
        _transferTokens(msg.sender, _pairCode, _LPamount, _KTY, _SDAO);

        emit WithDrawn(msg.sender, _pairCode, _KTY, _SDAO, _LPamount, _startBatchNumber, _endBatchNumber, block.timestamp);

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

        uint256 _pairCode = stakers[msg.sender].totalDeposits[_depositNumber][0];
        uint256 _batchNumber = stakers[msg.sender].totalDeposits[_depositNumber][1];

        // get the locked Liquidity token amount in this batch
        uint256 _amountLP = stakers[msg.sender].batchLockedLPamount[_pairCode][_batchNumber];
        require(_amountLP > 0, "No locked tokens in this deposit");

        (uint256 _KTY, uint256 _SDAO) = calculateRewardsByBatchNumber(msg.sender, _batchNumber, _pairCode);

        _updateWithdrawByBatchNumber(msg.sender, _pairCode, _batchNumber, _amountLP, _KTY, _SDAO);

        _transferTokens(msg.sender, _pairCode, _amountLP, _KTY, _SDAO);

        emit WithDrawn(msg.sender, _pairCode, _KTY, _SDAO, _amountLP, _batchNumber, _batchNumber, block.timestamp);
        return true;
    }

    /*                                                 SETTER FUNCTIONS                                               */
    /* ============================================================================================================== */
    /**
     * @dev Set the address of pairPool
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setPairPoolAddress(uint256 _pairCode, address _pairPool) public onlyOwner {
        pairPools[_pairCode] = _pairPool;
    }

    // Not necessary
    // /**
    //  * @dev Set the name of pairPool
    //  * @dev This function can only be carreid out by the owner of this contract.
    //  */
    // function setPairPoolName(uint256 _pairCode, string calldata _pairPoolName) external onlyOwner {
    //     pairPoolNames[_pairCode] = _pairPoolName;
    // }

    /**
     * @dev Set KittieFightToken contract
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setKittieFightToken(ERC20Standard _kittieFightToken) public onlyOwner {
        kittieFightToken = _kittieFightToken;
    }

    /**
     * @dev Set SuperDaoToken contract
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setSuperDaoToken(ERC20Standard _superDaoToken) public onlyOwner {
        superDaoToken = _superDaoToken;
    }

    /**
     * @dev Set KtyUniswapOracle contract
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setKtyUniswapOracle(KtyUniswapOracle _ktyUniswapOracle) public onlyOwner {
        ktyUniswapOracle = _ktyUniswapOracle;
    }

    /**
     * @dev This function transfers unclaimed KittieFightToken rewards to a new address
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function transferKTY(uint256 _amountKTY, address _addr) external onlyOwner returns (bool) {
        require(_amountKTY > 0, "Cannot transfer 0 tokens");
        require(kittieFightToken.transfer(_addr, _amountKTY), "Fail to transfer KTY");
        return true;
    }

    /**
     * @dev This function transfers unclaimed SuperDaoToken rewards to a new address
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function transferSDAO(uint256 _amountSDAO, address _addr) external onlyOwner returns (bool) {
        require(_amountSDAO > 0, "Cannot transfer 0 tokens");
        require(superDaoToken.transfer(_addr, _amountSDAO), "Fail to transfer SDAO");
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
        if (forKTY) {
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
        setMonth(_totalNumberOfMonths, _programStartAt);
    }

    /**
     * @notice Set start time for each month in Yield Farming Program 
     * @param _totalNumberOfMonths uint256 total number of months in the entire program duration
     * @param _programStartAt uint256 time when Yield Farming Program starts
     * @dev    This function can only be carreid out by the owner of this contract.
     */
    function setMonth(uint256 _totalNumberOfMonths, uint256 _programStartAt) public onlyOwner {
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
    /**
     * @param _pairCode uint256 Pair Code assocated with the Pair Pool 
     * @return the address of the pair pool associated with _pairCode
     */
    function getPairPool(uint256 _pairCode) external view returns (address) {
        return pairPools[_pairCode];
    }
    /**
     * @param _staker address the staker who has deposited Uniswap Liquidity tokens
     * @return uint256 the amount of Uniswap Liquidity tokens locked by the staker in this contract
     */
    function getLiquidityTokenLocked(address _staker) external view returns (uint256) {
        return stakers[_staker].totalLPlocked;
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
     * @return uint256 the deposit number for this _staker associated with the _batchNumber and _pairCode
     */
    function getDepositNumber(address _staker, uint256 _batchNumber, uint256 _pairCode)
        external view returns (uint256)
    {
        uint256[2][] memory allDeposits = stakers[_staker].totalDeposits;
        for (uint256 i = 0; i < allDeposits.length; i++) {
            if (_pairCode == allDeposits[i][0] && _batchNumber == allDeposits[i][1]) {
                return i;
            }
        }
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

    /**
     * @return uint256 the amount of locked liquidity tokens in a deposit of a staker assocaited with _depositNumber
     */
    function getLockedLPinDeposit(address _staker, uint256 _depositNumber)
        external view returns (uint256)
    {
        (uint256 _pairCode, uint256 _batchNumber) = getBathcNumberAndPairCode(_staker, _depositNumber); 
        return stakers[_staker].batchLockedLPamount[_pairCode][_batchNumber];
    }

    /**
     * @return uint256 the total amount of locked liquidity tokens of a staker assocaited with _pairCode
     */
    function getLockeLPbyPairCode(address _staker, uint256 _pairCode)
        external view returns (uint256)
    {
        return stakers[_staker].totalLPlockedbyPairCode[_pairCode];
    }

    /**
     * @param _staker address the staker who has deposited Uniswap Liquidity tokens
     * @param _pairCode uint256 Pair Code assocated with a Pair Pool 
     * @return uint256 the batch number of the last batch of the _staker. 
     *         The batch number of the first batch of a staker is always 0, and increments by 1 for 
     *         subsequent batches each.
     */
    function getLastBatchNumber(address _staker, uint256 _pairCode)
        external view returns (uint)
    {
        return stakers[_staker].batchLockedLPamount[_pairCode].length.sub(1);
    }

    /**
     * @param _staker address the staker who has deposited Uniswap Liquidity tokens
     * @param _batchNumber uint256 the batch number of which deposit the staker wishes to see the locked amount
     * @param _pairCode uint256 Pair Code assocated with a Pair Pool 
     * @return uint256 the amount of Uniswap Liquidity tokens locked in the batch with _batchNumber in _pairCode by the staker 
     */
    function getLiquidityTokenLockedPerBatch(address _staker, uint256 _batchNumber, uint256 _pairCode)
        external view returns (uint256)
    {
        return stakers[_staker].batchLockedLPamount[_pairCode][_batchNumber];
    }

    /**
     * @param _staker address the staker who has deposited Uniswap Liquidity tokens
     * @param _batchNumber uint256 the batch number of which deposit the staker wishes to see the locked amount
     * @param _pairCode uint256 Pair Code assocated with a Pair Pool 
     * @return bool true if the batch with the _batchNumber in the _pairCode of the _staker is a valid batch, false if it is non-valid.
     * @dev    A valid batch is a batch which has locked Liquidity tokens in it. 
     * @dev    A non-valid batch is an empty batch which has no Liquidity tokens in it.
     */
    function isBatchValid(address _staker, uint256 _batchNumber, uint256 _pairCode)
        public view returns (bool)
    {
        return stakers[_staker].batchLockedLPamount[_pairCode][_batchNumber] > 0;
    }

    function isDepositValid(address _staker, uint256 _depositNumber)
        public view returns (bool)
    {
        (uint256 _pairCode, uint256 _batchNumber) = getBathcNumberAndPairCode(_staker, _depositNumber); 
        return isBatchValid(_staker, _batchNumber, _pairCode);
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
        uint256 lockedAt = stakers[_staker].batchLockedAt[_pairCode][_batchNumber];
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

    function isDepositEligibleForRewards(address _staker, uint256 _depositNumber)
        public view returns (bool)
    {
        (uint256 _pairCode, uint256 _batchNumber) = getBathcNumberAndPairCode(_staker, _depositNumber); 
        return isBatchEligibleForRewards(_staker, _batchNumber, _pairCode);
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
        if (lockedAt != 0 && lockedAt <= programStartAt.add(DAY.mul(7))) {
            return true;
        }
        return false;
    }

    function isDepositEligibleForEarlyBonus(address _staker, uint256 _depositNumber)
        public view returns (bool)
    {
        (uint256 _pairCode, uint256 _batchNumber) = getBathcNumberAndPairCode(_staker, _depositNumber); 
        return isBatchEligibleForEarlyBonus(_staker, _batchNumber, _pairCode);
    }

    /**
     * @param _amountLP the amount of locked Liquidity token eligible for claiming early bonus
     * @return uint256 the amount of early bonus for this _staker. Since the amount of early bonus is the same
     *         for KittieFightToken and SuperDaoToken, only one number is returned.
     */
    function getEarlyBonusForBatch(uint256 _amountLP)
        public view returns (uint256)
    {
        return _amountLP.mul(EARLY_MINING_BONUS.div(totalLockedLPinEarlyMining));
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
        uint256[] memory allBatches = stakers[_staker].batchLockedLPamount[_pairCode];
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

    
    function calculateYieldsKTY(uint256 startMonth, uint256 endMonth, uint256 daysInStartMonth, uint256 lockedLP)
        internal view
        returns (uint256 yieldsKTY)
    {
        uint256 yieldsKTY_part_1 = calculateYieldsKTY_part_1(startMonth, daysInStartMonth, lockedLP);
        uint256 yieldsKTY_part_2 = calculateYieldsKTY_part_2(startMonth, endMonth, lockedLP);
  
        yieldsKTY = yieldsKTY_part_1.add(yieldsKTY_part_2);
    }

    function calculateYieldsKTY_part_1(uint256 startMonth, uint256 daysInStartMonth, uint256 lockedLP)
        internal view
        returns (uint256 yieldsKTY_part_1)
    {
        // yields KTY in startMonth
        uint256 rewardsKTYstartMonth = KTYunlockRates[startMonth].mul(totalRewardsKTY);
        yieldsKTY_part_1 = rewardsKTYstartMonth.mul(lockedLP).div(monthlyDeposits[startMonth])
                    .mul(daysInStartMonth).mul(DAILY_PORTION_IN_MONTH).div(1000000).div(1000000);
       
    }

    function calculateYieldsKTY_part_2(uint256 startMonth, uint256 endMonth, uint256 lockedLP)
        internal view
        returns (uint256 yieldsKTY_part_2)
    {
        // yields KTY in endMonth and other month between startMonth and endMonth
        if (endMonth == startMonth) {
            yieldsKTY_part_2 = 0;
        } else {
            for (uint256 i = startMonth.add(1); i <= endMonth; i++) {
                yieldsKTY_part_2 = yieldsKTY_part_2
                    .add(KTYunlockRates[i].mul(totalRewardsKTY).mul(lockedLP).div(monthlyDeposits[i]).div(1000000));
            }
        } 
    }

    function calculateYieldsSDAO(uint256 startMonth, uint256 endMonth, uint256 daysInStartMonth, uint256 lockedLP)
        internal view
        returns (uint256 yieldsSDAO)
    {
        uint256 yieldsSDAO_part_1 = calculateYieldsSDAO_part_1(startMonth, daysInStartMonth, lockedLP);
        uint256 yieldsSDAO_part_2 = calculateYieldsSDAO_part_2(startMonth, endMonth, lockedLP);
        yieldsSDAO = yieldsSDAO_part_1.add(yieldsSDAO_part_2);
    }

    function calculateYieldsSDAO_part_1(uint256 startMonth, uint256 daysInStartMonth, uint256 lockedLP)
        internal view
        returns (uint256 yieldsSDAO_part_1)
    {
        // yields SDAO in startMonth
        uint256 rewardsSDAOstartMonth = SDAOunlockRates[startMonth].mul(totalRewardsSDAO);
        yieldsSDAO_part_1 = rewardsSDAOstartMonth.mul(lockedLP).div(monthlyDeposits[startMonth])
                .mul(daysInStartMonth).mul(DAILY_PORTION_IN_MONTH).div(1000000).div(1000000);
    }

    function calculateYieldsSDAO_part_2(uint256 startMonth, uint256 endMonth, uint256 lockedLP)
        internal view
        returns (uint256 yieldsSDAO_part_2)
    {
        // yields SDAO in endMonth and in other months (between startMonth and endMonth)
        if (endMonth == startMonth) {
            yieldsSDAO_part_2 = 0;
        } else {
            for (uint256 i = startMonth.add(1); i <= endMonth; i++) {
                yieldsSDAO_part_2 = yieldsSDAO_part_2
                    .add(SDAOunlockRates[i].mul(totalRewardsSDAO).mul(lockedLP).div(monthlyDeposits[i]).div(1000000));
            }
        } 
    }

    /**
     * @return uint256 the total amount of Uniswap Liquidity tokens locked in this contract
     */
    function getTotalLiquidityTokenLocked() external view returns (uint256) {
        return totalLockedLP;
    }

    /**
     * @return uint256 DAI value representation of ETH in uniswap KTY - ETH pool, according to 
     *         all Liquidity tokens locked in this contract.
     */
    function getTotalLiquidityTokenLockedInDAI(uint256 _pairCode) external view returns (uint256) {
        // to do

        uint256 balance = IUniswapV2ERC20(pairPools[_pairCode]).balanceOf(address(this));
        uint256 totalSupply = IUniswapV2ERC20(pairPools[_pairCode]).totalSupply();
        uint256 percentLPinYieldFarm = balance.mul(1000000).div(totalSupply);
        
        uint256 totalKtyInPairPool = kittieFightToken.balanceOf(pairPools[_pairCode]);

        return totalKtyInPairPool.mul(percentLPinYieldFarm).mul(ktyUniswapOracle.KTY_DAI_price())
               .div(1000000000000000000).div(1000000);
    }

    /**
     * @return uint256 the total amount of KittieFightToken that have been claimed
     * @return uint256 the total amount of SuperDaoToken that have been claimed
     */
    function getTotalRewardsClaimed() external view returns (uint256, uint256) {
        uint256 totalKTYclaimed = totalRewardsKTYclaimed;
        uint256 totalSDAOclaimed = totalRewardsSDAOclaimed;
        return (totalKTYclaimed, totalSDAOclaimed);
    }

    /**
     * @return uint256 
     */
    function getAPY() external view returns (uint256) {
        // to do
    }

    /**
     * @return uint256 the Reward Multiplier for KittieFightToken
     * @return uint256 the Reward Multiplier for SuperDaoFightToken
     */
    function getRewardMultipliers() external view returns (uint256, uint256) {
        // to do
    }

    /**
     * @return uint256 the accrued KittieFightToken rewards
     * @return uint256 the accrued SuperDaoFightToken rewards
     */
    function getAccruedRewards() external view returns (uint256, uint256) {
        // to do
    }

    /**
     * @return uint256 the total amount of KittieFightToken rewards
     * @return uint256 the total amount of SuperDaoFightToken rewards
     */
    function getTotalRewards() external view returns (uint256, uint256) {
        return (totalRewardsKTY, totalRewardsSDAO);
    }

    /**
     * @return uint256 the total amount of Uniswap Liquidity tokens deposited
     *         including both locked tokens and withdrawn tokens
     */
    function getTotalDeposits() external view returns (uint256) {
        return totalDepositedLP;
    }

    /**
     * @return uint256 the total amount of KittieFightToken rewards yet to be distributed
     * @return uint256 the total amount of SuperDaoFightToken rewards yet to be distributed
     */
    function getLockedRewards() external view returns (uint256, uint256) {
        return (lockedRewardsKTY, lockedRewardsSDAO);
    }

    /**
     * @return uint256 the total amount of KittieFightToken rewards already distributed
     * @return uint256 the total amount of SuperDaoFightToken rewards already distributed
     */
    function getUnlockedRewards() external view returns (uint256, uint256) {
        uint256 unlockedKTY = totalRewardsKTY.sub(lockedRewardsKTY);
        uint256 unlockedSDAO = totalRewardsSDAO.sub(lockedRewardsSDAO);
        return (unlockedKTY, unlockedSDAO);
    }

    /**
     * @param _time uint256 The time point for which the month number is enquired
     * @return uint256 the month in which the time point _time is
     */
    function getMonth(uint256 _time) public view returns (uint256) {
        uint256 month;
        for (uint256 i = 5; i >= 0; i--) {
            if (_time >= monthsStartAt[i]) {
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
        if (_time <= programStartAt) {
            return 0;
        }
        uint256 elapsedTime = _time.sub(programStartAt);
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
        uint256 _currentMonth = getCurrentMonth();
        uint256 _lockedAt = stakers[_staker].batchLockedAt[_pairCode][_batchNumber];
        uint256 _startingDay = getDay(_lockedAt);

        _startingMonth = getMonth(_lockedAt); 
        _endingMonth = _currentMonth == 0 ? 0 : block.timestamp > programEndAt ? 5 : _currentMonth.sub(1);
        _daysInStartMonth = 30 - getElapsedDaysInMonth(_startingDay, _startingMonth);
    }

    /**
     * @return unit256 the current day
     * @dev    There are 180 days in this program in total, starting from day 0 to day 179.
     */
    function getCurrentDay() public view returns (uint256) {
        uint256 elapsedTime = block.timestamp.sub(programStartAt);
        uint256 currentDay = elapsedTime.div(DAY);
        return currentDay;
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
        uint256 dayInUnix = _days.mul(DAY).add(monthsStartAt[0]);
        // If _days are before the start of _month, then no day has been elapsed
        if (dayInUnix <= monthsStartAt[_month]) {
            return 0;
        }
        // get time elapsed in seconds
        uint256 timeElapsed = dayInUnix.sub(monthsStartAt[_month]);
        return timeElapsed.div(DAY);
    }

    /**
     * @return unit256 time in seconds until the current month ends
     */
    function timeUntilCurrentMonthEnd() public view returns (uint) {
        uint256 nextMonth = getCurrentMonth().add(1);
        if (nextMonth > 5) {
            if (block.timestamp >= monthsStartAt[5].add(MONTH)) {
                return 0;
            }
            return MONTH.sub(block.timestamp.sub(monthsStartAt[5]));
        }
        return monthsStartAt[nextMonth].sub(block.timestamp);
    }

    /**
     * @dev get info on program duration and month
     */
    function getProgramDuration() external view 
    returns
    (
        uint256 entireProgramDuration,
        uint256 monthDuration,
        uint256 startMonth,
        uint256 endMonth,
        uint256 activeMonth,
        uint256 elapsedMonths,
        uint256[6] memory allMonthsStartTime
    ) 
    {
        uint256 currentMonth = getCurrentMonth();
        entireProgramDuration = programDuration;
        monthDuration = MONTH;
        startMonth = 0;
        endMonth = 5;
        activeMonth = currentMonth;
        elapsedMonths = currentMonth == 0 ? 0 : currentMonth;
        allMonthsStartTime = monthsStartAt;
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

    /**
     * @return uint256 the Reward Unlock Rate for KittieFightToken for each month in the entire program duration
     * @return uint256 the Reward Unlock Rate for SuperDaoToken for each month in the entire program duration
     */
    function getRewardUnlockRate() external view returns (uint256[6] memory, uint256[6] memory) {
        return (KTYunlockRates, SDAOunlockRates);
    }

    /**
     * @param _month uint256 the month (from 0 to 5) for which the Reward Unlock Rate is returned
     * @return uint256 the amount of total Rewards for KittieFightToken for the _month
     * @return uint256 the amount of total Rewards for SuperDaoToken for the _month
     */
    function getTotalRewardsByMonth(uint256 _month)
        external view 
        returns (uint256 rewardKTYbyMonth, uint256 rewardSDAObyMonth)
    {
        rewardKTYbyMonth = totalRewardsKTY.mul(KTYunlockRates[_month]).div(1000000);
        rewardSDAObyMonth = totalRewardsSDAO.mul(SDAOunlockRates[_month]).div(1000000);
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

        stakers[_sender].totalDeposits.push([_pairCode, _batchNumber]);
        stakers[_sender].batchLockedLPamount[_pairCode].push(_amount);
        stakers[_sender].batchLockedAt[_pairCode].push(_lockedAt);
        stakers[_sender].totalLPlockedbyPairCode[_pairCode] = stakers[_sender].totalLPlockedbyPairCode[_pairCode].add(_amount);
        stakers[_sender].totalLPlocked = stakers[_sender].totalLPlocked.add(_amount);

        for (uint i = _currentMonth; i < 6; i++) {
            monthlyDeposits[i] = monthlyDeposits[i].add(_amount);
        }

        totalDepositedLP = totalDepositedLP.add(_amount);
        totalLockedLP = totalLockedLP.add(_amount);

        if (block.timestamp <= programStartAt.add(DAY.mul(7))) {
            totalLockedLPinEarlyMining = totalLockedLPinEarlyMining.add(_amount);
        }

        emit Deposited(msg.sender, _depositNumber, _pairCode, _batchNumber, _amount, _lockedAt);
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
        private 
    {
        // ========= update staker info =========
        // batch info
        uint256 withdrawAmount = 0;
       // all batches except the last batch
        for (uint256 i = _startBatchNumber; i < _endBatchNumber; i++) {
            withdrawAmount = withdrawAmount
                             .add(stakers[_sender].batchLockedLPamount[_pairCode][i]);

            stakers[_sender].batchLockedLPamount[_pairCode][i] = 0;
            stakers[_sender].batchLockedAt[_pairCode][i] = 0;
        }
        // the amount left after allocating to all batches except the last batch
        uint256 leftAmountLP = _LP.sub(withdrawAmount);
        // last batch
        if (leftAmountLP >= stakers[_sender].batchLockedLPamount[_pairCode][_endBatchNumber]) {
            stakers[_sender].batchLockedLPamount[_pairCode][_endBatchNumber] = 0;
            stakers[_sender].batchLockedAt[_pairCode][_endBatchNumber] = 0;
        } else {
            stakers[_sender].batchLockedLPamount[_pairCode][_endBatchNumber] = stakers[_sender].batchLockedLPamount[_pairCode][_endBatchNumber]
                                                                   .sub(leftAmountLP);
        }  

        // all batches in pair code info
        stakers[_sender].totalLPlockedbyPairCode[_pairCode] = stakers[_sender].totalLPlockedbyPairCode[_pairCode].sub(_LP);
        
        // general staker info
        stakers[_sender].totalLPlocked = stakers[_sender].totalLPlocked.sub(_LP);
        stakers[_sender].rewardsKTYclaimed = stakers[_sender].rewardsKTYclaimed.add(_KTY);
        stakers[_sender].rewardsSDAOclaimed = stakers[_sender].rewardsSDAOclaimed.add(_SDAO);

        // ========= update public variables =========
        totalRewardsKTYclaimed = totalRewardsKTYclaimed.add(_KTY);
        totalRewardsSDAOclaimed = totalRewardsSDAOclaimed.add(_SDAO);
        totalLockedLP = totalLockedLP.sub(_LP);

        uint256 _currentMonth = getCurrentMonth();
        if (_currentMonth < 5) {
            for (uint i = _currentMonth.add(1); i < 6; i++) {
                monthlyDeposits[i] = monthlyDeposits[i].sub(_LP);
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
        stakers[_sender].batchLockedLPamount[_pairCode][_batchNumber] = 0;
        stakers[_sender].batchLockedAt[_pairCode][_batchNumber] = 0;

        // all batches in pair code info
        stakers[_sender].totalLPlockedbyPairCode[_pairCode] = stakers[_sender].totalLPlockedbyPairCode[_pairCode].sub(_LP);
        
        // general staker info
        stakers[_sender].totalLPlocked = stakers[_sender].totalLPlocked.sub(_LP);
        stakers[_sender].rewardsKTYclaimed = stakers[_sender].rewardsKTYclaimed.add(_KTY);
        stakers[_sender].rewardsSDAOclaimed = stakers[_sender].rewardsSDAOclaimed.add(_SDAO);

        // ========= update public variables =========
        totalRewardsKTYclaimed = totalRewardsKTYclaimed.add(_KTY);
        totalRewardsSDAOclaimed = totalRewardsSDAOclaimed.add(_SDAO);
        totalLockedLP = totalLockedLP.sub(_LP);

        uint256 _currentMonth = getCurrentMonth();
        if (_currentMonth < 5) {
            for (uint i = _currentMonth; i < 6; i++) {
                monthlyDeposits[i] = monthlyDeposits[i].sub(_LP);
            }
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
        require(IUniswapV2ERC20(pairPools[_pairCode]).transfer(_user, _amountLP), "Fail to transfer liquidity token");

        // transfer rewards
        require(kittieFightToken.transfer(_user, _amountKTY), "Fail to transfer KTY");
        require(superDaoToken.transfer(_user, _amountSDAO), "Fail to transfer SDAO");
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
        private
        returns (uint256, uint256)
    {
        uint256 rewardKTY;
        uint256 rewardSDAO;

        // get the locked Liquidity token amount in this batch
        uint256 lockedLP = stakers[_staker].batchLockedLPamount[_pairCode][_batchNumber];

        // If the batch is locked less than 30 days, rewards are 0.
        if (!isBatchEligibleForRewards(_staker, _batchNumber, _pairCode)) {
            return(0, 0);
        }

        // If the program ends
        if (block.timestamp > programEndAt) {
            // if eligible for Early Mining Bonus, return the rewards for early bonus
            if (isBatchEligibleForEarlyBonus(_staker, _batchNumber, _pairCode)) {
                rewardKTY = getEarlyBonusForBatch(lockedLP);
                rewardSDAO = rewardKTY;
                return (rewardKTY, rewardSDAO);
            }
        }

        // if eligible for Early Mining Bonus but unstake before program end, deduct it from totalLockedLPinEarlyMining
        if (isBatchEligibleForEarlyBonus(_staker, _batchNumber, _pairCode)) {
            totalLockedLPinEarlyMining = totalLockedLPinEarlyMining.sub(lockedLP);
        }

        (
            uint256 _startingMonth,
            uint256 _endingMonth,
            uint256 _daysInStartMonth
        ) = getLockedPeriod(_staker, _batchNumber, _pairCode);

        // calculate KittieFightToken rewards
        rewardKTY = calculateYieldsKTY(_startingMonth, _endingMonth, _daysInStartMonth, lockedLP);
        rewardSDAO = calculateYieldsSDAO(_startingMonth, _endingMonth, _daysInStartMonth, lockedLP);
        return (rewardKTY, rewardSDAO);
    }

    /**
     * @notice Calculate the rewards (KittieFightToken and SuperDaoToken) by the amount of Uniswap Liquidity tokens 
     *         locked by a staker
     * @param _staker address the address of the staker for whom the rewards are calculated
     * @param _amountLP the amount of Uniswap Liquidity tokens locked
     * @param _pairCode uint256 Pair Code assocated with a Pair Pool 
     * @return unit256 the amount of KittieFightToken rewards associated with the _amountLP lockec by this _staker
     * @return unit256 the amount of SuperDaoToken rewards associated with the _amountLP lockec by this _staker
     * @return uint256 the starting batch number of deposit from which the amount of Uniswap Liquidity tokens are allocated
     * @return uint256 the ending batch number of deposit from which the amount of Uniswap Liquidity tokens are allocated
     * @dev    FIFO (First In, First Out) is used to allocate the amount of liquidity tokens to the batches of deposits of this staker
     */
    function calculateRewardsByAmount(address _staker, uint256 _pairCode, uint256 _amountLP)
        private
        returns (
            uint256 rewardKTY,
            uint256 rewardSDAO,
            uint256 startBatchNumber,
            uint256 endBatchNumber
        )
    {
        
        uint256 _startingMonth;
        uint256 _endingMonth;
        uint256 _daysInStartMonth;
        uint256 lockedLP;
        uint256 residual;
        uint256 earlyBonus;

        // allocate _amountLP per FIFO
        (startBatchNumber, endBatchNumber, residual) = allocateLP(_staker, _amountLP, _pairCode);

        if (startBatchNumber == endBatchNumber) {
            if (!isBatchEligibleForRewards(_staker, startBatchNumber, _pairCode)) {
                rewardKTY = 0;
                rewardSDAO = 0;
            } else {
                // check if early mining bonus applies here
                if (block.timestamp >= programEndAt && isBatchEligibleForEarlyBonus(_staker,startBatchNumber, _pairCode)) {
                    rewardKTY = getEarlyBonusForBatch(_amountLP);
                    rewardSDAO = rewardKTY;
                    
                } else {
                    ( _startingMonth, _endingMonth, _daysInStartMonth) = getLockedPeriod(_staker, startBatchNumber, _pairCode);
                    rewardKTY = calculateYieldsKTY(_startingMonth, _endingMonth, _daysInStartMonth, _amountLP);
                    rewardSDAO = calculateYieldsSDAO(_startingMonth, _endingMonth, _daysInStartMonth, _amountLP);

                    // if eligible for Early Mining Bonus before program end, deduct it from totalLockedLPinEarlyMining
                    if (isBatchEligibleForEarlyBonus(_staker, startBatchNumber, _pairCode)) {
                        totalLockedLPinEarlyMining = totalLockedLPinEarlyMining.sub(_amountLP);
                    }
                }
            }
        }

        if (startBatchNumber < endBatchNumber && residual == 0) {
            for (uint256 i = startBatchNumber; i <= endBatchNumber; i++) {
                // if this batch is eligible for claiming rewards, we calculate its rewards and add to total rewards for this staker
                if(isBatchEligibleForRewards(_staker, i, _pairCode)) {
                    lockedLP = stakers[_staker].batchLockedLPamount[_pairCode][i];
                    // if eligible for early bonus, the rewards for early bonus is added for this batch
                    if (block.timestamp >= programEndAt && isBatchEligibleForEarlyBonus(_staker, i, _pairCode)) {
                        earlyBonus = getEarlyBonusForBatch(lockedLP);
                        rewardKTY = rewardKTY.add(earlyBonus);
                        rewardSDAO = rewardSDAO.add(earlyBonus);
                        
                    } else {
                        ( _startingMonth, _endingMonth, _daysInStartMonth) = getLockedPeriod(_staker, i, _pairCode);
                        rewardKTY = rewardKTY.add(calculateYieldsKTY(_startingMonth, _endingMonth, _daysInStartMonth, lockedLP));
                        rewardSDAO = rewardSDAO.add(calculateYieldsSDAO(_startingMonth, _endingMonth, _daysInStartMonth, lockedLP));
                        // if eligible for Early Mining Bonus but unstaske before program end, deduct it from totalLockedLPinEarlyMining
                        if (isBatchEligibleForEarlyBonus(_staker, i, _pairCode)) {
                            totalLockedLPinEarlyMining = totalLockedLPinEarlyMining.sub(lockedLP);
                        }
                    } 
                } 
            }
        }

        if (startBatchNumber < endBatchNumber && residual > 0) {
            for (uint256 i = startBatchNumber; i < endBatchNumber; i++) {
                if(isBatchEligibleForRewards(_staker, i, _pairCode)) {
                    lockedLP = stakers[_staker].batchLockedLPamount[_pairCode][i];
                    // _amountLP = _amountLP.sub(lockedLP);
                    if (block.timestamp >= programEndAt && isBatchEligibleForEarlyBonus(_staker, i, _pairCode)) {
                        earlyBonus = getEarlyBonusForBatch(lockedLP);
                        rewardKTY = rewardKTY.add(earlyBonus);
                        rewardSDAO = rewardSDAO.add(earlyBonus);
                         
                    } else {
                        ( _startingMonth, _endingMonth, _daysInStartMonth) = getLockedPeriod(_staker, i, _pairCode);
                        rewardKTY = rewardKTY.add(calculateYieldsKTY(_startingMonth, _endingMonth, _daysInStartMonth, lockedLP));
                        rewardSDAO = rewardSDAO.add(calculateYieldsSDAO(_startingMonth, _endingMonth, _daysInStartMonth, lockedLP));

                        // if eligible for Early Mining Bonus before program end, deduct it from totalLockedLPinEarlyMining
                        if (isBatchEligibleForEarlyBonus(_staker, endBatchNumber, _pairCode)) {
                            totalLockedLPinEarlyMining = totalLockedLPinEarlyMining.sub(lockedLP);
                        }
                    }
                }       
            }
            // add rewards for end Batch from which only part of the locked amount is to be withdrawn
            if(isBatchEligibleForRewards(_staker, endBatchNumber, _pairCode)) {
                if (block.timestamp >= programEndAt && isBatchEligibleForEarlyBonus(_staker, endBatchNumber, _pairCode)) {
                    earlyBonus = getEarlyBonusForBatch(residual);
                    rewardKTY = rewardKTY.add(earlyBonus);
                    rewardSDAO = rewardSDAO.add(earlyBonus);
                    
                } else {
                    ( _startingMonth, _endingMonth, _daysInStartMonth) = getLockedPeriod(_staker, endBatchNumber, _pairCode);
                    rewardKTY = rewardKTY.add(calculateYieldsKTY(_startingMonth, _endingMonth, _daysInStartMonth, residual));
                    rewardSDAO = rewardSDAO.add(calculateYieldsSDAO(_startingMonth, _endingMonth, _daysInStartMonth, residual));
                    // if eligible for Early Mining Bonus before program end, deduct it from totalLockedLPinEarlyMining
                    if (isBatchEligibleForEarlyBonus(_staker, endBatchNumber, _pairCode)) {
                        totalLockedLPinEarlyMining = totalLockedLPinEarlyMining.sub(residual);
                    }
                }
            }    
        }
    }
}