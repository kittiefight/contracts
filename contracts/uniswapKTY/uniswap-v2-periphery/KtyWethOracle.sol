pragma solidity ^0.5.5;

import '../../modules/proxy/Proxied.sol';

import '../uniswap-v2-core/interfaces/IUniswapV2Factory.sol';
import '../uniswap-v2-core/interfaces/IUniswapV2Pair.sol';
import '../uniswap-lib/FixedPoint.sol';

import './libraries/UniswapV2OracleLibrary.sol';
import './libraries/UniswapV2Library.sol';

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract KtyWethOracle is Proxied {
    using FixedPoint for *;

    uint public constant PERIOD = 24 hours;

    IUniswapV2Pair public ktyWethPair;

    address public token0;
    address public token1;

    uint    public price0CumulativeLast;
    uint    public price1CumulativeLast;
    uint32  public blockTimestampLast;
    FixedPoint.uq112x112 public price0Average;
    FixedPoint.uq112x112 public price1Average;

    function initialize() public onlyOwner {
        ktyWethPair = IUniswapV2Pair(proxy.getContract(CONTRACT_NAME_UNISWAPV2_PAIR));
        token0 = ktyWethPair.token0();
        token1 = ktyWethPair.token1();
    }

    function update() external {
        (
            uint price0Cumulative,
            uint price1Cumulative,
            uint32 blockTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(proxy.getContract(CONTRACT_NAME_UNISWAPV2_PAIR));

        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        // ensure that at least one full period has passed since the last update
        //require(timeElapsed >= PERIOD, 'ExampleOracleSimple: PERIOD_NOT_ELAPSED');

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed));
        price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed));

        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;
    }

    function sortTokens(address _tokenA, address _tokenB)
        public pure returns (address, address)
    {
        return UniswapV2Library.sortTokens(_tokenA, _tokenB);
    }

    function quote(uint _amountA, uint _reserveA, uint _reserveB)
        public pure returns (uint)
    {
        return UniswapV2Library.quote(_amountA, _reserveA, _reserveB);
    }

    function getAmountOut(uint _amountIn, uint _reserveIn, uint _reserveOut)
        public pure returns (uint)
    {
        return UniswapV2Library.getAmountOut(_amountIn, _reserveIn, _reserveOut);
    }

    function getAmountsOut(address _pair, uint _amountIn, address[] memory _path)
        public view returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsOut(_pair, _amountIn, _path);
    }

    function getAmountIn(uint _amountOut, uint _reserveIn, uint _reserveOut)
        public pure returns (uint)
    {
        return UniswapV2Library.getAmountOut(_amountOut, _reserveIn, _reserveOut);
    }

    function pairFor(address _factory, address _tokenA, address _tokenB)
        public pure returns (address pair)
    {
        return UniswapV2Library.pairFor(_factory, _tokenA, _tokenB);
    }

    // note this will always return 0 before update has been called successfully for the first time.
    function consult(address token, uint amountIn) external view returns (uint amountOut) {
        if (token == token0) {
            amountOut = price0Average.mul(amountIn).decode144();
        } else {
            require(token == token1, 'ExampleOracleSimple: INVALID_TOKEN');
            amountOut = price1Average.mul(amountIn).decode144();
        }
    }
}
