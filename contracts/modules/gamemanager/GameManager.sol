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
import "../../GameVarAndFee.sol";
import "../endowment/EndowmentFund.sol";
import "./Forfeiter.sol";
import "./Scheduler.sol";
import "../algorithm/Betting.sol";
import "../algorithm/HitsResolveAlgo.sol";
import "../algorithm/RarityCalculator.sol";
import "../databases/ProfileDB.sol";
import "../../libs/SafeMath.sol";
import '../kittieHELL/KittieHELL.sol';
import '../../authority/Guard.sol';
import "../../interfaces/IKittyCore.sol";
import "./GameStore.sol";

contract GameManager is Proxied, Guard {
    using SafeMath for uint256;

    //Contract Variables
    GMSetterDB public gmSetterDB;
    GMGetterDB public gmGetterDB;
    GameVarAndFee public gameVarAndFee;
    EndowmentFund public endowmentFund;
    EndowmentDB public endowmentDB;
    Forfeiter public forfeiter;
    Scheduler public scheduler;
    Betting public betting;
    HitsResolve public hitsResolve;
    RarityCalculator public rarityCalculator;
    ProfileDB public profileDB;
    KittieHELL public kittieHELL;
    IKittyCore public cryptoKitties;
    GameStore public gameStore;
 
    enum eGameState {WAITING, PRE_GAME, MAIN_GAME, GAME_OVER, CLAIMING, KITTIE_HELL, CANCELLED}

    //EVENTS
    event NewGame(uint indexed gameId, address playerBlack, uint kittieBlack, address playerRed, uint kittieRed, uint gameStartTime);
    event NewSupporter(uint indexed game_id, address indexed supporter, address playerSupported);
    event PressStart(uint indexed game_id, address player);
    event NewBet(uint indexed game_id, address indexed player, uint ethAmount);
    event GameStateChanged(uint indexed game_id, eGameState old_state, eGameState new_state);

    enum HoneypotState {
        created,
        assigned,
        gameScheduled,
        gameStarted,
        forefeited,
        claimed
    }

    modifier onlyKittyOwner(address player, uint kittieId) {
        require(cryptoKitties.ownerOf(kittieId) == player);
        _;
    }

    modifier onlyGamePlayer(uint gameId, address player) {
        require(profileDB.getCivicId(player) > 0);
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
        gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        forfeiter = Forfeiter(proxy.getContract(CONTRACT_NAME_FORFEITER));
        scheduler = Scheduler(proxy.getContract(CONTRACT_NAME_SCHEDULER));
        betting = Betting(proxy.getContract(CONTRACT_NAME_BETTING));
        hitsResolve = HitsResolve(proxy.getContract(CONTRACT_NAME_HITSRESOLVE));
        rarityCalculator = RarityCalculator(proxy.getContract(CONTRACT_NAME_RARITYCALCULATOR));
        profileDB = ProfileDB(proxy.getContract(CONTRACT_NAME_PROFILE_DB));
        kittieHELL = KittieHELL(proxy.getContract(CONTRACT_NAME_KITTIEHELL));
        cryptoKitties = IKittyCore(proxy.getContract(CONTRACT_NAME_CRYPTOKITTIES));
        gameStore = GameStore(proxy.getContract(CONTRACT_NAME_GAMESTORE));
    }

    /**
     * @dev Checks and prevents unverified accounts, only accounts with available kitties can list
     */
    function listKittie
    (
        uint kittieId
    )
        external
        onlyProxy onlyPlayer
        onlyKittyOwner(getOriginalSender(), kittieId) //currently doesKittieBelong is not used, better
    {
        address player = getOriginalSender();

        //Pay Listing Fee
        endowmentFund.contributeKTY(player, gameVarAndFee.getListingFee());

        // When creating the game, set to true, then we set it to false when game cancels or ends
        require((gmGetterDB.getKittieState(kittieId) == false));

        scheduler.addKittyToList(kittieId, player);
    }

    /**
     * @dev Check to make sure the only superADmin can list, Takes in two kittieID's and accounts as well as the jackpot ether and token number.
     */
    function manualMatchKitties
    (
        address playerRed, address playerBlack,
        uint256 kittyRed, uint256 kittyBlack,
        uint gameStartTime
    )
        external
        onlyProxy onlySuperAdmin
        onlyKittyOwner(playerRed, kittyRed)
        onlyKittyOwner(playerBlack, kittyBlack)
    {
        require(!scheduler.isKittyListedForMatching(kittyRed));
        require(!scheduler.isKittyListedForMatching(kittyBlack));

        generateFight(playerBlack, playerRed, kittyBlack, kittyRed, gameStartTime);
    }

    /**
     * @dev Creates game and generates gameId
     * @return gameId
     */
    function generateFight
    (
        address playerRed, address playerBlack,
        uint256 kittyRed, uint256 kittyBlack,
        uint gameStartTime
    )
        internal
    {
        uint256 gameId = gmSetterDB.createGame(
            playerRed, playerBlack, kittyRed, kittyBlack, gameStartTime);
        
        gameStore.lockVars(gameId);

        (uint honeyPotId, uint initialEth) = endowmentFund.generateHoneyPot();
        gmSetterDB.setHoneypotInfo(gameId, honeyPotId, initialEth);

        emit NewGame(gameId, playerBlack, kittyBlack, playerRed, kittyRed, gameStartTime);
    }

    /**
     * @dev External function for Scheduler to call
     * @return gameId
     */
    function createFight
    (
        address playerRed, address playerBlack,
        uint256 kittyRed, uint256 kittyBlack,
        uint gameStartTime
    )
        external
        onlyContract(CONTRACT_NAME_SCHEDULER)
    {
        generateFight(playerRed, playerBlack, kittyRed, kittyBlack, gameStartTime);
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

        //Before KittieHell
        require(gameState <= 2);

        //pay ticket fee
        require(endowmentFund.contributeKTY(supporter, gameVarAndFee.getTicketFee()));
        
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

        require(gameState == uint(eGameState.PRE_GAME), 'Game has not reached pre-game state');

        address player = getOriginalSender();
        uint kittieId = gmGetterDB.getKittieInGame(gameId, player);

        // (,,,,,,,,,uint genes) = cryptoKitties.getKitty(kittieId); // TODO: check why it fails here

        // uint genes = 621602280461119273000377613714842202937902730777750890758407393079864686;
        
        gameStore.hitStart(gameId, player);
        gameStore.setRandom(gameId, player, randomNum);
            
        // uint defenseLevel = rarityCalculator.getDefenseLevel(kittieId, genes);
        // betting.setOriginalDefenseLevel(gameId, player, defenseLevel);

        require(kittieHELL.acquireKitty(kittieId, player), 'Error acquiring kitty');

        address opponentPlayer = gmGetterDB.getOpponent(gameId, player);

        emit PressStart(gameId, player);

        //Both Players Hit start
        if (gameStore.didHitStart(gameId, opponentPlayer)){

            //Call betting to set fight map
            betting.startGame(gameId, gameStore.getRandom(gameId, opponentPlayer), randomNum);
            //GameStarts
            gmSetterDB.updateGameState(gameId, uint(eGameState.MAIN_GAME));
            uint honeyPotId = gmGetterDB.getHoneypotId(gameId);
            endowmentFund.updateHoneyPotState(honeyPotId, uint(HoneypotState.gameStarted));
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
        if(gameEndTime.sub(now) <= 60) {
            //get initial jackpot, need endowment to send this when creating honeypot
            uint initialEth = gmGetterDB.getHoneypotInitialEth(gameId);
            uint currentJackpotEth = endowmentDB.getHoneypotTotalETH(gameId);

            if(currentJackpotEth > initialEth.mul(10)){
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

        //Check if game has ended
        // gameEnd(gameId);

        uint gameState = gmGetterDB.getGameState(gameId);
        
        require(gameState == uint(eGameState.MAIN_GAME));
        
        address sender = getOriginalSender();
        (, address supportedPlayer, bool payedFee) = gmGetterDB.getSupporterInfo(gameId, sender);

        require(payedFee); //Needs to call participate first if false
        
        //Transfer Funds to endowment
        require(endowmentFund.contributeETH.value(msg.value)(gameId));
        require(endowmentFund.contributeKTY(sender, gameVarAndFee.getBettingFee()));

        //Update bettor's total bet
        gmSetterDB.updateBettor(gameId, sender, msg.value, supportedPlayer);

        // Update Random
        hitsResolve.calculateCurrentRandom(gameId, randomNum);
        
        address opponentPlayer = gmGetterDB.getOpponent(gameId, supportedPlayer);
        
        //Send bet to betting algo, to decide attacks
        betting.bet(gameId, msg.value, supportedPlayer, opponentPlayer, randomNum);

        // update game variables
        gmSetterDB.updateTopbettors(gameId, sender, supportedPlayer);

        // check underperforming game if one minut
        //checkPerformance(gameId);

        emit NewBet(gameId, sender, msg.value);
    }

    /**
     * @dev game comes to an end at time duration,continously check game time end
     */
    function gameEnd(uint gameId) internal {
        require(gmGetterDB.getGameState(gameId) == uint(eGameState.MAIN_GAME));

        (,,uint endTime) = gmGetterDB.getGameTimes(gameId);

        if ( endTime >= now){
            gmSetterDB.updateGameState(gameId, uint(eGameState.GAME_OVER));
            gmSetterDB.removeKittiesInGame(gameId);
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

        address winner = playerBlackPoints > playerRedPoints ? playerBlack : playerRed;
        gmSetterDB.setWinner(gameId, winner);

        //TODO: Update HoneyPot state to claiming

        gmSetterDB.updateGameState(gameId, uint(eGameState.CLAIMING));
        emit GameStateChanged(gameId, eGameState.MAIN_GAME, eGameState.CLAIMING);

    }
    

    /**
     * @dev Cancels the game before the game starts
     */
    function cancelGame(uint gameId) external onlyContract(CONTRACT_NAME_FORFEITER) {
        uint gameState = gmGetterDB.getGameState(gameId);
        require(gameState == uint(eGameState.WAITING) ||
                gameState == uint(eGameState.PRE_GAME));

        gmSetterDB.updateGameState(gameId, uint(eGameState.CANCELLED));

        gmSetterDB.removeKittiesInGame(gameId);

    }
}
