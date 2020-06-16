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

contract GameStore is Proxied, Guard {

    using SafeMath for uint256;

    GameVarAndFee public gameVarAndFee;
    GMGetterDB public gmGetterDB;
    HitsResolve public hitsResolve;
    Scheduler public scheduler;
    TimeFrame public timeFrame;

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
        //uint finalizeRewards;
        uint timeExtension;
        uint performanceTime;
        uint[5] distributionRates;
    }

    //Players info in a game
    mapping(uint => mapping(address => Game)) public gameByPlayer;
    mapping(uint => GlobalSettings) public gameSettings;

    bool gameScheduled;

    function initialize() external onlyOwner {
        gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        gmGetterDB = GMGetterDB(proxy.getContract(CONTRACT_NAME_GM_GETTER_DB));
        hitsResolve = HitsResolve(proxy.getContract(CONTRACT_NAME_HITSRESOLVE));
        scheduler = Scheduler(proxy.getContract(CONTRACT_NAME_SCHEDULER));
        timeFrame = TimeFrame(proxy.getContract(CONTRACT_NAME_TIMEFRAME));
    }

    function lock(uint gameId) internal{
        GlobalSettings memory globalSettings;

        globalSettings.bettingFee = 0;
        globalSettings.ticketFee = 0;
        globalSettings.redemptionFee = 0;
        globalSettings.kittieHellExpirationTime = gameVarAndFee.getKittieExpiry();
        globalSettings.honeypotExpirationTime = gameVarAndFee.getHoneypotExpiration();
        globalSettings.minimumContributors = gameVarAndFee.getMinimumContributors();
        globalSettings.distributionRates = gameVarAndFee.getDistributionRates();
        //globalSettings.finalizeRewards = gameVarAndFee.getFinalizeRewards();
        globalSettings.timeExtension = gameVarAndFee.getTimeExtension();
        globalSettings.performanceTime = gameVarAndFee.getPerformanceTimeCheck();

        gameSettings[gameId] = globalSettings;
    }

    function lockVars(uint gameId) external onlyContract(CONTRACT_NAME_GAMECREATION){
        lock(gameId);
    }

    function lockVarsAdmin(uint gameId) external onlySuperAdmin{
        lock(gameId);
    }

    function getDistributionRates(uint gameId) public view returns(uint[5] memory){
        return gameSettings[gameId].distributionRates;
    }

    // return amount in dai
    function calculateDynamicFee
    (
        uint256 percentageHoneyPot,
        uint256 _eth_amount,
        uint256 _kty_amount
    )
        public view returns(uint256)
    {
        require(percentageHoneyPot > 0 && _eth_amount > 0 && _kty_amount > 0);

        // uint256 ethUsdPrice = gameVarAndFee.getEthUsdPrice();
        // uint256 usdKTYPrice = gameVarAndFee.getUsdKTYPrice();

        // convert ether to dai
        uint256 portion1DAI = gameVarAndFee.convertEthToDai(_eth_amount);

        // convert kty to ether, then to dai
        uint256 portion2ETH = gameVarAndFee.convertKtyToEth(_kty_amount);
        uint256 portion2DAI = gameVarAndFee.convertEthToDai(portion2ETH);

        // get the whole amount
        uint256 portionDAI = portion1DAI.add(portion2DAI);

        // 1,000,000 is the base used for percentage setting in kittieFight
        // for example, if percentageHoneyPot is 0.03% in real world, inside this function
        // percentageHoneyPot = 0.03% * 1,000,1000 which is 300, thus for the need of div(1000000)
        return portionDAI.mul(percentageHoneyPot).div(1000000);
    }

    // update kittieRedemptionFee and store in Dai
    function updateKittieRedemptionFee(uint256 gameId)
        public
        onlyContract(CONTRACT_NAME_GAMEMANAGER)
    {
        uint256 percentageHoneyPot = gameVarAndFee.getPercentageForKittieRedemptionFee();
        (uint256 totalEthFunds, uint256 totalKTYFunds) = gmGetterDB.getFinalHoneypot(gameId);

        gameSettings[gameId].redemptionFee = calculateDynamicFee(percentageHoneyPot, totalEthFunds, totalKTYFunds);        

        startGameAndCalculateEpoch(gameVarAndFee.getGameTimes().add(now));
    }

    // update Ticket Fee and store in Dai
    function updateTicketFee(uint256 gameId)
        public
        onlyContract(CONTRACT_NAME_GAMECREATION)
    {
        uint256 percentageHoneyPot = gameVarAndFee.getPercentageForTicketFee();
        (uint256 initialHoneypotEth, uint256 initialHoneypotKTY) = gmGetterDB.getInitialHoneypot(gameId);
        gameSettings[gameId].ticketFee = calculateDynamicFee(percentageHoneyPot, initialHoneypotEth, initialHoneypotKTY);
    }

    // update Betting Fee and store in Dai
    function updateBettingFee(uint256 gameId)
        public
        onlyContract(CONTRACT_NAME_GAMECREATION)
    {
        uint256 percentageHoneyPot = gameVarAndFee.getPercentageForBettingFee();
        (uint256 initialHoneypotEth, uint256 initialHoneypotKTY) = gmGetterDB.getInitialHoneypot(gameId);
        gameSettings[gameId].bettingFee = calculateDynamicFee(percentageHoneyPot, initialHoneypotEth, initialHoneypotKTY);
    }

    function getKittieExpirationTime(uint gameId) public view returns(uint){
        return  gameSettings[gameId].kittieHellExpirationTime;
    }

    function getKittieRedemptionFee(uint256 gameId) public view returns(uint256, uint256) {
        uint256 redemptionFeeDAI = gameSettings[gameId].redemptionFee;
        uint256 redemptionFeeKTY = getKTY(redemptionFeeDAI);
        uint256 etherForSwap = KtyUniswap(proxy.getContract(CONTRACT_NAME_KTY_UNISWAP)).etherFor(redemptionFeeKTY);
        return (etherForSwap, redemptionFeeKTY);
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

    function getTicketFee(uint256 gameId) public view returns(uint256, uint256){
        uint256 ticketFeeDAI = gameSettings[gameId].ticketFee;
        uint256 ticketFeeKTY = getKTY(ticketFeeDAI);
        uint256 ethForSwap = 0;//KtyUniswap(proxy.getContract(CONTRACT_NAME_KTY_UNISWAP)).etherFor(ticketFeeKTY);
        return (ethForSwap, ticketFeeKTY);
    }

    function getBettingFee(uint256 gameId) public view returns(uint256, uint256){
        uint256 bettingFeeDAI = gameSettings[gameId].bettingFee;
        uint256 bettingFeeKTY = getKTY(bettingFeeDAI);
        uint256 ethForFeeSwap = KtyUniswap(proxy.getContract(CONTRACT_NAME_KTY_UNISWAP)).etherFor(bettingFeeKTY);
        return (ethForFeeSwap, bettingFeeKTY);
    }

    function getMinimumContributors(uint gameId) public view returns(uint){
        return gameSettings[gameId].minimumContributors;
    }
    
    // stale function
    // function getFinalizeRewards(uint gameId) public view returns(uint){
    //     // get finalize rewards in dai
    //     uint256 rewardsDAI = gameSettings[gameId].finalizeRewards;

    //     return getKTY(rewardsDAI);
    // }

    function getKTY(uint256 _DAI) internal view returns(uint256) {
        uint256 _ETH = gameVarAndFee.convertDaiToEth(_DAI);
        return gameVarAndFee.convertEthToKty(_ETH);
    }

    function getPerformanceTimeCheck(uint gameId) public view returns(uint){
        return gameSettings[gameId].performanceTime;
    }

    function getTimeExtension(uint gameId) public view returns(uint){
        return gameSettings[gameId].timeExtension;
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
                gameByPlayer[_gameId][_supportedPlayer].topBettor = _account;
                gameByPlayer[_gameId][_supportedPlayer].secondTopBettor = topBettor;
            }
            else {
                address secondTopBettor = getSecondTopBettor(_gameId, _supportedPlayer);
                (uint256 secondTopBettorEth,,,) = gmGetterDB.getSupporterInfo(_gameId, secondTopBettor);
                if (bettorTotal > secondTopBettorEth && secondTopBettor != _account){
                    gameByPlayer[_gameId][_supportedPlayer].secondTopBettor = _account;
                }
            }
        }
    }

    function getOpponent(uint gameId, address player) public view returns(address){
        (address playerBlack, address playerRed,,) = gmGetterDB.getGamePlayers(gameId);
        if(playerBlack == player) return playerRed;
        return playerBlack;
    }

    function getCorner(uint gameId, address player) public view returns(uint){
        (address playerBlack, address playerRed,,) = gmGetterDB.getGamePlayers(gameId);
        if(playerBlack == player) return 0;
        if(playerRed == player) return 1;
        return 2;
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

    /**
    * @dev This function is called if a game gets cancelled, so as to start a new game.
    */
    function startAfterCancel()
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    {
        startGameAndCalculateEpoch(gameVarAndFee.getGameTimes().add(now));
    }

    /**
    * @dev This function is called from manualMatching, to check if game can be scheduled.
    */
    function startManually(uint256 gameStartTime)
    external
    onlyContract(CONTRACT_NAME_GAMECREATION)
    returns(bool)
    {
        uint256 activeEpochId = timeFrame.getActiveEpochID();
        uint256 currentEpochEndTime = timeFrame._epochEndTime(activeEpochId);
        return checkIfGameCanStart(gameStartTime, currentEpochEndTime);
    }

    function checkGame()
    external
    onlyContract(CONTRACT_NAME_SCHEDULER)
    returns(bool)
    {
        uint256 activeEpochId = timeFrame.getActiveEpochID();
        uint256 currentEpochEndTime = timeFrame._epochEndTime(activeEpochId);
        return checkIfGameCanStart(gameVarAndFee.getGameTimes().add(now), currentEpochEndTime);
    }

    function checkIfGameCanStart(uint256 gameStartTime, uint256 currentEpochEndTime)
    internal
    returns(bool)
    {
        //If less than "some time" from epoch's ending or anotherGame is scheduled, cannot create.
        if(currentEpochEndTime.sub(timeFrame.REST_DAY().add(timeFrame.SIX_HOURS())) <= gameStartTime || gameScheduled)
            return false;

        gameScheduled = true;
        return true;
    }

    function startGameAndCalculateEpoch(uint256 gameStartTime)
    internal
    {
        uint256 activeEpochId = timeFrame.getActiveEpochID();
        uint256 currentEpochEndTime = timeFrame._epochEndTime(activeEpochId);
        gameScheduled = false;

        if(checkIfGameCanStart(gameVarAndFee.getGameTimes().add(now), currentEpochEndTime))
            gameScheduled = scheduler.startGame();
        else {
            uint256 delay;
            if(now > currentEpochEndTime.sub(timeFrame.REST_DAY()))
                delay = now.sub(currentEpochEndTime.sub(timeFrame.REST_DAY()));

            CronJob cron = CronJob(proxy.getContract(CONTRACT_NAME_CRONJOB));
            cron.addCronJob(
                CONTRACT_NAME_GAMESTORE,
                currentEpochEndTime.add(delay),
                abi.encodeWithSignature("createGameAndEpoch()")
            );

            WithdrawPool(proxy.getContract(CONTRACT_NAME_WITHDRAW_POOL)).setInterestToEarningsTracker(
                activeEpochId,
                EndowmentDB(proxy.getContract(CONTRACT_NAME_ENDOWMENT_DB)).checkTotalForEpoch(activeEpochId)
            );
        }
    }

    /**
    * @dev added to cronjob : Creates new Game and New Epoch
    */
    function createGameAndEpoch()
    external
    onlyContract(CONTRACT_NAME_CRONJOB)
    {
        timeFrame.setNewEpoch();
        gameScheduled = scheduler.startGame();
        WithdrawPool(proxy.getContract(CONTRACT_NAME_WITHDRAW_POOL)).dissolveOldCreateNew();
    }

    function checkPerformanceHelper(uint gameId, uint gameEndTime) external view returns(bool){
        //each time 1 minute before game ends
        uint performanceTimeCheck = gameVarAndFee.getPerformanceTimeCheck();
        
        if(gameEndTime.sub(performanceTimeCheck) <= now) {
            //get initial jackpot, need endowment to send this when creating honeypot
            (,,uint initialEth, uint currentJackpotEth,,,) = gmGetterDB.getHoneypotInfo(gameId);

            if(currentJackpotEth < initialEth.mul(10)) return true;
            return false;
        }
    }
}