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

contract GameManager is Proxied {

    GameManagerDB public gameManagerDB;
    GameVarAndFee public gameVarAndFee;
    EndowmentFund public endowmentFund;
    Distribution public distribution;
    ERC20Standard public kittieFightToken;

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
        kittieFightToken = ERC20Standard(proxy.getContract('MockERC20Token'));
    }


    /**
     * @dev Checks and prevents unverified accounts, only accounts with available kitties can list
     */
    function listKittie(uint kittieId) external {

    }

    /**
     * @dev checked and called by ListKittie() at every 20th listing request
     * Matches all 20 players random by pairs, based on non-deterministic data.
     */
    function matchKitties() private {

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
        //TODO : onlySuperAdmin Modifier
    }

    /**
     * @dev Betters pay a ticket fee to participate in betting .
     */
    function participate(uint gameId, uint kittieId) external {
        //uint ticketFee = gameVarAndFee.getTicketFee();
        uint ticketFee = 100; //until we merge GVAF contract
        require(kittieFightToken.transferFrom(msg.sender, address(endowmentFund), ticketFee), "Error sending funds to endownment");

        
    }

    /**
     * @dev only both Actual players can call
     */
    function startGame(uint gameId) external onlyProxy {
        /**
            Funds honeypot from endowment fund, when both players are active with enough participator threshold .
            generates rarity scale for both players on game start
        */
    }

    

    /**
     * @dev Extend time of underperforming game indefinitely, each time 1 minute before game ends, by checking at everybet
     */
    function extendTime(uint gameId) internal {

    }

    /**
     * @dev KTY tokens are sent to endowment balance, Eth gets added to ongoing game honeypot
     */
    function bet(uint gameId, uint amountEth, uint amountKTY, address supportedPlayer) public {
        //Add bet to DB
        //gameManagerDB.addBet(gameId, amountEth, supportedPlayer);

        // if underperformed then call extendTime();
        // transfer amountKTY to endowmentFund
    }

    /**
     * @dev checks to see if current jackpot is at least 10 times (10x) the amount of funds originally placed in jackpot
     */
    function checkPerformance(uint gameId) external returns(bool) {

    }

    /**
     * @dev game comes to an end at time duration,continously check game time end
     */
    function gameEND(uint gameId) internal {

    }

    /**
     * @dev Determine winner of game based on  **HitResolver **
     */
    function Finalize(uint gameId) external {

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
