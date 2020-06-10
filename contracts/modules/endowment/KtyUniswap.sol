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
import '../../uniswapKTY/uniswap-v2-core/interfaces/IDaiWethPair.sol';
import '../../uniswapKTY/uniswap-V2-periphery/KtyWethOracle.sol';
import '../../uniswapKTY/uniswap-V2-periphery/DaiWethOracle.sol';

contract KtyUniswap is Proxied, Guard {
    using SafeMath for uint256;

    IUniswapV2Pair public ktyWethPair;
    KtyWethOracle public ktyWethOracle;

    IDaiWethPair public daiWethPair;
    DaiWethOracle public daiWethOracle;

    //===================== Initializer ===================
    function initialize() public onlyOwner {
        ktyWethPair = IUniswapV2Pair(proxy.getContract(CONTRACT_NAME_UNISWAPV2_PAIR));
        ktyWethOracle = KtyWethOracle(proxy.getContract(CONTRACT_NAME_KTY_WETH_ORACLE));

        daiWethPair = IDaiWethPair(proxy.getContract(CONTRACT_NAME_DAI_WETH_PAIR));
        daiWethOracle = DaiWethOracle(proxy.getContract(CONTRACT_NAME_DAI_WETH_ORACLE));
    }

    //===================== Getters ===================
    function isKtyToken0()
        public view returns (bool)
    {
        address token0;
        address token1;

        address kittieFightToken = proxy.getContract(CONTRACT_NAME_KITTIEFIGHTOKEN);
        address weth = proxy.getContract(CONTRACT_NAME_WETH);

        (token0, token1) = ktyWethOracle.sortTokens(kittieFightToken, weth);

        if (token0 == kittieFightToken) {
            return true;
        } else if (token0 == weth) {
            return false;
        }
    }

    function isDaiToken0()
        public view returns (bool)
    {
        address token0;
        address token1;

        address dai = proxy.getContract(CONTRACT_NAME_DAI);
        address weth = proxy.getContract(CONTRACT_NAME_WETH);

        (token0, token1) = daiWethOracle.sortTokens(dai, weth);

        if (token0 == dai) {
            return true;
        } else if (token0 == weth) {
            return false;
        }
    }

    /**
     * @dev returns the amount of KTY reserves in ktyWethPair contract.
     */
    function getReserveKTY()
        public view
        returns (uint256)
    {
        uint112 _reserveKTY;
        if (isKtyToken0()) {
            (_reserveKTY,,) = ktyWethPair.getReserves();
        } else {
            (,_reserveKTY,) = ktyWethPair.getReserves();
        }

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
        if (isKtyToken0()) {
            (,_reserveETH,) = ktyWethPair.getReserves();
        } else {
            (_reserveETH,,) = ktyWethPair.getReserves();
        }

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
     * @dev returns the amount of ktys swapped for the ethers of _ethAmount
     */
    function ktyFor(uint256 _ethAmount) public view returns (uint256) {
        uint256 _reserveKTY = getReserveKTY();
        uint256 _reserveETH = getReserveETH();
        uint256 kty_for = ktyWethOracle.quote(_ethAmount, _reserveETH, _reserveKTY);
        return kty_for;
    }

    /**
     * @dev returns the KTY to ether ratio on uniswap, that is, how many ether for 1 KTY
     */
    function KTY_ETH_ratio() public view returns (uint256) {
        uint256 _amountKTY = 1e18;  // 1 KTY
        uint256 _reserveKTY = getReserveKTY();
        uint256 _reserveETH = getReserveETH();
        return ktyWethOracle.quote(_amountKTY, _reserveKTY, _reserveETH);
    }

    /**
     * @dev returns the ether to KTY ratio on uniswap, that is, how many KTY for 1 ether
     */
    function ETH_KTY_ratio() public view returns (uint256) {
        uint256 _amountETH = 1e18; // 1 ether
        uint256 _reserveKTY = getReserveKTY();
        uint256 _reserveETH = getReserveETH();
        return ktyWethOracle.quote(_amountETH, _reserveETH, _reserveKTY);
    }

    /**
     * @dev returns the amount of KTY reserves in ktyWethPair contract.
     */
    function getReserveDAI()
        public view
        returns (uint256)
    {
        uint112 _reserveDAI;
        if (isDaiToken0()) {
            (_reserveDAI,,) = daiWethPair.getReserves();
        } else {
            (,_reserveDAI,) = daiWethPair.getReserves();
        }

        return uint256(_reserveDAI);
    }

    /**
     * @dev returns the amount of ether(wrapped) reserves in daiWethPair contract.
     */
    function getReserveETHfromDAI()
        public view
        returns (uint256)
    {
        uint112 _reserveETHfromDAI;
        if (isDaiToken0()) {
            (,_reserveETHfromDAI,) = daiWethPair.getReserves();
        } else {
            (_reserveETHfromDAI,,) = daiWethPair.getReserves();
        }

        return uint256(_reserveETHfromDAI);
    }

    /**
     * @dev returns the DAI to ether ratio on uniswap, that is, how many ether for 1 DAI
     */
    function DAI_ETH_ratio() public view returns (uint256) {
        uint256 _amountDAI = 1e18;  // 1 DAI
        uint256 _reserveDAI = getReserveDAI();
        uint256 _reserveETHfromDAI = getReserveETHfromDAI();
        return daiWethOracle.quote(_amountDAI, _reserveDAI, _reserveETHfromDAI);
    }

    /**
     * @dev returns the ether to DAI ratio on uniswap, that is, how many DAI for 1 ether
     */
    function ETH_DAI_ratio() public view returns (uint256) {
        uint256 _amountETH = 1e18; // 1 ether
        uint256 _reserveDAI = getReserveDAI();
        uint256 _reserveETHfromDAI = getReserveETHfromDAI();
        return daiWethOracle.quote(_amountETH, _reserveETHfromDAI, _reserveDAI);
    }

    /**
     * @dev returns the KTY to DAI ratio on uniswap, that is, how many DAI for 1 KTY
     */
    function KTY_DAI_ratio() public view returns (uint256) {
        // get the amount of ethers for 1 KTY
        uint256 etherPerKTY = KTY_ETH_ratio();
        // get the amount of DAI for 1 ether
        uint256 daiPerEther = ETH_DAI_ratio();
        // get the amount of DAI for 1 KTY
        uint256 daiPerKTY = etherPerKTY.mul(daiPerEther).div(1000000000000000000);
        return daiPerKTY;
    }

    /**
     * @dev returns the DAI to KTY ratio on uniswap, that is, how many KTY for 1 DAI
     */
    function DAI_KTY_ratio() public view returns (uint256) {
        // get the amount of ethers for 1 DAI
        uint256 etherPerDAI = DAI_ETH_ratio();
        // get the amount of KTY for 1 ether
        uint256 ktyPerEther = ETH_KTY_ratio();
        // get the amount of KTY for 1 DAI
        uint256 ktyPerDAI = etherPerDAI.mul(ktyPerEther).div(1000000000000000000);
        return ktyPerDAI;
    }
 }