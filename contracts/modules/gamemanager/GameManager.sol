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
import "../../DateTime.sol";
import "../algorithm/Betting.sol";
import "../algorithm/HitsResolveAlgo.sol";
import "../algorithm/RarityCalculator.sol";
import "../registration/Register.sol";
import "../../libs/LinkedListLib.sol";


contract GameManager is Proxied {
    using LinkedListLib for LinkedListLib.LinkedList;

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

    // Temporal variables for a game
    struct GameState {
        uint256 state;
        uint256 preStartTime;
        uint256 startTime;
        uint256 endTime;
        uint256 lastBet;
        address topBettor;
        address topSecondBettor;
        bool playerRedPressedStart;
        bool playerBlackPressedStart;
        // Maybe some other variables...
    }

    // List of games. We can keep the temporal data for games in this mapping.
    // The key value would be the id of a game which is created in GameManagerDB
    mapping (uint256 => GameState) public games;

    // We may also keep the list of kitties which are currently listed for possible match
    // Linked list would provide us abilities like iteration of the list and length of list.
    LinkedListLib.LinkedList internal listedKitties;
    // Also may keep a relation with owners for a quick access
    mapping (uint256 => address) public kittieOwners;


    // FIXME: Instead of this modifier, we can use onlyPlayer modifier from contracts/authority/Guard.sol contract
    // It checks whether the account has player access (which means the account's already given his kitty/ies to the system)
    // And by default it checks if the account is registered in the system.
    // To check if a specific kittie belongs to a specific account, you can use doesKittieBelong(address account, uint256 kittieId) function from Register contract.
    modifier onlyValidPlayer(address player, uint kittieId) {
        require(register.isRegistered(player), "Player not registered");
        require(register.hasKitties(player), "No kitties available");
        //check if kittieId belongs to player account (not implemented yet)
        //require(register.isKittyOwner(player, kittieId), "Not owner of kittie"); 
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
    function listKittie(uint kittieId, address player) external onlyProxy onlyValidPlayer(player, kittieId) {
        // listing fee?

        //store in Kittie list - Where to store them?
        //matchKitties(); //heck every time this function is called
    }

    /**
     * @dev checked and called by ListKittie() at every 20th listing request
     * Matches all 20 players random by pairs, based on non-deterministic data.
     */
    function matchKitties() private {
        //check if kittie list has 20 kitties (we dont have kittie list storage)
        //call scheduler to create fights
    }

    /**
     * @dev Check to make sure the only superADmin can list, Takes in two kittieID's and accounts as well as the jackpot ether and token number.
     */
    function manualMatchKitties
    (
        address playerRed, address playerBlack,
        uint256 kittyRed, uint256 kittyBlack
    )
        external
        onlyProxy
        onlyValidPlayer(playerRed, kittyRed)
        onlyValidPlayer(playerBlack, kittyBlack)
    {
        //Requirements? Checks?
        // check both players validity
        // check if kitties belong to the players
        genFightID(playerRed, playerBlack, kittyRed, kittyBlack);
    }

    /**
     * @dev Betters pay a ticket fee to participate in betting .
     */
    function participate(uint gameId, address supporter, address playerToSupport) external onlyProxy {
        //use onlyExistentGame(gameId) modifier?
        // no need for modifier as it will be checked in the DB calls - karl

        // check game state
        // uint gameState = gameManagerDB.getGameState(gameId); // not yet implemented

        // bettor can join before and even a live game
        // require(gameState == GAME_STATE_PRESTART ||
        //         gameState == GAME_STATE_STARTED, "Unable to join game"); 

        //uint ticketFee = gameVarAndFee.getTicketFee();
        uint ticketFee = 100; //until we merge GVAF contract

        //check if sender is one of the players in the gameId

        //(uint kittieId, uint status) = gameManagerDB.getPlayer(gameId, player);
        // kittieId should not be cero

        //pay ticket fee
        require(kittieFightToken.transferFrom(supporter, address(endowmentFund), ticketFee), "Error sending funds to endownment");

        // add supporter to the team
        // gameManagerDB.addSupporter(gameId, supporter, playerToSupport); // not yet implemented


        //If both player have payed ticket fee
        //change game state to created (not started because )
        //gameManagerDB.updateGameState(gameId, GAME_STATE_CREATED)
        // do we need the above statements? - karl

        //forfeiter.checkStatus();
        
    }

    /**
     * @dev only both Actual players can call
     */
    function startGame(uint gameId, address player, uint randNum) external onlyProxy {
        // check game status or just check the game schedule time?
        // require(gameManagerDB.getGameState(gameId) == GAME_STATE_PRESTART, "Game not ready to start"); 


        /**
            Funds honeypot from endowment fund, when both players are active with enough participator threshold .
            generates rarity scale for both players on game start
        */

        //Get cattributes

        //check both player's status
        //(uint kittieId, uint status) = gameManagerDB.getPlayer(gameId, player);


        //check player's supporters
        // uint minSupporters = gameVarAndFee.getMinimumContributors()
        // require(gameManagerDB.getSupportersCount(player) >= minSupporters, "Not enough contributors");

        // update the player's status to READY

        // check both player's status, should be both READY before generating honeypot and starts game

        //uint honeyPotId = endowmentFund.generateHoneyPot();
        //rarityCalculator.startGame(cattributes) ??? what params to send

        // add players as bettors?
        

        //forfeiter.checkStatus();

        // update game status
        // gameManagerDB.updateGameState(gameId, GAME_STATE_STARTED) 

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
        // check game status 
        // require(gameManagerDB.getGameState(gameId) == GAME_STATE_STARTED, "Game not started"); 

        //forfeiter.checkStatus();

        // if underperformed then call extendTime();
        
        //endowmentFund.contributeETH(gameId)

        //Add bet to DB 
        // we should add it only after successful bet transfer - karl
        //gameManagerDB.addBet(gameId, amountEth, supportedPlayer);

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
        // check game status 
        // require(gameManagerDB.getGameState(gameId) == GAME_STATE_STARTED, "Game not started"); 

        //what functions calls this internally?
        //get game end time
        //uint endTime = gameManagerDB.getEndTime(gameId);
        //if (endTime > now) gameManagerDB.updateGameState(gameId, GAME_STATE_FINISHED)
    }

    /**
     * @dev Determine winner of game based on  **HitResolver **
     */
    function Finalize(uint gameId) external {
        //hitsResolve.finalizeGame()  store returned 7 values
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

    /**
     * @dev Cancels the game
     */
    function cancelGame(uint gameId) internal {
        //gameManagerDB.updateGameState(gameId, GAME_STATE_CANCELLED)
    }

    /**
     * @dev Creates game and generates FightID
     * @return fightId
     */
    function genFightID
    (
        address playerRed, address playerBlack,
        uint256 kittyRed, uint256 kittyBlack
    )
        internal
        returns(uint)
    {
        //Internal or external
        //Create Game in DB
        // return gameManagerDB.createGame(playerRed, playerBlack, kittyRed, kittyBlack);
    }

    /**
     * @dev ?
     */
    function claim(uint kittieId) internal {

    }
}
