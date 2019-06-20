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

contract GameManager is Proxied {

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


    uint256 public constant PLAYER_STATUS_INITIATED = 1;
    uint256 public constant PLAYER_STATUS_PLAYING = 2;
    uint256 public constant GAME_STATE_CREATED = 0;
    uint256 public constant GAME_STATE_PRESTART = 1;
    uint256 public constant GAME_STATE_STARTED = 2;
    uint256 public constant GAME_STATE_CANCELLED = 3;
    uint256 public constant GAME_STATE_FINISHED = 4;


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
    }


    /**
     * @dev Checks and prevents unverified accounts, only accounts with available kitties can list
     */
    function listKittie(uint kittieId, address player) external onlyProxy {
        //check if player account is registered
        //require(register.isRegistered(player))

        //check if player has kitties
        //register.hasKitties(player)

        //check if kittieId belongs to player account (not implemented yet)

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
    {
        //Requirements? Checks?
        genFightID(playerRed, playerBlack, kittyRed, kittyBlack);
    }

    /**
     * @dev Betters pay a ticket fee to participate in betting .
     */
    function participate(uint gameId, address player) external onlyProxy {
        //use onlyExistentGame(gameId) modifier?
        //uint ticketFee = gameVarAndFee.getTicketFee();
        uint ticketFee = 100; //until we merge GVAF contract

        //check if sender is one of the players in the gameId

        //(uint kittieId, uint status) = gameManagerDB.getPlayer(gameId, player);
        // kittieId should not be cero

        //pay ticket fee
        require(kittieFightToken.transferFrom(player, address(endowmentFund), ticketFee), "Error sending funds to endownment");

        //If both player have payed ticket fee
        //change game state to created (not started because )
        //gameManagerDB.updateGameState(gameId, GAME_STATE_CREATED)

        //forfeiter.checkStatus();
        
    }

    /**
     * @dev only both Actual players can call
     */
    function startGame(uint gameId, address player, uint randNum) external onlyProxy {
        /**
            Funds honeypot from endowment fund, when both players are active with enough participator threshold .
            generates rarity scale for both players on game start
        */

        //Get cattributes

        //check both player's status
        //check player's supporters

        //uint honeyPotId = endowmentFund.generateHoneyPot();
        //rarityCalculator.startGame(cattributes) ??? what params to send

        //forfeiter.checkStatus();
    }
    

    /**
     * @dev Extend time of underperforming game indefinitely, each time 1 minute before game ends, by checking at everybet
     */
    function extendTime(uint gameId) internal {

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
        //Add bet to DB
        //gameManagerDB.addBet(gameId, amountEth, supportedPlayer);

        //forfeiter.checkStatus();

        // if underperformed then call extendTime();
        
        //endowmentFund.contributeETH(gameId)

        // transfer amountKTY to endowmentFund (endowmentFund.contributeKFT(gameId, account,amountKTY )?)
        //or
        //require(kittieFightToken.transferFrom(account, address(endowmentFund), amountKTY));

        //hitResolve
        //hitsResolve.caluclateCurrentRandom(randomNum)
    }

    /**
     * @dev checks to see if current jackpot is at least 10 times (10x) the amount of funds originally placed in jackpot
     */
    function checkPerformance(uint gameId) external returns(bool) {
        //get initial jackpot
        //gameManagerDB.getJackpotDetails(gameId)
    }

    /**
     * @dev game comes to an end at time duration,continously check game time end
     */
    function gameEND(uint gameId) internal {
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
     * @dev ?
     */
    function cancelGame(uint gameId) internal {
        //gameManagerDB.updateGameState(gameId, GAME_STATE_CANCELLED)
    }

    /**
     * @dev ?
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
