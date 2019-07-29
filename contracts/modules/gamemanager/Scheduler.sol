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
import "../../GameVarAndFee.sol";
import "./GameManager.sol";
import "./GameCreation.sol";
import "../../interfaces/ERC721.sol";


/**
 * @title Scheduler
 * @dev Responsible for game Schedule
 * @author @vikrammandal
 */

contract Scheduler is Proxied {
    using SafeMath for uint256;

    //Contract Variables
    GameManager public gameManager;
    GameCreation public gameCreation;
    GameVarAndFee public gameVarAndFee;
    ERC721 public cryptoKitties;
    uint256 lastGameCreationTime;

    struct Kitty {
        uint256 kittyId;
        address player;
    }

    uint256 randomNonce;
    Kitty[] kittyList;
    Kitty[] kittyListShuffled;

    /**
     * @dev Can be called only by the owner of this contract
     */
    function initialize() public onlyOwner {
        gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        gameManager = GameManager(proxy.getContract(CONTRACT_NAME_GAMEMANAGER));
        gameCreation = GameCreation(proxy.getContract(CONTRACT_NAME_GAMECREATION));
        cryptoKitties = ERC721(proxy.getContract(CONTRACT_NAME_CRYPTOKITTIES));
    }

    /**
    * @param _kittyId kitty id
    * @param _player is the address of the player
    */
    function addKittyToList(uint256 _kittyId, address _player) external onlyContract(CONTRACT_NAME_GAMECREATION){
        // a kitty may play only one game at a time
        require(!isKittyListedForMatching(_kittyId), "Kitty is already listed. A kitty can take part in only one game at a time");

        Kitty memory newKitty = Kitty(_kittyId, _player);
        kittyList.push(newKitty);

        if ((gameVarAndFee.getRequiredNumberMatches().mul(2)) == kittyList.length) {
            matchKitties();
        }
    }

    /**
    * @param _kittyId kitty id
    * @param _player is the address of the player
    */
    function addKittyToListAgain(uint256 _kittyId, address _player) private {
        // a kitty or player may play only one game at a time
        require(!isKittyListedForMatching(_kittyId), "Kitty is already listed. A kitty can take part in only one game at a time");

        Kitty memory newKitty = Kitty(_kittyId, _player);
        kittyList.push(newKitty);

        // if ((gameVarAndFee.getRequiredNumberMatches() * 2) == kittyList.length) {
        // temporary hardcoded for test, unable to setVarAndFee from test due to proxy issue (out of gas)
        if (4 == kittyList.length) {
            matchKitties();
        }
    }


    /**
     * @dev Create red and black corner players
     */
    function matchKitties() private {
        require(((kittyList.length % 2) == 0), "Number of Kitties should be even number");

        shuffleKittyList();
        uint256 gameCount = kittyListShuffled.length / 2;

        Kitty[] memory playerRed = new Kitty[](gameCount);
        Kitty[] memory playerBlack = new Kitty[](gameCount);

        for(uint256 i = 0; i < playerRed.length; i++){
            playerRed[i] = kittyListShuffled[i];
        }
        for(uint256 i = 0; i < playerBlack.length; i++){
            playerBlack[i] = kittyListShuffled[i + playerRed.length];
        }

        uint256 gameTimeSeperation = gameVarAndFee.getGameTimes();

        uint256 gameCreationTime = block.timestamp;
        if (lastGameCreationTime > gameCreationTime){
            gameCreationTime = lastGameCreationTime;
        }

        for(uint256 i = 0; i < gameCount; i++){
            gameCreationTime = gameCreationTime.add(gameTimeSeperation);

            // check kitty owners
            if ((cryptoKitties.ownerOf(playerRed[i].kittyId) == playerRed[i].player) &&
               (cryptoKitties.ownerOf(playerBlack[i].kittyId) == playerBlack[i].player)){

                gameCreation.createFight(
                    playerRed[i].player,
                    playerBlack[i].player,
                    playerRed[i].kittyId,
                    playerBlack[i].kittyId,
                    gameCreationTime
                    );

            }else { // owner has changed. add kitty who's owner has not changed back to unmatched list
                if (cryptoKitties.ownerOf(playerBlack[i].kittyId) == playerBlack[i].player){
                    addKittyToListAgain(playerBlack[i].kittyId, playerBlack[i].player);
                }
                if (cryptoKitties.ownerOf(playerRed[i].kittyId) == playerRed[i].player){
                    addKittyToListAgain(playerRed[i].kittyId, playerRed[i].player);
        }   }   }
        lastGameCreationTime = gameCreationTime;
        delete kittyListShuffled;
    }

    /**
     * Shuffle Kitty List
     */
    function shuffleKittyList() public {

        Kitty[] memory kittyListCopy = new Kitty[](kittyList.length);
        kittyListCopy = kittyList;
        delete kittyList;

        uint256 pos;
        Kitty memory temp;
        for(uint i = 0; i < kittyListCopy.length; i++){
            pos = randomNumber(kittyListCopy.length - 1);
            temp = kittyListCopy[i];
            kittyListCopy[i] = kittyListCopy[pos];
            kittyListCopy[pos] = temp;
        }

        for(uint i = 0; i < kittyListCopy.length; i++){
            kittyListShuffled.push(kittyListCopy[i]);
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
        for(uint256 i = 0; i < kittyList.length ; i++){
            if (_kittyId == kittyList[i].kittyId){
                return true;
            }
        }
        return false;
    }

    /**
     * @dev uint256[] Returns only ids of currently un mathced kitties
     */
    function getListedKitties() public view returns (uint256[] memory){
        uint256[] memory unMatchedKitties = new uint256[](kittyList.length);
        for (uint256 i = 0; i < kittyList.length; i++){
            unMatchedKitties[i] = kittyList[i].kittyId;
        }
        return unMatchedKitties;
    }

    /**
     * @dev address[] Returns addresses  of currently un mathced players
     */
    function getListedPlayers() public view returns (address[] memory){
        address[] memory unMatchedPlayers = new address[](kittyList.length);
        for (uint256 i = 0; i < kittyList.length; i++){
            unMatchedPlayers[i] = kittyList[i].player;
        }
        return unMatchedPlayers;
    }


    /**
     * @dev requiredNumber of listed kitties required before the next nbatches of fights is setup
     */
    function getRequiredMatchingNumber(uint256 nbatch) external view returns(uint256){
        uint256[] memory currentUnMatchedKitties = getListedKitties();
        //return  (nbatch * 2) - currentUnMatchedKitties.length;
        return nbatch.mul(2).sub(currentUnMatchedKitties.length);
    }


}