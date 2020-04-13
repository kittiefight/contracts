pragma solidity ^0.5.5;

import '../proxy/Proxied.sol';
import '../../authority/Guard.sol';
import '../../libs/SafeMath.sol';
import '../datetime/TimeFrame.sol';
import '../../GameVarAndFee.sol';
import './EndowmentFund.sol';
import '../../interfaces/IEthieToken.sol';


contract EarningsTracker is Proxied, Guard {
    using SafeMath for uint256;

    // Contract variables
    IEthieToken public ethieToken;
    //TimeFrame public timeFrame;
    //EndowmentFund public endowmentFund;

    // current funding limit - this funding limit determines the generation
    // this variable can be read by public, but can only be set by Admin
    uint256 public currentFundingLimit;

    // whether deposits are disabled
    bool internal depositsDisabled;

    uint256 constant WEEK = 7 * 24 * 60 * 60;
    uint256 constant THIRTY_DAYS = 30 * 24 * 60 * 60;

    struct NFT {
        address originalOwner; // the owner of this token at the time of minting
        uint256 generation;    // the generation of this funds, between number 0 and 6
        uint256 ethValue;      // the funder's current funding balance (ether deposited - ether withdrawal)
        uint256 lockedAt;      // the unix time at which this funds is locked
        uint256 lockTime;      // lock duration
        bool tokenBurnt;       // true if this token has been burnt
        uint256 tokenBurntAt;  // the time when this token was burnt
        address tokenBurntBy;  // who burnt this token (if this token was burnt)
    }

    struct Generation {
        uint256 start;           // time when this generation starts
        uint256 ethBalance;      // the lastest ether balance associated with this generation
        uint256 ethBalanceAt;    // the last time when the ethBlance is modified
        bool limitReached;
        uint256 numberOfNFTs;    // number of NFTs associated with this generation
    }

    // mapping generation to funding limit and other attributes associated with this generation
    mapping (uint256 => Generation) generations;

    // mapping ethieToken NFT to its properties
    mapping(uint256 => NFT) ethieTokens;

    // funding limit for each generation
    // pre-set in initialization
    // can only be changed by admin
    mapping (uint256 => uint256) public fundingLimit;

    // pre-set funding limit for each generation during initialization
    // No funding limit in generation 6. 2**256-1 is the maximum for uint256.
    // But 2**200 is a number big enough to be used as the maximum here.
    function initialize(address _ethieToken) external onlyOwner {
        ethieToken = IEthieToken(_ethieToken);

        fundingLimit[0] = 500 * 1e18;
        fundingLimit[1] = 1000 * 1e18;
        fundingLimit[2] = 2000 * 1e18;
        fundingLimit[3] = 5000 * 1e18;
        fundingLimit[4] = 10000 * 1e18;
        fundingLimit[5] = 50000 * 1e18;
        fundingLimit[6] = 2**200;
    }

    // deposit eth and receive an NFT token, which can be burned in order to retrieve
    // locked eth and interest
    function lockETH() external payable  returns (bool) {
        require(depositsDisabled == false, "Deposits are not allowed at this time");
        uint256 currentGeneration = getCurrentGeneration();
        // if funding limit of current generation is reached, reject any deposit
        require(!hasReachedLimit(currentGeneration),
                "Current funding limit has already been reached");

        uint256 _ethBalance = generations[currentGeneration].ethBalance;
        uint256 _fundingLimit = fundingLimit[currentGeneration];
        uint256 _totalETH = _ethBalance.add(msg.value);
        address _funder = getOriginalSender();
        
        if (_fundingLimit < _totalETH) {
            uint256 _extra = _totalETH.sub(_fundingLimit);
            _lockETH(_funder, msg.value);

            //TODO: truffle compile error for _funder: Invalid implicit conversion from address to address payable requested.
            // getOriginalSender() is not address payable
            //_returnEther(_funder, _extra);
            _returnEther(msg.sender, _extra);
            generations[currentGeneration].limitReached == true;
        } else if (_fundingLimit == _totalETH) {
            _lockETH(_funder, msg.value);
            generations[currentGeneration].limitReached == true;
        } else {
            _lockETH(_funder, msg.value);
        }

        return true;
    }

    // Release ether and cumulative interest to investor by burning KETH NFT
    // Requires KTY token payment
    // In the future, will give user lotto to redeem a high priced kitty
    function burnNFT
    (
        uint256 _ethieTokenID, uint256 _kty_fee
    ) 
        external returns(bool)
    {
        // the token may be sold to another person, therefore,
        // current owner may not be necessarily the original owner of
        // this token when it was minted.

        // get the current owner of the token
        //EthieToken ethieToken = EthieToken(proxy.getContract(CONTRACT_NAME_ETHIE_TOKEN));
        address currentOwner = ethieToken.ownerOf(_ethieTokenID);
        require(currentOwner == msg.sender);

        uint256 lockTime = now.sub(ethieTokens[_ethieTokenID].lockedAt);
        require(lockTime >= ethieTokens[_ethieTokenID].lockTime,
                "The lock time limit for this token has not been reached yet");

        // require this token had not been burnt already
        require(ethieTokens[_ethieTokenID].tokenBurnt == false,
                "This EthieToken NFT has already been burnt");
        // requires KTY payment
        require(_kty_fee == KTYforBurnEthie(),
                "Incorrect amount of KTY payment for burning Ethie token");
        
        uint256 ethValue = ethieTokens[_ethieTokenID].ethValue;
        uint256 generation = ethieTokens[_ethieTokenID].generation;
        // burn KETH NFT
        _burn(_ethieTokenID);

        // calculate interest
        uint256 interest = calculateInterest(ethValue, lockTime);
        uint256 totalEth = ethValue.add(interest);
        // update generations
        _updateGeneration_burn(generation, totalEth);
        // update funder
        _updateFunder_burn(msg.sender, _ethieTokenID);
        // update burntTokens
        // release ETH and accumulative interest to the current owner
        _returnEther(msg.sender, totalEth);
       
        // TODO: give user lotto to redeem a high priced kitty
        return true;
    }

    function setCurrentFundingLimit()
        public
        onlyAdmin
    {
        uint256 currentGeneration = getCurrentGeneration();
        // get previous generation funding limit
        uint256 _prevFundingLimit = currentGeneration == 0? 0 : fundingLimit[currentGeneration.sub(1)];
        // get current generation funding limit (which is preset)
        uint256 _currentFundingLimit = fundingLimit[currentGeneration];
        require(_currentFundingLimit > _prevFundingLimit,
                "Funding limit must be bigger than the previous generation");
        currentFundingLimit = _currentFundingLimit;
    }

    // modify pre-set funding limit for a generation, only called by admin
    function modifyFundingLimit(uint256 _generation, uint256 _fundingLimit)
        public
        onlyAdmin
    {
        fundingLimit[_generation] = _fundingLimit;
    }

    // stops any ability to continue to deposit funds
    function stopDeposits()
        internal
        onlyAdmin
    {
        depositsDisabled = true;
    }

    // re-enables any ability to continue to deposit funds
    function enableDeposits()
        internal
        onlyAdmin
    {
        depositsDisabled = false;
    }

    // Getters
    function getCurrentGeneration()
        public view returns (uint256)
    {
       for (uint256 i = 0; i < 6; i++) {
           if (fundingLimit[i] == currentFundingLimit) {
               return i;
           }
       }
    }

    // returns the current funding limit of the current generation
    function getcurrentFundingLimit() public view returns (uint256) {
        return currentFundingLimit;
    }

    // returns the pre-set funding limit for each generation
    function getFundingLimit(uint256 _generation) public view returns (uint256) {
        return fundingLimit[_generation];
    }

    function hasReachedLimit(uint256 _generation) public view returns (bool) {
        return generations[_generation].limitReached == true;
    }

    // returns the difference between the funding limit and the actual funding in current generation
    function howFartoFundingLimit() public view returns (uint256) {
        uint256 currentGeneration = getCurrentGeneration();
        return currentFundingLimit.sub(generations[currentGeneration].ethBalance);
    }

    // calculates and returns value of total interest earnings
    function viewTotalInterests() public view returns (uint256) {
        // todo
    }

    function calculateInterest(uint256 _eth_amount, uint256 _lockTime)
        public view returns (uint256 interest)
    {
        // formula for calculating simple interest: interest = A*r*t
        // A = principle money, r = interest rate, t = time
        GameVarAndFee gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        interest = _eth_amount.mul(gameVarAndFee.getInterestEthie()).mul(_lockTime.div(WEEK));
    }

    // returns current weekly epoch ID
    function getCurrentEpoch() public view returns (uint256) {
        TimeFrame timeFrame = TimeFrame(proxy.getContract(CONTRACT_NAME_TIMEFRAME));
        return timeFrame.getActiveEpochID();
    }

    // returns state, stage date and time (in unix) in a current weekly epoch
    function _viewEpochStage() public view returns (string memory state, uint256 start, uint256 end) {
        TimeFrame timeFrame = TimeFrame(proxy.getContract(CONTRACT_NAME_TIMEFRAME));
        uint256 currentEpochID = getCurrentEpoch();
        if (timeFrame.isWorkingDay(currentEpochID)) {
            state = "Working Days";
            end = (timeFrame._epochEndTime(currentEpochID)).sub(timeFrame.REST_DAY());
            start = timeFrame._epochStartTime(currentEpochID);
        } else {
            state = "Rest Day";
            end = timeFrame._epochEndTime(currentEpochID);
            start = end.sub(timeFrame.REST_DAY());
        }
    }

    // returns state, stage start date and time (human-readable) in a current weekly epoch
    function viewEpochStartStage()
        public view
        returns (
            string memory state,
            uint256 startYear,
            uint256 startMonth,
            uint256 startDay,
            uint256 startHour,
            uint256 startMinute,
            uint256 startSecond
        )
    {
        TimeFrame timeFrame = TimeFrame(proxy.getContract(CONTRACT_NAME_TIMEFRAME));
        uint256 startTime;
        (state, startTime,) = _viewEpochStage();
        (startYear, startMonth, startDay, startHour, startMinute, startSecond) = timeFrame.timestampToDateTime(startTime);
    }

    // returns state, stage end date and time (human-readable) in a current weekly epoch
    function viewEpochStageEndTime()
        public view
        returns (
            string memory state,
            uint256 endYear,
            uint256 endMonth,
            uint256 endDay,
            uint256 endHour,
            uint256 endMinute,
            uint256 endSecond
        )
    {
        TimeFrame timeFrame = TimeFrame(proxy.getContract(CONTRACT_NAME_TIMEFRAME));
        uint256 endTime;
        (state,, endTime) = _viewEpochStage();
        (endYear, endMonth, endDay, endHour, endMinute, endSecond) = timeFrame.timestampToDateTime(endTime);
    }

    // Returns the next date in which an investor can withdraw lockedETH and earnings by burning KETH
    function viewNextYieldClaimDate(uint256 ethieTokenID) 
        public view
        returns(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
    {
        TimeFrame timeFrame = TimeFrame(proxy.getContract(CONTRACT_NAME_TIMEFRAME));
        uint256 lockTime = ethieTokens[ethieTokenID].lockTime;
        uint256 lockedAt = ethieTokens[ethieTokenID].lockedAt;
        uint256 unLockAt = lockedAt.add(lockTime);
        (year, month, day, hour, minute, second) = timeFrame.timestampToDateTime(unLockAt);
    }

    // Check and return the date of locked ETH
    function checkLockETHDate(uint256 ethieTokenID)
        public view
        returns(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
    {
        TimeFrame timeFrame = TimeFrame(proxy.getContract(CONTRACT_NAME_TIMEFRAME));
        uint256 lockedAt = ethieTokens[ethieTokenID].lockedAt;
        (year, month, day, hour, minute, second) = timeFrame.timestampToDateTime(lockedAt);

    }

    // stale function
    // generate a gen for KETH to be generated based on the funding limit
   // function genGenerator(uint256 _eth_amount) public view returns (uint256) {
     //   for (uint i = 0; i < 6; i++) {
       //     if (_eth_amount <= fundingLimit[i]) {
         //       return i;
           // }
       // }
        //return 6;
    //}

    // for example, 2.5 is amplified by 1000000
    //becomes 2500000 returned to have precision of 7 digits
    function getPercentage(uint256 numerator, uint256 denominator)
        public view returns (uint256 quotient)
    {
        // amplify the numerator 10 ** 7 to get precision of 7 digits
        uint _numerator = numerator.mul(10 ** 7);
        // with rounding of last digit
        quotient = (_numerator.div(denominator).add(5)).div(10);
    }

    // generate locktime based on investment SIZE, generation and funding limit
    // Max funding limit/Value * 30 days
    // return locktime in days * 1000000
    function generateLockTime (uint256 _eth_amount)
        public view returns (uint256 lockTime)
    {
        uint256 _generation = getCurrentGeneration();
        uint256 _fundingLimit = currentFundingLimit;
        if (_generation == 6) {
            //TODO: how to factor in generation 6 which doesn't have a funding limit
            return THIRTY_DAYS.mul(1000000);
        }
        lockTime = THIRTY_DAYS.mul(getPercentage(_fundingLimit, _eth_amount));
    }

    function KTYforBurnEthie() public view returns (uint256) {
        GameVarAndFee gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        return gameVarAndFee.getKTYforBurnEthie();
    }

    // Internal Functions
    function _returnEther(address payable _funder, uint256 _eth_amount)
        internal
    {
        EndowmentFund endowmentFund = EndowmentFund(proxy.getContract(CONTRACT_NAME_ENDOWMENT_FUND));
        endowmentFund.transferETHfromEscrowEarningsTracker(_funder, _eth_amount);
    }
    
    // update funder profile when minting a new token
    function _updateFunder_mint
    (
        address _funder,
        uint256 _eth_amount,
        uint256 _lockTime,
        uint256 _ethieTokenID
    )
        internal
    {
        ethieTokens[_ethieTokenID].generation = getCurrentGeneration();
        ethieTokens[_ethieTokenID].ethValue = _eth_amount;
        ethieTokens[_ethieTokenID].lockedAt = now;
        ethieTokens[_ethieTokenID].lockTime = _lockTime;
        ethieTokens[_ethieTokenID].originalOwner = _funder;
    }
    
    // update generation profile when minting a new token
    function _updateGeneration_mint(
        uint256 _eth_amount
    ) internal {
        uint256 _generation = getCurrentGeneration();
        generations[_generation].ethBalance = generations[_generation].ethBalance.add(_eth_amount);
        generations[_generation].ethBalanceAt = now;
        generations[_generation].numberOfNFTs = generations[_generation].numberOfNFTs.add(1);
    }


    function _updateGeneration_burn(uint256 _generation, uint256 _eth_amount)
        internal
    {
        generations[_generation].ethBalance = generations[_generation].ethBalance.sub(_eth_amount);
        generations[_generation].ethBalanceAt = now;
        generations[_generation].numberOfNFTs = generations[_generation].numberOfNFTs.sub(1);

        // if _generation is current generation, then set limitReached as false if it is set true
        uint256 currentGeneration = getCurrentGeneration();
        if ((_generation == currentGeneration) && (generations[_generation].limitReached == true)) {
            generations[_generation].limitReached == false;
        }
    }

    function _updateFunder_burn
    (
        address _burner,
        uint256 _ethieTokenID
    )
        internal
    {
        // set values to 0 can get gas refund
        ethieTokens[_ethieTokenID].ethValue = 0;
        ethieTokens[_ethieTokenID].lockedAt = 0;
        ethieTokens[_ethieTokenID].lockTime = 0;
        ethieTokens[_ethieTokenID].tokenBurnt = true;
        ethieTokens[_ethieTokenID].tokenBurntAt = now;
        ethieTokens[_ethieTokenID].tokenBurntBy = _burner;
    }

    // called by BurnNFT to destroy a specific KETH NFT by ID
    function _burn(uint256 _tokenID) internal {
        ethieToken.burn(_tokenID);
    }

    // Called by LockETH, pass values to generate KETH with all atrributes as listed in params
    function _mint
    (
        address _to,
        uint256 _ethAmount,
        uint256 _lockTime
    )
        internal
        returns (uint256)
    {
        return ethieToken.mint(_to, _ethAmount, _lockTime);
    }

    function _lockETH(address _funder, uint256 _eth_amount) internal {
        // deposit ether
        EndowmentFund endowmentFund = EndowmentFund(proxy.getContract(CONTRACT_NAME_ENDOWMENT_FUND));
        endowmentFund.sendETHtoEscrow();
        // calculate locktime
        uint256 _lockTime = generateLockTime(_eth_amount);
        // receive an NFT token
        uint256 _ethieTokenID = _mint(_funder, _eth_amount, _lockTime);
        // update funder profile
        _updateFunder_mint(_funder, _eth_amount, _lockTime, _ethieTokenID);
        // update generation profile
        _updateGeneration_mint(_eth_amount);
    }

}