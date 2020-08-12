pragma solidity ^0.5.5;

import '../proxy/Proxied.sol';
import '../../authority/Guard.sol';
import "./GenericDB.sol";
import '../../libs/SafeMath.sol';
import '../datetime/TimeFrame.sol';
import '../../GameVarAndFee.sol';
import '../../interfaces/IEthieToken.sol';


contract EarningsTrackerDB is Proxied, Guard {
    using SafeMath for uint256;

    GenericDB public genericDB;
    TimeFrame public timeFrame;
    GameVarAndFee public gameVarAndFee;
    IEthieToken public ethieToken;

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

    /// @dev funding limit for each generation, pre-set in initialization, can only be changed by admin
    mapping (uint256 => uint256) public fundingLimit;

    constructor(GenericDB _genericDB) public {
        setGenericDB(_genericDB);
    }

    function setGenericDB(GenericDB _genericDB) public onlyOwner {
        genericDB = _genericDB;
    }

    // pre-set funding limit for each generation during initialization
    // No funding limit in generation 6. 2**256-1 is the maximum for uint256.
    // But 2**200 is a number big enough to be used as the maximum here.
    function initialize() public onlyOwner {
        timeFrame = TimeFrame(proxy.getContract(CONTRACT_NAME_TIMEFRAME));
        gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        ethieToken = IEthieToken(proxy.getContract(CONTRACT_NAME_ETHIETOKEN));

        fundingLimit[0] = 500 * 1e18;
        fundingLimit[1] = 1000 * 1e18;
        fundingLimit[2] = 2000 * 1e18;
        fundingLimit[3] = 5000 * 1e18;
        fundingLimit[4] = 10000 * 1e18;
        fundingLimit[5] = 50000 * 1e18;
        fundingLimit[6] = 2**200;

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

    /**
     * @dev moves the current funding to limit to next funding limit
     * can only be called when current funding limit is already reached
     * can only be called by admin
     */
    function setCurrentFundingLimit()
        public
        onlyAdmin
    {
        if (getcurrentFundingLimit() == 0) {
            genericDB.setUintStorage(CONTRACT_NAME_EARNINGS_TRACKER_DB, keccak256(abi.encode("currentFundingLimit")), fundingLimit[0]);
        } else {
            uint256 currentGeneration = getCurrentGeneration();
            require(genericDB.getBoolStorage(CONTRACT_NAME_EARNINGS_TRACKER_DB, keccak256(abi.encodePacked(currentGeneration, "limitReached"))),
                "Previous funding limit hasn't been reached");
            uint256 nextGeneration = currentGeneration.add(1);
            // get previous generation funding limit
            uint256 _prevFundingLimit = fundingLimit[currentGeneration];
            // get current generation funding limit (which is preset)
            uint256 _currentFundingLimit = fundingLimit[nextGeneration];
            require(_currentFundingLimit > _prevFundingLimit,
                    "Funding limit must be bigger than the previous generation");
            genericDB.setUintStorage(CONTRACT_NAME_EARNINGS_TRACKER_DB, keccak256(abi.encode("currentFundingLimit")), _currentFundingLimit);
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

    function setInvestment(uint256 epoch_id, uint256 _investment)
    external
    onlyContract(CONTRACT_NAME_WITHDRAW_POOL)
    {
        require(_investment > 0, "Waiting Investment");
        genericDB.setUintStorage(CONTRACT_NAME_EARNINGS_TRACKER_DB, keccak256(abi.encodePacked(epoch_id, "investment")), _investment);
    }

    function setInterest(uint256 epoch_id, uint256 _total)
    external
    onlyContract(CONTRACT_NAME_WITHDRAW_POOL)
    {
        uint256 investment = genericDB.getUintStorage(CONTRACT_NAME_EARNINGS_TRACKER_DB, keccak256(abi.encodePacked(epoch_id, "investment")));
        genericDB.setUintStorage(CONTRACT_NAME_EARNINGS_TRACKER_DB, keccak256(abi.encodePacked(epoch_id, "interest")),
            _total.sub(investment));
    }

    function setLimitReachedOrNot(uint256 _currentGeneration, bool limitReached)
    external
    onlyContract(CONTRACT_NAME_EARNINGS_TRACKER)
    {
        genericDB.setBoolStorage(
            CONTRACT_NAME_EARNINGS_TRACKER_DB,
            keccak256(abi.encodePacked(_currentGeneration, "limitReached")),
            limitReached);
    }

    function isDepositsDisabled() public view returns (bool) {
        return depositsDisabled;
    }
 
    /**
     * @dev gets the ID of the current generation
     */
    function getCurrentGeneration()
        public view returns (uint256)
    {
       for (uint256 i = 0; i < 7; i++) {
           if (fundingLimit[i] == getcurrentFundingLimit()) {
               return i;
           }
       }
    }

    /**
     * @dev gets the current funding limit of the current generation
     */
    function getcurrentFundingLimit() public view returns (uint256) {
        return genericDB.getUintStorage(CONTRACT_NAME_EARNINGS_TRACKER_DB, keccak256(abi.encode("currentFundingLimit")));
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
        return genericDB.getBoolStorage(CONTRACT_NAME_EARNINGS_TRACKER_DB, keccak256(abi.encodePacked(_generation, "limitReached")));
    }

    /**
     * @dev gets the difference between the funding limit and the actual funding in current generation
     */
    function ethNeededToReachFundingLimit() public view returns (uint256) {
        uint256 currentGeneration = getCurrentGeneration();
        return getcurrentFundingLimit().sub(genericDB.getUintStorage(CONTRACT_NAME_EARNINGS_TRACKER,
            keccak256(abi.encodePacked(currentGeneration, "ethBalance"))));
    }

    /**
     * @return uint256 total interest accumulated for all Ethie Token NFTs in each epoch
     */
    function viewWeeklyInterests(uint256 _epochID) public view returns (uint256) {
        return genericDB.getUintStorage(
            CONTRACT_NAME_EARNINGS_TRACKER_DB,
            keccak256(abi.encodePacked(_epochID, "interest")));
    }

    /**
     * @dev calculates the total interest accumulated for all Ethie Token NFTs in the latest 250 epochs
     * @return uint256 total interest accumulated for all Ethie Token NFTs in the last 250 epochs
     */
    function viewTotalInterests() public view returns (uint256) {
        uint256 activeEpochID = timeFrame.getActiveEpochID();
        uint256 totalInterest = 0;
        uint256 startID = activeEpochID < 250 ? 0 : activeEpochID - 250;
        for (uint256 i = startID; i < activeEpochID; i++) {
            uint256 interest = genericDB.getUintStorage(CONTRACT_NAME_EARNINGS_TRACKER_DB, keccak256(abi.encodePacked(i, "interest")));
            totalInterest = totalInterest.add(interest);
        }
        return totalInterest;

    }

    /**
     * @dev gets principal ethers locked plus the interest accumulated for an Ethie Token NFT
     * @param _eth_amount uint256 the amount of ethers associated with this NFT
     * with this NFT has been locked
     * @return uint256 principal ethers locked and interest accumulated in the NFT
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
                uint256  investment = genericDB.getUintStorage(CONTRACT_NAME_EARNINGS_TRACKER_DB, keccak256(abi.encodePacked(i, "investment")));
                uint256  interest = genericDB.getUintStorage(CONTRACT_NAME_EARNINGS_TRACKER_DB, keccak256(abi.encodePacked(i, "interest")));
                uint256 epochInterest = proportion.mul(interest).div(investment);
                proportion = proportion.add(epochInterest);
            }
            return proportion;
        }
    }

    /**
     * @dev gets the current weekly epoch ID
     */
    // function getCurrentEpoch() public view returns (uint256) {
    //     return timeFrame.getActiveEpochID();
    // }

    // function canBurn() public view returns (bool) {
    //     if (now <= timeFrame.workingDayEndTime()) {
    //         return true;
    //     }
    //     return false;
    // }

    
    /**
     * @dev gets the required KTY fee for burning an Ethie Token NFT
     */
    function KTYforBurnEthie(uint256 ethieTokenID) public view returns (uint256, uint256) {
        uint256 percentageBurnEthie = gameVarAndFee.getPercentageforBurnEthie();
        uint256 eth_amount = genericDB.getUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(ethieTokenID, "ethValue")));
        uint256 startingEpoch = genericDB.getUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(ethieTokenID, "startingEpochID")));
        uint256 withdrawAmountETH = calculateTotal(eth_amount, startingEpoch);
        uint256 withdrawAmountKTY = gameVarAndFee.convertEthToKty(withdrawAmountETH);
        uint256 burnEthieFeeKTY = withdrawAmountKTY.mul(percentageBurnEthie).div(1000000);
        uint256 etherForSwap = KtyUniswap(proxy.getContract(CONTRACT_NAME_KTY_UNISWAP)).etherFor(burnEthieFeeKTY);
        return (etherForSwap, burnEthieFeeKTY);
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
     * @dev gets the next unix time in which an investor can withdraw locked ethers
     * and earnings by burning an Ethie Token NFT and get future benefits like access to
     * pricy kitties in KittiHELL and lottery benefits
     * @param ethieTokenID uint256 the ID of the Ethie Token NFT to be burnt
     */
    function _viewNextYieldClaimDate(uint256 ethieTokenID)
        public view
        returns(uint256)
    {
        uint256 lockTime = genericDB.getUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(ethieTokenID, "lockTime")));
        uint256 lockedAt = genericDB.getUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(ethieTokenID, "lockedAt")));
        uint256 unLockAt = lockedAt.add(lockTime);
        return unLockAt;
    }

    /**
     * @dev gets unix time at which ethers were locked for an Ethie Token NFT
     * @param ethieTokenID uint256 the ID of the Ethie Token NFT to be burntT
     */
    function _checkLockETHDate(uint256 ethieTokenID)
        public view
        returns(uint256)
    {
        uint256 lockedAt = genericDB.getUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(ethieTokenID, "lockedAt")));
        return lockedAt;
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
        uint256 _fundingLimit = getcurrentFundingLimit();
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


}
  