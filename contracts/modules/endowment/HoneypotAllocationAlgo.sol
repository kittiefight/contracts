/**
 * @title HoneypotAllocationAlgo
 */
pragma solidity ^0.5.5;
/**
 * @title HoneypotAllocationAlgo
 * @dev Responsible for : allocate initial ETH and initial KTY funds to a new honeypot upon its creation
 * @author @ziweidream
 */
import '../proxy/Proxied.sol';
import '../../libs/SafeMath.sol';
import '../../GameVarAndFee.sol';
import '../databases/GenericDB.sol';
import "../../uniswapKTY/uniswap-v2-periphery/interfaces/IUniswapV2Router01.sol";
import "./KtyUniswap.sol";

contract HoneypotAllocationAlgo is Proxied {
    using SafeMath for uint256;

    address[] public path;

    /// @dev game honeypot classfication (based on actual funds in USD)
    string constant VERY_TINY_GAME = "veryTinyGame"; // <= $500
    string constant TINY_GAME = "tinyGame"; // >$500 && <= $1000
    string constant VERY_SMALL_GAME = "verySmallGame"; // > $1000 && <= $2500
    string constant SMALL_GAME = "smallGame"; // > $2500 && <= $5000
    string constant NORMAL_GAME = "normalGame"; // > $5000 && <= $7500
    string constant BIG_GAME = "bigGame"; // > $7500 && <= $10000
    string constant VERY_BIG_GAME = "veryBigGame"; // > $10000 && <= $20000
    string constant HUGE_GAME = "hugeGame"; // > $20000 && <= $30000
    string constant GREAT_GAME = "greatGame"; // > $30000 && <= $40000
    string constant INCREDIBLE_GAME_0 = "incredibleGame0";   // > $40000 && <= $50000
    string constant INCREDIBLE_GAME_1 = "incredibleGame1";   // > $50000 && <= $60000
    string constant INCREDIBLE_GAME_2 = "incredibleGame2";   // > $60000 && <= $70000
    string constant INCREDIBLE_GAME_3 = "incredibleGame3";   // > $70000 && <= $80000
    string constant INCREDIBLE_GAME_4 = "incredibleGame4";   // > $80000 && <= $90000
    string constant INCREDIBLE_GAME_5 = "incredibleGame5";   // > $90000 && <= $100000
    string constant INCREDIBLE_GAME_6 = "incredibleGame6";   // > $100000 && <= $110000
    string constant INCREDIBLE_GAME_7 = "incredibleGame7";   // > $110000 && <= $120000
    string constant INCREDIBLE_GAME_8 = "incredibleGame6";   // > $120000 && <= $130000
    string constant INCREDIBLE_GAME_9 = "incredibleGame9";   // > $130000 && <= $140000
    string constant INCREDIBLE_GAME_10 = "incredibleGame10";   // > $150000 && <= $160000
    string constant INCREDIBLE_GAME_11 = "incredibleGame11";   // > $160000 && <= $170000
    string constant INCREDIBLE_GAME_12 = "incredibleGame12";   // > $170000 && <= $180000
    string constant INCREDIBLE_GAME_13 = "incredibleGame13";   // > $180000 && <= $190000
    string constant INCREDIBLE_GAME_14 = "incredibleGame14";   // > $190000 && <= $200000
    string constant INCREDIBLE_GAME_15 = "incredibleGame15";   // > $200000 && <= $250000
    string constant INCREDIBLE_GAME_16 = "incredibleGame16";   // > $250000 && <= $300000
    string constant INCREDIBLE_GAME_17 = "incredibleGame17"; // > $300000 && <= $350000
    string constant INCREDIBLE_GAME_18 = "incredibleGame18"; // > $350000 && <= $400000
    string constant INCREDIBLE_GAME_19 = "incredibleGame19"; // > $400000 && <= $450000
    string constant INCREDIBLE_GAME_20 = "incredibleGame20"; // > $450000 && <= $500000
    string constant INCREDIBLE_GAME_21 = "incredibleGame21"; // > $500000 && <= $600000
    string constant INCREDIBLE_GAME_22 = "incredibleGame22"; // > $600000 && <= $700000
    string constant INCREDIBLE_GAME_23 = "incredibleGame23"; // > $700000 && <= $800000
    string constant INCREDIBLE_GAME_24 = "incredibleGame24"; // > $800000 && <= $900000
    string constant INCREDIBLE_GAME_25 = "incredibleGame25"; // > $900000 && <= $1000000
    string constant INCREDIBLE_GAME_26 = "incredibleGame26"; // > $1000000 && <= $1500000
    string constant INCREDIBLE_GAME_27 = "incredibleGame27"; // > $1500000 && <= $2000000
    string constant INCREDIBLE_GAME_28 = "incredibleGame28"; // > $2000000 && <= $3000000
    string constant INCREDIBLE_GAME_29 = "incredibleGame29"; // > $3000000 && <= $4000000
    string constant INCREDIBLE_GAME_30 = "incredibleGame30"; // > $4000000 && <= $5000000
    string constant INCREDIBLE_GAME_31 = "incredibleGame31"; // > $5000000 && <= $6000000
    string constant INCREDIBLE_GAME_32 = "incredibleGame32"; // > $6000000 && <= $7000000
    string constant INCREDIBLE_GAME_33 = "incredibleGame33"; // > $7000000 && <= $8000000
    string constant INCREDIBLE_GAME_34 = "incredibleGame34"; // > $8000000 && <= $9,000,000
    string constant INCREDIBLE_GAME_35 = "incredibleGame35"; // > $9,000,000 && <= $10,000,000
    string constant INCREDIBLE_GAME_36 = "incredibleGame36"; // > $10,000,000 && <= $20,000,000

    /// @dev honeypot allocation percentage
    uint256 constant HONEYPOT_ALLOCATION_PERCENTAGE_GREAT            = 1000000; // very tiny game - big game: 100%
    uint256 constant HONEYPOT_ALLOCATION_PERCENTAGE_INCREDIBLE_0_2   = 900000; // Incredible Game 0 - Incredible Game 2: 90%
    uint256 constant HONEYPOT_ALLOCATION_PERCENTAGE_INCREDIBLE_3_5   = 800000; // Incredible Game 3 - Incredible Game 5: 80%
    uint256 constant HONEYPOT_ALLOCATION_PERCENTAGE_INCREDIBLE_6_9   = 700000; // Incredible Game 6 - Incredible Game 9: 70%
    uint256 constant HONEYPOT_ALLOCATION_PERCENTAGE_INCREDIBLE_10_14 = 600000; // Incredible Game 10 - Incredible Game 14: 60%
    uint256 constant HONEYPOT_ALLOCATION_PERCENTAGE_INCREDIBLE_15_20 = 500000; // Incredible Game 15 - Incredible Game 19: 50%
    uint256 constant HONEYPOT_ALLOCATION_PERCENTAGE_INCREDIBLE_21_25 = 400000; // Incredible Game 20 - Incredible Game 24: 40%
    uint256 constant HONEYPOT_ALLOCATION_PERCENTAGE_INCREDIBLE_26_27 = 300000; // Incredible Game 25 - Incredible Game 26: 30%
    uint256 constant HONEYPOT_ALLOCATION_PERCENTAGE_INCREDIBLE_28_30 = 200000; // Incredible Game 27 - Incredible Game 29: 20%
    uint256 constant HONEYPOT_ALLOCATION_PERCENTAGE_INCREDIBLE_31_36 = 100000; // Incredible Game 30 - Incredible Game 35: 10%

    /// @dev an array of all the honeypot incredible-class names
    string[] honeypotClassIncredible = [
        INCREDIBLE_GAME_0, INCREDIBLE_GAME_1, INCREDIBLE_GAME_2,
        INCREDIBLE_GAME_3, INCREDIBLE_GAME_4, INCREDIBLE_GAME_5,
        INCREDIBLE_GAME_6, INCREDIBLE_GAME_7, INCREDIBLE_GAME_8,
        INCREDIBLE_GAME_9, INCREDIBLE_GAME_10, INCREDIBLE_GAME_11,
        INCREDIBLE_GAME_12, INCREDIBLE_GAME_13, INCREDIBLE_GAME_14,
        INCREDIBLE_GAME_15, INCREDIBLE_GAME_16, INCREDIBLE_GAME_17,
        INCREDIBLE_GAME_18, INCREDIBLE_GAME_19, INCREDIBLE_GAME_20,
        INCREDIBLE_GAME_21, INCREDIBLE_GAME_22, INCREDIBLE_GAME_23,
        INCREDIBLE_GAME_24, INCREDIBLE_GAME_25, INCREDIBLE_GAME_26,
        INCREDIBLE_GAME_27, INCREDIBLE_GAME_28, INCREDIBLE_GAME_29,
        INCREDIBLE_GAME_30, INCREDIBLE_GAME_31, INCREDIBLE_GAME_32,
        INCREDIBLE_GAME_33, INCREDIBLE_GAME_34, INCREDIBLE_GAME_35,
        INCREDIBLE_GAME_36
    ];

    function initialize()
    public
    onlyContract(CONTRACT_NAME_ENDOWMENT_FUND)
    {
        address _WETH = proxy.getContract(CONTRACT_NAME_WETH);
        path.push(_WETH);
        address _KTY = proxy.getContract(CONTRACT_NAME_KITTIEFIGHTOKEN);
        path.push(_KTY);
    }

    /**
     * @dev calculates the amount of initial ethers and KTYs allocated to a new honeypot
     * upon its generations, based on the amount of available funds in USD
     * @return ktyAllocated uint256 the amount of initial KTYs allocated to a honeypot
     * @return ethAllocated uint256 the amount of initial ethers allocated to a honeypot
     * @return honeypotClass string the name of the class assigned to a honeypot
     */
    function calculateAllocationToHoneypot()
        public
        view
        // onlyContract(CONTRACT_NAME_ENDOWMENT_DB)
        returns (uint256 ktyAllocated, uint256 ethAllocated, string memory honeypotClass)
    {
        GameVarAndFee gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        uint256 ethUsdPrice = gameVarAndFee.getEthUsdPrice();
        uint256 usdKTYPrice = gameVarAndFee.getUsdKTYPrice();
        uint256 actualFundsETH = GenericDB(proxy.getContract(CONTRACT_NAME_GENERIC_DB))
                                 .getUintStorage(
                                     CONTRACT_NAME_ENDOWMENT_DB,
                                     keccak256(abi.encodePacked("actualFundsETH")));

        uint256 actualFundsUSD = convertETHtoUSD(actualFundsETH);
        uint256 percentageETH;
        if (actualFundsUSD > 40000) {
            (percentageETH, honeypotClass) = _honeypotAllocationETH_incredible(actualFundsUSD);
        } else {
            (percentageETH, honeypotClass) = _honeypotAllocationETH_great(actualFundsUSD);
        }
        ethAllocated = percentageETH.mul(actualFundsETH).div(1000000);
        ktyAllocated = gameVarAndFee.getPercentageHoneypotAllocationKTY()
                                    .mul(ethAllocated).mul(ethUsdPrice)
                                    .div(usdKTYPrice).div(1000000);// 1,000,000 is the percentage base
    }

    /**
    * @dev send reward to the user that pressed finalize button
    */
    function getFinalizeRewards()
        external
        view
        onlyContract(CONTRACT_NAME_ENDOWMENT_FUND)
        returns(uint256)
    {
        GameVarAndFee gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        // get reward amount in KTY
        uint rewardDAI = gameVarAndFee.getFinalizeRewards();
        // convert from Dai to ether
        uint rewardETH = gameVarAndFee.convertDaiToEth(rewardDAI);
        // convert from ether to KTY
        return gameVarAndFee.convertEthToKty(rewardETH);
    }

    /**
    * @dev exchange ether for KTY
    */
    function swapEtherForKTY(uint256 _kty_amount, address _escrow)
        external
        payable
        onlyContract(CONTRACT_NAME_ENDOWMENT_FUND)
        returns(uint256)
    { 
        uint etherForSwap = KtyUniswap(proxy.getContract(CONTRACT_NAME_KTY_UNISWAP)).etherFor(_kty_amount);
        // allow an error within 0.0001 ether range, which is around $0.002 USD, that is, 0.2 cents.
        require(msg.value >= etherForSwap.sub(10000000000000), "Insufficient ether for swap KTY");
        // exchange KTY on uniswap
        IUniswapV2Router01(proxy.getContract(CONTRACT_NAME_UNISWAPV2_ROUTER)).swapExactETHForTokens.value(msg.value)(
            0,
            path,
            _escrow,
            2**255
        );
    }

    /**
     * @dev Convert funds from ether to USD
     * @param _eth uint256 the amount of ethers to be converted to USD
     * @return _usd uint256 the amount of USD converted from ether
     */
    function convertETHtoUSD(uint256 _eth)
        public view returns(uint256 _usd) {
        GameVarAndFee gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        _usd = _eth.mul(gameVarAndFee.getEthUsdPrice()).div(1000000000000000000).div(1000000000000000000);
    }

    /**
     * @dev Determines if a honeypot should belong to the incredible class or not
     * @param _actualFundsUSD uint256 the amount of acutal funds available in USD
     * @return true if the honeypot is of an incredible class
     */
    function _isIncredible(uint256 _actualFundsUSD) internal pure returns(bool) {
        return _actualFundsUSD > 40000;
    }

    /**
     * @dev Determines the percentage of actual funds in ether to be allocated to a new honeypot
     * and the class name of a honeypot
     * @dev This function is for honeypots belonging to an incredible class.
     * @param _actualFundsUSD uint256 the amount of actual funds available in USD, which should be at least $40,000
     * @return percentage uint256 the percentage of actual funds availabe for initial ehter allocation to a honeypot
     * @return honeypotClass string the name of the class of the honeypot
     */
    function _honeypotAllocationETH_incredible(uint256 _actualFundsUSD)
        internal
        view
        returns (uint256 percentage, string memory honeypotClass)
    {
        require(_actualFundsUSD > 40000, "Not enough funds for incredible class");
        // incredible class 0, 1, 2
        if (_actualFundsUSD <= 70000) {
            if (_actualFundsUSD <= 50000) {
            honeypotClass = honeypotClassIncredible[0];
            }
            if (_actualFundsUSD <= 60000 && _actualFundsUSD > 50000) {
                honeypotClass = honeypotClassIncredible[1];
            }
            if (_actualFundsUSD <= 70000 && _actualFundsUSD > 60000) {
                honeypotClass = honeypotClassIncredible[2];
            }
            percentage = HONEYPOT_ALLOCATION_PERCENTAGE_INCREDIBLE_0_2;
        }

        // incredible class 3, 4, 5
        if (_actualFundsUSD > 70000 && _actualFundsUSD <= 100000) {
            if (_actualFundsUSD <= 80000) {
            honeypotClass = honeypotClassIncredible[3];
            }
            if (_actualFundsUSD > 80000 && _actualFundsUSD <= 90000) {
                honeypotClass = honeypotClassIncredible[4];
            }
            if (_actualFundsUSD > 90000 && _actualFundsUSD > 100000) {
                honeypotClass = honeypotClassIncredible[5];
            }
            percentage = HONEYPOT_ALLOCATION_PERCENTAGE_INCREDIBLE_3_5;
        }

        // incredible class 6, 7, 8, 9
        if (_actualFundsUSD > 100000 && _actualFundsUSD <= 140000) {
            if (_actualFundsUSD > 100000 && _actualFundsUSD <= 110000) {
            honeypotClass = honeypotClassIncredible[6];
            }
            if (_actualFundsUSD > 110000 && _actualFundsUSD <= 120000) {
                honeypotClass = honeypotClassIncredible[7];
            }
            if (_actualFundsUSD > 120000 && _actualFundsUSD <= 130000) {
                honeypotClass = honeypotClassIncredible[8];
            }
            if (_actualFundsUSD > 130000 && _actualFundsUSD <= 140000) {
                honeypotClass = honeypotClassIncredible[9];
            }
            percentage = HONEYPOT_ALLOCATION_PERCENTAGE_INCREDIBLE_6_9;
        }

        // incredible class 10, 11, 12, 13, 14
        if (_actualFundsUSD > 150000 && _actualFundsUSD <= 200000) {
            if (_actualFundsUSD > 150000 && _actualFundsUSD <= 160000) {
            honeypotClass = honeypotClassIncredible[10];
            }
            if (_actualFundsUSD > 160000 && _actualFundsUSD <= 170000) {
                honeypotClass = honeypotClassIncredible[11];
            }
            if (_actualFundsUSD > 170000 && _actualFundsUSD <= 180000) {
                honeypotClass = honeypotClassIncredible[12];
            }
            if (_actualFundsUSD > 180000 && _actualFundsUSD <= 190000) {
                honeypotClass = honeypotClassIncredible[13];
            }
            if (_actualFundsUSD > 190000 && _actualFundsUSD <= 200000) {
                honeypotClass = honeypotClassIncredible[14];
            }
            percentage = HONEYPOT_ALLOCATION_PERCENTAGE_INCREDIBLE_10_14;
        }

        // incredible class 15, 16, 17, 18, 19, 20
        if (_actualFundsUSD > 200000 && _actualFundsUSD <= 500000) {
            if (_actualFundsUSD > 200000 && _actualFundsUSD <= 250000) {
            honeypotClass = honeypotClassIncredible[15];
            }
            if (_actualFundsUSD > 250000 && _actualFundsUSD <= 300000) {
                honeypotClass = honeypotClassIncredible[16];
            }
            if (_actualFundsUSD > 300000 && _actualFundsUSD <= 350000) {
                honeypotClass = honeypotClassIncredible[17];
            }
            if (_actualFundsUSD > 350000 && _actualFundsUSD <= 400000) {
                honeypotClass = honeypotClassIncredible[18];
            }
            if (_actualFundsUSD > 400000 && _actualFundsUSD <= 450000) {
                honeypotClass = honeypotClassIncredible[19];
            }
            if (_actualFundsUSD > 450000 && _actualFundsUSD <= 500000) {
                honeypotClass = honeypotClassIncredible[20];
            }
            percentage = HONEYPOT_ALLOCATION_PERCENTAGE_INCREDIBLE_15_20;
        }

        // incredible class 21, 22, 23, 24, 25
        if (_actualFundsUSD > 500000 && _actualFundsUSD <= 1000000) {
            if (_actualFundsUSD > 500000 && _actualFundsUSD <= 600000) {
                honeypotClass = honeypotClassIncredible[21];
            }
            if (_actualFundsUSD > 600000 && _actualFundsUSD <= 7000000) {
                honeypotClass = honeypotClassIncredible[22];
            }
            if (_actualFundsUSD > 700000 && _actualFundsUSD <= 800000) {
                honeypotClass = honeypotClassIncredible[23];
            }
            if (_actualFundsUSD > 800000 && _actualFundsUSD <= 900000) {
                honeypotClass = honeypotClassIncredible[24];
            }
            if (_actualFundsUSD > 900000 && _actualFundsUSD <= 1000000) {
                honeypotClass = honeypotClassIncredible[25];
            }
            percentage = HONEYPOT_ALLOCATION_PERCENTAGE_INCREDIBLE_21_25;
        }

        // incredible class 26, 27
        if (_actualFundsUSD > 1000000 && _actualFundsUSD <= 2000000) {
            if (_actualFundsUSD > 1000000 && _actualFundsUSD <= 1500000) {
                honeypotClass = honeypotClassIncredible[26];
            }
            if (_actualFundsUSD > 1500000 && _actualFundsUSD <= 2000000) {
                honeypotClass = honeypotClassIncredible[27];
            }
            percentage = HONEYPOT_ALLOCATION_PERCENTAGE_INCREDIBLE_26_27;
        }

        // incredible class 28, 29, 30
        if (_actualFundsUSD > 2000000 && _actualFundsUSD <= 5000000) {
            if (_actualFundsUSD > 2000000 && _actualFundsUSD <= 3000000) {
                honeypotClass = honeypotClassIncredible[28];
            }
            if (_actualFundsUSD > 3000000 && _actualFundsUSD <= 4000000) {
                honeypotClass = honeypotClassIncredible[29];
            }
            if (_actualFundsUSD > 4000000 && _actualFundsUSD <= 5000000) {
                honeypotClass = honeypotClassIncredible[30];
            }
            percentage = HONEYPOT_ALLOCATION_PERCENTAGE_INCREDIBLE_28_30;
        }

        // incredible class 31, 32, 33, 34, 35, 36
        if (_actualFundsUSD > 5000000 && _actualFundsUSD <= 20000000) {
            if (_actualFundsUSD > 5000000 && _actualFundsUSD <= 60000000) {
                honeypotClass = honeypotClassIncredible[31];
            }
            if (_actualFundsUSD > 6000000 && _actualFundsUSD <= 7000000) {
                honeypotClass = honeypotClassIncredible[32];
            }
            if (_actualFundsUSD > 7000000 && _actualFundsUSD <= 80000000) {
                honeypotClass = honeypotClassIncredible[33];
            }
            if (_actualFundsUSD > 8000000 && _actualFundsUSD <= 9000000) {
                honeypotClass = honeypotClassIncredible[34];
            }
            if (_actualFundsUSD > 9000000 && _actualFundsUSD <= 10000000) {
                honeypotClass = honeypotClassIncredible[35];
            }
            if (_actualFundsUSD > 10000000 && _actualFundsUSD <= 20000000) {
                honeypotClass = honeypotClassIncredible[36];
            }
            percentage = HONEYPOT_ALLOCATION_PERCENTAGE_INCREDIBLE_31_36;
        }
    }

    /**
     * @dev Determines the percentage of actual funds in ether to be allocated to a new honeypot
     * and the class name of a honeypot
     * @dev This function is for honeypots belonging to a great class or lower.
     * @param _actualFundsUSD uint256 the amount of actual funds available in USD, which should be at most $40,000
     * @return percentage uint256 the percentage of actual funds availabe for initial ehter allocation to a honeypot
     * @return honeypotClass string the name of the class of the honeypot
     */
    function _honeypotAllocationETH_great(uint256 _actualFundsUSD)
        internal
        pure
        returns (uint256 percentage, string memory honeypotClass)
    {
        require(_actualFundsUSD > 0, "Funds must be bigger than 0");
        require(_actualFundsUSD <= 40000, "Too much funds for a honeypot class below increcible");

        if (_actualFundsUSD <= 500) {
            honeypotClass = VERY_TINY_GAME;
        }

        if (_actualFundsUSD > 500 && _actualFundsUSD <= 1000) {
            honeypotClass = TINY_GAME;
        }

        if (_actualFundsUSD > 1000 && _actualFundsUSD <= 2500) {
            honeypotClass = VERY_SMALL_GAME;
        }

        if (_actualFundsUSD > 2500 && _actualFundsUSD <= 5000) {
            honeypotClass = SMALL_GAME;
        }

        if (_actualFundsUSD > 5000 && _actualFundsUSD <= 7500) {
            honeypotClass = NORMAL_GAME;
        }

        if (_actualFundsUSD > 7500 && _actualFundsUSD <= 10000) {
            honeypotClass = BIG_GAME;
        }

        if (_actualFundsUSD > 10000 && _actualFundsUSD <= 20000) {
            honeypotClass = VERY_BIG_GAME;
        }

        if (_actualFundsUSD > 20000 && _actualFundsUSD <= 30000) {
            honeypotClass = HUGE_GAME;
        }

        if (_actualFundsUSD > 30000 && _actualFundsUSD <= 40000) {
            honeypotClass = GREAT_GAME;
        }

        percentage = HONEYPOT_ALLOCATION_PERCENTAGE_GREAT;
    }
}