pragma solidity ^0.5.5;

import "../authority/Owned.sol";
import '../libs/SafeMath.sol';
import './YieldFarming.sol';
import './YieldFarmingHelper.sol';

contract YieldsCalculator is Owned {
    using SafeMath for uint256;

    YieldFarming public yieldFarming;
    YieldFarmingHelper public yieldFarmingHelper;

   

    uint256 constant public base18 = 1000000000000000000;
    uint256 constant public base6 = 1000000;

    uint256 constant public MONTH = 30 * 24 * 60 * 60; // MONTH duration is 30 days, to keep things standard
    uint256 constant public DAY = 24 * 60 * 60;

    // proportionate a month into 30 parts, each part is 0.033333 * 1000000 = 33333
    uint256 constant public DAILY_PORTION_IN_MONTH = 33333;

    function initialize
    (
        YieldFarming _yieldFarming,
        YieldFarmingHelper _yieldFarmingHelper
    ) 
        public onlyOwner
    {
        setYieldFarming(_yieldFarming);
        setYieldFarmingHelper(_yieldFarmingHelper);
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
    function setYieldFarmingHelper(YieldFarmingHelper _yieldFarmingHelper) public onlyOwner {
        yieldFarmingHelper = _yieldFarmingHelper;
    }

    
}