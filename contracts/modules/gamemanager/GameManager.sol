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
import "../endowment/Distribution.sol";
import "../../interfaces/ERC20Standard.sol";
import "./Forfeiter.sol";
import "./Scheduler.sol";
import "../datetime/DateTime.sol";
import "../algorithm/Betting.sol";
import "../algorithm/HitsResolveAlgo.sol";
import "../algorithm/RarityCalculator.sol";
import "../registration/Register.sol";
import "../databases/ProfileDB.sol";
import "../../libs/SafeMath.sol";
import '../kittieHELL/KittieHELL.sol';
import '../../authority/Guard.sol';


contract GameManager is Proxied, Guard {
    using SafeMath for uint256;

    //Contract Variables
    GMSetterDB public gmSetterDB;
    GMGetterDB public gmGetterDB;
    GameVarAndFee public gameVarAndFee;
    EndowmentFund public endowmentFund;
    EndowmentDB public endowmentDB;
    Distribution public distribution;
    ERC20Standard public kittieFightToken;
    Forfeiter public forfeiter;
    DateTime public timeContract;
    Scheduler public scheduler;
    Betting public betting;
    HitsResolve public hitsResolve;
    RarityCalculator public rarityCalculator;
    Register public register;
    ProfileDB public profileDB;
    KittieHELL public kittieHELL;


    uint256 public constant PLAYER_STATUS_INITIATED = 1;
    uint256 public constant PLAYER_STATUS_PLAYING = 2;
    uint256 public constant GAME_STATE_CREATED = 0;
    uint256 public constant GAME_STATE_PRESTART = 1;
    uint256 public constant GAME_STATE_STARTED = 2;
    uint256 public constant GAME_STATE_CANCELLED = 3;
    uint256 public constant GAME_STATE_FINISHED = 4;

    struct Player{
        uint gameId;
        uint random;
        bool hitStart;
        uint defenseLevel;
    }

    mapping(address => mapping(uint => Player)) players;

    //TODO: check to add more states (expired, claiming gains)

    modifier onlyKittyOwner(address account, uint kittieId) {
        require(register.doesKittieBelong(account, kittieId), "Not owner of kittie");
        _;
    }

    modifier onlyGamePlayer(uint gameId, address player) {
        // TODO: Is this the check?
        require(profileDB.getCivicId(player) > 0, "Invalid Civic ID");
        require(gmGetterDB.isPlayer(gameId, player), "Invalid player");
        _;
    }

    /**
    * @dev Sets related contracts
    * @dev Can be called only by the owner of this contract
    */
    function initialize() external onlyOwner {

        //TODO: Check what other contracts do we need
        gmSetterDB = GMSetterDB(proxy.getContract(CONTRACT_NAME_GM_SETTER_DB));
        gmGetterDB = GMGetterDB(proxy.getContract(CONTRACT_NAME_GM_GETTER_DB));
        endowmentFund = EndowmentFund(proxy.getContract(CONTRACT_NAME_ENDOWMENT_FUND));
        endowmentDB = EndowmentDB(proxy.getContract(CONTRACT_NAME_ENDOWMENT_DB));
        distribution = Distribution(proxy.getContract(CONTRACT_NAME_DISTRIBUTION));
        gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        forfeiter = Forfeiter(proxy.getContract(CONTRACT_NAME_FORFEITER));
        timeContract = DateTime(proxy.getContract(CONTRACT_NAME_TIMECONTRACT));
        scheduler = Scheduler(proxy.getContract(CONTRACT_NAME_SCHEDULER));
        betting = Betting(proxy.getContract(CONTRACT_NAME_BETTING));
        hitsResolve = HitsResolve(proxy.getContract(CONTRACT_NAME_HITSRESOLVE));
        rarityCalculator = RarityCalculator(proxy.getContract(CONTRACT_NAME_RARITYCALCULATOR));
        // kittieFightToken = ERC20Standard(proxy.getContract('MockERC20Token'));
        register = Register(proxy.getContract(CONTRACT_NAME_REGISTER));
        profileDB = ProfileDB(proxy.getContract(CONTRACT_NAME_PROFILE_DB));
        // kittieHELL = KittieHELL(proxy.getContract(CONTRACT_NAME_KITTIEHELL));
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
        onlyKittyOwner(getOriginalSender(), kittieId)
    {
        // TODO: endowment Team
        // contributeKTY expects gameId? I think they need to change that function
        //endowmentFund.contributeKFT(player, gameVarAndFee.getListingFee());

        // When creating the game, set to true, then we set it to false when game cancels or ends
        require((gmGetterDB.getKittieState(kittieId) == false), "Kitty can play only one game at a time");

        scheduler.addKittyToList(kittieId, getOriginalSender());
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
        require(scheduler.isKittyListedForMatching(kittyRed), "Kitty already listed");
        require(scheduler.isKittyListedForMatching(kittyBlack), "Kitty already listed");

        generateFight(playerRed, playerBlack, kittyRed, kittyBlack, gameStartTime);
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
        returns(uint)
    {
        uint256 preStartTime = gameStartTime.sub(gameVarAndFee.getGamePrestart());
        uint256 endTime = gameStartTime.add(gameVarAndFee.getGameDuration());

        uint256 gameId = gmSetterDB.createGame(
            playerRed, playerBlack, kittyRed, kittyBlack, gameStartTime, preStartTime, endTime);

        (uint honeyPotId, uint initialEth) = endowmentFund.generateHoneyPot();
        gmSetterDB.setHoneypotInfo(gameId, honeyPotId, initialEth);

        // TODO: endowment Team
        // endowmentFund.updateHoneyPotState(scheduled); //not yet implemented
        
        return gameId;
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
        returns(uint)
    {
        return generateFight(playerRed, playerBlack, kittyRed, kittyBlack, gameStartTime);
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
        external
        onlyProxy onlyBettor
        onlyGamePlayer(gameId, playerToSupport)
    {
        uint gameState = gmGetterDB.getGameState(gameId);

        require(gameState != GAME_STATE_CANCELLED &&
                gameState != GAME_STATE_FINISHED, "Unable to join game");

        //pay ticket fee
        // TODO: endowment Team, only needs amount and supporter sending
        // endowmentFund.contributeKFT(supporter, gameVarAndFee.getTicketFee());
        
        gmSetterDB.addBettor(gameId, getOriginalSender(), playerToSupport);

        if (gameState == 1) forfeiter.checkGameStatus(gameId, gameState);

        (,uint preStartTime,) = gmGetterDB.getGameTimes(gameId);
        //Update state if reached prestart time
        if (preStartTime >= now)
            gmSetterDB.updateGameState(gameId, GAME_STATE_PRESTART);
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

        require(gameState == GAME_STATE_PRESTART, "Game state is not Prestart");

        address player = getOriginalSender();

        address opponentPlayer = getOpponent(gameId, player);

        //Both Players Hit start
        if (players[opponentPlayer][gameId].hitStart){
            //Call betting to set fight map
            betting.startGame(gameId, players[opponentPlayer][gameId].random, randomNum);
            players[opponentPlayer][gameId].defenseLevel = rarityCalculator.getDefenseLevel(gmGetterDB.getKittieInGame(gameId, player));
            gmSetterDB.updateGameState(gameId, GAME_STATE_STARTED);
        }
        //
        else{
            players[player][gameId].hitStart = true;
            players[player][gameId].random = randomNum;
            players[player][gameId].defenseLevel = rarityCalculator.getDefenseLevel(gmGetterDB.getKittieInGame(gameId, player));
        }

        uint256 kittieId = gmGetterDB.getKittieInGame(gameId, player);
        require(kittieHELL.acquireKitty(kittieId, player)); 
    }

    function getOpponent(uint gameId, address player) internal view returns(address){
        (address playerBlack, address playerRed,,,,) = gmGetterDB.getGame(gameId);
        if(playerBlack == player) return playerRed;
        return playerBlack;
    }

    /**
     * @dev Extend time of underperforming game indefinitely, each time 1 minute before game ends, by checking at everybet
     */
    function extendTime(uint gameId) internal {
        // check if underperforming
        (,,uint gameEndTime) = gmGetterDB.getGameTimes(gameId);

        //each time 1 minute before game ends
        if(gameEndTime - now <= 60) {
            if(!checkPerformance(gameId)) gmSetterDB.updateEndTime(gameId, gameEndTime.add(60));
        }
    }

    /**
     * @dev checks to see if current jackpot is at least 10 times (10x)
     *  the amount of funds originally placed in jackpot
     */
    function checkPerformance(uint gameId) internal view returns(bool) {
        //get initial jackpot, need endowment to send this when creating honeypot
        (,uint initialEth) = gmGetterDB.getHoneypotInfo(gameId);
        uint currentJackpotEth = endowmentDB.getHoneypotTotalETH(gameId);

        if(currentJackpotEth > initialEth.mul(10)) return true;

        return false;
    }

    // /**
    //  * @dev KTY tokens are sent to endowment balance, Eth gets added to ongoing game honeypot
    //  * @author Felipe
    //  * @author Karl
    //  * @author Vikrammandal
    //  */
    // function bet
    // (
    //     uint gameId, uint amountKTY, uint randomNum
    // )
    //     external payable
    //     onlyProxy onlyBettor
    // {

    //     // TODO: check if bettor already payed ticket feee

    //     require(msg.value > 0);

    //     uint gameState = gmGetterDB.getGameState(gameId);
        
    //     require(gameState == GAME_STATE_STARTED, "Game has not started yet");
        
    //     address sender = getOriginalSender();
        
    //     //Send bet to endowment
    //     endowmentFund.contributeETH.value(msg.value)(gameId);

    //     // hits resolver
    //     hitsResolve.calculateCurrentRandom(gameId, randomNum);
        
    //     (, address supportedPlayer) = gmGetterDB.getBettor(gameId, sender);

    //     address opponentPlayer = getOpponent(gameId, supportedPlayer);

    //     // transfer bettingFee to endowmentFund
    //     // endowmentFund.contributeKFT(account, gameVarAndFee.getBettingFee());
        
    //     (string memory attackType, bytes32 attackHash, uint256 defenseLevel) = betting.bet(gameId, msg.value, supportedPlayer, opponentPlayer, randomNum);

    //     // update opposite corner kittie defense level if changed
    //     if (players[opponentPlayer][gameId].defenseLevel != defenseLevel)
    //         players[opponentPlayer][gameId].defenseLevel = defenseLevel;

    //     //Update bettor's total bet
    //     gmSetterDB.updateBettor(gameId, sender, msg.value, supportedPlayer);

    //     // update game variables
    //     calculateBettorStats(gameId, sender, msg.value, supportedPlayer);

    //     // check underperforming game if one minut
    //     extendTime(gameId);

    //     //Check if game has ended
    //     gameEND(gameId);
    // }

    /**
    * set lastBet, topBettor, secondTopBettor
    * @author vikrammandal
    */
    function calculateBettorStats(
        uint256 _gameId, address _account, uint256 _amountEth, address _supportedPlayer
    ) private {
        // lastBet, topBettor, secondTopBettor, etc...
        // Already done by betting algo
        // gmSetterDB.setLastBet(_gameId, _amountEth, now, _supportedPlayer);

        ( ,uint256 topBettorEth) = gmGetterDB.getTopBettor(_gameId, _supportedPlayer);

        if (_amountEth > topBettorEth){
            gmSetterDB.setTopBettor(_gameId, _account, _supportedPlayer, _amountEth);
        } else {
            ( ,uint256 secondTopBettorEth) = gmGetterDB.getSecondTopBettor(_gameId, _supportedPlayer);
            if (_amountEth > secondTopBettorEth){
                gmSetterDB.setSecondTopBettor(_gameId, _account, _supportedPlayer, _amountEth);
    }   }   }


    /**
     * @dev game comes to an end at time duration,continously check game time end
     */
    function gameEND(uint gameId) internal {
        require(gmGetterDB.getGameState(gameId) == GAME_STATE_STARTED, "Game not started");

        (,,uint endTime) = gmGetterDB.getGameTimes(gameId);

        if ( endTime >= now)
            gmSetterDB.updateGameState(gameId, GAME_STATE_FINISHED);

        updateKitties(gameId);
    }

    /**
     * @dev Determine winner of game based on  **HitResolver **
     */
    function finalize(uint gameId, uint randomNum) external {
        require(gmGetterDB.getGameState(gameId) == GAME_STATE_FINISHED, "Game has not finished yet");

        (address playerBlack, address playerRed, , , ,) = gmGetterDB.getGame(gameId);

        uint256 playerBlackPoints = hitsResolve.calculateFinalPoints(gameId, playerBlack, randomNum);
        uint256 playerRedPoints = hitsResolve.calculateFinalPoints(gameId, playerRed, randomNum);

        address winner = playerBlackPoints > playerRedPoints ? playerBlack : playerRed;
        gmSetterDB.setWinner(gameId, winner);
    }
    

    /**
     * @dev Cancels the game before the game starts
     */
    function cancelGame(uint gameId, string calldata reason) external onlyContract(CONTRACT_NAME_FORFEITER) {
        require(gmGetterDB.getGameState(gameId) == GAME_STATE_CREATED ||
                gmGetterDB.getGameState(gameId) == GAME_STATE_PRESTART, "Unable to cancel game");

        gmSetterDB.updateGameState(gameId, GAME_STATE_CANCELLED);

        updateKitties(gameId);

    }

    function updateKitties(uint gameId) internal {
        // When creating the game, set to true, then we set it to false when game cancels or ends
        ( , , uint256 kittyBlack, uint256 kittyRed, , ) = gmGetterDB.getGame(gameId);
        gmSetterDB.updateKittieState(kittyRed, false);
        gmSetterDB.updateKittieState(kittyBlack, false);
    }

    // /**
    //  * @dev ?
    //  */
    // function claim(uint kittieId) external {

    // }

    // /**
    //  * @dev ?
    //  */
    // function winnersClaim() external {

    // }

    // /**
    //  * @dev ?
    //  */
    // function winnersGroupClaim() external {

    // }
}
