pragma solidity ^0.5.5;

import "../proxy/Proxied.sol";
import "./GenericDB.sol";
import "./GMGetterDB.sol";
import "./EarningsTrackerDB.sol";
import "../../libs/SafeMath.sol";
import "../gamemanager/GameStore.sol";
import "../gamemanager/GameManagerHelper.sol";
import '../endowment/KtyUniswap.sol';
import "../datetime/TimeFrame.sol";
import "./AccountingDB.sol";

/**
 * @title BusinessInsight
 * @notice This contract is responsible for providing business insight to the front end
 */

contract BusinessInsight is Proxied {
    using SafeMath for uint256;

    GenericDB public genericDB;
    TimeFrame public timeFrame;
    GMGetterDB public gmGetterDB;
    GameStore public gameStore;
    GameManagerHelper public gameManagerHelper;
    EarningsTrackerDB public earningsTrackerDB;
    KtyUniswap public ktyUniswap;
    AccountingDB public accountingDB;

    bytes32 internal constant TABLE_KEY_GAME= keccak256(abi.encodePacked("GameTable"));
    string internal constant TABLE_NAME_BETTOR = "BettorTable";

    function initialize() external onlyOwner {
        genericDB = GenericDB(proxy.getContract(CONTRACT_NAME_GENERIC_DB));
        timeFrame = TimeFrame(proxy.getContract(CONTRACT_NAME_TIMEFRAME));
        gmGetterDB = GMGetterDB(proxy.getContract(CONTRACT_NAME_GM_GETTER_DB));
        gameStore = GameStore(proxy.getContract(CONTRACT_NAME_GAMESTORE));
        gameManagerHelper = GameManagerHelper(proxy.getContract(CONTRACT_NAME_GAMEMANAGER_HELPER));
        earningsTrackerDB = EarningsTrackerDB(proxy.getContract(CONTRACT_NAME_EARNINGS_TRACKER_DB));
        ktyUniswap = KtyUniswap(proxy.getContract(CONTRACT_NAME_KTY_UNISWAP));
        accountingDB = AccountingDB(proxy.getContract(CONTRACT_NAME_ACCOUNTING_DB));
    }

    // ===================== FRONTEND GETTERS =====================

    // ========= getter for active epoch =========
    /**
     * @dev gets the current weekly epoch ID
     */
    function getCurrentEpoch() public view returns (uint256) {
        return timeFrame.getActiveEpochID();
    }

    // ========= getters about KTY uniswap in game =========
    /**
     * @dev returns the KTY to ether price on uniswap, that is, how many ether for 1 KTY
     */
    function KTY_ETH_price() public view returns (uint256) {
        return ktyUniswap.KTY_ETH_price();
    }

    /**
     * @dev returns the ether KTY price on uniswap, that is, how many KTYs for 1 ether
     */
    function ETH_KTY_price() public view returns (uint256) {
        return ktyUniswap.ETH_KTY_price();
    }

    /**
     * @dev return total Spent in ether in a game with gameId
     */
    function getTotalSpentInGame(uint256 gameId)
    public view returns (uint256)
    {
        return genericDB.getUintStorage(
            CONTRACT_NAME_ACCOUNTING_DB,
            keccak256(abi.encodePacked(gameId, "totalSpentInGame")));
    }

    /**
     * @dev return total uniswap auto-swapped KTY in a game with gameId
     */
    function getTotalSwappedKtyInGame(uint256 gameId)
    public view returns (uint256)
    {
        return genericDB.getUintStorage(
        CONTRACT_NAME_ACCOUNTING_DB,
        keccak256(abi.encodePacked(gameId, "totalSwappedKtyInGame")));
    }

    // ========= getters about game and honeypot =========
    function getLastGameID()
    public view returns (uint256)
    {
        (,uint256 _prevGameId) = genericDB.getAdjacent(CONTRACT_NAME_GM_SETTER_DB, TABLE_KEY_GAME, 0, true);
        return _prevGameId;
    }

    function getTotalGames()
    public view returns (uint256)
    {
        return getLastGameID();
    }

    function getInitialHoneypot(uint256 gameId)
        public view returns(uint256 initialHoneypotEth, uint256 initialHoneypotKty)
    {
        initialHoneypotEth = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "initialEth")));
        initialHoneypotKty = genericDB.getUintStorage(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, "initialKty")));
    }

    function getInitialHoneypotKTYInEther(uint256 gameId)
        public view returns (uint256)
    {
        (,uint256 _initialKTY) = getInitialHoneypot(gameId);
        return _initialKTY.mul(KtyUniswap(proxy.getContract(CONTRACT_NAME_KTY_UNISWAP)).KTY_ETH_price()).div(1000000000000000000);
    }

    // ========= getters about lenders (ethie token holders) =========
    /**
     * @return uint256 total interest accumulated for all Ethie Token NFTs in each epoch
     */
    function viewWeeklyInterests(uint256 _epochID) public view returns (uint256) {
        return genericDB.getUintStorage(
            CONTRACT_NAME_EARNINGS_TRACKER_DB,
            keccak256(abi.encodePacked(_epochID, "interest")));
    }

    /**
     * @dev calculates the total payout (i.e., total interest) for all lenders (i.e. ethie token holders)
     *      in the last weekly epoch
     * @return uint256 total payout for all lenders in the last weekly epoch
     */
    function getLastWeeklyLenderPayOut()
        public view returns (uint256)
    {
        uint256 lastEpochID = getCurrentEpoch() == 0 ? 0 : getCurrentEpoch().sub(1);
        uint256 lastWeeklyPayOut = viewWeeklyInterests(lastEpochID);
        return lastWeeklyPayOut;
    }

    /**
     * @dev calculates the total interest accumulated for all Ethie Token NFTs in the latest 250 epochs
     * @return uint256 total interest accumulated for all Ethie Token NFTs in the last 250 epochs
     */
    function viewTotalInterests() public view returns (uint256) {
        uint256 activeEpochID = timeFrame.getActiveEpochID();
        uint256 totalInterest = 0;
        for (uint256 i = 0; i < activeEpochID+1; i++) {
            uint256 interest = genericDB.getUintStorage(CONTRACT_NAME_EARNINGS_TRACKER_DB, keccak256(abi.encodePacked(i, "interest")));
            totalInterest = totalInterest.add(interest);
        }
        return totalInterest;
    }

    /**
     * @dev calculates the pooled ether for all lenders (i.e, investment) in an epoch with _epochID
     * @param _epochID uint256 epoch ID of the pooled ether
     * @return uint256 total payout for all lenders in all epochs
     */
    function getPooledEther(uint256 _epochID)
        public view returns (uint256)
    {
        return genericDB.getUintStorage(
            CONTRACT_NAME_EARNINGS_TRACKER_DB,
            keccak256(abi.encodePacked(_epochID, "investment")));
    }

    // ========= getters about withdraw pools (SuperDao stakers) =========
    /**
     * @dev This function is returning the Ether that has been allocated to all pools.
     */
    function viewTotalEthAllocatedToPools() public view returns (uint256) {
        uint256 activeEpochID = timeFrame.getActiveEpochID();
        uint256 totalAllocated = 0;
        for (uint256 i = 0; i < activeEpochID+1; i++) {
            uint256 allocated = getInitialETH(i);
            totalAllocated = totalAllocated.add(allocated);
        }
        return totalAllocated;
    }

    /**
     * @dev This function is returning the Ether that has been claimed by all pools.
     */
    function getEthPaidOut()
    external
    view
    returns(uint256)
    {
        return genericDB.getUintStorage(
            CONTRACT_NAME_WITHDRAW_POOL_YIELDS,
            keccak256(abi.encode("totalEthPaidOut"))
          );
    }

    // get the initial ether available in a pool
    function getInitialETH(uint256 _poolID)
        public
        view
        returns (uint256)
    {
        return genericDB.getUintStorage(
            CONTRACT_NAME_ENDOWMENT_DB,
            keccak256(abi.encodePacked(_poolID, "InitialETHinPool"))
          );
    }

    // ========= getters about ethie tokens =========
    function getEthieInfo(uint256 _ethieTokenID)
        public view
        returns (
            uint256 etherValue,
            uint256 startingEpoch,
            uint256 generation,
            uint256 lockedAt,
            uint256 lockTime,
            bool isBurnt
        )
    {
        etherValue = genericDB.getUintStorage(
            CONTRACT_NAME_EARNINGS_TRACKER,
            keccak256(abi.encodePacked(_ethieTokenID, "ethValue"))
            );
        startingEpoch = genericDB.getUintStorage(
            CONTRACT_NAME_EARNINGS_TRACKER,
            keccak256(abi.encodePacked(_ethieTokenID, "startingEpochID"))
            );

        generation = genericDB.getUintStorage(
            CONTRACT_NAME_EARNINGS_TRACKER,
            keccak256(abi.encodePacked(_ethieTokenID, "generation"))
            );
        lockedAt = genericDB.getUintStorage(
            CONTRACT_NAME_EARNINGS_TRACKER,
            keccak256(abi.encodePacked(_ethieTokenID, "lockedAt"))
            );
        lockTime = genericDB.getUintStorage(
            CONTRACT_NAME_EARNINGS_TRACKER,
            keccak256(abi.encodePacked(_ethieTokenID, "lockTime"))
            );
        isBurnt = genericDB.getBoolStorage(
            CONTRACT_NAME_EARNINGS_TRACKER,
            keccak256(abi.encodePacked(_ethieTokenID, "tokenBurnt"))
            );
    }
    
    // ========= getters for static values =========
    /** returns following values:
     *   bettingFee((1)ether for swap, (2)KTY)
     *   ticketFee((1)ether for swap, (2)KTY)
     *   redemptionFee ((1)ether for swap, (2)KTY)
     *   kittieHellExpirationTime
     *   honeypotExpirationTime
     *   minimumContributors

     *   an array for all share distribution rates:
        [
            shareWinner,
            shareTopSupporter,
            shareSecondSupporter,
            shareRemainingSupporter,
            shareEndowmentFund,
        ]
     */
     function getGameStaticInfo(uint256 gameId)
     public view
     returns (
         uint256 bettingFeeEtherSwap,
         uint256 bettingFeeKTY,
         uint256 ticketFeeEtherSwap,
         uint256 ticketFeeKTY,
         uint256 redemptionFeeEtherSwap,
         uint256 redemptionFeeKTY,
         uint256 kittieHellExpirationTime,
         uint256 honeypotExpirationTime,
         uint256 minimumContributors,
         uint256[5] memory shares
     )
     {
         (bettingFeeEtherSwap, bettingFeeKTY) = accountingDB.getBettingFee(gameId);
         (ticketFeeEtherSwap, ticketFeeKTY) = accountingDB.getTicketFee(gameId);
         (redemptionFeeEtherSwap, redemptionFeeKTY) = accountingDB.getKittieRedemptionFee(gameId);
         kittieHellExpirationTime = accountingDB.getKittieExpirationTime(gameId);
         honeypotExpirationTime = accountingDB.getHoneypotExpiration(gameId);
         minimumContributors = gameManagerHelper.getMinimumContributors(gameId);
         shares = gameManagerHelper.getDistributionRates(gameId);
     }

     /**
      * getter for dynamic values which are called periodically (every block) in FE
      * returns:
      * time info         (GMGetterDB.getGameTimes)
      * honeypot info     (GMGetterDB.getHoneypotInfo, getFinalHoneypot)
      * winner info       (GMGetterDB.getWinners)
      */
    function getGameDynamicInfo(uint gameId)
    public view
    returns (
        uint[3] memory gameTimes,
        uint[6] memory honeypotInfo,
        uint[2] memory ethByCorner,
        uint[2] memory finalHoneypot,
        address[3] memory winners
    )
    {
        // get game times
        gameTimes = getGameTimes(gameId);
        // get honeypot info
        (honeypotInfo, ethByCorner, finalHoneypot) = getHoneypot(gameId);
        // get winner info
        winners = getWinners(gameId);
    }

    function getAccountInfo(address account)
    public view
    returns(bool isRegistered, bool isVerified, uint256 civicId)
    {
        isRegistered = Register(proxy.getContract(CONTRACT_NAME_REGISTER)).isRegistered(account);
        civicId = ProfileDB(proxy.getContract(CONTRACT_NAME_PROFILE_DB)).getCivicId(account);
        isVerified = civicId > 0;
    }

    // ========= other getters =========
    function getWinners(uint gameId) public view returns (address[3] memory winners) {
        (address winner, address topBettor, address secondTopBettor) = gmGetterDB.getWinners(gameId);
        winners[0] = winner;
        winners[1] = topBettor;
        winners[2] = secondTopBettor;
    }

    function getGameTimes(uint gameId) public view returns (uint[3] memory gameTimes) {
        (uint startTime, uint preStartTime, uint endTime) = gmGetterDB.getGameTimes(gameId);
        gameTimes[0] = startTime;
        gameTimes[1] = preStartTime;
        gameTimes[2] = endTime;
    }

    function getHoneypot(uint gameId)
    public view
    returns (uint[6] memory honeypotInfo, uint[2] memory ethByCorner, uint[2] memory finalHoneypot)
    {
        // honeypot 
        (uint honeypotId, uint status, uint initialEth,
         uint ethTotal,,uint ktyTotal, uint expTime) = gmGetterDB.getHoneypotInfo(gameId);
        honeypotInfo[0] = honeypotId;
        honeypotInfo[1] = status;
        honeypotInfo[2] = initialEth;
        honeypotInfo[3] = ethTotal;
        honeypotInfo[4] = ktyTotal;
        honeypotInfo[5] = expTime;
        (,,,,ethByCorner,,) = gmGetterDB.getHoneypotInfo(gameId);
        // final honey pot
        (uint totalEthFinal, uint totalKtyFinal) = gmGetterDB.getFinalHoneypot(gameId);
        finalHoneypot[0] = totalEthFinal;
        finalHoneypot[1] = totalKtyFinal;
    }

    function getMyInfo(uint256 gameId, address sender)
    public view
    returns(bool isSupporter, uint supportedCorner, bool isPlayerInGame, uint corner)
    {
        isSupporter = genericDB.doesNodeAddrExist(CONTRACT_NAME_GM_SETTER_DB, keccak256(abi.encodePacked(gameId, TABLE_NAME_BETTOR)), sender);
        address supportedPlayer = genericDB.getAddressStorage(
            CONTRACT_NAME_GM_SETTER_DB,
            keccak256(abi.encodePacked(gameId, sender, "supportedPlayer")));
        supportedCorner = gameManagerHelper.getCorner(gameId, supportedPlayer);
        isPlayerInGame = gmGetterDB.isPlayer(gameId, sender);
        corner = gameManagerHelper.getCorner(gameId, sender);
    }

    function getPlayer(uint gameId, address player)
    public view
    returns(uint kittieId, uint corner, uint betsTotalEth)
    {
        kittieId = gmGetterDB.getKittieInGame(gameId, player);
        corner = gameManagerHelper.getCorner(gameId, player);
        betsTotalEth = gmGetterDB.getTotalBet(gameId, player);
    }
}