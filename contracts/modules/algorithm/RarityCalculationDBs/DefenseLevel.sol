pragma solidity ^0.5.5;

import "../../../libs/SafeMath.sol";
import "../../proxy/Proxied.sol";
import "../../../authority/Guard.sol";

/**
 * @title This contract is responsible to set lower and upper limit of each defense level
 * @author @ziweidream
 */
contract DefenseLevel is Proxied, Guard {
    using SafeMath for uint256;

    struct DefenseLevelLimit {
        uint256 level1Limit;
        uint256 level2Limit;
        uint256 level3Limit;
        uint256 level4Limit;
        uint256 level5Limit;
    }

    DefenseLevelLimit internal defenseLevelLimit;

    /**
     * @author @ziweidream
     * @notice set the lower and upper limit of each defense level of a kitty
     * @param max the sum of the maximum score of all types of cattributes
     * @param min the sum of the minimum score of all types of cattributes
     * @param totalKitties the total number of cryptokitties on CryptoKitties
     * @dev maximum and minimum scores of all types of cattributes are obtained from https://api.cryptokitties.co/cattributes
     * @dev example of maximum and minimum scores of all types of cattributes
     *        type	  max	   min
            pattern	357328	1754
              eyes	261737	1845
              mouth	239894	961
             color3	231062	758
             color2	208081	832
            color1	197753	1381
               body	178290	904
         coloreyes	158208	740
               sum 	1832353	9175
     */
    function setDefenseLevelLimit (uint256 max, uint256 min, uint256 totalKitties)
        public // temporarily set as public just for truffle test purpose
        // internal
        //onlySuperAdmin
      {
      defenseLevelLimit.level5Limit = (max.sub(min)).mul(10000000).div(totalKitties);
      defenseLevelLimit.level4Limit = (max.sub(min)).mul(20000000).div(totalKitties);
      defenseLevelLimit.level3Limit = (max.sub(min)).mul(40000000).div(totalKitties);
      defenseLevelLimit.level2Limit = (max.sub(min)).mul(60000000).div(totalKitties);
      defenseLevelLimit.level1Limit = (max.sub(min)).mul(80000000).div(totalKitties);
    }
}