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
import "../../GameVarAndFee.sol";
import "../endowment/EndowmentFund.sol";
import "./Scheduler.sol";
import "../../libs/SafeMath.sol";
import '../kittieHELL/KittieHELL.sol';
import '../../authority/Guard.sol';
import "../../interfaces/IKittyCore.sol";
import "./GameStore.sol";

contract GameCreation is Proxied, Guard {
    using SafeMath for uint256;

    //Contract Variables
    GMSetterDB public gmSetterDB;
    GMGetterDB public gmGetterDB;
    GameVarAndFee public gameVarAndFee;
    EndowmentFund public endowmentFund;
    Scheduler public scheduler;
    IKittyCore public cryptoKitties;
    GameStore public gameStore;
 
    

    //EVENTS
    event NewGame(uint indexed gameId, address playerBlack, uint kittieBlack, address playerRed, uint kittieRed, uint gameStartTime);
    event NewListing(uint indexed kittieId, address indexed owner, uint timeListed);

    modifier onlyKittyOwner(address player, uint kittieId) {
        require(cryptoKitties.ownerOf(kittieId) == player, "You are not the owner of this kittie");
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
        gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        scheduler = Scheduler(proxy.getContract(CONTRACT_NAME_SCHEDULER));
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

        require((gmGetterDB.getGameOfKittie(kittieId) == 0), "Kittie is already playing a game");

        scheduler.addKittyToList(kittieId, player);

        emit NewListing(kittieId, player, now);
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
        require(!scheduler.isKittyListedForMatching(kittyRed), "fighter is already listed for matching");
        require(!scheduler.isKittyListedForMatching(kittyBlack), "fighter is already listed for matching");

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

        uint initialEth = endowmentFund.generateHoneyPot();
        gmSetterDB.setHoneypotInfo(gameId, initialEth);

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

}
