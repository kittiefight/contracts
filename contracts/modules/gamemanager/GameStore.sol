pragma solidity ^0.5.5;

import '../proxy/Proxied.sol';
import "../../GameVarAndFee.sol";
import "../databases/GMGetterDB.sol";
import "../../libs/SafeMath.sol";
import "../algorithm/HitsResolveAlgo.sol";
import '../../authority/Guard.sol';
import "../datetime/TimeFrame.sol";
import "../../withdrawPool/WithdrawPool.sol";
import "../gamemanager/Scheduler.sol";
import "../../CronJob.sol";
import "../databases/EndowmentDB.sol";
import "../databases/GenericDB.sol";

contract GameStore is Proxied, Guard {

    using SafeMath for uint256;

    GameVarAndFee public gameVarAndFee;
    GMGetterDB public gmGetterDB;
    HitsResolve public hitsResolve;
    Scheduler public scheduler;
    TimeFrame public timeFrame;
    GenericDB public genericDB;

    bool gameScheduled;

    function initialize() external onlyOwner {
        gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        gmGetterDB = GMGetterDB(proxy.getContract(CONTRACT_NAME_GM_GETTER_DB));
        hitsResolve = HitsResolve(proxy.getContract(CONTRACT_NAME_HITSRESOLVE));
        scheduler = Scheduler(proxy.getContract(CONTRACT_NAME_SCHEDULER));
        timeFrame = TimeFrame(proxy.getContract(CONTRACT_NAME_TIMEFRAME));
        genericDB = GenericDB(proxy.getContract(CONTRACT_NAME_GENERIC_DB));
    }

    function lock(uint gameId) internal{
        genericDB.setUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "bettingFee")),
            0
        );

        genericDB.setUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "ticketFee")),
            0
        );

        genericDB.setUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "kittieRedemptionFee")),
            0
        );

        genericDB.setUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "kittieHellExpirationTime")),
            gameVarAndFee.getKittieExpiry()
        );

        genericDB.setUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "honeypotExpirationTime")),
            gameVarAndFee.getHoneypotExpiration()
        );

        genericDB.setUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "minimumContributors")),
            gameVarAndFee.getMinimumContributors()
        );

        uint[5] memory distributionRates = gameVarAndFee.getDistributionRates();

        genericDB.setUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "distributionRates", "winningKittie")),
            distributionRates[0]
        );

        genericDB.setUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "distributionRates", "topBettor")),
            distributionRates[1]
        );

        genericDB.setUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "distributionRates", "secondRunnerUp")),
            distributionRates[2]
        );

        genericDB.setUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "distributionRates", "otherBettors")),
            distributionRates[3]
        );

        genericDB.setUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "distributionRates", "endownment")),
            distributionRates[4]
        );

        genericDB.setUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "timeExtension")),
            gameVarAndFee.getTimeExtension()
        );

        genericDB.setUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "performanceTime")),
            gameVarAndFee.getPerformanceTimeCheck()
        );
    }

    function lockVars(uint gameId) external onlyContract(CONTRACT_NAME_GAMECREATION){
        lock(gameId);
    }

    function lockVarsAdmin(uint gameId) external onlySuperAdmin{
        lock(gameId);
    }

    // update kittieRedemptionFee and store in Dai
    function updateKittieRedemptionFee(uint256 gameId)
        public
        onlyContract(CONTRACT_NAME_GAMEMANAGER)
    {
        uint256 percentageHoneyPot = gameVarAndFee.getPercentageForKittieRedemptionFee();
        (uint256 totalEthFunds, uint256 totalKTYFunds) = gmGetterDB.getFinalHoneypot(gameId);

        uint256 redemptionFee = scheduler.calculateDynamicFee(percentageHoneyPot, totalEthFunds, totalKTYFunds);
        genericDB.setUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "kittieRedemptionFee")),
            redemptionFee
        );
    }

    // update Ticket Fee and store in Dai
    function updateTicketFee(uint256 gameId)
        public
        onlyContract(CONTRACT_NAME_GAMECREATION)
    {
        uint256 percentageHoneyPot = gameVarAndFee.getPercentageForTicketFee();
        (uint256 initialHoneypotEth, uint256 initialHoneypotKTY) = gmGetterDB.getInitialHoneypot(gameId);
        uint256 ticketFee = scheduler.calculateDynamicFee(percentageHoneyPot, initialHoneypotEth, initialHoneypotKTY);
        genericDB.setUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "ticketFee")),
            ticketFee
        );
    }

    // update Betting Fee and store in Dai
    function updateBettingFee(uint256 gameId)
        public
        onlyContract(CONTRACT_NAME_GAMECREATION)
    {
        uint256 percentageHoneyPot = gameVarAndFee.getPercentageForBettingFee();
        (uint256 initialHoneypotEth, uint256 initialHoneypotKTY) = gmGetterDB.getInitialHoneypot(gameId);
        uint256 bettingFee = scheduler.calculateDynamicFee(percentageHoneyPot, initialHoneypotEth, initialHoneypotKTY);
        genericDB.setUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "bettingFee")),
            bettingFee
        );
    }

    function start(uint gameId, address player, uint randomNum) external onlyContract(CONTRACT_NAME_GAMEMANAGER){
        genericDB.setBoolStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, player, "pressedStart")),
            true
        );

        genericDB.setUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, player, "randomNum")),
            randomNum
        );
    }

    function getRandom(uint gameId, address player) public view returns(uint){
        return genericDB.getUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, player, "randomNum"))
        );
    }

    function updateTopBettor(uint gameId, address player, address newTopBettor) external onlyContract(CONTRACT_NAME_GM_SETTER_DB){
        genericDB.setAddressStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, player, "topBettor")),
            newTopBettor
        );
    }

    function updateSecondTopBettor(uint gameId, address player, address newSecondTopBettor) external onlyContract(CONTRACT_NAME_GM_SETTER_DB){
        genericDB.setAddressStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, player, "secondTopBettor")),
            newSecondTopBettor
        );
    }

    function updateTopbettors(uint256 _gameId, address _account, address _supportedPlayer)
        external
        onlyContract(CONTRACT_NAME_GAMEMANAGER)
        // onlyExistentGame(_gameId)
    {

        address topBettor = getTopBettor(_gameId, _supportedPlayer);
        (uint256 bettorTotal,,,) = gmGetterDB.getSupporterInfo(_gameId, _account);
        (uint256 topBettorEth,,,) = gmGetterDB.getSupporterInfo(_gameId, topBettor);
        
        if(topBettor != _account){
            if (bettorTotal > topBettorEth){
                //If topBettor is already the account, dont update
                genericDB.setAddressStorage(
                    CONTRACT_NAME_GAMESTORE,
                    keccak256(abi.encodePacked(_gameId, _supportedPlayer, "topBettor")),
                    _account
                );

                genericDB.setAddressStorage(
                    CONTRACT_NAME_GAMESTORE,
                    keccak256(abi.encodePacked(_gameId, _supportedPlayer, "secondTopBettor")),
                    topBettor
                );
            }
            else {
                address secondTopBettor = getSecondTopBettor(_gameId, _supportedPlayer);
                (uint256 secondTopBettorEth,,,) = gmGetterDB.getSupporterInfo(_gameId, secondTopBettor);
                if (bettorTotal > secondTopBettorEth && secondTopBettor != _account){
                    genericDB.setAddressStorage(
                    CONTRACT_NAME_GAMESTORE,
                    keccak256(abi.encodePacked(_gameId, _supportedPlayer, "secondTopBettor")),
                    _account
                );
                }
            }
        }
    }

    function calculateWinner
    (
        uint gameId, address playerBlack, address playerRed, uint random
    )
        external view
        onlyContract(CONTRACT_NAME_GAMEMANAGER)
        returns(address winner, address loser, uint pointsBlack, uint pointsRed)
    {
        pointsBlack = hitsResolve.calculateFinalPoints(gameId, playerBlack, random);
        pointsRed = hitsResolve.calculateFinalPoints(gameId, playerRed, random);

        //Added to make game more balanced
        pointsBlack = (gmGetterDB.getTotalBet(gameId, playerBlack)).mul(pointsBlack);
        pointsRed = (gmGetterDB.getTotalBet(gameId, playerRed)).mul(pointsRed);

        if (pointsBlack > pointsRed)
        {
            winner = playerBlack;
            loser = playerRed;
        }
        else if(pointsRed > pointsBlack)
        {
            winner = playerRed;
            loser = playerBlack;
        }
        //If there is a tie in point, define by total eth bet
        else
        {
            (,,,,uint[2] memory ethByCorner,,) = gmGetterDB.getHoneypotInfo(gameId);
            if(ethByCorner[0] > ethByCorner[1] ){
                winner = playerBlack;
                loser = playerRed;
            }
            else{
                winner = playerRed;
                loser = playerBlack;
            }
        }
    }

    // getters
    function getTopBettor(uint gameId, address player) public view returns(address){
        return genericDB.getAddressStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, player, "topBettor"))
        );
    }

    function getSecondTopBettor(uint gameId, address player) public view returns(address){
        return genericDB.getAddressStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, player, "secondTopBettor"))
        );
    }
}