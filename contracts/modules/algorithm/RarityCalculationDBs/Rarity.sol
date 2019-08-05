pragma solidity ^0.5.5;

import "../../../libs/SafeMath.sol";
import "./KittiesCattributesDB.sol";
import "./CattributesScoresDB.sol";

/**
 * @title This contract is responsible to calculate the rarity level of a kitty 
 * @author @ziweidream
 */
// can only partially implement safe math in this contract due to compilation error of stack too deep
contract Rarity is KittiesCattributesDB, CattributesScoresDB {
    using SafeMath for uint256;

    /**
     * @author @ziweidream
     * @notice calculate a kitty's rarity based on its cattributes
     * @return the rarity of a kittie as an integer
     */

    function calculateRarity(uint256 kittieId)
       public // temporarily set as public just for truffle testing purpose. should be internal
       //internal
       view
       returns (uint256 rarity)
    {
      rarity = (CattributesScores[kittiesDominantCattributes[kittieId][0]]
                + CattributesScores[kittiesDominantCattributes[kittieId][1]]
                + CattributesScores[kittiesDominantCattributes[kittieId][2]]
                + CattributesScores[kittiesDominantCattributes[kittieId][3]]
                + CattributesScores[kittiesDominantCattributes[kittieId][4]]
                + CattributesScores[kittiesDominantCattributes[kittieId][5]]
                + CattributesScores[kittiesDominantCattributes[kittieId][6]]
                + CattributesScores[kittiesDominantCattributes[kittieId][8]]).mul(100000000).div(totalKitties);
    }
}