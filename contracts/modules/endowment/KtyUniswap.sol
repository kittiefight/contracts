pragma solidity ^0.5.5;
/**
 * @title KtyUniswap
 * @dev Responsible for : exchange ether for KTY
 * @author @ziweidream
 */
import '../proxy/Proxied.sol';
import '../../authority/Guard.sol';
import '../../libs/SafeMath.sol';
import '../../uniswapKTY/uniswap-v2-core/interfaces/IUniswapV2Pair.sol';
import '../../uniswapKTY/uniswap-V2-periphery/KtyWethOracle.sol';
import '../../uniswapKTY/uniswap-V2-periphery/UniswapV2Router01.sol';

// This contract assumes KTY is token1 in the ktyWethPair contract.
// Corresponding modificaitons will be made if KTY is token0 in the future deployment
// of the ktyWethPair contract on mainnet.

contract KtyUniswap is Proxied, Guard {
    using SafeMath for uint256;

    IUniswapV2Pair public ktyWethPair;
    KtyWethOracle public ktyWethOracle;
    UniswapV2Router01 public router;

    address[] public path;
    address internal escrow;

    //===================== Events ===================
    event Swapped(address indexed msgSender, uint256 ethAmout, uint256 time);

    //===================== Initializer ===================
    function initialize(address payable _router, address _weth, address _escrow) public onlyOwner {
        ktyWethPair = IUniswapV2Pair(proxy.getContract(CONTRACT_NAME_UNISWAPV2_PAIR));
        ktyWethOracle = KtyWethOracle(proxy.getContract(CONTRACT_NAME_KTY_WETH_ORACLE));
        router = UniswapV2Router01(_router);
        path.push(_weth);
        address _KTY = proxy.getContract(CONTRACT_NAME_KITTIEFIGHTOKEN);
        path.push(_KTY);
        escrow = _escrow;
    }

    //===================== Public Functions ===================
    /**
     * @dev swap ethers for KTY. Can only be used by endowmentFund.
     */
    function swapEthForKtyEndowment()
        public onlyContract(CONTRACT_NAME_ENDOWMENT_FUND)
    {
        _swapEthForKty(escrow);
    }

    /**
     * @dev swap ethers for KTY. Can only be used by kittieHELL.
     */
    function swapEthForKtyKittieHELL()
        public onlyContract(CONTRACT_NAME_KITTIEHELL)
    {
        address _kittieHELL = proxy.getContract(CONTRACT_NAME_KITTIEHELL);
        _swapEthForKty(_kittieHELL);
    }

    //===================== Getters ===================
    /**
     * @dev returns the amount of KTY reserves in ktyWethPair contract.
     */
    function getReserveKTY()
        public view
        returns (uint256)
    {
        uint112 _reserveKTY;
        (,_reserveKTY,) = ktyWethPair.getReserves();
        return uint256(_reserveKTY);
    }

    /**
     * @dev returns the amount of ether(wrapped) reserves in ktyWethPair contract.
     */
    function getReserveETH()
        public view
        returns (uint256)
    {
        uint112 _reserveETH;
        (_reserveETH,,) = ktyWethPair.getReserves();
        return uint256(_reserveETH);
    }

    /**
     * @dev returns the amount of ethers needed to swap for some amount of KTY
     * @param _ktyAmount the amount of KTY to be swapped for
     */
    function etherFor(uint256 _ktyAmount) public view returns (uint256) {
        uint256 _reserveKTY = getReserveKTY();
        uint256 _reserveETH = getReserveETH();
        uint256 ether_needed = ktyWethOracle.quote(_ktyAmount, _reserveKTY, _reserveETH);
        return ether_needed;
    }

    /**
     * @dev returns the KTY to ether ratio on uniswap
     */
    function KTY_ETH_ratio() public view returns (uint256) {
        uint256 _amountKTY = 1e18;  // 1 KTY
        uint256 _reserveKTY = getReserveKTY();
        uint256 _reserveETH = getReserveETH();
        return ktyWethOracle.quote(_amountKTY, _reserveKTY, _reserveETH);
    }

    /**
     * @dev returns the ether to KTY ratio on uniswap
     */
    function ETH_KTY_ratio() public view returns (uint256) {
        uint256 _amountETH = 1e18; // 1 ether
        uint256 _reserveKTY = getReserveKTY();
        uint256 _reserveETH = getReserveETH();
        return ktyWethOracle.quote(_amountETH, _reserveETH, _reserveKTY);
    }

    //===================== Internal Functions ===================
    /**
     * @dev swaps ether for KTY
     * @param _to the address to which swapped KTY is sent
     */
    function _swapEthForKty(address _to) internal returns (bool) {
        address msgSender = getOriginalSender();
        router.swapExactETHForTokens(0, path, _to, 2**200);
        emit Swapped(msgSender, msg.value, now);
        return true;
    }
 }