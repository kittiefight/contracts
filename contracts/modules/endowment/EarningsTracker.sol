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
import './EndowmentFund.sol';
import '../../interfaces/IEthieToken.sol';
import "../databases/GenericDB.sol";
import "../databases/EarningsTrackerDB.sol";


contract EarningsTracker is Proxied, Guard {
    using SafeMath for uint256;

    // Contract variables
    IEthieToken public ethieToken;
    EndowmentFund public endowmentFund;
    GenericDB public genericDB;
    EarningsTrackerDB public earningsTrackerDB;

    //============================ Initializer ============================

    function initialize() external onlyOwner {
        ethieToken = IEthieToken(proxy.getContract(CONTRACT_NAME_ETHIETOKEN));
        endowmentFund = EndowmentFund(proxy.getContract(CONTRACT_NAME_ENDOWMENT_FUND));
        genericDB = GenericDB(proxy.getContract(CONTRACT_NAME_GENERIC_DB));
        earningsTrackerDB = EarningsTrackerDB(proxy.getContract(CONTRACT_NAME_EARNINGS_TRACKER_DB));
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

    

    /**
     * @dev deposit eth and receive an NFT token, which can be burned
     * in order to retrieve locked eth and accumulated interest
     * @return uint256 ID of the Ethie Token NFT minted to the funder
     */
    function lockETH()
        external
        payable
        onlyProxy
        returns (uint256)
    {
        require(earningsTrackerDB.isDepositsDisabled() == false, "Deposits disabled");
        uint256 currentGeneration = earningsTrackerDB.getCurrentGeneration();
        // if funding limit of current generation is reached, reject any deposit
        require(!genericDB.getBoolStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(currentGeneration, "limitReached"))),
                "Current funding limit reached");

        uint256 _ethBalance = genericDB.getUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(currentGeneration, "ethBalance")));
        uint256 _fundingLimit = earningsTrackerDB.getcurrentFundingLimit();
        uint256 _totalETH = _ethBalance.add(msg.value);
        address _funder = getOriginalSender();

        // transfer funds to endowmentFund
        require(endowmentFund.contributeETH_Ethie.value(msg.value)(), "Funds deposit failed");

        uint256 _lockTime;
        uint256 _ethieTokenID;

        if (_fundingLimit < _totalETH) {
            uint256 _extra = _totalETH.sub(_fundingLimit);
            uint256 _legitEthValue = msg.value.sub(_extra);
            // calculate locktime
            _lockTime = earningsTrackerDB.generateLockTime(_legitEthValue);
            // receive an NFT token
            _ethieTokenID = _mint(_funder, _legitEthValue, _lockTime);
            // update funder profile
            _updateFunder_mint(_funder, _legitEthValue, _lockTime, _ethieTokenID);
            // update generation profile
            _updateGeneration_mint(_legitEthValue);
            // return extra ether back to the funder
            _returnEther(msg.sender, _extra, false);

            genericDB.setBoolStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(currentGeneration, "limitReached")), true);

        } else {
            // calculate locktime
            _lockTime = earningsTrackerDB.generateLockTime(msg.value);
            // receive an NFT token
            _ethieTokenID = _mint(_funder, msg.value, _lockTime);
            // update funder profile
            _updateFunder_mint(_funder, msg.value, _lockTime, _ethieTokenID);
            // update generation profile
            _updateGeneration_mint(msg.value);

            if (_fundingLimit == _totalETH) {
                earningsTrackerDB.setLimitReachedOrNot(currentGeneration, true);
            }
        }

        if(genericDB.getUintStorage(CONTRACT_NAME_EARNINGS_TRACKER_DB, keccak256(abi.encodePacked("0", "investment"))) == 0)
            genericDB.setUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_ethieTokenID, "startingEpochID")), 0);
        else {
            uint256 nextEpoch = genericDB.getUintStorage(CONTRACT_NAME_TIMEFRAME, keccak256(abi.encode("activeEpoch"))).add(1);
            genericDB.setUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_ethieTokenID, "startingEpochID")), nextEpoch);
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
        external onlyProxy payable returns(bool)
    {
        // Ethie Tokens can only be burnt on a Rest Day in the current epoch
        require(genericDB.getBoolStorage(CONTRACT_NAME_WITHDRAW_POOL, keccak256(abi.encode("rest_day"))), "Can only burn on Rest Day");

        // the token may be sold to another person, therefore,
        // current owner may not be necessarily the original owner of
        // this token when it was minted.

        // get the current owner of the token
        //EthieToken ethieToken = EthieToken(proxy.getContract(CONTRACT_NAME_ETHIE_TOKEN));
        address payable msgSender = address(uint160(getOriginalSender()));
        address currentOwner = ethieToken.ownerOf(_ethieTokenID);
        require(currentOwner == msgSender, "Only the token owner can burn");

        // require this token had not been burnt already
        require(!genericDB.getBoolStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_ethieTokenID, "tokenBurnt"))),
                "Already burnt");
        // requires KTY payment
        (uint256 _eth_for_swap, uint256 _kty_fee) = earningsTrackerDB.KTYforBurnEthie(_ethieTokenID);
        require(endowmentFund.contributeKTY.value(msg.value)(msgSender, _eth_for_swap, _kty_fee),
                "Failed to pay KTY burning fee");

        // burn Ethie Token NFT
        ethieToken.burn(_ethieTokenID);

        uint256 tokenLockedAt = genericDB.getUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_ethieTokenID, "lockedAt")));
        uint256 lockTime = now.sub(tokenLockedAt);
        // calculate interest
        uint256 ethValue = genericDB.getUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_ethieTokenID, "ethValue")));
        uint256 generation = genericDB.getUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_ethieTokenID, "generation")));
        uint256 startingEpochID = genericDB.getUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_ethieTokenID, "startingEpochID")));
        uint256 totalEth = earningsTrackerDB.calculateTotal(ethValue, startingEpochID);
        uint256 interest = totalEth.sub(ethValue);
        // update generations
        _updateGeneration_burn(generation, ethValue);
        // update funder
        _updateFunder_burn(msgSender, _ethieTokenID, interest);
        // update burntTokens
        // release ETH and accumulative interest to the current owner
        uint256 activeEpochID = genericDB.getUintStorage(CONTRACT_NAME_TIMEFRAME, keccak256(abi.encode("activeEpoch")));
        if(startingEpochID > activeEpochID)
            _returnEther(msgSender, totalEth, false);
        else
            _returnEther(msgSender, totalEth, true);

        emit EthieTokenBurnt(msgSender, _ethieTokenID, generation, ethValue, interest);
        return true;
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
        genericDB.setUintStorage(
            CONTRACT_NAME_EARNINGS_TRACKER,
            keccak256(abi.encodePacked(_ethieTokenID, "generation")),
            earningsTrackerDB.getCurrentGeneration());
        genericDB.setUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_ethieTokenID, "ethValue")), _eth_amount);
        genericDB.setUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_ethieTokenID, "lockedAt")), now);
        genericDB.setUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_ethieTokenID, "lockTime")), _lockTime);
        genericDB.setAddressStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_ethieTokenID, "originalOwner")), _funder);
    }

    /**
     * @dev Updates generation profile when minting a new Ethie Token NFT
     * @param _eth_amount uint256 the amount of ethers locked for the new Ethie Token NFT
     */
    function _updateGeneration_mint(
        uint256 _eth_amount
    ) internal {
        uint256 _generation = earningsTrackerDB.getCurrentGeneration();
        uint256 ethBalance = genericDB.getUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_generation, "ethBalance")));
        genericDB.setUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_generation, "ethBalance")), ethBalance.add(_eth_amount));
        genericDB.setUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_generation, "ethBalanceAt")), now);
        uint256 noOfNFTs = genericDB.getUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_generation, "ethBalance")));        
        genericDB.setUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_generation, "numberOfNFTs")), noOfNFTs.add(1));
    }

    /**
     * @dev Updates generation profile when an existing Ethie Token NFT is burnt
     * @param _generation generation ID associated with this Ethie Token NFT
     * @param _eth_amount uint256 the amount of ethers released for burning the Ethie Token NFT
     */
    function _updateGeneration_burn(uint256 _generation, uint256 _eth_amount)
        internal
    {        
        uint256 ethBalance = genericDB.getUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_generation, "ethBalance")));
        genericDB.setUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_generation, "ethBalance")), ethBalance.sub(_eth_amount));
        genericDB.setUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_generation, "ethBalanceAt")), now);
        uint256 noOfNFTs = genericDB.getUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_generation, "ethBalance")));        
        genericDB.setUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_generation, "numberOfNFTs")), noOfNFTs.sub(1));

        // if _generation is current generation, then set limitReached as false if it is set true
        uint256 currentGeneration = earningsTrackerDB.getCurrentGeneration();
        if ((_generation == currentGeneration) && (earningsTrackerDB.hasReachedLimit(currentGeneration)))
            earningsTrackerDB.setLimitReachedOrNot(currentGeneration, false);
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
        genericDB.setUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_ethieTokenID, "ethValue")), 0);
        genericDB.setUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_ethieTokenID, "lockedAt")), 0);
        genericDB.setUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_ethieTokenID, "lockTime")), 0);
        genericDB.setBoolStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_ethieTokenID, "tokenBurnt")), true); 
        genericDB.setUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_ethieTokenID, "tokenBurntAt")), now);
        genericDB.setAddressStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_ethieTokenID, "tokenBurntBy")), _burner);
        genericDB.setUintStorage(CONTRACT_NAME_EARNINGS_TRACKER, keccak256(abi.encodePacked(_ethieTokenID, "interestPaid")), _interestPaid);
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
