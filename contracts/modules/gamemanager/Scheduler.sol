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
//import "../databases/GameManagerDB.sol";
//import "../../DateTime.sol"; // used for time formating?
//import "./GameManager.sol";


/**
 * @title Scheduler
 * @dev Responsible for game Schedule
 * @author @vikrammandal
 */

contract Scheduler is Proxied {
    using SafeMath for uint256;

    //Contract Variables
    //GameManagerDB public gameManagerDB;
    //GameManager public gameManager;
    //DateTimeAPI public timeContract;

    uint256 randomNonce;

    struct MatchedPlayers {
        uint256     gameId;
        uint256     gameTime;
        address     redPlayer;
        uint256     redPlayerKittyId;
        address     blackPlayer;
        uint256     blackPlayerKittyId;
    }
    MatchedPlayers[] gameList;

    uint256 kittyCount;
    struct Kittie {
        uint256 kittyId;
        address owner;
    }
    Kittie[] kittieList;
    Kittie[] kittieListSuffled;


    /**
     * @dev Can be called only by the owner of this contract
     */
    function initialize() public onlyOwner {
        //gameManager = GameManager(proxy.getContract('GameManager'));
    }

    /**
    * @dev what modifier to add?
    * @param _kittyId kitty id
    * @param _owner is the address of the kittie owner
    */
    function addKittieToList(uint256 _kittyId, address _owner) private {
        kittieList[kittyCount] = Kittie({ kittyId: _kittyId, owner: _owner });
        kittyCount++;
        // we can matchKitties() from here as well if kittyCount == 20
    }


    /**
     * @dev this will be called by GameManager::matchKitties()
     */
    function matchKitties() private {
        require((kittyCount % 2) != 0, "kittie count should be even number");

        Kittie[] memory redPlayers;
        Kittie[] memory blackPlayers;
        uint256 gameCount = kittyCount / 2;

        sufflekittieList();

        for(uint256 i = 0; i < gameCount; i++){
            redPlayers[i] = kittieListSuffled[i];
        }
        for(uint256 i = gameCount - 1; i < kittyCount; i++){
            blackPlayers[i] = kittieListSuffled[i];
        }

        //generate match pairs and time
        uint256 gameId;
        uint256 gameTime;
        
        for(uint256 i = 0; i < gameCount; i++){
            gameId = generateGameId(redPlayers[i].owner, redPlayers[i].kittyId, blackPlayers[i].owner, blackPlayers[i].kittyId);
            gameTime = now + 1 hours; // each game to be seperated by 1 hour.
            gameList[gameId] = MatchedPlayers({
                                    gameId: gameId,
                                    gameTime: gameTime,
                                    redPlayer: redPlayers[i].owner,
                                    redPlayerKittyId: redPlayers[i].kittyId,
                                    blackPlayer: blackPlayers[i].owner,
                                    blackPlayerKittyId: blackPlayers[i].kittyId
                                });
        }

        // Add to DB


        // reset kittieList, kittieListSuffled, kittyCount
        kittyCount = 0;
        delete kittieList;
        delete kittieListSuffled;
    }


    /**
     * needs to be tested
     */
    function sufflekittieList() private {
        uint256 pos;
        for(uint256 i = 0; i < kittyCount; i++){
            pos = randomNumber(kittyCount);
            kittieListSuffled[pos] = kittieList[i];
        }
    }

    /**
     * needs to be tested
     */
    function randomNumber(uint256 max) internal returns (uint){
        uint256 random = uint(keccak256(abi.encodePacked(now, msg.sender, randomNonce))) % max;
        randomNonce++;
        return random;
    }

    /**
     * @dev Generate game ID
     * @dev since a player may list more than one kittie hence kittyId is also used to generate the game ID
     */
    function generateGameId( address redPlayerId, uint256 redPlayerKittyId, address blackPlayerId, uint256 blackPlayerKittyId )
     public view returns ( uint256 ) {
        return uint256(keccak256(abi.encodePacked(redPlayerId, redPlayerKittyId, blackPlayerId, blackPlayerKittyId, now)));
    }



    /**
     * returns the game start time
     */
    function fightTimeStart(uint256 gameId) internal returns ( uint256 ){
        // get from the DB
    }

    /**
     *
     */
    function fightMatchLimit() internal returns ( uint256 ){

    }





}