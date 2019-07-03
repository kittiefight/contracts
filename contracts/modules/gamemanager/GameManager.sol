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
import "../databases/GameManagerSetterDB.sol";
import "../databases/GameManagerGetterDB.sol";
import "../../GameVarAndFee.sol";
import "../endowment/EndowmentFund.sol";
import "../endowment/Distribution.sol";
import "../../interfaces/ERC20Standard.sol";
import "./Forfeiter.sol";
import "./Scheduler.sol";
import "../datetime/DateTime.sol";
import "../algorithm/Betting.sol";
import "../algorithm/HitsResolveAlgo.sol";
import "../algorithm/RarityCalculator.sol";
import "../registration/Register.sol";
import "../../libs/SafeMath.sol";
import '../kittieHELL/KittieHELL.sol';


contract GameManager is Proxied {
    using SafeMath for uint256;

    //Contract Variables
    GameManagerGetterDB public gameManagerGetterDB;
    GameManagerSetterDB public gameManagerSetterDB;
    GameVarAndFee public gameVarAndFee;
    EndowmentFund public endowmentFund;
    Distribution public distribution;
    ERC20Standard public kittieFightToken;
    Forfeiter public forfeiter;
    DateTime public timeContract;
    Scheduler public scheduler;
    Betting public betting;
    HitsResolve public hitsResolve;
    RarityCalculator public rarityCalculator;
    Register public register;
    KittieHELL public kittieHELL;


    uint256 public constant PLAYER_STATUS_INITIATED = 1;
    uint256 public constant PLAYER_STATUS_PLAYING = 2;
    uint256 public constant GAME_STATE_CREATED = 0;
    uint256 public constant GAME_STATE_PRESTART = 1;
    uint256 public constant GAME_STATE_STARTED = 2;
    uint256 public constant GAME_STATE_CANCELLED = 3;
    uint256 public constant GAME_STATE_FINISHED = 4;

    modifier onlyKittyOwner(address account, uint kittieId) {
        // require(register.doesKittieBelong(account, kittieId), "Not owner of kittie");
        //TODO: ADD verify check here?
        _;
    }

    modifier onlyGamePlayer(uint gameId, address player) {
        require(gameManagerGetterDB.isPlayer(gameId, player), "Invalid player");
        _;
    }

    // only when there is a change it is stored in DB
    struct HigestBettors {
        address topBettorRed;
        uint256 topBettorEthRed;
        address secondTopBettorRed;
        uint256 secondTopBettorEthRed;
        address topBettorBlack;
        uint256 topBettorEthBlack;
        address secondTopBettorBlack;
        uint256 secondTopBettorEthBlack;
    }
    mapping(uint256 => HigestBettors) gameBettors;


    /**
    * @dev Sets related contracts
    * @dev Can be called only by the owner of this contract
    */
    function initialize() external onlyOwner {

        //TODO: Check what other contracts do we need
        gameManagerSetterDB = GameManagerSetterDB(proxy.getContract(CONTRACT_NAME_GAMEMANAGER_SETTER_DB));
        gameManagerGetterDB = GameManagerGetterDB(proxy.getContract(CONTRACT_NAME_GAMEMANAGER_GETTER_DB));
        // endowmentFund = EndowmentFund(proxy.getContract(CONTRACT_NAME_ENDOWMENT));
        // distribution = Distribution(proxy.getContract(CONTRACT_NAME_DISTRIBUTION));
        gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        forfeiter = Forfeiter(proxy.getContract(CONTRACT_NAME_FORFEITER));
        timeContract = DateTime(proxy.getContract(CONTRACT_NAME_TIMECONTRACT));
        scheduler = Scheduler(proxy.getContract(CONTRACT_NAME_SCHEDULER));
        // betting = Betting(proxy.getContract(CONTRACT_NAME_BETTING));
        // hitsResolve = HitsResolve(proxy.getContract(CONTRACT_NAME_HITSRESOLVE));
        // rarityCalculator = RarityCalculator(proxy.getContract(CONTRACT_NAME_RARITYCALCULATOR));
        // kittieFightToken = ERC20Standard(proxy.getContract('MockERC20Token'));
        register = Register(proxy.getContract(CONTRACT_NAME_REGISTER));
        // kittieHELL = KittieHELL(proxy.getContract(CONTRACT_NAME_KITTIEHELL));
    }


    /**
     * @dev Checks and prevents unverified accounts, only accounts with available kitties can list
     */
    function listKittie
    (
        uint kittieId, address player
    )
        external
        onlyProxy
        onlyKittyOwner(player, kittieId)
    {
        // TODO: call endowment function to send tokens, not using transfer
        // contributeKTY expects gameId? I think they need to change that function
        //endowment.contributeKFT(gameId, player, gameVarAndFee.getListingFee());

        // require((GameManagerGetterDB.getKittieState(kittieId) == false), "Kitty can play only one game at a time");

        scheduler.addKittyToList(kittieId, player);
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
        onlyProxy
        onlyKittyOwner(playerRed, kittyRed)
        onlyKittyOwner(playerBlack, kittyBlack)
    {
        // TODO: Check if kitties are not already listed
        generateFight(playerRed, playerBlack, kittyRed, kittyBlack, gameStartTime);
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
        returns(uint)
    {
        uint256 preStartTime = gameStartTime.sub(gameVarAndFee.getGamePrestart());
        uint256 endTime = gameStartTime.add(gameVarAndFee.getGameDuration());

        uint256 gameId = gameManagerSetterDB.createGame(
            playerRed, playerBlack, kittyRed, kittyBlack, gameStartTime, preStartTime, endTime);

        // uint honeyPotId = endowmentFund.generateHoneyPot();
        // gameManagerDB.setHoneypotId(gameId, honeyPotId);
        // endowmentFund.updateHoneyPotState(scheduled); not yet implemented
        
        return gameId;
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
        returns(uint)
    {
        return generateFight(playerRed, playerBlack, kittyRed, kittyBlack, gameStartTime);
    }


    /**
     * @dev Betters pay a ticket fee to participate in betting .
     *      Betters can join before and even a live game.
     */
    function participate
    (
        uint gameId, address supporter,
        address playerToSupport
    )
        external
        onlyProxy
        onlyGamePlayer(gameId, playerToSupport)
    {
        require(gameManagerGetterDB.getGameState(gameId) != GAME_STATE_CANCELLED &&
                gameManagerGetterDB.getGameState(gameId) != GAME_STATE_FINISHED, "Unable to join game");

        //pay ticket fee
        // endowmentFund.contributeKFT(gameId, supporter, gameVarAndFee.getTicketFee());
        gameManagerSetterDB.addBettor(gameId, supporter, 0, playerToSupport);

        forfeiter.checkGameStatus(gameId);

        //Update state if reached prestart time
        if (gameManagerGetterDB.getPrestartTime(gameId) >= now)
            gameManagerSetterDB.updateGameState(gameId, GAME_STATE_PRESTART);
    }

    /**
     * @dev only both Actual players can call
     */
    function startGame
    (
        uint gameId, address player,
        uint randomNum
    )
        external
        onlyProxy
        onlyGamePlayer(gameId, player)
        returns(bool)
    {
        require(gameManagerGetterDB.getGameState(gameId) == GAME_STATE_PRESTART, "Game state is not Prestart");

        if(true //forfeiter.checkGameStatus(gameId)
            ) {
            // TODO: get defense level for player with given kittieId
            //uint defenseLevel = rarityCalculator.getDefenseLevel(gameManagerGetterDB.getKittieInGame(gameId, player));            

            //If both players hit start, do the following:
            //gameManagerSetterDB.updateGameState(gameId, GAME_STATE_PRESTART);
            // TODO: store fight map from betting algo
            // TODO: create a setter for this random number in DB
            // betting.startGame(randomRed, randomBlack);

            // Grouping calls, set hitStart and defense level (TODO: set fight map too here)
            // gameManagerSetterDB.startGameVars(gameId, player, defenseLevel);

        }

        uint256 kittieId = gameManagerGetterDB.getKittieInGame(gameId, player);
        kittieHELL.acquireKitty(kittieId, player);
    }

    /**
     * @dev Extend time of underperforming game indefinitely, each time 1 minute before game ends, by checking at everybet
     */
    function extendTime(uint gameId) internal {
        // check if underperforming
        if(!checkPerformance(gameId)){
            // extend time
        }
    }




    /**
     * @dev KTY tokens are sent to endowment balance, Eth gets added to ongoing game honeypot
     * @author Felipe
     * @author Karl
     * @author Vikrammandal
     */
    function bet (
        uint gameId, address account, uint amountEth,
        address supportedPlayer, uint randomNum
    ) external onlyProxy {

        require(gameManagerGetterDB.getGameState(gameId) == GAME_STATE_STARTED, "Game has not started yet");
        
        forfeiter.checkGameStatus(gameId);

        // if underperformed then call extendTime();
        //  endowmentFund.contributeETH(gameId);

        // hits resolver
        // hitsResolve.calculateCurrentRandom(gameId, randomNum);

        // transfer bettingFee to endowmentFund
        // endowmentFund.contributeKFT(gameId, account, gameVarAndFee.getBettingFee());

        // (bytes4 attackHash, uint attackType) = betting.bet(gameId, amountEth);

        // TODO: store other variables in bet (attack hash, type)
        //store bet info in DB

        // "A bettor pays the KTY token to join a fight and at the same time select the side(Black or Red corner)"
        // "bet method checks if a bettor has paid the required KTY token to join a fight"
        // https://gitlab.com/kittiefight/alpha/issues/6#note_184274144
        // so addBettor() should also set the corner if not set. it should return corner

        gameManagerSetterDB.addBettor(gameId, account, amountEth, supportedPlayer);

        // TODO: update game variables
        // lastBet, topBettor, secondTopBettor, etc...
        bytes32 corner = "Red"; // "Black"  = gameManagerSetterDB.addBettor(gameId, account, amountEth, supportedPlayer);
        calculateBettorStats(gameId, account, amountEth, corner);

        // check underperforming game
        // extendTime(gameId);

        //Check if game has ended
        gameEND(gameId);
    }

    /**
    * set topBettor, secondTopBettor
    * @author vikrammandal
    */
    function calculateBettorStats(
        uint256 _gameId, address _account, uint256 _amountEth, bytes32 _corner
    ) private {
        // TODO: update game variables
        // lastBet, topBettor, secondTopBettor, etc...

        if (keccak256(abi.encodePacked(_corner)) == keccak256(abi.encodePacked("Red"))) {
            // initialize
            if (gameBettors[_gameId].topBettorRed == address(0x0)){
                gameBettors[_gameId].topBettorRed = _account;
                gameBettors[_gameId].topBettorEthRed = _amountEth;
                gameManagerSetterDB.setTopBettor(_gameId, _account, _corner, _amountEth); // update DB
            }
            if (gameBettors[_gameId].secondTopBettorRed == address(0x0)){
                gameBettors[_gameId].secondTopBettorRed = _account;
                gameBettors[_gameId].secondTopBettorEthRed = _amountEth;
                gameManagerSetterDB.setSecondTopBettor(_gameId, _account, _corner, _amountEth);
            }
            // compare
            if (_amountEth > gameBettors[_gameId].topBettorEthRed){
                gameBettors[_gameId].topBettorRed = _account;
                gameBettors[_gameId].topBettorEthRed = _amountEth;
                gameManagerSetterDB.setTopBettor(_gameId, _account, _corner, _amountEth);
            }else if (gameBettors[_gameId].secondTopBettorEthBlack > _amountEth) {
                gameBettors[_gameId].secondTopBettorBlack = _account;
                gameBettors[_gameId].secondTopBettorEthBlack = _amountEth;
                gameManagerSetterDB.setSecondTopBettor(_gameId, _account, _corner, _amountEth);
            }

        }else{ // "Black" corner
            // initialize
            if (gameBettors[_gameId].topBettorBlack == address(0x0)){
                gameBettors[_gameId].topBettorBlack = _account;
                gameBettors[_gameId].topBettorEthBlack = _amountEth;
                gameManagerSetterDB.setTopBettor(_gameId, _account, _corner, _amountEth);
            }
            if (gameBettors[_gameId].secondTopBettorBlack == address(0x0)){
                gameBettors[_gameId].secondTopBettorBlack = _account;
                gameBettors[_gameId].secondTopBettorEthBlack = _amountEth;
                gameManagerSetterDB.setSecondTopBettor(_gameId, _account, _corner, _amountEth);
            }

            // compare
            if (_amountEth > gameBettors[_gameId].topBettorEthBlack){
                gameBettors[_gameId].topBettorBlack = _account;
                gameBettors[_gameId].topBettorEthBlack = _amountEth;
                gameManagerSetterDB.setTopBettor(_gameId, _account, _corner, _amountEth);
            }else if (gameBettors[_gameId].secondTopBettorEthBlack > _amountEth) {
                gameBettors[_gameId].secondTopBettorBlack = _account;
                gameBettors[_gameId].secondTopBettorEthBlack = _amountEth;
                gameManagerSetterDB.setSecondTopBettor(_gameId, _account, _corner, _amountEth);
            }

        }

    }


    /**
     * @dev checks to see if current jackpot is at least 10 times (10x) the amount of funds originally placed in jackpot
     */
    function checkPerformance(uint gameId) internal returns(bool) {
        //get initial jackpot
        //gameManagerDB.getJackpotDetails(gameId)
    }

    /**
     * @dev game comes to an end at time duration,continously check game time end
     */
    function gameEND(uint gameId) internal {
        require(gameManagerGetterDB.getGameState(gameId) == GAME_STATE_STARTED, "Game not started");

        if (gameManagerGetterDB.getEndTime(gameId) >= now)
            gameManagerSetterDB.updateGameState(gameId, GAME_STATE_FINISHED);


        // delete local var
        // gameBettors[_gameId]
    }

    /**
     * @dev Determine winner of game based on  **HitResolver **
     */
    function finalize(uint gameId, uint randomNum) external {
        require(gameManagerGetterDB.getGameState(gameId) == GAME_STATE_FINISHED, "Game has not finished yet");

        // (uint256 lowPunch, uint256 lowKick, uint256 lowThunder, uint256 hardPunch,
        // uint256 hardKick, uint256 hardThunder, uint256 slash) =
        // hitsResolve.finalizeHitTypeValues(gameId, randomNum);

        // TODO: loop through each corners betting list, and add-multiply bet attack
        // with attackvalue retrieved from hitsResolver

        // TODO: store winner, and points of damage done by each player.

        // TODO: upda

    }
    

    /**
     * @dev Cancels the game before the game starts
     */
    function cancelGame(uint gameId) external onlyContract(CONTRACT_NAME_FORFEITER) {
        require(gameManagerGetterDB.getGameState(gameId) == GAME_STATE_CREATED ||
                gameManagerGetterDB.getGameState(gameId) == GAME_STATE_PRESTART, "Unable to cancel game");

        gameManagerSetterDB.updateGameState(gameId, GAME_STATE_CANCELLED);
    }

    

    /**
     * @dev ?
     */
    function claim(uint kittieId) internal {

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
}
