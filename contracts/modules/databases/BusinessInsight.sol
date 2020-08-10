pragma solidity ^0.5.5;

import "../proxy/Proxied.sol";
import "./GenericDB.sol";
import "./GMGetterDB.sol";
import "../../libs/SafeMath.sol";
import "../gamemanager/GameStore.sol";


contract BusinessInsight is Proxied {
    using SafeMath for uint256;

    GenericDB public genericDB;
    GMGetterDB public gmGetterDB;
    GameStore public gameStore;

    bytes32 internal constant TABLE_KEY_GAME= keccak256(abi.encodePacked("GameTable"));
    string internal constant TABLE_NAME_BETTOR = "BettorTable";

    function initialize() external onlyOwner {
        genericDB = GenericDB(proxy.getContract(CONTRACT_NAME_GENERIC_DB));
        gmGetterDB = GMGetterDB(proxy.getContract(CONTRACT_NAME_GM_GETTER_DB));
        gameStore = GameStore(proxy.getContract(CONTRACT_NAME_GAMESTORE));
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
        supportedCorner = gameStore.getCorner(gameId, supportedPlayer);
        isPlayerInGame = gmGetterDB.isPlayer(gameId, sender);
        corner = gameStore.getCorner(gameId, sender);
    }

    function getPlayer(uint gameId, address player)
    public view
    returns(uint kittieId, uint corner, uint betsTotalEth)
    {
        kittieId = gmGetterDB.getKittieInGame(gameId, player);
        corner = gameStore.getCorner(gameId, player);
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
}