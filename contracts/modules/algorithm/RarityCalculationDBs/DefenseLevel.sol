pragma solidity ^0.5.5;

import "../../../authority/Owned.sol";

/**
 * @title This contract is responsible to set lower and upper limit of each defense level
 * @author @ziweidream
 */
contract DefenseLevel is Owned {
    
    struct DefenseLevelLimit {
        uint level1Limit;
        uint level2Limit;
        uint level3Limit;
        uint level4Limit;
        uint level5Limit;
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
    function setDefenseLevelLimit (uint max, uint min, uint totalKitties) public onlyOwner {
      defenseLevelLimit.level5Limit = (max - min) * 10000000 / totalKitties;
      defenseLevelLimit.level4Limit = (max - min) * 20000000 / totalKitties;
      defenseLevelLimit.level3Limit = (max - min) * 40000000 / totalKitties;
      defenseLevelLimit.level2Limit = (max - min) * 60000000 / totalKitties;
      defenseLevelLimit.level1Limit = (max - min) * 80000000 / totalKitties;
    }
}