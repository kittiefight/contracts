pragma solidity ^0.5.5;

import "../../libs/SafeMath.sol";
import "../../misc/BasicControls.sol";
import "../proxy/Proxied.sol";
import "../../authority/Guard.sol";
import "../../interfaces/ERC721.sol";
import "../../interfaces/ERC20Standard.sol";
import "../../GameVarAndFee.sol";
import "../../CronJob.sol";


/**
 * @title This contract is responsible to acquire ownership of participating kitties,
 * keep the mortality status and permanent lock them if needed.
 * @author @panos, @ugwu, @ziweidream
 * @notice This contract is able to lock kitties forever caution is advised
 */
contract KittieHELL is BasicControls, Proxied, Guard {

    using SafeMath for uint256;

    ERC721 public cryptoKitties;
    ERC20Standard public kittieFightToken;
    GameVarAndFee public gameVarAndFee;
    CronJob public cronJob;

    uint256 public scheduledJob;

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
        cryptoKitties = ERC721(proxy.getContract('CryptoKitties'));
        kittieFightToken = ERC20Standard(proxy.getContract('KittieFightToken'));
        gameVarAndFee = GameVarAndFee(proxy.getContract('GameVarAndFee'));
        cronJob = CronJob(proxy.getContract('CronJob'));
    }

    // onlyContract(CONTRACT_NAME_GAMEMANAGER) is temporarily commented out
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
        //onlyContract(CONTRACT_NAME_GAMEMANAGER)
        returns (bool)
    {
        cryptoKitties.transferFrom(owner, address(this), _kittyID);
        require(cryptoKitties.ownerOf(_kittyID) == address(this));
        kitties[_kittyID].owner = owner;
        emit KittyAcquired(_kittyID);
        return true;
    }

    function updateKittyPlayingStatus(uint256 _kittyID, bool _isPlaying)
        public
       // onlyContract(CONTRACT_NAME_GAMEMANAGER)
        onlyOwnedKitty(_kittyID)
        onlyNotKilledKitty(_kittyID)
    {
        kitties[_kittyID].playing = _isPlaying;
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

    function scheduleKillKitty(uint256 _kittyID, uint256 _delay) 
        public
        returns(bool)
    {
        CronJob cron = CronJob(proxy.getContract(CONTRACT_NAME_CRONJOB));
        scheduledJob = cron.addCronJob("KittieHell", now+_delay, abi.encodeWithSignature("killKitty(uint256)", _kittyID));
        emit Scheduled(scheduledJob, now+_delay, _kittyID);
        return true;
    }

    /**
     * @author @ziweidream
     * @notice Killing kitty `_kittyID`
     * @dev This function can only be carried out via CronJOb
     * @param _kittyID The kitty to kill
     * @return true/false if the kitty ID is killed or not
     */
    function killKitty(uint256 _kittyID)
    public
    onlyOwnedKitty(_kittyID)
    onlyContract(CONTRACT_NAME_CRONJOB)
    returns (bool) {
        kitties[_kittyID].dead = true;
        kitties[_kittyID].deadAt = now;
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
     * @notice Getting kitty `_kittyID` resurrection cost
     * @dev The resurrection cost per sec is a constant determined by GameVarAndFee contract
     * @param _kittyID The kitty for whom the resurrection cost is requested
     * @return the kitty's resurrection cost
     */
    function getResurrectionCost(uint256 _kittyID)
    public
    view
    onlyOwnedKitty(_kittyID)
    onlyNotGhostKitty(_kittyID)
    returns(uint) {
        // kittieRedemptionFee is temporarily hardcoded until GameVarAndFee.sol is further developed to
        // be able to return a valid number instead of 0
        uint256 kittieRedemptionFee = 1e8; //gameVarAndFee.getKittieRedemptionFee();
	    return block.timestamp.sub(kitties[_kittyID].deadAt).mul(kittieRedemptionFee);
	}

     /**
     * @author @ziweidream
     * @notice Resurrecting kitty `_kittyID`
     * @param _kittyID The kitty to resurrect
     * @dev The kitty must not be permanent dead
     * @dev This function can only be carried out via proxy
     * @dev The ressurection payment is in KTY tokens and sent to EndowmentFund contract
     * @return true/false if the kitty ID is resurrected or not
     */

    function payForResurrection(uint256 _kittyID)
        public
        payable
        onlyOwnedKitty(_kittyID)
        onlyNotGhostKitty(_kittyID)
        onlyProxy
    returns (bool) {
        uint256 tokenAmount = getResurrectionCost(_kittyID);
        require(tokenAmount > 0);
        kittieFightToken.transferFrom(kitties[_kittyID].owner, proxy.getContract('EndowmentFund'), tokenAmount);
        releaseKitty(_kittyID);
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
        public // temporarily set as public for truffle testing purpose
        //internal
        onlyOwnedKitty(_kittyID)
    returns (bool) {
        cryptoKitties.transfer(kitties[_kittyID].owner, _kittyID);
        kitties[_kittyID].owner = address(0);
        emit KittyReleased(_kittyID);
        return true;
    }

    function releaseKittyForfeiter(uint256 _kittyID)
        public
        //onlyContract(CONTRACT_NAME_FORFEITER)
    returns (bool) {
        releaseKitty(_kittyID);
    }

    function scheduleBecomeGhost(uint256 _kittyID, uint256 _delay) 
        public
        returns(bool)
    {
        CronJob cron = CronJob(proxy.getContract(CONTRACT_NAME_CRONJOB));
        scheduledJob = cron.addCronJob("KittieHell", now+_delay, abi.encodeWithSignature("becomeGhost(uint256)", _kittyID));
        emit Scheduled(scheduledJob, now+_delay, _kittyID);
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
        uint kittieExpiry = gameVarAndFee.getKittieExpiry();
	    require(now.sub(kitties[_kittyID].deadAt) > kittieExpiry);
        kitties[_kittyID].ghost = true;
        cryptoKitties.transfer(proxy.getContract("KittieHellDB"), _kittyID);
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

