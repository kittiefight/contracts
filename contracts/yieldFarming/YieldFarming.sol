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
 
    IUniswapV2ERC20 public LP;   // Liquidity token
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

    struct Deposit {
        uint256 amountLP;
        uint256 lockedAt;
    }

    struct Staker {
        uint256 totalDepositTimes;
        uint256 totalLPLocked;
        uint256 rewardsKTYclaimed;
        uint256 rewardsSDAOclaimed;
    }

    mapping(address => mapping(uint256 => Deposit)) public deposits;
    mapping(address => Staker) public stakers;

    mapping(uint256 => uint256) public KTYunlockRate;
    mapping(uint256 => uint256) public SDAOunlockRate;
    
    // initializer
    function initialize(
        address _liquidityToken,
        address _kittieFightToken,
        address _superDaoToken
    ) external onlyOwner
    {
        LP = IUniswapV2ERC20(_liquidityToken);
        kittieFightToken = ERC20Standard(_kittieFightToken);
        superDaoToken = ERC20Standard(_superDaoToken);

        uint256[6] memory KTYunlockRates;
        uint256[6] memory SDAOunlockRates;
        KTYunlockRates[0] = 300000;
        KTYunlockRates[1] = 250000;
        KTYunlockRates[2] = 150000;
        KTYunlockRates[3] = 100000;
        KTYunlockRates[4] = 100000;
        KTYunlockRates[5] = 100000;

        SDAOunlockRates[0] = 100000;
        SDAOunlockRates[1] = 100000;
        SDAOunlockRates[2] = 100000;
        SDAOunlockRates[3] = 150000;
        SDAOunlockRates[4] = 250000;
        SDAOunlockRates[5] = 300000;

        setRewardUnlockRate(KTYunlockRates, SDAOunlockRates);

        uint256 duration = 180 * 24 * 60 * 60; // to do

        setProgramDuration(duration);
    }

    // events
    event Deposited(address indexed sender, uint256 depositAmount, uint256 indexed depositTime);

    event WithDrawn(
        address indexed sender,
        uint256 KTYamount,
        uint256 SDAOamount,
        uint256 LPamount,
        uint256 startDepositNumber,
        uint256 endDepositNumber, 
        uint256 withdrawTime
    );

    // YieldFarming functions
    function deposit(uint256 _amountLP) public returns (bool) {
         
        require(LP.transferFrom(msg.sender, address(this), _amountLP), "Fail to deposit liquidity tokens");

        _addDeposit(msg.sender, _amountLP, block.timestamp);

        emit Deposited(msg.sender, _amountLP, block.timestamp);

        return true;
    }

    function withDraw(uint256 _LP) public returns (bool) {
        require(_LP <= stakers[msg.sender].totalLPLocked, "Insuffient liquidity tokens locked");

        (uint256 _KTY, uint256 _SDAO, uint256 _startDepositNumber, uint256 _endDepositNumber) = estimateRewards(msg.sender, _LP);
        require(_KTY > 0 && _SDAO > 0, "Rewards cannot be 0");
        require(_startDepositNumber > 0 && _endDepositNumber > 0, "Invalid deposit number");

        // deduct _LP from mapping deposits storage
        _deductDeposits(msg.sender, _LP, _startDepositNumber, _endDepositNumber);

        // update _KTY, _SDAO, _LP in mapping stakers storage and public variables
        _updateWithdraw (_KTY, _SDAO, _LP);

        // transfer liquidity tokens, KTY and SDAO to the staker
        require(LP.transfer(msg.sender, _LP), "Fail to transfer liquidity token");
        require(kittieFightToken.transfer(msg.sender, _KTY), "Fail to transfer KTY");
        require(superDaoToken.transfer(msg.sender, _SDAO), "Fail to transfer SDAO");

        emit WithDrawn(msg.sender, _KTY, _SDAO, _LP, _startDepositNumber, _endDepositNumber, block.timestamp);
        return true;
    }

    // Setters
    function setRewardUnlockRate
    (
        uint256[6] memory _KTYunlockRates, uint256[6] memory _SDAOunlockRates
    ) 
        public onlyOwner
    {
        for (uint256 i = 0; i < 6; i++) {
            KTYunlockRate[i] = _KTYunlockRates[i];
            SDAOunlockRate[i] = _SDAOunlockRates[i];
        }
    }

    function modifyRewardUnlockRate(uint256 _month, uint256 _rate, bool forKTY) public onlyOwner {
        if (forKTY) {
            KTYunlockRate[_month] = _rate;
        } else {
            SDAOunlockRate[_month] = _rate;
        }
    }

    function setProgramDuration(uint256 _time) public onlyOwner {
        programDuration = _time;
    }

    // Getters
    function getLiquidityTokenBalance() public view returns (uint256) {
        return LP.balanceOf(msg.sender);
    }

    function estimateRewards(address _sender, uint256 _amountLP)
        public view
        returns (uint256 rewardKTY, uint256 rewardSDAO, uint256 startDepositNumber, uint256 endDepositNumber)
    {
        // to do
    }

    function getTotalLiquidityTokenLocked() public view returns (uint256) {
        return totalLockedLP;
    }

    function getLiquidityTokenLocked(address _staker) public view returns (uint256) {
        return stakers[_staker].totalLPLocked;
    }

    function getLiquidityTokenLockedPerBatch(address _staker, uint256 _depositNumber)
        public view returns (uint256)
    {
        return deposits[_staker][_depositNumber].amountLP;
    }

    function getTotalRewardsClaimed() public view returns (uint256, uint256) {
        uint256 totalKTYclaimed = totalRewardsKTYclaimed;
        uint256 totalSDAOclaimed = totalRewardsSDAOclaimed;
        return (totalKTYclaimed, totalSDAOclaimed);
    }

    function getAPY() public view returns (uint256) {
        // to do
    }


    function getRewardMultipliers() public view returns (uint256, uint256) {
        // to do
    }


    function getAccruedRewards() public view returns (uint256, uint256) {
        // to do
    }

    // Balance of TOTAL INITIAL KTY & SDAO Tokens to be distributed.
    function getTotalRewards() public view returns (uint256, uint256) {
        return (totalRewardsKTY, totalRewardsSDAO);
    }

    function getTotalDeposits() public view returns (uint256) {
        return totalDepositedLP;
    }

    function getLockedRewards() public view returns (uint256, uint256) {
        return (lockedRewardsKTY, lockedRewardsSDAO);
    }

    function getUnlockedRewards() public view returns (uint256, uint256) {
        uint256 unlockedKTY = totalRewardsKTY.sub(lockedRewardsKTY);
        uint256 unlockedSDAO = totalRewardsSDAO.sub(lockedRewardsSDAO);
        return (unlockedKTY, unlockedSDAO);
    }

    function getProgramDuration() public view returns (uint256, uint256, uint256) {
        // to do
    }

    function getRewardUnlockRate(uint256 _month) public view returns (uint256, uint256) {
        uint256 _KTYunlockRate = KTYunlockRate[_month];
        uint256 _SDAOunlockRate = SDAOunlockRate[_month];
        return (_KTYunlockRate, _SDAOunlockRate);
    }

    // internal functions used in deposit()
    function _addDeposit(address _sender, uint256 _amount, uint256 _lockedAt) internal {
        // get total deposit times for msgSender
        uint256 depositTimes = stakers[_sender].totalDepositTimes.add(1);
        stakers[_sender].totalDepositTimes = depositTimes;
        stakers[_sender].totalLPLocked = stakers[_sender].totalLPLocked.add(_amount);
        deposits[_sender][depositTimes].amountLP = _amount;
        deposits[_sender][depositTimes].lockedAt = block.timestamp;

        totalDepositedLP = totalDepositedLP.add(_amount);
        totalLockedLP = totalLockedLP.add(_amount);
    }

    // internal functions used in withdraw()
    function _deductDeposits
    (
        address _sender,
        uint256 _amount,
        uint256 _startDepositNumber,
        uint256 _endDepositNumber
    ) 
        internal 
    {
        uint256 withdrawAmount = 0;
        for (uint256 i = _startDepositNumber; i < _endDepositNumber; i++) {
            withdrawAmount = withdrawAmount.add(deposits[_sender][i].amountLP);
            deposits[_sender][i].amountLP = 0;
            deposits[_sender][i].lockedAt = 0;
        }
        uint256 leftAmountLP = _amount.sub(withdrawAmount);
        deposits[_sender][_endDepositNumber].amountLP = deposits[_sender][_endDepositNumber].amountLP.sub(leftAmountLP);
    }

    function _updateWithdraw (uint256 _KTY, uint256 _SDAO, uint256 _LP) internal {
        // update staker info
        stakers[msg.sender].totalLPLocked = stakers[msg.sender].totalLPLocked.sub(_LP);
        stakers[msg.sender].rewardsKTYclaimed = stakers[msg.sender].rewardsKTYclaimed.add(_KTY);
        stakers[msg.sender].rewardsSDAOclaimed = stakers[msg.sender].rewardsSDAOclaimed.add(_SDAO);
        // update public variables
        totalRewardsKTYclaimed = totalRewardsKTYclaimed.add(_KTY);
        totalRewardsSDAOclaimed = totalRewardsSDAOclaimed.add(_SDAO);
        totalLockedLP = totalLockedLP.sub(_LP);
    }

}