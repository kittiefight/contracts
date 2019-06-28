/**
 * @title Scheduler
 *
 * @author @kittieFIGHT @ola
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
import "../../libs/SafeMath.sol";
//import "../../authority/Guard.sol";
import "../../GameVarAndFee.sol";
import "./GameManager.sol";


/**
 * @title Scheduler
 * @dev Responsible for game Schedule
 * @author @vikrammandal
 */

contract Scheduler is Proxied {
    using SafeMath for uint256;

    //Contract Variables
    GameManager public gameManager;
    GameVarAndFee public gameVarAndFee;

    struct Kitty {
        uint256 kittyId;
        address player;
    }

    uint256 randomNonce;
    Kitty[] kittyList;
    Kitty[] kittyListSuffled;

    /**
     * @dev Can be called only by the owner of this contract
     */
    function initialize() public onlyOwner {
        gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        gameManager = GameManager(proxy.getContract(CONTRACT_NAME_GAMEMANAGER));
    }

    /**
    * @dev what modifier to add? onlyValidPlayer
    * @param _kittyId kitty id
    * @param _player is the address of the player
    */
    function addKittyToList(uint256 _kittyId, address _player) external onlyContract(CONTRACT_NAME_GAMEMANAGER){

        require(!isKittyListedForMatching(_kittyId), "Kitty is already listed for upcomming games");

        Kitty memory newKitty = Kitty(_kittyId, _player);
        kittyList.push(newKitty);

        if ((gameVarAndFee.getRequiredNumberMatches() * 2) == kittyList.length) {
            matchKitties();
        }
    }

    /**
     * @dev Create red and black corner players
     * under testing
     */
    function matchKitties() private {
        require(((kittyList.length % 2) == 0), "Number of Kitties should be even number");

        suffleKittyList();
        uint256 gameCount = kittyListSuffled.length / 2;

        Kitty[] memory playerRed = new Kitty[](gameCount);
        Kitty[] memory playerBlack = new Kitty[](gameCount);


        for(uint256 i = 0; i < gameCount; i++){
            playerRed[i] = kittyListSuffled[i];
        }
        for(uint256 i = gameCount - 1; i < kittyListSuffled.length; i++){
            playerBlack[i] = kittyListSuffled[i];
        }

        uint256 gameCreationTime;
        uint256 gameTimeSeperation = gameVarAndFee.getGameTimes(); //OR getRequiredTimeDistance() ?

        //generate match pairs
        for(uint256 i = 0; i < gameCount; i++){
            gameCreationTime = block.timestamp + (gameTimeSeperation * 1 seconds);
            gameManager.createFight(playerRed[i].player, playerBlack[i].player,  playerRed[i].kittyId, playerBlack[i].kittyId, gameCreationTime);
        }

        delete kittyListSuffled; // reset
    }

    /**
     * Suffle Kitty List
     */
    function suffleKittyList() public {

        Kitty[] memory kittyListCopy = new Kitty[](kittyList.length);
        kittyListCopy = kittyList;
        delete kittyList;   // reset

        uint256 pos;
        Kitty memory temp;
        for(uint i = 0; i < kittyListCopy.length; i++){
            pos = randomNumber(kittyListCopy.length - 1);
            temp = kittyListCopy[i];
            kittyListCopy[i] = kittyListCopy[pos];
            kittyListCopy[pos] = temp;
        }

        for(uint i = 0; i < kittyListCopy.length; i++){
            kittyListSuffled.push(kittyListCopy[i]);
        }
    }

    /**
     * @dev Random number - very basic implementation
     */
    function randomNumber(uint256 max) internal returns (uint256){
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, randomNonce))) % max;
        randomNonce++;
        return random;
    }

    /**
    * @dev Checkes if kitty is listed for matching in future games
    */
    function isKittyListedForMatching(uint256 _kittyId) public view returns (bool) {
        uint256[] memory unListed = getUnMatchedKitties();
        for(uint256 i = 0; i < unListed.length ; i++){
            if (_kittyId == unListed[i]){
                return true;
            }
        }
        return false;
    }

    /**
     * @return uint256[] Returns only ids of currently un mathced kitties
     */
    function getUnMatchedKitties() public view returns (uint256[] memory){
        uint256[] memory unMatchedKitties;
        for (uint256 i = 0; i < kittyList.length; i++){
            unMatchedKitties[i] = kittyList[i].kittyId;
        }
        return unMatchedKitties;
    }

    /**
     * @return address[] Returns addresses  of currently un mathced players
     */
    function getUnMatchedPlayers() public view returns (address[] memory){
        address[] memory unMatchedPlayers;
        for (uint256 i = 0; i < kittyList.length; i++){
            unMatchedPlayers[i] = kittyList[i].player;
        }
        return unMatchedPlayers;
    }

    /**
     * @return requiredNumber of listed kitties required before the next nbatches of fights is setup
     */
    function getRequiredMatchingNumber(uint256 nbatch) external view returns(uint256){
        uint256[] memory currentUnMatchedKitties = getUnMatchedKitties();
        return  (nbatch * 2) - currentUnMatchedKitties.length;
    }

    /**
     * @dev internal getter to return requiredtime distance between all fights
     * Is it required?
     * /
    function getRequiredTimeDistance() external view returns(uint256){
        return gameVarAndFee.getGameTimes();
    }*/


}