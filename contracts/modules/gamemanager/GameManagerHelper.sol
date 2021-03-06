pragma solidity ^0.5.5;

import '../proxy/Proxied.sol';
import '../../authority/Guard.sol';
import "../../libs/SafeMath.sol";
import "../../GameVarAndFee.sol";
import "../databases/GenericDB.sol";
import "../databases/GMSetterDB.sol";
import "../databases/GMGetterDB.sol";
import "../endowment/EndowmentFund.sol";
import "../databases/EndowmentDB.sol";
import "../endowment/Distribution.sol";
import "../databases/KittieHellDB.sol";
import "./Scheduler.sol";
import '../kittieHELL/KittieHell.sol';
import "../databases/AccountingDB.sol";
import "../../interfaces/IKittyCore.sol";
import "./GameCreation.sol";
import "../algorithm/HitsResolveAlgo.sol";

contract GameManagerHelper is Proxied, Guard {
    using SafeMath for uint256;

    //Contract Variables
    GenericDB public genericDB;
    GMSetterDB public gmSetterDB;
    GMGetterDB public gmGetterDB;
    GameVarAndFee public gameVarAndFee;
    EndowmentDB public endowmentDB;
    EndowmentFund public endowmentFund;
    Scheduler public scheduler;
    KittieHell public kittieHELL;
    KittieHellDB public kittieHellDB;
    AccountingDB public accountingDB;
    IKittyCore public cryptoKitties;
    GameCreation public gameCreation;
    Distribution public distribution;
    HitsResolve public hitsResolve;

    enum HoneypotState {
        created,
        assigned,
        gameScheduled,
        gameStarted,
        forefeited,
        claiming,
        dissolved
    }

    enum eGameState {WAITING, PRE_GAME, MAIN_GAME, GAME_OVER, CLAIMING, CANCELLED}

    modifier onlyKittyOwner(address player, uint kittieId) {
        require(cryptoKitties.ownerOf(kittieId) == player, "You are not the owner of this kittie");
        _;
    }

    /**
    * @dev Sets related contracts
    * @dev Can be called only by the owner of this contract
    */
    function initialize() external onlyOwner {
        genericDB = GenericDB(proxy.getContract(CONTRACT_NAME_GENERIC_DB));
        gmSetterDB = GMSetterDB(proxy.getContract(CONTRACT_NAME_GM_SETTER_DB));
        gmGetterDB = GMGetterDB(proxy.getContract(CONTRACT_NAME_GM_GETTER_DB));
        gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        endowmentDB = EndowmentDB(proxy.getContract(CONTRACT_NAME_ENDOWMENT_DB));
        endowmentFund = EndowmentFund(proxy.getContract(CONTRACT_NAME_ENDOWMENT_FUND));
        scheduler = Scheduler(proxy.getContract(CONTRACT_NAME_SCHEDULER));
        kittieHELL = KittieHell(proxy.getContract(CONTRACT_NAME_KITTIEHELL));
        kittieHellDB = KittieHellDB(proxy.getContract(CONTRACT_NAME_KITTIEHELL_DB));
        accountingDB = AccountingDB(proxy.getContract(CONTRACT_NAME_ACCOUNTING_DB));
        cryptoKitties = IKittyCore(proxy.getContract(CONTRACT_NAME_CRYPTOKITTIES));
        gameCreation = GameCreation(proxy.getContract(CONTRACT_NAME_GAMECREATION));
        distribution = Distribution(proxy.getContract(CONTRACT_NAME_DISTRIBUTION));
        hitsResolve = HitsResolve(proxy.getContract(CONTRACT_NAME_HITSRESOLVE));
    }

    // Setters
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

    function removeKitties(uint256 gameId)
        external
        onlyContract(CONTRACT_NAME_GAMEMANAGER)
    {
        _removeKitties(gameId);
    }

    function updateKitties(address winner, address loser, uint256 gameId)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    {
        //Release winner's Kittie
        kittieHELL.releaseKittyGameManager(gmGetterDB.getKittieInGame(gameId, winner));

        //Kill losers's Kittie
        kittieHELL.killKitty(gmGetterDB.getKittieInGame(gameId, loser), gameId);

        if(genericDB.getBoolStorage(CONTRACT_NAME_SCHEDULER, keccak256(abi.encode("schedulerMode"))))
            scheduler.startGame();
    }

    /**
    * @dev updateHoneyPotState
    */
    function updateHoneyPotState(uint256 _gameId, uint _state) public onlyContract(CONTRACT_NAME_GAMEMANAGER) {
        _updateHoneyPotState(_gameId, _state);
    }

    /**
     * @dev Update kittie playing game Id
     */
    function updateKittiesGame(uint kittyBlack, uint kittyRed, uint gameId)
        external
        onlyContract(CONTRACT_NAME_GAMECREATION)
    {
        _updateKittiesGame(kittyBlack, kittyRed, gameId);
    }

    /**
     * @dev Cancels the game before the game starts
     */
    function cancelGame(uint gameId) external onlyContract(CONTRACT_NAME_FORFEITER) {
        uint gameState = gmGetterDB.getGameState(gameId);
        require(gameState == uint(eGameState.WAITING) ||
                gameState == uint(eGameState.PRE_GAME));

        gmSetterDB.updateGameState(gameId, uint(eGameState.CANCELLED));

        //Set to forfeited
        _updateHoneyPotState(gameId, 4);
        _removeKitties(gameId);

        gameCreation.deleteCronjob(gameId);
    }

    // getters
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

     function getWinnerLoser(uint256 gameId)
        public view
        returns(address winner, address loser, uint256 totalBetsForLosingCorner)
    {
        (winner,,) = gmGetterDB.getWinners(gameId);
        loser = getOpponent(gameId, winner);
        totalBetsForLosingCorner = gmGetterDB.getTotalBet(gameId, loser);
    }

    function getDistributionRates(uint gameId) public view returns(uint[5] memory){
        uint[5] memory distributionRates;
        distributionRates[0] = genericDB.getUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "distributionRates", "winningKittie"))
        );
        distributionRates[1] = genericDB.getUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "distributionRates", "topBettor"))
        );
        distributionRates[2] = genericDB.getUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "distributionRates", "secondRunnerUp"))
        );
        distributionRates[3] = genericDB.getUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "distributionRates", "otherBettors"))
        );
        distributionRates[4] = genericDB.getUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "distributionRates", "endownment"))
        );
        return distributionRates;
    }

    function didHitStart(uint gameId, address player) public view returns(bool){
        return genericDB.getBoolStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, player, "pressedStart"))
        );
    }

    function getMinimumContributors(uint gameId) public view returns(uint){
        return genericDB.getUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "minimumContributors"))
        );
    }

    function getPerformanceTimeCheck(uint gameId) public view returns(uint){
        return genericDB.getUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "performanceTime"))
        );
    }

    function getTimeExtension(uint gameId) public view returns(uint){
        return genericDB.getUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "timeExtension"))
        );
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

    // internal functions
    function _updateKittiesGame(uint kittyBlack, uint kittyRed, uint gameId)
        internal
    {
        genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_HELPER, keccak256(abi.encodePacked(kittyBlack, "playingGame")), gameId);
        genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_HELPER, keccak256(abi.encodePacked(kittyRed, "playingGame")), gameId);
    }

    function _removeKitties(uint256 gameId)
        internal
    {
        ( , ,uint256 kittyBlack, uint256 kittyRed) = gmGetterDB.getGamePlayers(gameId);

        //Set gameId to 0 to both kitties (not playing any game)
        _updateKittiesGame(kittyBlack, kittyRed, 0);

        if(genericDB.getBoolStorage(CONTRACT_NAME_SCHEDULER, keccak256(abi.encode("schedulerMode"))))
            scheduler.startGame();
    }

    function _updateHoneyPotState(uint256 _gameId, uint _state) internal {
        uint256 claimTime;
        if (_state == uint(HoneypotState.claiming)){
            //Send immediately initialEth+15%oflosing and 15%ofKTY to endowment
            (uint256 winningsETH, uint256 winningsKTY) = distribution.getEndowmentShare(_gameId);
            endowmentDB.updateEndowmentFund(winningsKTY, winningsETH, false);
            endowmentDB.updateHoneyPotFund(_gameId, winningsKTY, winningsETH, true);
        }
        if(_state == uint(HoneypotState.forefeited)) {
            (uint256 eth, uint256 kty) = accountingDB.getHoneypotTotal(_gameId);
            endowmentDB.updateEndowmentFund(kty, eth, false);
            endowmentDB.updateHoneyPotFund(_gameId, kty, eth, true);
        }
        endowmentDB.setHoneypotState(_gameId, _state);
    }
    
}
