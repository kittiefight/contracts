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
import "../databases/SchedulerDB.sol";

/**
 * @title Scheduler
 * @dev Responsible for game Schedule
 * @author @Xaleee
 */

contract Scheduler is Proxied, SchedulerDB {
    using SafeMath for uint256;

    GameCreation public gameCreation;
    GameVarAndFee public gameVarAndFee;
    KittieHell public kittieHell;
    ERC721 public cryptoKitties;
    GameStore public gameStore;

    struct Game {
        // address playerRed;
        // address playerBlack;
        uint256 kittyRed;
        uint256 kittyBlack;
        uint256 next;
    }

    //mapping(uint256 => Game) public gameList;

    // uint256 headGame;
    // uint256 tailGame;
    // uint256 noOfGames;

    //mapping(uint256 => address) kittyOwner;
    //mapping(uint256 => uint256) kittyList;

    //uint256 noOfKittiesListed;

    //uint256 randomNonce;

    //mapping(uint256 => bool) public isKittyListed;

    //bool immediateStart = true;

    /*                                                GENERAL VARIABLES                                               */
    /*                                                       END                                                      */
    /* ============================================================================================================== */

    /*                                                    MODIFIERS                                                   */
    /*                                                      START                                                     */
    /* ============================================================================================================== */

    modifier onlyUnlistedKitty(uint256 _kittyId) { 
        require(!getKittyListed(_kittyId), "Scheduler: Cannot list same Kitty again");
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
    onlyContract(CONTRACT_NAME_LIST_KITTIES)
    onlyUnlistedKitty(_kittyId)
    {
        require(kittieHell.acquireKitty(_kittyId, _player));
        uint noOfKittiesListed = getNoOfKittiesListed();

        setKittyListed(_kittyId, true);
        setKittyId(noOfKittiesListed, _kittyId);    //kittyList[noOfKittiesListed] = _kittyId;
        setKittyOwner(_kittyId, _player);   //kittyOwner[_kittyId] = _player;
        
        noOfKittiesListed = noOfKittiesListed.add(1);
        setNoOfKittiesListed(noOfKittiesListed);
        bool immediateStart = getImmediateStart();

        if(noOfKittiesListed >= 2) {
            if((gameVarAndFee.getRequiredNumberMatches().mul(2)) == noOfKittiesListed)
                matchKitties();
            else if(immediateStart) {
                createFlashGame();
                setImmediateStart(false); //immediateStart = false;
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
    only2Contracts(CONTRACT_NAME_GAMESTORE, CONTRACT_NAME_GAMEMANAGER_HELPER)
    returns(bool)
    {
        uint noOfKittiesListed = getNoOfKittiesListed();
        uint headGame = getHeadGame();        
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
        uint256 noOfKittiesListed = getNoOfKittiesListed();
        uint256[] memory listedKitties = new uint256[](noOfKittiesListed);
        for (uint256 i = 0; i < noOfKittiesListed; i++){
            listedKitties[i] = getKittyId(i);
        }
        return listedKitties;
    }

    /**
     * @dev This function is returning the addresses of players that their Kitties are listed in kittyList.
     */
    function getListedPlayers() public view returns (address[] memory){
        uint256 noOfKittiesListed = getNoOfKittiesListed();
        address[] memory listedPlayers = new address[](noOfKittiesListed);
        for (uint256 i = 0; i < noOfKittiesListed; i++){
            listedPlayers[i] = getKittyOwner(getKittyId(i));
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
        return getKittyListed(_kittyId);
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

        uint noOfKittiesListed = getNoOfKittiesListed();

        Game memory game;
        game.kittyRed = getKittyId(noOfKittiesListed.sub(1));
        game.kittyBlack = getKittyId(noOfKittiesListed.sub(2));

        setKittyListed(game.kittyRed,false);
        setKittyListed(game.kittyBlack,false);

        uint noOfGames = getNoOfGames().add(1);
        noOfKittiesListed = noOfKittiesListed.sub(2);

        setGame(noOfGames, encodeGame(game)); //gameList[noOfGames] = game;
        setHeadGame(noOfGames);

        _startGame();

        setNoOfKittiesListed(noOfKittiesListed);
        setNoOfGames(noOfGames);
    }

    /**
     * @dev This function is creating a whole list of games when required kitties are listed.
     *      Starts a created game immediatelly if immediateStart is true.
     */
    function matchKitties() internal {
        shuffleKittyList();

        Game memory game;
        uint256 noOfGames = getNoOfGames();
        uint256 headGame = getHeadGame();
        uint256 tailGame = getTailGame();
        uint256 noOfKittiesListed = getNoOfKittiesListed();

        for(uint256 i = 0; i < noOfKittiesListed.div(2); i += 2) {
            game.kittyRed = getKittyId(i);
            game.kittyBlack = getKittyId(i.add(1));

            setKittyListed(game.kittyRed, false);
            setKittyListed(game.kittyBlack, false);

            noOfGames = noOfGames.add(1);

            if(headGame == 0) {
                headGame = noOfGames;
            } else {
                setGameProperty_next(tailGame, noOfGames); //gameList[tailGame].next = noOfGames;
            }

            tailGame = noOfGames;
            setGame(noOfGames, encodeGame(game));//gameList[noOfGames] = game;
        }

        setHeadGame(headGame);
        setTailGame(tailGame);
        setNoOfGames(noOfGames);
        setNoOfKittiesListed(0); //noOfKittiesListed = 0;

        bool immediateStart = getImmediateStart();
        if(immediateStart) {
            immediateStart = !(_startGame());
            setImmediateStart(immediateStart);
        }
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

        uint256 headGame = getHeadGame();
        Game memory game = decodeGame(getGame(headGame));
        gameCreation.createFight(
            getKittyOwner(game.kittyRed),
            getKittyOwner(game.kittyBlack),
            game.kittyRed,
            game.kittyBlack,
            gameStartTime
        );

        setHeadGame(game.next);
        return true;
    }


    /**
     * @dev This function is shuffling the list of Kitties, for random matching.
     */
    function shuffleKittyList() internal {
        uint256 noOfKittiesListed = getNoOfKittiesListed();
        for(uint256 i = 0; i < noOfKittiesListed; i++) {
            uint256 tempKitty = getKittyId(i);
            uint256 index = randomNumber(noOfKittiesListed, i);
            setKittyId(i, getKittyId(index));
            setKittyId(index, tempKitty);
        }
    }

    /**
     * @dev This function is providing a random number between 0 and max.
     * @param max The number generated is less than max (not euqal).
     */
    function randomNumber(uint256 max, uint256 iteration) internal view returns (uint256){
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, iteration))).mod(max);
    }


    function setGameProperty_next(uint256 gameId, uint256 newNext) internal {
        Game memory game = decodeGame(getGame(gameId));
        game.next = newNext;
        setGame(gameId, encodeGame(game));
    }

    function encodeGame(Game memory game) internal pure returns(bytes memory){
        return abi.encode(
            // game.playerRed;
            // game.playerBlack;
            game.kittyRed,
            game.kittyBlack,
            game.next
        );
    }

    function decodeGame(bytes memory encGame) internal pure returns(Game memory game){
        if(encGame.length == 0) {
            game = Game({
                // playerRed: address(0),
                // playerBlack: address(0),
                kittyRed: 0,
                kittyBlack: 0,
                next:0
            });
        }else{
            (uint256 kittyRed, uint256 kittyBlack, uint256 next) = abi.decode(encGame, (uint256, uint256, uint256));
            game = Game(kittyRed, kittyBlack, next);
        }
    }

    
    /*                                                INTERNAL FUNCTIONS                                              */
    /*                                                       END                                                      */
    /* ============================================================================================================== */
}
