pragma solidity ^0.5.5;

import '../proxy/Proxied.sol';
import "../../GameVarAndFee.sol";

contract GameStore is Proxied {

    GameVarAndFee public gameVarAndFee;

    struct Game {
        uint randomNum; //when pressing start
        bool pressedStart;
        address topBettor;
        address secondTopBettor;
    }

    struct GlobalSettings {
        uint bettingFee;
        uint ticketFee;
        uint redemptionFee;
        uint kittieHellExpirationTime;
        uint honeypotExpirationTime;
        uint minimumContributors;
        uint[5] distributionRates;
    }

    //Players info in a game
    mapping(uint => mapping(address => Game)) public gameByPlayer;
    mapping(uint => GlobalSettings) public gameSettings;

    function initialize() external onlyOwner {
        gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
    }

    function lockVars(uint gameId) external onlyContract(CONTRACT_NAME_GAMECREATION){
        GlobalSettings memory globalSettings;

        globalSettings.bettingFee = gameVarAndFee.getBettingFee();
        globalSettings.ticketFee = gameVarAndFee.getTicketFee();
        globalSettings.redemptionFee = gameVarAndFee.getKittieRedemptionFee();
        globalSettings.kittieHellExpirationTime = gameVarAndFee.getKittieExpiry();
        globalSettings.honeypotExpirationTime = gameVarAndFee.getHoneypotExpiration();
        globalSettings.minimumContributors = gameVarAndFee.getMinimumContributors();
        globalSettings.distributionRates = gameVarAndFee.getDistributionRates();

        gameSettings[gameId] = globalSettings;
    }

    function getDistributionRates(uint gameId) public view returns(uint[5] memory){
        return gameSettings[gameId].distributionRates;
    }

    function getKittieExpirationTime(uint gameId) public view returns(uint){
        return  gameSettings[gameId].kittieHellExpirationTime;
    }

    function getKittieRedemptionFee(uint gameId) public view returns(uint){
        return  gameSettings[gameId].redemptionFee;
    }
    
    function getHoneypotExpiration(uint gameId) public view returns(uint){
        return  gameSettings[gameId].honeypotExpirationTime;
    }


    function start(uint gameId, address player, uint randomNum) external onlyContract(CONTRACT_NAME_GAMEMANAGER){
        gameByPlayer[gameId][player].pressedStart = true;
        gameByPlayer[gameId][player].randomNum = randomNum;
    }

    function didHitStart(uint gameId, address player) public view returns(bool){
        return gameByPlayer[gameId][player].pressedStart;
    }

    function getRandom(uint gameId, address player) public view returns(uint){
        return gameByPlayer[gameId][player].randomNum;
    }

    function updateTopBettor(uint gameId, address player, address newTopBettor) external onlyContract(CONTRACT_NAME_GM_SETTER_DB){
        gameByPlayer[gameId][player].topBettor = newTopBettor;
    }

    function getTopBettor(uint gameId, address player) public view returns(address){
        return gameByPlayer[gameId][player].topBettor;
    }

    function updateSecondTopBettor(uint gameId, address player, address newSecondTopBettor) external onlyContract(CONTRACT_NAME_GM_SETTER_DB){
        gameByPlayer[gameId][player].secondTopBettor = newSecondTopBettor;
    }

    function getSecondTopBettor(uint gameId, address player) public view returns(address){
        return gameByPlayer[gameId][player].secondTopBettor;
    }

    function getTicketFee(uint gameId) public view returns(uint){
        return gameSettings[gameId].ticketFee;
    }

    function getBettingFee(uint gameId) public view returns(uint){
        return gameSettings[gameId].bettingFee;
    }

    
}