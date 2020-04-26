/**
* @title EarningsTracker
*
* @author @ziweidream
*
*/
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
    TimeFrame public timeFrame;
    GameVarAndFee public gameVarAndFee;
    EndowmentFund public endowmentFund;

    /// @dev current funding limit
    uint256 public currentFundingLimit;

    /// @dev true if deposits are disabled
    bool internal depositsDisabled;

    uint256 constant WEEK                        = 7 * 24 * 60 * 60;
    uint256 constant THIRTY_DAYS                 = 30 * 24 * 60 * 60;   // GEN 0
    uint256 constant SIXTY_DAYS                  = 60 * 24 * 60 * 60;   // GEN 1
    uint256 constant SEVENTY_FIVE_DAYS           = 75 * 24 * 60 * 60;   // GEN 2
    uint256 constant NINETY_DAYS                 = 90 * 24 * 60 * 60;   // GEN 3
    uint256 constant ONE_HUNDRED_AND_FIVE_DAYS   = 105 * 24 * 60 * 60;  // GEN 4
    uint256 constant ONE_HUNDRED_AND_TWENTY_DAYS = 120 * 24 * 60 * 60;  // GEN 5
    uint256 constant ONE_HUNDRED_AND_THIRTY_FIVE_DAYS = 135 * 24 * 60 * 60;  // GEN 6

    uint256 internal factor;               // used in calculating the total interest accumulated in all Ethie Tokens
    uint256 internal interestReleased;     // interest released from all burnt Ethie token NFTs
    uint256 public totalBalance;  // total ETH balance from all generations

    /// @dev an EthieToken NFT's associated properties
    struct NFT {
        address originalOwner; // the owner of this token at the time of minting
        uint256 generation;    // the generation of this funds, between number 0 and 6
        uint256 ethValue;      // the funder's current funding balance (ether deposited - ether withdrawal)
        uint256 lockedAt;      // the unix time at which this funds is locked
        uint256 lockTime;      // lock duration
        bool tokenBurnt;       // true if this token has been burnt
        uint256 tokenBurntAt;  // the time when this token was burnt
        address tokenBurntBy;  // who burnt this token (if this token was burnt)
        uint256 interestPaid; // interest released to the burner when this token was burnt
        uint256 startingEpochID; //The epochId this token started to contribute.
    }

    struct AmountsEpoch {
        uint256 investment;
        uint256 interest;
    }

    mapping(uint256 => AmountsEpoch) public amountsPerEpoch;

    /// @dev a generation's associated properties
    struct Generation {
        uint256 start;           // time when this generation starts
        uint256 ethBalance;      // the lastest ether balance associated with this generation
        uint256 ethBalanceAt;    // the last time when the ethBlance is modified
        bool limitReached;       // true if the funding limit of this generation is reached
        uint256 numberOfNFTs;    // number of NFTs associated with this generation
    }

    /// @dev mapping generation ID to its properties
    mapping (uint256 => Generation) generations;

    /// @dev mapping ethieToken NFT to its properties
    mapping(uint256 => NFT) ethieTokens;

    /// @dev funding limit for each generation, pre-set in initialization, can only be changed by admin
    mapping (uint256 => uint256) public fundingLimit;

    //============================ Initializer ============================
    // pre-set funding limit for each generation during initialization
    // No funding limit in generation 6. 2**256-1 is the maximum for uint256.
    // But 2**200 is a number big enough to be used as the maximum here.
    function initialize(address _ethieToken) external onlyOwner {
        ethieToken = IEthieToken(_ethieToken);
        timeFrame = TimeFrame(proxy.getContract(CONTRACT_NAME_TIMEFRAME));
        gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        endowmentFund = EndowmentFund(proxy.getContract(CONTRACT_NAME_ENDOWMENT_FUND));

        fundingLimit[0] = 500 * 1e18;
        fundingLimit[1] = 1000 * 1e18;
        fundingLimit[2] = 2000 * 1e18;
        fundingLimit[3] = 5000 * 1e18;
        fundingLimit[4] = 10000 * 1e18;
        fundingLimit[5] = 50000 * 1e18;
        fundingLimit[6] = 2**200;
    }

    //============================ Events ============================
    event EtherLocked(
        address indexed funder,
        uint256 indexed ethieTokenID,
        uint256 indexed generation
    );

    event EthieTokenBurnt(
        address indexed burner,
        uint256 indexed ethieTokenID,
        uint256 indexed generation,
        uint256 principalEther,
        uint256 interestPaid
    );

    //============================ Public Functions ============================

    function setInvestment(uint256 epoch_id, uint256 _investment)
    external
    onlyContract(CONTRACT_NAME_WITHDRAW_POOL)
    {
        amountsPerEpoch[epoch_id].investment = _investment;
    }

    function setInterest(uint256 epoch_id, uint256 _total)
    external
    onlyContract(CONTRACT_NAME_WITHDRAW_POOL)
    {
        amountsPerEpoch[epoch_id].interest = _total.sub(amountsPerEpoch[epoch_id].investment);
    }

    /**
     * @dev deposit eth and receive an NFT token, which can be burned
     * in order to retrieve locked eth and accumulated interest
     * @return uint256 ID of the Ethie Token NFT minted to the funder
     */
    function lockETH()
        external
        payable
        //onlyProxy
        returns (uint256)
    {
        require(depositsDisabled == false, "Deposits are not allowed at this time");
        uint256 currentGeneration = getCurrentGeneration();
        // if funding limit of current generation is reached, reject any deposit
        require(generations[currentGeneration].limitReached == false,
                "Current funding limit has already been reached");

        uint256 _ethBalance = generations[currentGeneration].ethBalance;
        uint256 _fundingLimit = currentFundingLimit;
        uint256 _totalETH = _ethBalance.add(msg.value);
        address _funder = getOriginalSender();

        // // transfer funds to endowmentFund
        require(endowmentFund.contributeETH_Ethie.value(msg.value)(), "Funds deposit failed");

        uint256 _lockTime;
        uint256 _ethieTokenID;

        if (_fundingLimit < _totalETH) {
            uint256 _extra = _totalETH.sub(_fundingLimit);
            uint256 _legitEthValue = msg.value.sub(_extra);
            // calculate locktime
            _lockTime = generateLockTime(_legitEthValue);
            // receive an NFT token
            _ethieTokenID = _mint(_funder, _legitEthValue, _lockTime);
            // update funder profile
            _updateFunder_mint(_funder, _legitEthValue, _lockTime, _ethieTokenID);
            // update generation profile
            _updateGeneration_mint(_legitEthValue);
            // return extra ether back to the funder
            _returnEther(msg.sender, _extra, false);

            generations[currentGeneration].limitReached == true;

        } else {
            // calculate locktime
            _lockTime = generateLockTime(msg.value);
            // receive an NFT token
            _ethieTokenID = _mint(_funder, msg.value, _lockTime);
            // update funder profile
            _updateFunder_mint(_funder, msg.value, _lockTime, _ethieTokenID);
            // update generation profile
            _updateGeneration_mint(msg.value);

            if (_fundingLimit == _totalETH) {
                generations[currentGeneration].limitReached = true;
            }
        }

        if(amountsPerEpoch[0].investment == 0)
            ethieTokens[_ethieTokenID].startingEpochID = 0;
        else {
            uint256 nextEpoch = getCurrentEpoch().add(1);
            ethieTokens[_ethieTokenID].startingEpochID = nextEpoch;
        }

        emit EtherLocked(_funder, _ethieTokenID, currentGeneration);

        return _ethieTokenID;
    }

    /**
     * @dev Release ether and cumulative interest to investor by burning Ethie Token NFT
     * Requires KTY token payment
     * In the future, will give user lotto to redeem a high priced kitty from KittieHELL
     * @param _ethieTokenID uint256 the ID of the Ethie Token NFT
     * @return true if this NFT is burnt and locked ethers and cumulative interest
     * are transferred to the token owner
     */
    function burnNFT
    (
        uint256 _ethieTokenID
    )
        external returns(bool)
    {
        // Ethie Tokens can only be burnt on a Rest Day in the current epoch
        require(timeFrame.checkBurn(), "Can only burn on Rest Day");

        // the token may be sold to another person, therefore,
        // current owner may not be necessarily the original owner of
        // this token when it was minted.

        // get the current owner of the token
        //EthieToken ethieToken = EthieToken(proxy.getContract(CONTRACT_NAME_ETHIE_TOKEN));
        address currentOwner = ethieToken.ownerOf(_ethieTokenID);
        require(currentOwner == msg.sender, "Only the owner of this token can burn it");

        // require this token had not been burnt already
        require(ethieTokens[_ethieTokenID].tokenBurnt == false,
                "This EthieToken NFT has already been burnt");
        // requires KTY payment
        uint256 _kty_fee = KTYforBurnEthie();
        require(endowmentFund.contributeKTY(msg.sender, _kty_fee),
                "Failed to pay KTY fee for burning Ethie Token");

        // burn Ethie Token NFT
        ethieToken.burn(_ethieTokenID);

        uint256 tokenLockedAt = ethieTokens[_ethieTokenID].lockedAt;
        uint256 lockTime = now.sub(tokenLockedAt);
        // calculate interest
        uint256 ethValue = ethieTokens[_ethieTokenID].ethValue;
        uint256 generation = ethieTokens[_ethieTokenID].generation;
        uint256 totalEth = calculateTotal(ethValue, ethieTokens[_ethieTokenID].startingEpochID);
        uint256 interest = totalEth.sub(ethValue);
        // update generations
        _updateGeneration_burn(generation, ethValue);
        // update funder
        _updateFunder_burn(msg.sender, _ethieTokenID, interest);
        // update burntTokens
        // release ETH and accumulative interest to the current owner
        uint256 activeEpochID = timeFrame.getActiveEpochID();
        if(ethieTokens[_ethieTokenID].startingEpochID < activeEpochID)
            _returnEther(msg.sender, totalEth, false);
        else
            _returnEther(msg.sender, totalEth, true);

        factor = factor.sub(ethValue.mul(tokenLockedAt));
        interestReleased = interestReleased.add(interest);
        totalBalance = totalBalance.sub(ethValue);

        emit EthieTokenBurnt(msg.sender, _ethieTokenID, generation, ethValue, interest);
        return true;
    }

    //============================ Setters ============================
    /**
     * @dev moves the current funding to limit to next funding limit
     * can only be called when current funding limit is already reached
     * can only be called by admin
     */
    function setCurrentFundingLimit()
        public
        onlyAdmin
    {
        if (currentFundingLimit == 0) {
            currentFundingLimit = fundingLimit[0];
        } else {
            uint256 currentGeneration = getCurrentGeneration();
            require(generations[currentGeneration].limitReached == true, "Previous funding limit hasn't been reached");
            uint256 nextGeneration = currentGeneration.add(1);
            // get previous generation funding limit
            uint256 _prevFundingLimit = fundingLimit[currentGeneration];
            // get current generation funding limit (which is preset)
            uint256 _currentFundingLimit = fundingLimit[nextGeneration];
            require(_currentFundingLimit > _prevFundingLimit,
                    "Funding limit must be bigger than the previous generation");
            currentFundingLimit = _currentFundingLimit;
        }
    }

    /**
     * @dev modify pre-set funding limit for a generation
     * can only be called by admin
     * @param _generation the id of the generation of which the funding limit is modified
     * @param _fundingLimit the new funding limit of _generation
     */
    function modifyFundingLimit(uint256 _generation, uint256 _fundingLimit)
        public
        onlyAdmin
    {
        if (_generation == 0) {
            fundingLimit[_generation] = _fundingLimit;
        } else if (_generation > 0) {
            uint256 _prevGeneration = _generation.sub(1);
            require(_fundingLimit > fundingLimit[_prevGeneration],
                    "Funding limit must be higher than the previous generation");
            fundingLimit[_generation] = _fundingLimit;
        }
    }

    /**
     * @dev stops any ability to continue to deposit funds
     * can only be called by admin
     */
    function stopDeposits()
        public
        onlyAdmin
    {
        depositsDisabled = true;
    }

    /**
     * @dev re-enables any ability to continue to deposit funds
     * can only be called by admin
     */
    function enableDeposits()
        public
        onlyAdmin
    {
        depositsDisabled = false;
    }

    /**
     * @dev set current generation in EthieToken contract
     * can only be called by admin
     */
    function incrementGenerationInEthieToken() public onlyAdmin {
        ethieToken.incrementGeneration();
    }

    //============================ Getters ============================
    /**
     * @dev gets the ID of the current generation
     */
    function getCurrentGeneration()
        public view returns (uint256)
    {
       for (uint256 i = 0; i < 6; i++) {
           if (fundingLimit[i] == currentFundingLimit) {
               return i;
           }
       }
       return 6;
    }

    /**
     * @dev gets the current funding limit of the current generation
     */
    function getcurrentFundingLimit() public view returns (uint256) {
        return currentFundingLimit;
    }

    /**
     * @dev gets the pre-set funding limit for the generation with id _generation
     */
    function getFundingLimit(uint256 _generation) public view returns (uint256) {
        return fundingLimit[_generation];
    }

    /**
     * @dev true if the funding limit of the generation is reached
     */
    function hasReachedLimit(uint256 _generation) public view returns (bool) {
        return generations[_generation].limitReached;
    }

    /**
     * @dev gets the difference between the funding limit and the actual funding in current generation
     */
    function ethNeededToReachFundingLimit() public view returns (uint256) {
        uint256 currentGeneration = getCurrentGeneration();
        return currentFundingLimit.sub(generations[currentGeneration].ethBalance);
    }

    /**
     * @dev calculates the total interest accumulated for all Ethie Token NFTs in all generations
     * Formula: Total interest =
     *   weekly interest x (total ether balance from all generations x now – factor) / WEEK
     *   + total interest from burnt tokens
     * @return uint256 total interest accumulated for all Ethie Token NFTs
     */
    function viewTotalInterests() public view returns (uint256) {
        uint256 r = gameVarAndFee.getInterestEthie();
        uint256 total = totalBalance.mul(now).div(WEEK);
        uint256 f = factor.div(WEEK);
        uint256 dif = total.sub(f);
        uint256 interest = r.mul(dif).div(1000000);
        uint256 totalInterest = interest.add(interestReleased);
        return totalInterest;
    }

    /**
     * @dev gets the interest accumulated for an Ethie Token NFT
     * @param _eth_amount uint256 the amount of ethers associated with this NFT
     * with this NFT has been locked
     * @return uint256 interest accumulated in the NFT
     */
    function calculateTotal(uint256 _eth_amount, uint256 _startingEpoch)
        public view returns (uint256)
    {
        uint256 activeEpochID = timeFrame.getActiveEpochID();
        if(_startingEpoch > activeEpochID) {
            return _eth_amount;
        }
        else {
            uint256 proportion = _eth_amount;
            for(uint256 i = _startingEpoch; i < activeEpochID.add(1); i++) {
                uint256 epochInterest = proportion.mul(amountsPerEpoch[i].interest).div(amountsPerEpoch[i].investment);
                proportion = proportion.add(epochInterest);
            }
            return proportion;
        }
    }

    /**
     * @dev gets the current weekly epoch ID
     */
    function getCurrentEpoch() public view returns (uint256) {
        return timeFrame.getActiveEpochID();
    }

    /**
     * @dev ture if now is in the stage of Six-Working-Days in a current weekly epoch
     */
    function isWorkingDay() public view returns (bool) {
        if (now <= timeFrame.workingDayEndTime()) {
            return true;
        }
        return false;
    }

    function canBurn() public view returns (bool) {
        if (now <= timeFrame.workingDayEndTime()) {
            return true;
        }
        return false;
    }

    /**
     * @dev gets state, stage date and time (in unix) in a current weekly epoch
     * @return string state, uint256 start time, uint256 end time
     */
    function _viewEpochStage() public view returns (string memory state, uint256 start, uint256 end) {
        if (now <= timeFrame.workingDayEndTime()) {
            state = "Working Days";
            start = timeFrame.workingDayStartTime();
            end = timeFrame.workingDayEndTime();
        } else if (now > timeFrame.workingDayEndTime()) {
            state = "Rest Day";
            start = timeFrame.restDayStartTime();
            end = timeFrame.restDayEndTime();
        }
    }

    /**
     * @dev gets state, stage start date and time (human-readable) in a current weekly epoch
     */
    function viewEpochStageStartTime()
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
        uint256 startTime;
        (state, startTime,) = _viewEpochStage();
        (startYear, startMonth, startDay, startHour, startMinute, startSecond) = timeFrame.timestampToDateTime(startTime);
    }

    /**
     * @dev gets state, stage end date and time (human-readable) in a current weekly epoch
     */
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
        uint256 endTime;
        (state,, endTime) = _viewEpochStage();
        (endYear, endMonth, endDay, endHour, endMinute, endSecond) = timeFrame.timestampToDateTime(endTime);
    }

    /**
     * @dev gets the next date and time in which an investor can withdraw locked ethers
     * and earnings by burning an Ethie Token NFT
     * @param ethieTokenID uint256 the ID of the Ethie Token NFT to be burnt
     */
    function viewNextYieldClaimDate(uint256 ethieTokenID)
        public view
        returns(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
    {
        uint256 lockTime = ethieTokens[ethieTokenID].lockTime;
        uint256 lockedAt = ethieTokens[ethieTokenID].lockedAt;
        uint256 unLockAt = lockedAt.add(lockTime);
        (year, month, day, hour, minute, second) = timeFrame.timestampToDateTime(unLockAt);
    }

    /**
     * @dev gets the date and time at which ethers were locked for an Ethie Token NFT
     * @param ethieTokenID uint256 the ID of the Ethie Token NFT to be burntT
     */
    function checkLockETHDate(uint256 ethieTokenID)
        public view
        returns(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
    {
        uint256 lockedAt = ethieTokens[ethieTokenID].lockedAt;
        (year, month, day, hour, minute, second) = timeFrame.timestampToDateTime(lockedAt);
    }

    /**
     * @dev Generates locktime based on investment SIZE, generation and funding limit
     * Max funding limit/Value * 30 days
     * @param _eth_amount uint256 the amount of ethers to be locked
     * @return uint256 locktime in seconds
     */
    function generateLockTime (uint256 _eth_amount)
        public view returns (uint256)
    {
        uint256 _generation = getCurrentGeneration();
        uint256 _fundingLimit = currentFundingLimit;
        if (_generation == 0) {
            return THIRTY_DAYS.mul(_fundingLimit).div(_eth_amount);
        }
        else if (_generation == 1) {
            return SIXTY_DAYS.mul(_fundingLimit).div(_eth_amount);
        }
        else if (_generation == 2) {
            return SEVENTY_FIVE_DAYS.mul(_fundingLimit).div(_eth_amount);
        }
        else if (_generation == 3) {
            return NINETY_DAYS.mul(_fundingLimit).div(_eth_amount);
        }
        else if (_generation == 4) {
            return ONE_HUNDRED_AND_FIVE_DAYS.mul(_fundingLimit).div(_eth_amount);
        }
        else if (_generation == 5) {
            return ONE_HUNDRED_AND_TWENTY_DAYS.mul(_fundingLimit).div(_eth_amount);
        }
        else{
            //TODO: how to factor in generation 6 the funding limit of which is extremely large
            return ONE_HUNDRED_AND_THIRTY_FIVE_DAYS.mul(_fundingLimit).div(_eth_amount);
        }
    }

    /**
     * @dev gets the required KTY fee for burning an Ethie Token NFT
     */
    function KTYforBurnEthie() public view returns (uint256) {
        return gameVarAndFee.getKTYforBurnEthie();
    }

    //============================ Internal Functions ============================
    /**
     * @dev transfers ethers to an investor
     * @param _funder account address of the investor
     * @param _eth_amount uint256 the amount of ethers to transfer to _funder
     */
    function _returnEther(address payable _funder, uint256 _eth_amount, bool invested)
        internal
    {
        endowmentFund.transferETHfromEscrowEarningsTracker(_funder, _eth_amount, invested);
    }

    /**
     * @dev Updates funder profile when minting a new token to a funder
     */
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

        factor = factor.add(now.mul(_eth_amount));
    }

    /**
     * @dev Updates generation profile when minting a new Ethie Token NFT
     * @param _eth_amount uint256 the amount of ethers locked for the new Ethie Token NFT
     */
    function _updateGeneration_mint(
        uint256 _eth_amount
    ) internal {
        uint256 _generation = getCurrentGeneration();
        generations[_generation].ethBalance = generations[_generation].ethBalance.add(_eth_amount);
        generations[_generation].ethBalanceAt = now;
        generations[_generation].numberOfNFTs = generations[_generation].numberOfNFTs.add(1);

        totalBalance = totalBalance.add(_eth_amount);
    }

    /**
     * @dev Updates generation profile when an existing Ethie Token NFT is burnt
     * @param _generation generation ID associated with this Ethie Token NFT
     * @param _eth_amount uint256 the amount of ethers released for burning the Ethie Token NFT
     */
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

    /**
     * @dev Updates funder profile when an existing Ethie Token NFT is burnt
     * @param _burner address who burns this NFT
     * @param _ethieTokenID uint256 the ID of the burnt Ethie Token NFT
     */
    function _updateFunder_burn
    (
        address _burner,
        uint256 _ethieTokenID,
        uint256 _interestPaid
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
        ethieTokens[_ethieTokenID].interestPaid = _interestPaid;
    }

    /**
     * @dev Called by LockETH(), pass values to generate Ethie Token NFT with all atrributes as listed in params
     * @param _to address who this Ethie Token NFT is minted to
     * @param _ethAmount uint256 the amount of ethers associated with this NFT
     * @param _lockTime uint256 the time duration during which the ethers associated
     * with this NFT has been locked
     * @return uint256 ID of the Ethie Token NFT minted
     */
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

}