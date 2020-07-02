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
import "../databases/GMGetterDB.sol";
import "../databases/KittieHellDB.sol";
import "../endowment/EndowmentFund.sol";
import "../../uniswapKTY/uniswap-v2-periphery/interfaces/IUniswapV2Router01.sol";
import "../endowment/KtyUniswap.sol";

/**
 * @title This contract is responsible to acquire ownership of participating kitties,
 * keep the mortality status and permanent lock them if needed.
 * @author @panos, @ugwu, @ziweidream @Xalee @wafflemakr
 * @notice This contract is able to lock kitties forever caution is advised
 */
contract KittieHell is BasicControls, Proxied, Guard {

    using SafeMath for uint256;

    CronJob public cronJob;
    ERC721 public cryptoKitties;
    ERC20Standard public kittieFightToken;
    GameVarAndFee public gameVarAndFee;
    GameStore public gameStore;
    GMGetterDB public gmGetterDB;
    EndowmentFund public endowmentFund;
    address[] public path;

    uint256 public scheduledJob;
    mapping (uint => uint) public scheduledJobs;

    struct KittyStatus {
        address owner;  // This is the owner before the kitty got transferred to us
        bool dead;      // This is the mortality status of the kitty
        bool playing;   // This is the current game participation status of the kitty
        bool ghost;     // This is set to "destroy" or permanent kill the kitty
        uint deadAt;    // Timestamp when the kitty is dead.
    }

    /* This is all the kitties owned and managed by the game */
    mapping(uint256 => KittyStatus) public kitties;

    function initialize() external onlyOwner {
        cronJob = CronJob(proxy.getContract(CONTRACT_NAME_CRONJOB));
        cryptoKitties = ERC721(proxy.getContract(CONTRACT_NAME_CRYPTOKITTIES));
        kittieFightToken = ERC20Standard(proxy.getContract(CONTRACT_NAME_KITTIEFIGHTOKEN));
        gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        gameStore = GameStore(proxy.getContract(CONTRACT_NAME_GAMESTORE));
        gmGetterDB = GMGetterDB(proxy.getContract(CONTRACT_NAME_GM_GETTER_DB));
        endowmentFund = EndowmentFund(proxy.getContract(CONTRACT_NAME_ENDOWMENT_FUND));

        address _WETH = proxy.getContract(CONTRACT_NAME_WETH);
        path.push(_WETH);
        address _KTY = proxy.getContract(CONTRACT_NAME_KITTIEFIGHTOKEN);
        path.push(_KTY);
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
        only2Contracts(CONTRACT_NAME_SCHEDULER, CONTRACT_NAME_GAMECREATION)
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
        cryptoKitties.transferFrom(owner, address(this), _kittyID);
        require(cryptoKitties.ownerOf(_kittyID) == address(this));
        kitties[_kittyID].owner = owner;
        emit KittyAcquired(_kittyID);
        return true;
    }

    /**
     * @author @ziweidream
     * @notice Getting kitty `_kittyID` mortality status
     * @param _kittyID The kitty to get status
     * @return true/false if the kitty ID is dead or not
     */
    function isKittyDead(uint256 _kittyID)
    public
    view
    onlyOwnedKitty(_kittyID)
    returns (bool) {
        return kitties[_kittyID].dead;
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
    onlyContract(CONTRACT_NAME_GAMECREATION)
    returns (bool) {
        kitties[_kittyID].dead = true;
        kitties[_kittyID].deadAt = now;
        scheduleBecomeGhost(_kittyID, gameStore.getKittieExpirationTime(gameId));
        emit KittyDied(_kittyID);
        return true;
    }

    /**
     * @author @ziweidream
     * @notice Getting kitty `_kittyID` death time
     * @param _kittyID The kitty whose death time is requested
     * @return the kitty's death time
     */
    function kittyDeathTime(uint256 _kittyID) public view returns(uint) {
        return kitties[_kittyID].deadAt;
    }

     /**
     * @author @ziweidream
     * @notice Resurrecting kitty `_kittyID`
     * @param _kittyID The kitty to resurrect
     * @dev The kitty must not be permanent dead
     * @dev This function can only be carried out via proxy
     * @dev This function can only proceed after the required number of replacement kitties have become permanent ghosts
     * @dev The ressurection payment is in KTY tokens and locked/burned in kittieHELL contract
     * @return true/false if the kitty ID is resurrected or not
     */

    function payForResurrection
    (
        uint256 _kittyID,
        uint gameId,
        address _owner,
        uint256[] memory sacrificeKitties
    )
        public
        payable
        onlyOwnedKitty(_kittyID)
        onlyNotGhostKitty(_kittyID)
        onlyProxy
    returns (bool) {
        (uint ethersNeeded, uint256 tokenAmount) = gameStore.getKittieRedemptionFee(gameId);
        require(tokenAmount > 0, "KTY amount must be greater than 0");
        require(msg.value >= ethersNeeded.sub(10000000000000), "Insufficient ethers to pay for resurrection");
        for (uint i = 0; i < sacrificeKitties.length; i++) {
            KittieHellDB(proxy.getContract(CONTRACT_NAME_KITTIEHELL_DB)).sacrificeKittieToHell(_kittyID, _owner, sacrificeKitties[i]);
        }
        uint256 requiredNumberOfSacrificeKitties = gameVarAndFee.getRequiredKittieSacrificeNum();
        uint256 numberOfSacrificeKitties = KittieHellDB(proxy.getContract(CONTRACT_NAME_KITTIEHELL_DB)).getNumberOfSacrificeKitties(_kittyID);
        require(requiredNumberOfSacrificeKitties == numberOfSacrificeKitties, "Please meet the required number of sacrificing kitties.");
        //kittieFightToken.transferFrom(kitties[_kittyID].owner, address(this), tokenAmount);
        // exchange KTY on uniswap
        IUniswapV2Router01(proxy.getContract(CONTRACT_NAME_UNISWAPV2_ROUTER)).swapExactETHForTokens.value(msg.value)(
            0,
            path,
            address(this),
            2**255
        );

        KittieHellDB(proxy.getContract(CONTRACT_NAME_KITTIEHELL_DB)).lockKTYsInKittieHell(_kittyID, tokenAmount);
        releaseKitty(_kittyID);
        kitties[_kittyID].dead = false;
        emit KittyResurrected(_kittyID);
        return true;
    }

    /**
     * @author @ugwu @ziweidream
     * @notice transfer the ownership of a kittie back to its previous owner
     * @dev The kitty must be owned by the game
     * @dev This function can only be carried out via proxy
     * @param _kittyID The kittie to release
     * @return true if the release was successful
     */
    function releaseKitty(uint256 _kittyID)
        internal
        onlyOwnedKitty(_kittyID)
    returns (bool) {
        cryptoKitties.transfer(kitties[_kittyID].owner, _kittyID);
        kitties[_kittyID].owner = address(0);
        if(kitties[_kittyID].dead){
            CronJob cron = CronJob(proxy.getContract(CONTRACT_NAME_CRONJOB));
            cron.deleteCronJob(CONTRACT_NAME_KITTIEHELL, scheduledJobs[_kittyID]);
        }
        emit KittyReleased(_kittyID);
        return true;
    }

    function releaseKittyGameManager(uint256 _kittyID)
        public
        only2Contracts(CONTRACT_NAME_FORFEITER, CONTRACT_NAME_GAMECREATION)
    returns (bool) {
        releaseKitty(_kittyID);
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
        CronJob cron = CronJob(proxy.getContract(CONTRACT_NAME_CRONJOB));
        scheduledJob = cron.addCronJob(
            CONTRACT_NAME_KITTIEHELL,
            now.add(_delay),
            abi.encodeWithSignature("becomeGhost(uint256)", _kittyID));
        scheduledJobs[_kittyID] = scheduledJob;
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
        kitties[_kittyID].ghost = true;
        cryptoKitties.transfer(proxy.getContract(CONTRACT_NAME_KITTIEHELL_DB), _kittyID);
        KittieHellDB(proxy.getContract(CONTRACT_NAME_KITTIEHELL_DB)).loserKittieToHell(_kittyID, kitties[_kittyID].owner);
        emit KittyPermanentDeath(_kittyID);
        return true;
    }

    /**
     * @author @ziweidream
     * @param _kittyID The kittie to release
     * @return the previous kitty owner, the kitty dead status, the kitty playing status, the kitty ghost status, and the kitty death time   
     */
    function getKittyStatus(uint256 _kittyID) public view returns (address _owner, bool _dead, bool _playing, bool _ghost, uint _deadAt) {
        _owner = kitties[_kittyID].owner;
        _dead = kitties[_kittyID].dead;
        _playing = kitties[_kittyID].playing;
        _ghost = kitties[_kittyID].ghost;
        _deadAt = kitties[_kittyID].deadAt;
    }

    /*
     * Use the owner field as a control indicator to check if
     * the kitty is owned by the game
     */
    modifier onlyOwnedKitty(uint256 _kittyID) {
        require(kitties[_kittyID].owner != address(0));
        _;
    }

    /*
     * Use the owner field as a control indicator to check if
     * the kitty is not already owned by the game
     */
    modifier onlyNotOwnedKitty(uint256 _kittyID) {
        require(kitties[_kittyID].owner == address(0));
        _;
    }

    /*
     * Use the ghost field as a control indicator to check if
     * the kitty is not permanent killed
     */
    modifier onlyNotGhostKitty(uint256 _kittyID) {
        require(!kitties[_kittyID].ghost);
        _;
    }

    /*
     * Use the dead field as a control indicator to check if
     * the kitty is not temporary killed
     */
    modifier onlyNotKilledKitty(uint256 _kittyID) {
        require(!kitties[_kittyID].dead);
        _;
    }

    event KittyAcquired(uint256 indexed _kittyID);

    event KittyReleased(uint256 indexed _kittyID);

    event KittyDied(uint256 indexed _kittyID);

    event KittyResurrected(uint256 indexed _kittyID);

    event KittyPermanentDeath(uint256 indexed _kittyID);

    event Scheduled(uint256 scheduledJob, uint256 time, uint256 indexed kittyID);
}

