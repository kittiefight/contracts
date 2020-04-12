/* Code by Xaleee ======================================================================================= Kittiefight */

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
import "../kittieHELL/KittieHell.sol";

/**
 * @title Scheduler
 * @dev Responsible for game Schedule
 * @author @Xaleee
 */

contract Scheduler is Proxied {
    using SafeMath for uint256;

    //Contract Variables
    GameManager public gameManager;
    GameCreation public gameCreation;
    GameVarAndFee public gameVarAndFee;
    KittieHell public kittieHell;
    ERC721 public cryptoKitties;
    uint256 lastGameCreationTime;

    struct Game {
        address playerRed;
        address playerBlack;
        uint256 kittyRed;
        uint256 kittyBlack;
        uint256 next;
    }

    mapping(uint256 => Game) public gameList;

    uint256 headGame;
    uint256 tailGame;
    uint256 noOfGames;

    mapping(uint256 => address) kittyOwner;
    mapping(uint256 => uint256) kittyList;

    uint256 noOfKittiesListed;

    uint256 randomNonce;

    mapping(uint256 => bool) public isKittyListed;

    bool immediateStart = true;

    /*                                                GENERAL VARIABLES                                               */
    /*                                                       END                                                      */
    /* ============================================================================================================== */

    /*                                                    MODIFIERS                                                   */
    /*                                                      START                                                     */
    /* ============================================================================================================== */

    modifier onlyUnlistedKitty(uint256 _kittyId) { 
        require(!isKittyListed[_kittyId], "Scheduler: Cannot list same Kitty again");
        _;
    }
    

    /*                                                    MODIFIERS                                                   */
    /*                                                       END                                                      */
    /* ============================================================================================================== */

    /*                                                   INITIALIZOR                                                  */
    /*                                                      START                                                     */
    /* ============================================================================================================== */

    /**
    * @dev Initializes all contracts needed for Scheduler.
    */
    function initialize() public onlyOwner {
        gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        gameManager = GameManager(proxy.getContract(CONTRACT_NAME_GAMEMANAGER));
        gameCreation = GameCreation(proxy.getContract(CONTRACT_NAME_GAMECREATION));
        cryptoKitties = ERC721(proxy.getContract(CONTRACT_NAME_CRYPTOKITTIES));
        kittieHell = KittieHell(proxy.getContract(CONTRACT_NAME_KITTIEHELL));
    }

    /*                                                   INITIALIZOR                                                  */
    /*                                                       END                                                      */
    /* ============================================================================================================== */

    /*                                                 ACTION FUNCTIONS                                               */
    /*                                                      START                                                     */
    /* ============================================================================================================== */

    /**
    * @param _kittyId kitty id
    * @param _player is the address of the player
    */
    function addKittyToList(uint256 _kittyId, address _player)
    external
    onlyContract(CONTRACT_NAME_GAMECREATION)
    onlyUnlistedKitty(_kittyId)
    {
        require(kittieHell.acquireKitty(_kittyId, _player));
        isKittyListed[_kittyId] = true;
        kittyList[noOfKittiesListed] = _kittyId;
        kittyOwner[_kittyId] = _player;
        
        noOfKittiesListed = noOfKittiesListed.add(1);

        if((gameVarAndFee.getRequiredNumberMatches().mul(2)) == noOfKittiesListed)
            matchKitties();
        else if(immediateStart && noOfKittiesListed >= 2) {
            createFlashGame();
            immediateStart = false;
        }
    }

    /**
     * @dev This function is called by GameManager's finalize function, so as a new game to be created immediately.
     *      In case there are no matches created yet, it checks if there are 2 or more available kitties in Kittylist.
     *      If yes, it creates a flash game for two random kitties, otherwise it makes immediateStart true, so as when
     *      two kitties come in kittyList a flashGame to be created.
     */
    function startGame()
    external
    onlyContract(CONTRACT_NAME_GAMESTORE)
    {
        if(headGame == 0) {
            if(noOfKittiesListed < 2)
                immediateStart = true;
            else
                createFlashGame();
        }
        else
            _startGame();
    }
    
    /*                                                 ACTION FUNCTIONS                                               */
    /*                                                       END                                                      */
    /* ============================================================================================================== */

    /*                                                 GETTER FUNCTIONS                                               */
    /*                                                      START                                                     */
    /* ============================================================================================================== */

    /**
     * @dev This function is returning the kitties that are listed in kittyList.
     */
    function getListedKitties() public view returns (uint256[] memory){
        uint256[] memory listedKitties = new uint256[](noOfKittiesListed);
        for (uint256 i = 0; i < noOfKittiesListed; i++){
            listedKitties[i] = kittyList[i];
        }
        return listedKitties;
    }

    /**
     * @dev This function is returning the addresses of players that their Kitties are listed in kittyList.
     */
    function getListedPlayers() public view returns (address[] memory){
        address[] memory listedPlayers = new address[](noOfKittiesListed);
        for (uint256 i = 0; i < noOfKittiesListed; i++){
            listedPlayers[i] = kittyOwner[kittyList[i]];
        }
        return listedPlayers;
    }

    /**
     * @dev This function is returning true when kitty is in kittyList and false when not.
     */
    function isKittyListedForMatching(uint256 _kittyId)
    external
    view
    returns(bool)
    {
        return isKittyListed[_kittyId];
    }

    /*                                                 GETTER FUNCTIONS                                               */
    /*                                                       END                                                      */
    /* ============================================================================================================== */

    /*                                                INTERNAL FUNCTIONS                                              */
    /*                                                      START                                                     */
    /* ============================================================================================================== */

    /**
     * @dev This function is creating a flash games. Flash games are created when list has not yet reached the
     *      required amount of Kitties, but gameManager asked for a game (case where no game exists).
     */
    function createFlashGame()
    internal
    {
        shuffleKittyList();

        Game memory game;
        game.playerRed = kittyOwner[kittyList[noOfKittiesListed.sub(1)]];
        game.playerBlack = kittyOwner[kittyList[noOfKittiesListed.sub(2)]];
        game.kittyRed = kittyList[noOfKittiesListed.sub(1)];
        game.kittyBlack = kittyList[noOfKittiesListed.sub(2)];

        isKittyListed[kittyList[noOfKittiesListed.sub(1)]] = false;
        isKittyListed[kittyList[noOfKittiesListed.sub(2)]] = false;

        noOfGames = noOfGames.add(1);
        noOfKittiesListed = noOfKittiesListed.sub(2);

        gameList[noOfGames] = game;
        headGame = noOfGames;

        _startGame();
    }

    /**
     * @dev This function is creating a whole list of games when required kitties are listed.
     *      Starts a created game immediatelly if immediateStart is true.
     */
    function matchKitties() internal {
        shuffleKittyList();

        Game memory game;

        for(uint256 i = 0; i < noOfKittiesListed.div(2); i += 2) {
            game.playerRed = kittyOwner[kittyList[i]];
            game.playerBlack = kittyOwner[kittyList[i.add(1)]];
            game.kittyRed = kittyList[i];
            game.kittyBlack = kittyList[i.add(1)];

            isKittyListed[kittyList[i]] = false;
            isKittyListed[kittyList[i.add(1)]] = false;

            noOfGames = noOfGames.add(1);

            if(headGame == 0)
                headGame = noOfGames;
            else
                gameList[tailGame].next = noOfGames;

            tailGame = noOfGames;
            gameList[noOfGames] = game;
        }

        noOfKittiesListed = 0;

        if(immediateStart) {
            _startGame();
            immediateStart = false;
        }
    }

    /**
     * @dev This function is creating a game, which becomes scheduled immediately.
     */
    function _startGame()
    internal
    {
        gameCreation.createFight(
            gameList[headGame].playerRed,
            gameList[headGame].playerBlack,
            gameList[headGame].kittyRed,
            gameList[headGame].kittyBlack,
            gameVarAndFee.getGameTimes().add(now)
        );

        headGame = gameList[headGame].next;
    }


    /**
     * @dev This function is shuffling the list of Kitties, for random matching.
     */
    function shuffleKittyList() internal {
        for(uint256 i = 0; i < noOfKittiesListed; i++) {
            uint256 tempKitty = kittyList[i];
            uint256 index = randomNumber(noOfKittiesListed);
            kittyList[i] = kittyList[index];
            kittyList[index] = tempKitty;
        }
    }

    /**
     * @dev This function is providing a random number between 0 and max.
     * @param max The number generated is less than max (not euqal).
     */
    function randomNumber(uint256 max) internal returns (uint256){
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, randomNonce))).mod(max);
        randomNonce = randomNonce.add(1);
        return random;
    }
    
    /*                                                INTERNAL FUNCTIONS                                              */
    /*                                                       END                                                      */
    /* ============================================================================================================== */
}
