pragma solidity ^0.5.5;

import '../proxy/Proxied.sol';
import "../datetime/TimeFrame.sol";
import "../databases/EndowmentDB.sol";
import "../databases/GMSetterDB.sol";
import "../databases/GMGetterDB.sol";
import "../../GameVarAndFee.sol";
import "../endowment/EndowmentFund.sol";
import "./Scheduler.sol";
import "../../libs/SafeMath.sol";
import '../../authority/Guard.sol';
import "../../interfaces/IKittyCore.sol";
import "./GameStore.sol";
import "./GameManager.sol";
import "../../CronJob.sol";
import "./Forfeiter.sol";
import '../kittieHELL/KittieHell.sol';
import "../endowment/HoneypotAllocationAlgo.sol";
import '../endowment/KtyUniswap.sol';
import "../databases/GenericDB.sol";
import "../../withdrawPool/WithdrawPool.sol";
import "../databases/AccountingDB.sol";
import "./GameManagerHelper.sol";
import "./GameCreation.sol";

contract ListKitties is Proxied, Guard {
    using SafeMath for uint256;

    //Contract Variables
    GMSetterDB public gmSetterDB;
    GMGetterDB public gmGetterDB;
    GameVarAndFee public gameVarAndFee;
    EndowmentFund public endowmentFund;
    Scheduler public scheduler;
    IKittyCore public cryptoKitties;
    GameStore public gameStore;
    CronJob public cronJob;
    KittieHell public kittieHELL;
    GenericDB public genericDB;
    WithdrawPool public withdrawPool;
    AccountingDB public accountingDB;
    GameManagerHelper public gameManagerHelper;
    GameCreation public gameCreation;


    //EVENTS
    event NewGame(uint indexed gameId, address playerBlack, uint kittieBlack, address playerRed, uint kittieRed, uint gameStartTime);
    event NewListing(uint indexed kittieId, address indexed owner, uint timeListed);
    // event Scheduled(uint indexed jobId, uint jobTime, uint indexed gameId, string job);

    //mapping(uint256 => uint256) public cronJobsForGames; //using gmGetterDB.getCronJobForGame()/gmSetterDB.setCronJobForGame() instead

    modifier onlyKittyOwner(address player, uint kittieId) {
        require(cryptoKitties.ownerOf(kittieId) == player, "Not the owner of this kittie");
        _;
    }

    /**
    * @dev Sets related contracts
    * @dev Can be called only by the owner of this contract
    */
    function initialize() external onlyOwner {
        gmSetterDB = GMSetterDB(proxy.getContract(CONTRACT_NAME_GM_SETTER_DB));
        gmGetterDB = GMGetterDB(proxy.getContract(CONTRACT_NAME_GM_GETTER_DB));
        endowmentFund = EndowmentFund(proxy.getContract(CONTRACT_NAME_ENDOWMENT_FUND));
        gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        scheduler = Scheduler(proxy.getContract(CONTRACT_NAME_SCHEDULER));
        cryptoKitties = IKittyCore(proxy.getContract(CONTRACT_NAME_CRYPTOKITTIES));
        gameStore = GameStore(proxy.getContract(CONTRACT_NAME_GAMESTORE));
        cronJob = CronJob(proxy.getContract(CONTRACT_NAME_CRONJOB));
        kittieHELL = KittieHell(proxy.getContract(CONTRACT_NAME_KITTIEHELL));
        genericDB = GenericDB(proxy.getContract(CONTRACT_NAME_GENERIC_DB));
        withdrawPool = WithdrawPool(proxy.getContract(CONTRACT_NAME_WITHDRAW_POOL));
        accountingDB = AccountingDB(proxy.getContract(CONTRACT_NAME_ACCOUNTING_DB));
        gameManagerHelper = GameManagerHelper(proxy.getContract(CONTRACT_NAME_GAMEMANAGER_HELPER));
        gameCreation = GameCreation(proxy.getContract(CONTRACT_NAME_GAMECREATION));
    }

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
        onlyProxy onlySuperAdmin
        onlyKittyOwner(playerRed, kittyRed)
        onlyKittyOwner(playerBlack, kittyBlack)
    {
        require(genericDB.getUintStorage(CONTRACT_NAME_TIMEFRAME, keccak256(abi.encodePacked(
            genericDB.getUintStorage(CONTRACT_NAME_TIMEFRAME, keccak256(abi.encodePacked("activeEpoch"))),"endTimeForGames"))) > gameStartTime,
            "Wrong start time");

        require(!genericDB.getBoolStorage(CONTRACT_NAME_SCHEDULER, keccak256(abi.encodePacked("schedulerMode"))), "No manual match mode");

        require(!scheduler.isKittyListedForMatching(kittyRed), "fighter already listed");
        require(!scheduler.isKittyListedForMatching(kittyBlack), "fighter already listed");

        require(kittieHELL.acquireKitty(kittyRed, playerRed));
        require(kittieHELL.acquireKitty(kittyBlack, playerBlack));

        emit NewListing(kittyRed, playerRed, now);
        emit NewListing(kittyBlack, playerBlack, now);

        gameCreation.createFight(playerRed, playerBlack, kittyRed, kittyBlack, gameStartTime);
    }

}