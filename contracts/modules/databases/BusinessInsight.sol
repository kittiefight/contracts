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



contract BusinessInsight is Proxied {
    using SafeMath for uint256;

    GenericDB public genericDB;
    TimeFrame public timeFrame;
    GMGetterDB public gmGetterDB;
    GameStore public gameStore;
    GameManagerHelper public gameManagerHelper;
    EarningsTrackerDB public earningsTrackerDB;
    KtyUniswap public ktyUniswap;

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
    }

     // === FRONTEND GETTERS ===
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

    function getAccountInfo(address account)
    public view
    returns(bool isRegistered, bool isVerified)
    {
        isRegistered = Register(proxy.getContract(CONTRACT_NAME_REGISTER)).isRegistered(account);
        uint civicId = ProfileDB(proxy.getContract(CONTRACT_NAME_PROFILE_DB)).getCivicId(account);
        isVerified = civicId > 0;
    }

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

    ///@dev return total Spent in ether in a game with gameId
    function getTotalSpentInGame(uint256 gameId)
    public view returns (uint256)
    {
        return genericDB.getUintStorage(
            CONTRACT_NAME_GM_SETTER_DB,
            keccak256(abi.encodePacked(gameId, "totalSpentInGame")));
    }

    ///@dev return total uniswap auto-swapped KTY in a game with gameId
    function getTotalSwappedKtyInGame(uint256 gameId)
    public view returns (uint256)
    {
        return genericDB.getUintStorage(
        CONTRACT_NAME_GM_SETTER_DB,
        keccak256(abi.encodePacked(gameId, "totalSwappedKtyInGame")));
    }

    /**
     * @dev gets the current weekly epoch ID
     */
    function getCurrentEpoch() public view returns (uint256) {
        return timeFrame.getActiveEpochID();
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
        uint256 startID = activeEpochID < 250 ? 0 : activeEpochID - 250;
        for (uint256 i = startID; i < activeEpochID; i++) {
            uint256 interest = genericDB.getUintStorage(CONTRACT_NAME_EARNINGS_TRACKER_DB, keccak256(abi.encodePacked(i, "interest")));
            totalInterest = totalInterest.add(interest);
        }
        return totalInterest;

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
}