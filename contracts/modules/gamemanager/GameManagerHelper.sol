pragma solidity ^0.5.5;

import '../proxy/Proxied.sol';
import '../../authority/Guard.sol';
import "../../libs/SafeMath.sol";
import "../../GameVarAndFee.sol";
import "../databases/GenericDB.sol";
import "../databases/GMGetterDB.sol";
import "../endowment/EndowmentFund.sol";
import "../databases/EndowmentDB.sol";
import "../databases/KittieHellDB.sol";
import "./Scheduler.sol";
import '../kittieHELL/KittieHell.sol';
import "../databases/AccountingDB.sol";
import "../../interfaces/IKittyCore.sol";

contract GameManagerHelper is Proxied, Guard {
    using SafeMath for uint256;

    //Contract Variables
    GenericDB public genericDB;
    GMGetterDB public gmGetterDB;
    GameVarAndFee public gameVarAndFee;
    EndowmentDB public endowmentDB;
    EndowmentFund public endowmentFund;
    Scheduler public scheduler;
    KittieHell public kittieHELL;
    KittieHellDB public kittieHellDB;
    AccountingDB public accountingDB;
    IKittyCore public cryptoKitties;

    enum HoneypotState {
        created,
        assigned,
        gameScheduled,
        gameStarted,
        forefeited,
        claiming,
        dissolved
    }

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
        genericDB = GenericDB(proxy.getContract(CONTRACT_NAME_GENERIC_DB));
        gmGetterDB = GMGetterDB(proxy.getContract(CONTRACT_NAME_GM_GETTER_DB));
        gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        endowmentDB = EndowmentDB(proxy.getContract(CONTRACT_NAME_ENDOWMENT_DB));
        endowmentFund = EndowmentFund(proxy.getContract(CONTRACT_NAME_ENDOWMENT_FUND));
        scheduler = Scheduler(proxy.getContract(CONTRACT_NAME_SCHEDULER));
        kittieHELL = KittieHell(proxy.getContract(CONTRACT_NAME_KITTIEHELL));
        kittieHellDB = KittieHellDB(proxy.getContract(CONTRACT_NAME_KITTIEHELL_DB));
        accountingDB = AccountingDB(proxy.getContract(CONTRACT_NAME_ACCOUNTING_DB));
        cryptoKitties = IKittyCore(proxy.getContract(CONTRACT_NAME_CRYPTOKITTIES));
    }

    // Setters
    /**
     * @dev Checks and prevents unverified accounts, only accounts with available kitties can list
     */
    function listKittie
    (
        uint kittieId
    )
        external
        payable
        onlyProxy onlyPlayer
        onlyKittyOwner(getOriginalSender(), kittieId) //currently doesKittieBelong is not used, better
    {
        address player = getOriginalSender();

        //Pay Listing Fee
        // get listing fee in Dai
        (uint etherForListingFeeSwap, uint listingFeeKTY) = gameVarAndFee.getListingFee();

        require(endowmentFund.contributeKTY.value(msg.value)(player, etherForListingFeeSwap, listingFeeKTY), "Need to pay listing fee");
        //endowmentFund.contributeKTY(player, gameVarAndFee.getListingFee());

        require((gmGetterDB.getGameOfKittie(kittieId) == 0), "Kittie is already playing a game");

        scheduler.addKittyToList(kittieId, player);

        accountingDB.recordKittieListingFee(kittieId, msg.value, listingFeeKTY);

        emit NewListing(kittieId, player, now);
    }

    function removeKitties(uint256 gameId)
        external
        onlyContract(CONTRACT_NAME_GAMEMANAGER)
    {
        ( , ,uint256 kittyBlack, uint256 kittyRed) = gmGetterDB.getGamePlayers(gameId);

        //Set gameId to 0 to both kitties (not playing any game)
        _updateKittiesGame(kittyBlack, kittyRed, 0);

        if(genericDB.getBoolStorage(CONTRACT_NAME_SCHEDULER, keccak256(abi.encode("schedulerMode"))))
            scheduler.startGame();
    }

    function updateKitties(address winner, address loser, uint256 gameId)
    external
    onlyContract(CONTRACT_NAME_GAMEMANAGER)
    {
        //Release winner's Kittie
        kittieHELL.releaseKittyGameManager(gmGetterDB.getKittieInGame(gameId, winner));

        //Kill losers's Kittie
        kittieHELL.killKitty(gmGetterDB.getKittieInGame(gameId, loser), gameId);

        if(genericDB.getBoolStorage(CONTRACT_NAME_SCHEDULER, keccak256(abi.encode("schedulerMode"))))
            scheduler.startGame();
    }

    /**
    * @dev updateHoneyPotState
    */
    function updateHoneyPotState(uint256 _gameId, uint _state) public onlyContract(CONTRACT_NAME_GAMEMANAGER) {
        if (_state == uint(HoneypotState.claiming)){
            //Send immediately initialEth+15%oflosing and 15%ofKTY to endowment
            (uint256 winningsETH, uint256 winningsKTY) = endowmentFund.getEndowmentShare(_gameId);
            endowmentDB.updateEndowmentFund(winningsKTY, winningsETH, false);
            endowmentDB.updateHoneyPotFund(_gameId, winningsKTY, winningsETH, true);
        }
        if(_state == uint(HoneypotState.forefeited)) {
            (uint256 eth, uint256 kty) = accountingDB.getHoneypotTotal(_gameId);
            endowmentDB.updateEndowmentFund(kty, eth, false);
            endowmentDB.updateHoneyPotFund(_gameId, kty, eth, true);
        }
        endowmentDB.setHoneypotState(_gameId, _state);
    }

    /**
     * @dev Update kittie playing game Id
     */
    function updateKittiesGame(uint kittyBlack, uint kittyRed, uint gameId)
        external
        onlyContract(CONTRACT_NAME_GAMECREATION)
    {
        _updateKittiesGame(kittyBlack, kittyRed, gameId);
    }

    // getters
    function checkPerformanceHelper(uint gameId, uint gameEndTime) external view returns(bool){
        //each time 1 minute before game ends
        uint performanceTimeCheck = gameVarAndFee.getPerformanceTimeCheck();
        
        if(gameEndTime.sub(performanceTimeCheck) <= now) {
            //get initial jackpot, need endowment to send this when creating honeypot
            (,,uint initialEth, uint currentJackpotEth,,,) = gmGetterDB.getHoneypotInfo(gameId);

            if(currentJackpotEth < initialEth.mul(10)) return true;
            return false;
        }
    }

     function getWinnerLoser(uint256 gameId)
        public view
        returns(address winner, address loser, uint256 totalBetsForLosingCorner)
    {
        (winner,,) = gmGetterDB.getWinners(gameId);
        loser = getOpponent(gameId, winner);
        totalBetsForLosingCorner = gmGetterDB.getTotalBet(gameId, loser);
    }

    function getDistributionRates(uint gameId) public view returns(uint[5] memory){
        uint[5] memory distributionRates;
        distributionRates[0] = genericDB.getUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "distributionRates", "winningKittie"))
        );
        distributionRates[1] = genericDB.getUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "distributionRates", "topBettor"))
        );
        distributionRates[2] = genericDB.getUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "distributionRates", "secondRunnerUp"))
        );
        distributionRates[3] = genericDB.getUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "distributionRates", "otherBettors"))
        );
        distributionRates[4] = genericDB.getUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "distributionRates", "endownment"))
        );
        return distributionRates;
    }

    function getKittieExpirationTime(uint gameId) public view returns(uint){
        return genericDB.getUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "kittieHellExpirationTime"))
        );
    }

    function getKittieRedemptionFee(uint256 gameId) public view returns(uint256, uint256) {
        uint256 redemptionFeeDAI = genericDB.getUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "kittieRedemptionFee"))
        );
        uint256 redemptionFeeKTY = getKTY(redemptionFeeDAI);
        uint256 etherForSwap = KtyUniswap(proxy.getContract(CONTRACT_NAME_KTY_UNISWAP)).etherFor(redemptionFeeKTY);
        return (etherForSwap, redemptionFeeKTY);
    }
    
    function getHoneypotExpiration(uint gameId) public view returns(uint){
        return  genericDB.getUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "honeypotExpirationTime"))
        );
    }

    function didHitStart(uint gameId, address player) public view returns(bool){
        return genericDB.getBoolStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, player, "pressedStart"))
        );
    }

    function getTicketFee(uint256 gameId) public view returns(uint256, uint256){
        uint256 ticketFeeDAI = genericDB.getUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "ticketFee"))
        );
        uint256 ticketFeeKTY = getKTY(ticketFeeDAI);
        uint256 ethForSwap = KtyUniswap(proxy.getContract(CONTRACT_NAME_KTY_UNISWAP)).etherFor(ticketFeeKTY);
        return (ethForSwap, ticketFeeKTY);
    }

    function getBettingFee(uint256 gameId) public view returns(uint256, uint256){
        uint256 bettingFeeDAI = genericDB.getUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "bettingFee"))
        );
        uint256 bettingFeeKTY = getKTY(bettingFeeDAI);
        uint256 ethForFeeSwap = KtyUniswap(proxy.getContract(CONTRACT_NAME_KTY_UNISWAP)).etherFor(bettingFeeKTY);
        return (ethForFeeSwap, bettingFeeKTY);
    }

    function getMinimumContributors(uint gameId) public view returns(uint){
        return genericDB.getUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "minimumContributors"))
        );
    }

    function getKTY(uint256 _DAI) internal view returns(uint256) {
        uint256 _ETH = gameVarAndFee.convertDaiToEth(_DAI);
        return gameVarAndFee.convertEthToKty(_ETH);
    }

    function getPerformanceTimeCheck(uint gameId) public view returns(uint){
        return genericDB.getUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "performanceTime"))
        );
    }

    function getTimeExtension(uint gameId) public view returns(uint){
        return genericDB.getUintStorage(
            CONTRACT_NAME_GAMESTORE,
            keccak256(abi.encodePacked(gameId, "timeExtension"))
        );
    }

    function getOpponent(uint gameId, address player) public view returns(address){
        (address playerBlack, address playerRed,,) = gmGetterDB.getGamePlayers(gameId);
        if(playerBlack == player) return playerRed;
        return playerBlack;
    }

    function getCorner(uint gameId, address player) public view returns(uint){
        (address playerBlack, address playerRed,,) = gmGetterDB.getGamePlayers(gameId);
        if(playerBlack == player) return 0;
        if(playerRed == player) return 1;
        return 2;
    }

    function getFighterByKittieID(uint256 kittieId)
    public view
    returns (address owner, bool isDead, uint deathTime, uint kittieHellExp, bool isGhost, bool isPlaying, uint gameId)
  {
    (owner, isDead,, isGhost, deathTime) = kittieHellDB.kittyStatus(kittieId);
    gameId = gmGetterDB.getGameOfKittie(kittieId);
    //If gameId is 0 is not playing, otherwise, it is.
    isPlaying = (gameId != 0);
    if(isDead) kittieHellExp = deathTime.add(getKittieExpirationTime(gameId));
  }

    // internal functions
    function _updateKittiesGame(uint kittyBlack, uint kittyRed, uint gameId)
        internal
    {
        genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_HELPER, keccak256(abi.encodePacked(kittyBlack, "playingGame")), gameId);
        genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_HELPER, keccak256(abi.encodePacked(kittyRed, "playingGame")), gameId);
    }
    
}