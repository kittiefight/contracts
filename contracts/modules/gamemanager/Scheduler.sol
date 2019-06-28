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
        kittyList[kittyList.length] = Kitty({ kittyId: _kittyId, player: _player });

        if (gameVarAndFee.getRequiredNumberMatches() == (kittyList.length * 2) ) {
            matchKitties();
        }
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
     * @dev Create red and black corner players
     */
    function matchKitties() private {
        require((kittyList.length % 2) != 0, "Number of Kitties should be even number");

        Kitty[] memory playerRed;
        Kitty[] memory playerBlack;

        suffleKittyList();
        uint256 gameCount = kittyListSuffled.length / 2;

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
     * needs to be tested
     */
    function suffleKittyList() internal {

        Kitty[] memory kittyListCopy;
        kittyListCopy = kittyList;
        uint256 suffleKittyListCount = kittyList.length;
        delete kittyList;   // reset

        uint256 pos;
        for(uint256 i = 0; i < suffleKittyListCount; i++){
            pos = randomNumber(suffleKittyListCount);
            kittyListSuffled[pos] = kittyListCopy[i];
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
     * return requiredNumber of listed kitties required before the next nbatches of fights is setup
     */
    function getRequiredMatchingnumber(uint256 nbatch) external view returns(uint256){
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