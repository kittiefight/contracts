pragma solidity ^0.5.5;

import "../../libs/SafeMath.sol";
import "../../misc/BasicControls.sol";
import "../proxy/Proxied.sol";
import "../../authority/Guard.sol";
import "../../CronJob.sol";
import "../../interfaces/ERC721.sol";
import "../../interfaces/ERC20Standard.sol";
import "../../GameVarAndFee.sol";
import "../gamemanager/GameStore.sol";
import "../gamemanager/GameManagerHelper.sol";
import "../databases/GMGetterDB.sol";
import "../databases/GMSetterDB.sol";
import "../databases/KittieHellDB.sol";
import "../endowment/EndowmentFund.sol";
import "../../uniswapKTY/uniswap-v2-periphery/interfaces/IUniswapV2Router01.sol";
import "../endowment/KtyUniswap.sol";
import "./KittieHellDungeon.sol";
import "../databases/AccountingDB.sol";
import "./KittieHellStruct.sol";

/**
 * @title This contract is responsible to acquire ownership of participating kitties,
 * keep the mortality status and permanent lock them if needed.
 * @author @panos, @ugwu, @ziweidream @Xalee @wafflemakr
 * @notice This contract is able to lock kitties forever caution is advised
 */
contract KittieHell is BasicControls, Proxied, Guard, KittieHellStruct {

    using SafeMath for uint256;

    CronJob public cronJob;
    ERC721 public cryptoKitties;
    ERC20Standard public kittieFightToken;
    GameVarAndFee public gameVarAndFee;
    GameStore public gameStore;
    GMGetterDB public gmGetterDB;
    GMSetterDB public gmSetterDB;
    KittieHellDB public kittieHellDB;
    EndowmentFund public endowmentFund;
    KittieHellDungeon public kittieHellDungeon;
    AccountingDB public accountingDB;
    GameManagerHelper public gameManagerHelper;

    // address[] public path;

    /* This is all the kitties owned and managed by the game */
    //mapping(uint256 => KittyStatus) public kitties; //moved to KittieHellDB

    function initialize() external onlyOwner {
        cronJob = CronJob(proxy.getContract(CONTRACT_NAME_CRONJOB));
        cryptoKitties = ERC721(proxy.getContract(CONTRACT_NAME_CRYPTOKITTIES));
        kittieFightToken = ERC20Standard(proxy.getContract(CONTRACT_NAME_KITTIEFIGHTOKEN));
        gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        gameStore = GameStore(proxy.getContract(CONTRACT_NAME_GAMESTORE));
        gmGetterDB = GMGetterDB(proxy.getContract(CONTRACT_NAME_GM_GETTER_DB));
        gmSetterDB = GMSetterDB(proxy.getContract(CONTRACT_NAME_GM_SETTER_DB));
        kittieHellDB = KittieHellDB(proxy.getContract(CONTRACT_NAME_KITTIEHELL_DB));
        endowmentFund = EndowmentFund(proxy.getContract(CONTRACT_NAME_ENDOWMENT_FUND));
        kittieHellDungeon = KittieHellDungeon(proxy.getContract(CONTRACT_NAME_KITTIEHELL_DUNGEON));
        accountingDB = AccountingDB(proxy.getContract(CONTRACT_NAME_ACCOUNTING_DB));
        gameManagerHelper = GameManagerHelper(proxy.getContract(CONTRACT_NAME_GAMEMANAGER_HELPER));

        // delete path; //Required to allow calling initialize() several times
        // address _WETH = proxy.getContract(CONTRACT_NAME_WETH);
        // path.push(_WETH);
        // address _KTY = proxy.getContract(CONTRACT_NAME_KITTIEFIGHTOKEN);
        // path.push(_KTY);
    }

    /**
     * @author @ugwu @ziweidream
     * @notice transfer the ownership of a kittie to this contract
     * @dev The last owner must be stored as a returned reference
     * @dev This function can only be carried out via proxy
     * @param _kittyID the kittie to acquire
     * @return true if the acquisition was successful
     */
    function acquireKitty(uint256 _kittyID, address owner)
        public
        onlyNotOwnedKitty(_kittyID)
        only2Contracts(CONTRACT_NAME_SCHEDULER, CONTRACT_NAME_LIST_KITTIES)
        returns (bool)
    {
        return _acquireKitty(_kittyID, owner);
    }

    /**
     * @author @ugwu @ziweidream
     * @notice transfer the ownership of a kittie to this contract
     * @dev The last owner must be stored as a returned reference
     * @dev This function can only be carried out via proxy
     * @param _kittyID the kittie to acquire
     * @return true if the acquisition was successful
     */
    function _acquireKitty(uint256 _kittyID, address owner)
        internal
        returns (bool)
    {
        kittieHellDungeon.transferFrom(owner, _kittyID);
        require(cryptoKitties.ownerOf(_kittyID) == address(kittieHellDungeon));
        KittyStatus memory ks = decodeKittieStatus(kittieHellDB.getKittieStatus(_kittyID));
        ks.owner = owner;
        kittieHellDB.setKittieStatus(_kittyID, encodeKittieStatus(ks));
        emit KittyAcquired(_kittyID);
        return true;
    }

    /**
     * @author @ziweidream
     * @notice Killing kitty `_kittyID`
     * @dev This function can only be carried out via CronJOb
     * @param _kittyID The kitty to kill
     * @return true/false if the kitty ID is killed or not
     */
    function killKitty(uint256 _kittyID, uint gameId)
    public
    onlyOwnedKitty(_kittyID)
    only2Contracts(CONTRACT_NAME_GAMECREATION, CONTRACT_NAME_GAMEMANAGER_HELPER)
    returns (bool) {
        KittyStatus memory ks = decodeKittieStatus(kittieHellDB.getKittieStatus(_kittyID));
        ks.dead = true;
        ks.deadAt = now;
        kittieHellDB.setKittieStatus(_kittyID, encodeKittieStatus(ks));
        scheduleBecomeGhost(_kittyID, accountingDB.getKittieExpirationTime(gameId));
        emit KittyDied(_kittyID);
        return true;
    }

    //  /**
    //  * @author @ziweidream
    //  * @notice Resurrecting kitty `_kittyID`
    //  * @param _kittyID The kitty to resurrect
    //  * @dev The kitty must not be permanent dead
    //  * @dev This function can only be carried out via proxy
    //  * @dev This function can only proceed after the required number of replacement kitties have become permanent ghosts
    //  * @dev The ressurection payment is in KTY tokens and locked/burned in kittieHELL contract
    //  * @return true/false if the kitty ID is resurrected or not
    //  */
    // function payForResurrection
    // (
    //     uint256 _kittyID,
    //     uint gameId,
    //     address _owner,
    //     uint256[] memory sacrificeKitties
    // )
    //     public
    //     payable
    //     onlyOwnedKitty(_kittyID)
    //     onlyNotGhostKitty(_kittyID)
    //     onlyProxy
    // returns (bool) {
    //     (uint ethersNeeded, uint256 tokenAmount) = accountingDB.getKittieRedemptionFee(gameId);
    //     require(tokenAmount > 0, "KTY cannot be 0");
    //     require(msg.value >= ethersNeeded.sub(10000000000000), "Insufficient ethers");
    //     for (uint i = 0; i < sacrificeKitties.length; i++) {
    //         kittieHellDB.sacrificeKittieToHell(_kittyID, _owner, sacrificeKitties[i]);
    //     }
    //     uint256 requiredNumberOfSacrificeKitties = gameVarAndFee.getRequiredKittieSacrificeNum();
    //     uint256 numberOfSacrificeKitties = kittieHellDB.getNumberOfSacrificeKitties(_kittyID);
    //     require(requiredNumberOfSacrificeKitties == numberOfSacrificeKitties, "Insufficient sacrificing kitties");
    //     //kittieFightToken.transferFrom(kitties[_kittyID].owner, address(this), tokenAmount);
    //     // exchange KTY on uniswap
    //     IUniswapV2Router01(proxy.getContract(CONTRACT_NAME_UNISWAPV2_ROUTER)).swapExactETHForTokens.value(msg.value)(
    //         0,
    //         path,
    //         address(this),
    //         2**255
    //     );

    //     // record kittie redemption fee in total spent in game
    //     accountingDB.setTotalSpentInGame(gameId, msg.value, tokenAmount);

    //     kittieHellDB.lockKTYsInKittieHell(_kittyID, tokenAmount);
    //     releaseKitty(_kittyID);
    //     resurrectKitty(_kittyID);
    //     return true;
    // }

    function _resurrectKitty(uint256 _kittyID) internal {
        KittyStatus memory ks = decodeKittieStatus(kittieHellDB.getKittieStatus(_kittyID));
        ks.dead = false;
        kittieHellDB.setKittieStatus(_kittyID, encodeKittieStatus(ks));
        emit KittyResurrected(_kittyID);
    }

    function resurrectKitty(uint256 _kittyID) public onlyContract(CONTRACT_NAME_REDEEM_KITTIE) {
        _resurrectKitty(_kittyID);
    }

    /**
     * @author @ugwu @ziweidream
     * @notice transfer the ownership of a kittie back to its previous owner
     * @dev The kitty must be owned by the game
     * @dev This function can only be carried out via proxy
     * @param _kittyID The kittie to release
     * @return true if the release was successful
     */
    function _releaseKitty(uint256 _kittyID)
        internal
        onlyOwnedKitty(_kittyID)
    returns (bool) {
        KittyStatus memory ks = decodeKittieStatus(kittieHellDB.getKittieStatus(_kittyID));
        //cryptoKitties.transfer(ks.owner, _kittyID);
        kittieHellDungeon.transfer(ks.owner, _kittyID);
        ks.owner = address(0);
        kittieHellDB.setKittieStatus(_kittyID, encodeKittieStatus(ks));
        if(ks.dead){
            uint256 job = kittieHellDB.getGhostifyJob(_kittyID);
            if(job != 0) {
                cronJob.deleteCronJob(CONTRACT_NAME_KITTIEHELL, job);
            }
        }
        emit KittyReleased(_kittyID);
        return true;
    }

    function releaseKittyGameManager(uint256 _kittyID)
        public
        only3Contracts(CONTRACT_NAME_FORFEITER, CONTRACT_NAME_GAMECREATION, CONTRACT_NAME_GAMEMANAGER_HELPER)
    returns (bool) {
        _releaseKitty(_kittyID);
    }

    function releaseKitty(uint256 _kittyID) public onlyContract(CONTRACT_NAME_REDEEM_KITTIE) returns (bool) {
        _releaseKitty(_kittyID);
    }

    function adminRelease(uint256 _kittyID)
        public
        onlyProxy
        onlySuperAdmin
    {
        releaseKitty(_kittyID);
    }

    function scheduleBecomeGhost(uint256 _kittyID, uint256 _delay)
        internal
        returns(bool)
    {
        uint256 scheduledJob = cronJob.addCronJob(
            CONTRACT_NAME_KITTIEHELL,
            now.add(_delay),
            abi.encodeWithSignature("becomeGhost(uint256)", _kittyID));
        kittieHellDB.setGhostifyJob(_kittyID, scheduledJob);
        emit Scheduled(scheduledJob, now.add(_delay), _kittyID);
        return true;
    }

    /**
     * @author @ziweidream
     * @dev The kitty must be owned by the game
     * @dev This function can only be carried out via CronJob
     * @dev This function will make a kitty permanently dead
     * @param _kittyID The kittie to become ghost
     * @return true if the kittie became a ghost and transferred to KittieHellDB
     */
    function becomeGhost(uint256 _kittyID)
        public
        onlyOwnedKitty(_kittyID)
        onlyContract(CONTRACT_NAME_CRONJOB)
        returns (bool)
    {
        //unnecessary to check kittie expiration time since this is ensured by cronjob
        //uint kittieExpiry = gameStore.getKittieExpirationTime(_gameId);
	    //require(now.sub(kitties[_kittyID].deadAt) > kittieExpiry);
        KittyStatus memory ks = decodeKittieStatus(kittieHellDB.getKittieStatus(_kittyID));
        ks.ghost = true;
        kittieHellDB.setKittieStatus(_kittyID, encodeKittieStatus(ks));
        //cryptoKitties.transfer(address(kittieHellDB), _kittyID); // Now ghosts are also stored in KittieHell, so that we can revive them later
        kittieHellDB.loserKittieToHell(_kittyID, ks.owner);
        emit KittyPermanentDeath(_kittyID);
        return true;
    }


    /**
     * @dev This function is used for upgrading KittieHell only
     * @dev This function needs to be run before upgrading to new KittieHell
     */
    function transferKTYsLockedInHell(address _newKittieHell)
        external onlySuperAdmin returns (bool)
    {
        uint256 lockedKTYs = kittieFightToken.balanceOf(address(this));
        kittieFightToken.transfer(_newKittieHell, lockedKTYs);
        return true;
    }

    /*
     * Use the owner field as a control indicator to check if
     * the kitty is owned by the game
     */
    modifier onlyOwnedKitty(uint256 _kittyID) {
        KittyStatus memory ks = decodeKittieStatus(kittieHellDB.getKittieStatus(_kittyID));
        require(ks.owner != address(0));
        _;
    }

    /*
     * Use the owner field as a control indicator to check if
     * the kitty is not already owned by the game
     */
    modifier onlyNotOwnedKitty(uint256 _kittyID) {
        KittyStatus memory ks = decodeKittieStatus(kittieHellDB.getKittieStatus(_kittyID));
        require(ks.owner == address(0));
        _;
    }

    /*
     * Use the ghost field as a control indicator to check if
     * the kitty is not permanent killed
     */
    modifier onlyNotGhostKitty(uint256 _kittyID) {
        KittyStatus memory ks = decodeKittieStatus(kittieHellDB.getKittieStatus(_kittyID));
        require(!ks.ghost);
        _;
    }

    /*
     * Use the dead field as a control indicator to check if
     * the kitty is not temporary killed
     */
    modifier onlyNotKilledKitty(uint256 _kittyID) {
        KittyStatus memory ks = decodeKittieStatus(kittieHellDB.getKittieStatus(_kittyID));
        require(!ks.dead);
        _;
    }

    event KittyAcquired(uint256 indexed _kittyID);

    event KittyReleased(uint256 indexed _kittyID);

    event KittyDied(uint256 indexed _kittyID);

    event KittyResurrected(uint256 indexed _kittyID);

    event KittyPermanentDeath(uint256 indexed _kittyID);

    event Scheduled(uint256 scheduledJob, uint256 time, uint256 indexed kittyID);
}

