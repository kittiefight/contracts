pragma solidity ^0.5.5;

import "../../libs/SafeMath.sol";
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
import "./KittieHell.sol";

/**
 * @title This contract is responsible to acquire ownership of participating kitties,
 * keep the mortality status and permanent lock them if needed.
 * @author @panos, @ugwu, @ziweidream @Xalee @wafflemakr
 * @notice This contract is able to lock kitties forever caution is advised
 */
contract RedeemKittie is Proxied, Guard, KittieHellStruct {

    using SafeMath for uint256;

    CronJob public cronJob;
    ERC721 public cryptoKitties;
    ERC20Standard public kittieFightToken;
    GameVarAndFee public gameVarAndFee;
    GameStore public gameStore;
    GMGetterDB public gmGetterDB;
    GMSetterDB public gmSetterDB;
    KittieHellDB public kittieHellDB;
    KittieHell public kittieHell;
    EndowmentFund public endowmentFund;
    KittieHellDungeon public kittieHellDungeon;
    AccountingDB public accountingDB;
    GameManagerHelper public gameManagerHelper;

    address[] public path;

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
        kittieHell = KittieHell(proxy.getContract(CONTRACT_NAME_KITTIEHELL));
        endowmentFund = EndowmentFund(proxy.getContract(CONTRACT_NAME_ENDOWMENT_FUND));
        kittieHellDungeon = KittieHellDungeon(proxy.getContract(CONTRACT_NAME_KITTIEHELL_DUNGEON));
        accountingDB = AccountingDB(proxy.getContract(CONTRACT_NAME_ACCOUNTING_DB));
        gameManagerHelper = GameManagerHelper(proxy.getContract(CONTRACT_NAME_GAMEMANAGER_HELPER));

        delete path; //Required to allow calling initialize() several times
        address _WETH = proxy.getContract(CONTRACT_NAME_WETH);
        path.push(_WETH);
        address _KTY = proxy.getContract(CONTRACT_NAME_KITTIEFIGHTOKEN);
        path.push(_KTY);
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
        (uint ethersNeeded, uint256 tokenAmount) = accountingDB.getKittieRedemptionFee(gameId);
        require(tokenAmount > 0, "KTY cannot be 0");
        require(msg.value >= ethersNeeded.sub(10000000000000), "Insufficient ethers");
        for (uint i = 0; i < sacrificeKitties.length; i++) {
            kittieHellDB.sacrificeKittieToHell(_kittyID, _owner, sacrificeKitties[i]);
        }
        uint256 requiredNumberOfSacrificeKitties = gameVarAndFee.getRequiredKittieSacrificeNum();
        uint256 numberOfSacrificeKitties = kittieHellDB.getNumberOfSacrificeKitties(_kittyID);
        require(requiredNumberOfSacrificeKitties == numberOfSacrificeKitties, "Insufficient sacrificing kitties");
        //kittieFightToken.transferFrom(kitties[_kittyID].owner, address(this), tokenAmount);
        // exchange KTY on uniswap
        IUniswapV2Router01(proxy.getContract(CONTRACT_NAME_UNISWAPV2_ROUTER)).swapExactETHForTokens.value(msg.value)(
            0,
            path,
            address(this),
            2**255
        );

        // record kittie redemption fee in total spent in game
        accountingDB.setTotalSpentInGame(gameId, msg.value, tokenAmount);

        kittieHellDB.lockKTYsInKittieHell(_kittyID, tokenAmount);
        kittieHell.releaseKitty(_kittyID);
        kittieHell.resurrectKitty(_kittyID);
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
     * Use the ghost field as a control indicator to check if
     * the kitty is not permanent killed
     */
    modifier onlyNotGhostKitty(uint256 _kittyID) {
        KittyStatus memory ks = decodeKittieStatus(kittieHellDB.getKittieStatus(_kittyID));
        require(!ks.ghost);
        _;
    }
}

