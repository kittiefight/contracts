pragma solidity >=0.5.0 <0.6.0;

import "../../libs/SafeMath.sol";
import "../../misc/BasicControls.sol";
import "../../interfaces/ERC721.sol";
import "../../interfaces/ERC223Receiver.sol";

import "../../interfaces/IContractManager.sol";


/**
 * @title This contract is responsible to acquire ownership of participating kitties,
 * keep the mortality status and permanent lock them if needed.
 * @author @panos, @ugwu, @dev-l33
 * @notice This contract is able to lock kitties forever caution is advised
 */
contract KittieHELL is ERC223Receiver, BasicControls {

    using SafeMath for uint256;

    /* Contract manager address */
    address contractManager;

    struct KittyStatus {
        address owner;  // This is the owner before the kitty got transferred to us
        bool dead;      // This is the mortality status of the kitty
        bool playing;   // This is the current game participation status of the kitty
        bool ghost;     // This is set to "destroy" or permanent kill the kitty
        uint deadAt;    // Timestamp when the kitty is dead.
    }

    /* This is all the kitties owned and managed by the game */
    mapping(uint256 => KittyStatus) public kitties;

    uint public constant TOKENS_PER_SEC_FOR_RESURRECTION = 1e8;

    /**
     * @author @panos
     * @notice creating kitty hell contract using `_contractManager` as contract manager address
     * @param _contractManager the contract manager used by the game
     */
    constructor(address _contractManager) public {
        contractManager = _contractManager;
    }

    /**
     * @author @ugwu
     * @notice transfer the ownership of a kittie to this contract
     * @dev The last owner must be stored as a returned reference
     * @param _kittyID the kittie to acquire
     * @return true if the acquisition was successful
     */
    function acquireKitty(uint256 _kittyID, address owner)
    public
    onlyNotOwnedKitty(_kittyID)
    returns (bool) {
        ERC721 ckc = ERC721(IContractManager(contractManager).getContract("CryptoKittiesCore"));
        ckc.transferFrom(owner, address(this), _kittyID);
        require(ckc.ownerOf(_kittyID) == address(this));
        kitties[_kittyID].owner = owner;
        emit KittyAcquired(_kittyID);
        return true;
    }

    /**
     * @author @dev-l33
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
     * @author @dev-l33
     * @notice Killing kitty `_kittyID`
     * @param _kittyID The kitty to kill
     * @return true/false if the kitty ID is killed or not
     */
    function killKitty(uint256 _kittyID)
    public
    onlyOwnedKitty(_kittyID)
    returns (bool) {
        kitties[_kittyID].dead = true;
        kitties[_kittyID].deadAt = now;
        emit KittyDied(_kittyID);
        return true;
    }

    function tokenFallback() //address _from, uint _value, bytes memory _data)
    public view
    {
        require(msg.sender == IContractManager(contractManager).getContract("KittieFIGHTToken"));
    }

    /**
     * @author @dev-l33
     * @notice Resurrecting kitty `_kittyID`
     * @param _kittyID The kitty to resurrect
     * @dev The kitty must not be permanent dead
     * @return true/false if the kitty ID is resurrected or not
     */
    function payForResurrection(uint256 _kittyID)
    public view
    onlyOwnedKitty(_kittyID)
    onlyNotGhostKitty(_kittyID)
    returns (bool) {
        uint256 tokenAmount = block.timestamp.sub(kitties[_kittyID].deadAt).mul(TOKENS_PER_SEC_FOR_RESURRECTION);
        require(tokenAmount > 0);

        //KittieFIGHTToken kittieToken = KittieFIGHTToken(tokenAddress);
        //kittieToken.transferFrom(kitties[_kittyID].owner, this, tokenAmount);
        //releaseKitty(_kittyID);
        //KittyResurrected(_kittyID);
        return true;
    }

    /**
     * @author @ugwu
     * @notice transfer the ownership of a kittie back to its previous owner
     * @dev The kitty must not be dead and not participating in a game
     * @param _kittyID The kittie to release
     * @return true if the release was successful
     */
    function releaseKitty(uint256 _kittyID) internal
    onlyOwnedKitty(_kittyID)
    returns (bool) {
        ERC721 ckc = ERC721(IContractManager(contractManager).getContract("CryptoKittiesCore"));
        ckc.transfer(kitties[_kittyID].owner, _kittyID);
        kitties[_kittyID].owner = address(0);
        return true;
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

    event KittyAcquired(uint256 _kittyID);

    event KittyReleased(uint256 _kittyID);

    event KittyDied(uint256 _kittyID);

    event KittyResurrected(uint256 _kittyID);

    event KittyPermanentDeath(uint256 _kittyID);
}
