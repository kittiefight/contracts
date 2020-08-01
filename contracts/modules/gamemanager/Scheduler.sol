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
import "./GameCreation.sol";
import "../../interfaces/ERC721.sol";
import "../kittieHELL/KittieHell.sol";
import "./GameStore.sol";
import "../databases/GenericDB.sol";

/**
 * @title Scheduler
 * @dev Responsible for game Schedule
 * @author @Xaleee
 */

contract Scheduler is Proxied {
    using SafeMath for uint256;

    GameCreation public gameCreation;
    GameVarAndFee public gameVarAndFee;
    KittieHell public kittieHell;
    ERC721 public cryptoKitties;
    GameStore public gameStore;
    GenericDB public genericDB;

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
        gameCreation = GameCreation(proxy.getContract(CONTRACT_NAME_GAMECREATION));
        cryptoKitties = ERC721(proxy.getContract(CONTRACT_NAME_CRYPTOKITTIES));
        kittieHell = KittieHell(proxy.getContract(CONTRACT_NAME_KITTIEHELL));
        gameStore = GameStore(proxy.getContract(CONTRACT_NAME_GAMESTORE));
        genericDB = GenericDB(proxy.getContract(CONTRACT_NAME_GENERIC_DB));
    }

    /**
    * @dev Changes mode of game creation.
    */
    function changeMode() public onlyOwner {
        require(genericDB.getBoolStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encode("unlocked"))), "Can change mode only in Rest Day");

        if(genericDB.getBoolStorage(CONTRACT_NAME_SCHEDULER, keccak256(abi.encode("schedulerMode"))))
            genericDB.setBoolStorage(CONTRACT_NAME_SCHEDULER, keccak256(abi.encode("schedulerMode")), false);
        else
            genericDB.setBoolStorage(CONTRACT_NAME_SCHEDULER, keccak256(abi.encode("schedulerMode")), true);
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

        if(noOfKittiesListed >= 2) {
            if((gameVarAndFee.getRequiredNumberMatches().mul(2)) == noOfKittiesListed)
                matchKitties();
            else if(immediateStart) {
                createFlashGame();
                immediateStart = false;
            }
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
    returns(bool)
    {
        if(headGame == 0) {
            if(noOfKittiesListed >= 2)
                createFlashGame();
            else
                return false;
        }
        else
            _startGame();

        return true;
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

    // return amount in dai
    function calculateDynamicFee
    (
        uint256 percentageHoneyPot,
        uint256 _eth_amount,
        uint256 _kty_amount
    )
        public view returns(uint256)
    {
        require(percentageHoneyPot > 0 && _eth_amount > 0 && _kty_amount > 0);

        // uint256 ethUsdPrice = gameVarAndFee.getEthUsdPrice();
        // uint256 usdKTYPrice = gameVarAndFee.getUsdKTYPrice();

        // convert ether to dai
        uint256 portion1DAI = gameVarAndFee.convertEthToDai(_eth_amount);

        // convert kty to ether, then to dai
        uint256 portion2ETH = gameVarAndFee.convertKtyToEth(_kty_amount);
        uint256 portion2DAI = gameVarAndFee.convertEthToDai(portion2ETH);

        // get the whole amount
        uint256 portionDAI = portion1DAI.add(portion2DAI);

        // 1,000,000 is the base used for percentage setting in kittieFight
        // for example, if percentageHoneyPot is 0.03% in real world, inside this function
        // percentageHoneyPot = 0.03% * 1,000,1000 which is 300, thus for the need of div(1000000)
        return portionDAI.mul(percentageHoneyPot).div(1000000);
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

        if(immediateStart)
            immediateStart = !(_startGame());
    }

    /**
     * @dev This function is creating a game, which becomes scheduled immediately.
     */
    function _startGame()
    internal
    returns(bool)
    {
        uint256 gameStartTime = gameVarAndFee.getGameTimes().add(now);
        if(genericDB.getUintStorage(CONTRACT_NAME_TIMEFRAME, keccak256(abi.encodePacked(
            genericDB.getUintStorage(CONTRACT_NAME_TIMEFRAME, keccak256(abi.encode("activeEpoch"))),"endTimeForGames"))) > gameStartTime
            || !genericDB.getBoolStorage(CONTRACT_NAME_SCHEDULER, keccak256(abi.encode("schedulerMode"))))
            return false;

        gameCreation.createFight(
            gameList[headGame].playerRed,
            gameList[headGame].playerBlack,
            gameList[headGame].kittyRed,
            gameList[headGame].kittyBlack,
            gameStartTime
        );

        headGame = gameList[headGame].next;
        return true;
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
