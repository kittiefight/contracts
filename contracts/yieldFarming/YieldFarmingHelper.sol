pragma solidity ^0.5.5;

import "../authority/Owned.sol";
import '../libs/SafeMath.sol';
import '../uniswapKTY/uniswap-v2-core/interfaces/IUniswapV2Pair.sol';
import '../uniswapKTY/uniswap-v2-periphery/libraries/UniswapV2Library.sol';
import './YieldFarming.sol';
import "../interfaces/ERC20Standard.sol";

contract YieldFarmingHelper is Owned {
    using SafeMath for uint256;

    YieldFarming public yieldFarming;

    address public ktyWethPair;
    IUniswapV2Pair public daiWethPair;

    address public kittieFightTokenAddr;
    address public wethAddr;
    address public daiAddr;

    uint256 base18 = 1000000000000000000;
    uint256 base6 = 1000000;

    function initialize
    (
        YieldFarming _yieldFarming,
        address _ktyWethPair,
        IUniswapV2Pair _daiWethPair,
        address _kittieFightToken,
        address _weth,
        address _dai
    ) 
        public onlyOwner
    {
        setYieldFarming(_yieldFarming);
        setKtyWethPair(_ktyWethPair);
        setDaiWethPair(_daiWethPair);
        setTokenAddress(_kittieFightToken, _weth, _dai);
    }

    /**
     * @dev Set Uniswap KTY-Weth Pair contract
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setYieldFarming(YieldFarming _yieldFarming) public onlyOwner {
        yieldFarming = _yieldFarming;
    }

    /**
     * @dev Set Uniswap KTY-Weth Pair contract
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setKtyWethPair(address _ktyWethPair) public onlyOwner {
        ktyWethPair = _ktyWethPair;
    }

    /**
     * @dev Set Uniswap Dai-Weth Pair contract
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setDaiWethPair(IUniswapV2Pair _daiWethPair) public onlyOwner {
        daiWethPair = _daiWethPair;
    }

    /**
     * @dev Set tokens address
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setTokenAddress(address _kittieFightToken, address _weth, address _dai) public onlyOwner {
        kittieFightTokenAddr = _kittieFightToken;
        wethAddr = _weth;
        daiAddr = _dai;
    }

    //===================== Getters ===================
    // Getters YieldFarming
    function getLPinfo(uint256 _pairCode)
        public view returns (uint256 reserveKTY, uint256 totalSupplyLP) 
    {
        (,address pairPoolAddress, address _tokenAddr) = yieldFarming.getPairPool(_pairCode);
        reserveKTY = getReserveKTY(_tokenAddr, pairPoolAddress);
        totalSupplyLP = IUniswapV2Pair(pairPoolAddress).totalSupply();
    }

    /**
     * @return uint256 the total amount of Uniswap Liquidity tokens locked in this contract
     */
    function getTotalLiquidityTokenLocked() external view returns (uint256) {
        return yieldFarming.totalLockedLP();
    }

    function totalLockedLPinDAI() external view returns (uint256) {
        uint256 _totalLockedLPinDAI = 0;
        uint256 _LPinDai;
        uint256 totalNumberOfPairPools = yieldFarming.totalNumberOfPairPools();
        for (uint256 i = 0; i < totalNumberOfPairPools; i++) {
            _LPinDai = getTotalLiquidityTokenLockedInDAI(i);
            _totalLockedLPinDAI = _totalLockedLPinDAI.add(_LPinDai);
        }

        return _totalLockedLPinDAI;
    }

    /**
     * @return uint256 DAI value representation of ETH in uniswap KTY - ETH pool, according to 
     *         all Liquidity tokens locked in this contract.
     */
    function getTotalLiquidityTokenLockedInDAI(uint256 _pairCode) public view returns (uint256) {
        (,address pairPoolAddress,) = yieldFarming.getPairPool(_pairCode);
        uint256 balance = IUniswapV2Pair(pairPoolAddress).balanceOf(address(this));
        uint256 totalSupply = IUniswapV2Pair(pairPoolAddress).totalSupply();
        uint256 percentLPinYieldFarm = balance.mul(base6).div(totalSupply);
        
        uint256 totalKtyInPairPool = ERC20Standard(kittieFightTokenAddr).balanceOf(pairPoolAddress);

        return totalKtyInPairPool.mul(percentLPinYieldFarm).mul(KTY_DAI_price()).div(base18).div(base6);
    }

    // Getters Uniswap


    function isKtyToken0(address _tokenAddr)
        public view returns (bool)
    {
        address token0;
        address token1;

        (token0, token1) = UniswapV2Library.sortTokens(kittieFightTokenAddr, _tokenAddr);

        if (token0 == kittieFightTokenAddr) {
            return true;
        } 

        return false;
    }

    function isDaiToken0()
        public view returns (bool)
    {
        address token0;
        address token1;

        (token0, token1) = UniswapV2Library.sortTokens(daiAddr, wethAddr);

        if (token0 == daiAddr) {
            return true;
        } 
        
        return false;
    }

    /**
     * @dev returns the amount of KTY reserves in ktyWethPair contract.
     */
    function getReserveKTY(address _otherTokenAddr, address _pairPoolAddr)
        public view
        returns (uint256)
    {
        uint112 _reserveKTY;
        if (isKtyToken0(_otherTokenAddr)) {
            (_reserveKTY,,) = IUniswapV2Pair(_pairPoolAddr).getReserves();
        } else {
            (,_reserveKTY,) = IUniswapV2Pair(_pairPoolAddr).getReserves();
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
        if (isKtyToken0(wethAddr)) {
            (,_reserveETH,) = IUniswapV2Pair(ktyWethPair).getReserves();
        } else {
            (_reserveETH,,) = IUniswapV2Pair(ktyWethPair).getReserves();
        }

        return uint256(_reserveETH);
    }

    /**
     * @dev returns the KTY to ether price on uniswap, that is, how many ether for 1 KTY
     */
    function KTY_ETH_price() public view returns (uint256) {
        uint256 _amountKTY = 1e18;  // 1 KTY
        uint256 _reserveKTY = getReserveKTY(wethAddr, ktyWethPair);
        uint256 _reserveETH = getReserveETH();
        return UniswapV2Library.getAmountIn(_amountKTY, _reserveETH, _reserveKTY);
    } 

    /**
     * @dev returns the ether KTY price on uniswap, that is, how many KTYs for 1 ether
     */
    function ETH_KTY_price() public view returns (uint256) {
        uint256 _amountETH = 1e18;  // 1 KTY
        uint256 _reserveKTY = getReserveKTY(wethAddr, ktyWethPair);
        uint256 _reserveETH = getReserveETH();
        return UniswapV2Library.getAmountIn(_amountETH, _reserveKTY, _reserveETH);
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
     * @dev returns the DAI to ether price on uniswap, that is, how many ether for 1 DAI
     */
    function DAI_ETH_price() public view returns (uint256) {
        uint256 _amountDAI = 1e18;  // 1 KTY
        uint256 _reserveDAI = getReserveDAI();
        uint256 _reserveETHfromDAI = getReserveETHfromDAI();
        return UniswapV2Library.getAmountIn(_amountDAI, _reserveETHfromDAI, _reserveDAI);
    }

    /**
     * @dev returns the ether to DAI price on uniswap, that is, how many DAI for 1 ether
     */
    function ETH_DAI_price() public view returns (uint256) {
        uint256 _amountETH = 1e18;  // 1 KTY
        uint256 _reserveDAI = getReserveDAI();
        uint256 _reserveETHfromDAI = getReserveETHfromDAI();
        return UniswapV2Library.getAmountIn(_amountETH, _reserveDAI, _reserveETHfromDAI);
    }

    /**
     * @dev returns the KTY to DAI price derived from uniswap price in pair contracts, that is, how many DAI for 1 KTY
     */
    function KTY_DAI_price() public view returns (uint256) {
        // get the amount of ethers for 1 KTY
        uint256 etherPerKTY = KTY_ETH_price();
        // get the amount of DAI for 1 ether
        uint256 daiPerEther = ETH_DAI_price();
        // get the amount of DAI for 1 KTY
        uint256 daiPerKTY = etherPerKTY.mul(daiPerEther).div(1000000000000000000);
        return daiPerKTY;
    }

    /**
     * @dev returns the DAI to KTY price derived from uniswap price in pair contracts, that is, how many KTY for 1 DAI
     */
    function DAI_KTY_price() public view returns (uint256) {
        // get the amount of ethers for 1 DAI
        uint256 etherPerDAI = DAI_ETH_price();
        // get the amount of KTY for 1 ether
        uint256 ktyPerEther = ETH_KTY_price();
        // get the amount of KTY for 1 DAI
        uint256 ktyPerDAI = etherPerDAI.mul(ktyPerEther).div(1000000000000000000);
        return ktyPerDAI;
    }
   
}