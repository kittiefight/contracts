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
    //Register public register;

    uint256 randomNonce;

    uint256 kittyCount;
    struct Kitty {
        uint256 kittyId;
        address player;
    }
    Kitty[] KittyList;
    Kitty[] KittyListSuffled;


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
    * @param _player is the address of the palyer
    */
    function addKittyToList(uint256 _kittyId, address _player) external {

        KittyList[kittyCount] = Kitty({ kittyId: _kittyId, player: _player });
        kittyCount++;

        // call matchKitties - check with GameVarFee getRequiredNumberMatches()
        /*
        // GameVarFee not updated in this branch
        if (gameVarAndFee.getRequiredNumberMatches() == kittyCount) {
            matchKitties();
        }
        */

    }


    /**
     * @dev this will be called by GameManager::matchKitties()
     */
    function matchKitties() private {
        require((kittyCount % 2) != 0, "Kitty count should be even number");

        Kitty[] memory playerRed;
        Kitty[] memory playerBlack;
        uint256 gameCount = kittyCount / 2;

        suffleKittyList();

        for(uint256 i = 0; i < gameCount; i++){
            playerRed[i] = KittyListSuffled[i];
        }
        for(uint256 i = gameCount - 1; i < kittyCount; i++){
            playerBlack[i] = KittyListSuffled[i];
        }

        uint gameCreationTime;
        uint gameTimeSeperation = gameVarAndFee.getGameTimes(); //OR getRequiredTimeDistance() ?

        //generate match pairs
        for(uint i = 0; i < gameCount; i++){
            gameCreationTime = block.timestamp + (gameTimeSeperation * 1 seconds);

            // createFight not public
            //gameManager.createFight(playerRed[i].owner, playerBlack[i].owner,  playerRed[i].kittyId, playerBlack[i].kittyId, gameCreationTime);

        }

        // reset KittyList, KittyListSuffled, kittyCount
        kittyCount = 0;
        delete KittyList;
        delete KittyListSuffled;
    }


    /**
     * needs to be tested
     */
    function suffleKittyList() internal {
        uint256 pos;
        for(uint256 i = 0; i < kittyCount; i++){
            pos = randomNumber(kittyCount);
            KittyListSuffled[pos] = KittyList[i];
        }
    }

    /**
     * needs to be tested
     */
    function randomNumber(uint256 max) internal returns (uint256){
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, randomNonce))) % max;
        randomNonce++;
        return random;
    }

}