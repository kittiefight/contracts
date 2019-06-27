/**
 * @title GamesManager
 *
 * @author @wafflemakr
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
import "../databases/GameManagerDB.sol";
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
import "../../libs/LinkedListLib.sol";

import "../../libs/SafeMath.sol";


contract GameManager is Proxied {
    using LinkedListLib for LinkedListLib.LinkedList;
    using SafeMath for uint256;

    //Contract Variables
    GameManagerDB public gameManagerDB;
    GameVarAndFee public gameVarAndFee;
    EndowmentFund public endowmentFund;
    Distribution public distribution;
    ERC20Standard public kittieFightToken;
    Forfeiter public forfeiter;
    DateTimeAPI public timeContract;
    Scheduler public scheduler;
    Betting public betting;
    HitsResolve public hitsResolve;
    RarityCalculator public rarityCalculator;
    Register public register;


    uint256 public constant PLAYER_STATUS_INITIATED = 1;
    uint256 public constant PLAYER_STATUS_PLAYING = 2;
    uint256 public constant GAME_STATE_CREATED = 0;
    uint256 public constant GAME_STATE_PRESTART = 1;
    uint256 public constant GAME_STATE_STARTED = 2;
    uint256 public constant GAME_STATE_CANCELLED = 3;
    uint256 public constant GAME_STATE_FINISHED = 4;

    
    // struct GameState {
    //     uint256 state;
    //     uint256 preStartTime;
    //     uint256 startTime;
    //     uint256 endTime;
    //     uint256 lastBet;
    //     address topBettor;
    //     address topSecondBettor;
    //     bool playerRedPressedStart;
    //     bool playerBlackPressedStart;
    //     uint256 honeyPotId;
    //     //fight map
    // }

    // List of games. We can keep the temporal data for games in this mapping.
    // The key value would be the id of a game which is created in GameManagerDB
    //mapping (uint256 => GameState) public games;

    // We may also keep the list of kitties which are currently listed for possible match
    // Linked list would provide us abilities like iteration of the list and length of list.
    LinkedListLib.LinkedList internal listedKitties;
    // Also may keep a relation with owners for a quick access
    //mapping (uint256 => address) public kittieOwners;

    modifier onlyKittyOwner(address account, uint kittieId) {
        require(register.doesKittieBelong(account, kittieId), "Not owner of kittie");
        //TODO: ADD verify check here?
        _;
    }

    /**
    * @dev Sets related contracts
    * @dev Can be called only by the owner of this contract
    */
    function initialize() external onlyOwner {

        //TODO: Check what other contracts do we need
        gameManagerDB = GameManagerDB(proxy.getContract(CONTRACT_NAME_GAMEMANAGER_DB));
        endowmentFund = EndowmentFund(proxy.getContract(CONTRACT_NAME_ENDOWMENT));
        distribution = Distribution(proxy.getContract(CONTRACT_NAME_DISTRIBUTION));
        gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        forfeiter = Forfeiter(proxy.getContract(CONTRACT_NAME_FORFEITER));
        timeContract = DateTimeAPI(proxy.getContract(CONTRACT_NAME_TIMECONTRACT));
        scheduler = Scheduler(proxy.getContract(CONTRACT_NAME_SCHEDULER));
        betting = Betting(proxy.getContract(CONTRACT_NAME_BETTING));
        hitsResolve = HitsResolve(proxy.getContract(CONTRACT_NAME_HITSRESOLVE));
        rarityCalculator = RarityCalculator(proxy.getContract(CONTRACT_NAME_RARITYCALCULATOR));
        kittieFightToken = ERC20Standard(proxy.getContract('MockERC20Token'));
        register = Register(proxy.getContract(CONTRACT_NAME_REGISTER));
    }


    /**
     * @dev Checks and prevents unverified accounts, only accounts with available kitties can list
     */
    function listKittie(uint kittieId, address player) external onlyProxy onlyKittyOwner(player, kittieId) {
        // TODO: Check if player is verified
        //uint256 listingFee = gameVarAndFee.getListingFee();
        //TODO: call endowment to charge listing fee

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
        onlyProxy
        onlyKittyOwner(playerRed, kittyRed)
        onlyKittyOwner(playerBlack, kittyBlack)
    {

        createFight(playerRed, playerBlack, kittyRed, kittyBlack, gameStartTime);
    }

    /**
     * @dev Creates game and generates FightID
     * @return fightId
     */
    function createFight
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

        uint256 fightId = gameManagerDB.createGame(playerRed, playerBlack, kittyRed, kittyBlack, gameStartTime, preStartTime, endTime);

        return fightId;
    }

    /**
     * @dev Betters pay a ticket fee to participate in betting .
     *      Betters can join before and even a live game.
     */
    function participate(uint gameId, address supporter, address playerToSupport) external onlyProxy {
        require(gameManagerDB.getGameState(gameId) == GAME_STATE_PRESTART ||
                gameManagerDB.getGameState(gameId) == GAME_STATE_STARTED, "Unable to join game");

        uint ticketFee = gameVarAndFee.getTicketFee();

        //pay ticket fee
        require(kittieFightToken.transferFrom(supporter, address(endowmentFund), ticketFee), "Error sending funds to endownment");
        gameManagerDB.addBettor(gameId, supporter, 0, playerToSupport);


        //Update state if reached prestart time
        if (gameManagerDB.getPrestartTime(gameId) >= now)
            gameManagerDB.updateGameState(gameId, GAME_STATE_PRESTART);
    }

    /**
     * @dev only both Actual players can call
     */
    function startGame
    (
        uint gameId, address player,
        uint randNum
    )
        external
        onlyProxy
        returns(bool)
    {
        require(gameManagerDB.getGameState(gameId) == GAME_STATE_PRESTART, "Game state is not Prestart");
        require(gameManagerDB.isPlayer(gameId, player), "Not authorized player");
   
        // adding player as a bettor himself, charge separate fee?
        gameManagerDB.addBettor(gameId, player, 0, player);

        // TODO update playerRedPressedStart or playerBlackPressedStart
        if(true //forfeiter.checkGameStatus(gameId) TODO send GameState struct as param instead
            ) {
            // uint honeyPotId = endowmentFund.generateHoneyPot();
            //uint honeyPotId = 123;

            //rarityCalculator.startGame(cattributes) ??? what params to send
            gameManagerDB.updateGameState(gameId, GAME_STATE_STARTED);
        }

        //TODO: Lock kittie of player if reached this point
    }

    /**
     * @dev Extend time of underperforming game indefinitely, each time 1 minute before game ends, by checking at everybet
     */
    function extendTime(uint gameId) internal {
        // check if underperforming
        if(!checkPerformance(gameId)){
            // extend time
        }
    }

    /**
     * @dev KTY tokens are sent to endowment balance, Eth gets added to ongoing game honeypot
     */
    function bet
    (
        uint gameId, address account, uint amountEth, 
        uint amountKTY, address supportedPlayer, uint randomNum
    ) 
        external
        onlyProxy 
    {

        require(gameManagerDB.getGameState(gameId) == GAME_STATE_STARTED, "Game has not started yet");
        
        forfeiter.checkGameStatus(gameId);

        // if underperformed then call extendTime();
        //  endowmentFund.contributeETH(gameId)

        gameManagerDB.addBettor(gameId, account, amountEth, supportedPlayer);

        // transfer amountKTY to endowmentFund (endowmentFund.contributeKFT(gameId, account,amountKTY )?)
        //or
        //require(kittieFightToken.transferFrom(account, address(endowmentFund), amountKTY));

        //hitResolve
        //hitsResolve.caluclateCurrentRandom(randomNum)

        // check underperforming game
        // extendTime(gameId);
    }

    /**
     * @dev checks to see if current jackpot is at least 10 times (10x) the amount of funds originally placed in jackpot
     */
    function checkPerformance(uint gameId) internal returns(bool) {
        //get initial jackpot
        //gameManagerDB.getJackpotDetails(gameId)
    }

    /**
     * @dev game comes to an end at time duration,continously check game time end
     */
    function gameEND(uint gameId) internal {
        require(gameManagerDB.getGameState(gameId) == GAME_STATE_STARTED, "Game not started");

        if (gameManagerDB.getEndTime(gameId) >= now)
            gameManagerDB.updateGameState(gameId, GAME_STATE_FINISHED);
    }

    /**
     * @dev Determine winner of game based on  **HitResolver **
     */
    function finalize(uint gameId) external {
        //hitsResolve.finalizeGame()  store returned 7 values
    }
    

    /**
     * @dev Cancels the game
     */
    function cancelGame(uint gameId) internal {
        gameManagerDB.updateGameState(gameId, GAME_STATE_CANCELLED);
    }

    

    /**
     * @dev ?
     */
    function claim(uint kittieId) internal {

    }

    /**
     * @dev ?
     */
    function winnersClaim() internal {

    }

    /**
     * @dev ?
     */
    function winnersGroupClaim() internal {

    }
}
