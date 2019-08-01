/**
 * @title GamesManager
 *
 * @author @wafflemakr @karl @vikrammandal

 *
 */
//modifier class (DSAuth )
//Event class ( DSNote )
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.5.5;

import '../proxy/Proxied.sol';
import "../databases/GMSetterDB.sol";
import "../databases/GMGetterDB.sol";
import "../databases/EndowmentDB.sol";
import "../endowment/EndowmentFund.sol";
import "./Forfeiter.sol";
import "../algorithm/Betting.sol";
import "../algorithm/HitsResolveAlgo.sol";
import "../algorithm/RarityCalculator.sol";
import "../databases/ProfileDB.sol";
import "../../libs/SafeMath.sol";
import '../kittieHELL/KittieHELL.sol';
import '../../authority/Guard.sol';
import '../../mocks/MockERC721Token.sol';
import "./GameStore.sol";

contract GameManager is Proxied, Guard {
    using SafeMath for uint256;

    //Contract Variables
    GMSetterDB public gmSetterDB;
    GMGetterDB public gmGetterDB;
    EndowmentFund public endowmentFund;
    EndowmentDB public endowmentDB;
    Forfeiter public forfeiter;
    Betting public betting;
    HitsResolve public hitsResolve;
    KittieHELL public kittieHELL;
    GameStore public gameStore;
 
    enum eGameState {WAITING, PRE_GAME, MAIN_GAME, GAME_OVER, CLAIMING, KITTIE_HELL, CANCELLED}

    //EVENTS
    event NewSupporter(uint indexed gameId, address supporter, address indexed playerSupported);
    event PressStart(uint indexed gameId, address player);
    event GameStateChanged(uint indexed gameId, eGameState old_state, eGameState new_state);
    event GameEnded(uint indexed gameId, address indexed winner, address indexed loser, uint pointsBlack, uint pointsRed);

    modifier onlyGamePlayer(uint gameId, address player) {
        require(ProfileDB(proxy.getContract(CONTRACT_NAME_PROFILE_DB)).getCivicId(player) > 0);
        require(gmGetterDB.isPlayer(gameId, player));
        _;
    }

    /**
    * @dev Sets related contracts
    * @dev Can be called only by the owner of this contract
    */
    function initialize() external onlyOwner {

        gmSetterDB = GMSetterDB(proxy.getContract(CONTRACT_NAME_GM_SETTER_DB));
        gmGetterDB = GMGetterDB(proxy.getContract(CONTRACT_NAME_GM_GETTER_DB));
        endowmentFund = EndowmentFund(proxy.getContract(CONTRACT_NAME_ENDOWMENT_FUND));
        endowmentDB = EndowmentDB(proxy.getContract(CONTRACT_NAME_ENDOWMENT_DB));
        forfeiter = Forfeiter(proxy.getContract(CONTRACT_NAME_FORFEITER));
        betting = Betting(proxy.getContract(CONTRACT_NAME_BETTING));
        hitsResolve = HitsResolve(proxy.getContract(CONTRACT_NAME_HITSRESOLVE));
        kittieHELL = KittieHELL(proxy.getContract(CONTRACT_NAME_KITTIEHELL));
        gameStore = GameStore(proxy.getContract(CONTRACT_NAME_GAMESTORE));
    }

    /**
     * @dev Betters pay a ticket fee to participate in betting .
     *      Betters can join before and even a live game.
     */
    function participate
    (
        uint gameId,
        address playerToSupport
    )
        public
        onlyProxy onlyBettor
        onlyGamePlayer(gameId, playerToSupport)
        returns(bool)
    {
        uint gameState = gmGetterDB.getGameState(gameId);

        address supporter = getOriginalSender();

        //Before GAME_OVER
        require(gameState <= 2);

        //pay ticket fee
        require(endowmentFund.contributeKTY(supporter, gameStore.getTicketFee(gameId)));
        
        require(gmSetterDB.addBettor(gameId, supporter, playerToSupport));

        if (gameState == 1) forfeiter.checkGameStatus(gameId, gameState);

        (,uint preStartTime,) = gmGetterDB.getGameTimes(gameId);

        //Update state if reached prestart time
        //Include check game state because it can be called from the bet function
        if (gameState == uint(eGameState.WAITING) && preStartTime <= now){
            gmSetterDB.updateGameState(gameId, uint(eGameState.PRE_GAME));
            emit GameStateChanged(gameId, eGameState.WAITING, eGameState.PRE_GAME);
        }
            
        
        emit NewSupporter(gameId, supporter, playerToSupport);
        
        return true;
    }

    /**
     * @dev only both Actual players can call
     */
    function startGame
    (
        uint gameId,
        uint randomNum
    )
        external
        onlyProxy onlyPlayer
        onlyGamePlayer(gameId, getOriginalSender())
        returns(bool)
    {
        uint gameState = gmGetterDB.getGameState(gameId);
        forfeiter.checkGameStatus(gameId, gameState);

        require(gameState == uint(eGameState.PRE_GAME));

        address player = getOriginalSender();
        uint kittieId = gmGetterDB.getKittieInGame(gameId, player);
        
        gameStore.start(gameId, player,randomNum);

        // (,,,,,,,,,uint genes) = MockERC721Token(proxy.getContract(CONTRACT_NAME_CRYPTOKITTIES)).getKitty(kittieId);
        uint genes = MockERC721Token(proxy.getContract(CONTRACT_NAME_CRYPTOKITTIES)).getKitty(kittieId);
        betting.setDefenseLevel(gameId, player, RarityCalculator(proxy.getContract(CONTRACT_NAME_RARITYCALCULATOR)).getDefenseLevel(kittieId, genes));

        require(kittieHELL.acquireKitty(kittieId, player));

        address opponentPlayer = gmGetterDB.getOpponent(gameId, player);

        emit PressStart(gameId, player);

        //Both Players Hit start
        if (gameStore.didHitStart(gameId, opponentPlayer)){
            //Call betting to set fight map
            betting.startGame(gameId, randomNum, gameStore.getRandom(gameId, opponentPlayer));

            //GameStarts
            gmSetterDB.updateGameState(gameId, uint(eGameState.MAIN_GAME));
            endowmentFund.updateHoneyPotState(gameId, 3);
            emit GameStateChanged(gameId, eGameState.PRE_GAME, eGameState.MAIN_GAME);
            return true; //Game Started
        }

        return false; //Game is not starting yet
    }

    /**
     * @dev checks to see if current jackpot is at least 10 times (10x)
     *  the amount of funds originally placed in jackpot
     */
    function checkPerformance(uint gameId) internal {
        (,,uint gameEndTime) = gmGetterDB.getGameTimes(gameId);

        //each time 1 minute before game ends
        if(gameEndTime.sub(now) <= 5) {
            //get initial jackpot, need endowment to send this when creating honeypot
            (,uint initialEth,,,) = gmGetterDB.getHoneypotInfo(gameId);
            uint currentJackpotEth = endowmentDB.getHoneypotTotalETH(gameId);

            if(currentJackpotEth < initialEth.mul(10)){
                gmSetterDB.updateEndTime(gameId, gameEndTime.add(60));
            }
        }
    }

    /**
     * @dev KTY tokens are sent to endowment balance, Eth gets added to ongoing game honeypot
     * @author Felipe
     * @author Karl
     * @author Vikrammandal
     */
    function bet
    (
        uint gameId, uint randomNum
    )
        external payable
        onlyProxy onlyBettor
    {
        require(msg.value > 0);

        uint gameState = gmGetterDB.getGameState(gameId);
        
        require(gameState == uint(eGameState.MAIN_GAME));
        
        address sender = getOriginalSender();
        (, address supportedPlayer, bool payedFee,) = gmGetterDB.getSupporterInfo(gameId, sender);

        require(payedFee); //Needs to call participate first if false
        
        //Transfer Funds to endowment
        require(endowmentFund.contributeETH.value(msg.value)(gameId));
        require(endowmentFund.contributeKTY(sender, gameStore.getBettingFee(gameId)));

        //Update bettor's total bet
        if (sender != supportedPlayer) gmSetterDB.updateBettor(gameId, sender, msg.value, supportedPlayer);

        // Update Random
        hitsResolve.calculateCurrentRandom(gameId, randomNum);
        
        address opponentPlayer = gmGetterDB.getOpponent(gameId, supportedPlayer);
        
        //Send bet to betting algo, to decide attacks
        betting.bet(gameId, msg.value, supportedPlayer, opponentPlayer, randomNum);

        // update game variables
        gmSetterDB.updateTopbettors(gameId, sender, supportedPlayer);

        // check underperforming game if one minut
        checkPerformance(gameId);

        //Check if game has ended
        gameEnd(gameId);
    }

    /**
     * @dev game comes to an end at time duration,continously check game time end
     */
    function gameEnd(uint gameId) internal {
        require(gmGetterDB.getGameState(gameId) == uint(eGameState.MAIN_GAME));

        (,,uint endTime) = gmGetterDB.getGameTimes(gameId);

        if ( endTime <= now){
            gmSetterDB.updateGameState(gameId, uint(eGameState.GAME_OVER));
            //KittieHell needs kittie gameId
            //gmSetterDB.removeKittiesInGame(gameId);
            emit GameStateChanged(gameId, eGameState.MAIN_GAME, eGameState.GAME_OVER);
        }
    }

    /**
     * @dev Determine winner of game based on  **HitResolver **
     */
    function finalize(uint gameId, uint randomNum) external {
        require(gmGetterDB.getGameState(gameId) == uint(eGameState.GAME_OVER));

        (address playerBlack, address playerRed,,) = gmGetterDB.getGamePlayers(gameId);

        uint256 playerBlackPoints = hitsResolve.calculateFinalPoints(gameId, playerBlack, randomNum);
        uint256 playerRedPoints = hitsResolve.calculateFinalPoints(gameId, playerRed, randomNum);

        address winner;
        address loser;

        if (playerBlackPoints > playerRedPoints)
        {
            winner = playerBlack;
            loser = playerRed;
        }
        else if(playerRedPoints > playerBlackPoints)
        {
            winner = playerRed;
            loser = playerBlack;
        }
        //If there is a tie in point, define by total eth bet
        else
        {
            (,,,uint[2] memory ethByCorner,) = gmGetterDB.getHoneypotInfo(gameId);
            if(ethByCorner[0] > ethByCorner[0] ){
               winner = playerBlack;
                loser = playerRed;
            }
            else{
                winner = playerRed;
                loser = playerBlack;
            }
        }

        //Store Winners in DB
        gmSetterDB.setWinners(gameId, winner, gameStore.getTopBettor(gameId, winner),
            gameStore.getSecondTopBettor(gameId, winner));

        //Release winner's Kittie
        kittieHELL.releaseKittyGameManager(gmGetterDB.getKittieInGame(gameId, winner));

        //Kill losers's Kittie
        kittieHELL.killKitty(gmGetterDB.getKittieInGame(gameId, loser));

        //Set to claiming
        endowmentFund.updateHoneyPotState(gameId, 5);

        gmSetterDB.updateGameState(gameId, uint(eGameState.CLAIMING));
        emit GameStateChanged(gameId, eGameState.MAIN_GAME, eGameState.CLAIMING);

        emit GameEnded(gameId, winner, loser, playerBlackPoints, playerRedPoints);
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
        endowmentFund.updateHoneyPotState(gameId, 4);
        gmSetterDB.removeKittiesInGame(gameId);

    }
}
